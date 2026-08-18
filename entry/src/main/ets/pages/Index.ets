import { common } from '@kit.AbilityKit';
import { PreferencesStore } from '../data/PreferencesStore';
import { JsonCandidateLoadResult, JsonTransfer } from '../data/JsonTransfer';
import {
  derivePeriods,
  MenstrualDay,
  PeriodProbability,
  predictCycleForecast
} from '../domain/MenstrualData';
import { todayKey } from '../domain/DateUtils';
import { DateCandidateResult, ImportIssues } from '../domain/ImportTypes';
import { createImportedDays, validateTextImport } from '../domain/ImportPipeline';
import { ImportValidationResult } from '../domain/ImportValidator';
import { WindowMetricsController, WindowMetricsSnapshot } from '../platform/WindowMetricsController';
import { ResponsivePageShell } from '../components/ResponsivePageShell';
import { WelcomeComponent } from '../components/WelcomeComponent';
import { LoadingComponent } from '../components/LoadingComponent';
import { AboutComponent } from '../components/AboutComponent';
import { TextImportComponent } from '../components/TextImportComponent';
import { ImportConfirmationComponent } from '../components/ImportConfirmationComponent';
import { DEFAULT_THEME_ID, resolveTheme, ThemeId, ThemePalette } from '../domain/Theme';

const GITHUB_REPOSITORY_URL: string = 'https://github.com/Kiruno-lz/hercula';

@Entry
@Preview
@Component
struct Index {
  @State private markedDays: Array<MenstrualDay> = [];
  // Swiper 会缓存离屏页面；每次记录变化都递增，通知历史页重建其派生列表。
  @State private dataRevision: number = 0;
  @State private welcomeDialogOpen: boolean = false;
  @State private aboutDialogOpen: boolean = false;
  @State private textImportDialogOpen: boolean = false;
  @State private textImportInput: string = '';
  @State private textImportNotice: string = '';
  @State private jsonImportIssues: ImportIssues = { invalidTokens: [], duplicateDates: [] };
  @State private importConfirmationOpen: boolean = false;
  @State private importValidation: ImportValidationResult = {
    candidateDates: [],
    validDates: [],
    futureDates: [],
    duplicateDates: [],
    existingDates: [],
    invalidTokens: []
  };
  @State private isLoading: boolean = true;
  @State private themeId: ThemeId = DEFAULT_THEME_ID;
  @State private windowWidth: number = 1320;
  @State private windowHeight: number = 2120;
  @State private safeAreaTopInset: number = 0;
  @State private safeAreaBottomInset: number = 0;
  @State private densityPixels: number = 1;
  private jsonCandidateLoaded: boolean = false;
  private importConfirmationInProgress: boolean = false;
  private store: PreferencesStore | undefined = undefined;
  private readonly windowMetrics: WindowMetricsController = new WindowMetricsController(
    (snapshot: WindowMetricsSnapshot): void => this.applyWindowMetrics(snapshot)
  );

  aboutToAppear(): void {
    this.loadLocalData();
  }

  onPageShow(): void {
    this.refreshWindowMetrics();
  }

  onPageHide(): void {
    this.windowMetrics.detach();
  }

  private async refreshWindowMetrics(): Promise<void> {
    const context: common.UIAbilityContext | undefined = this.getAbilityContext();
    if (context !== undefined) {
      await this.windowMetrics.refresh(context);
    }
  }

  private applyWindowMetrics(snapshot: WindowMetricsSnapshot): void {
    if (snapshot.width > 0 && snapshot.height > 0) {
      this.windowWidth = snapshot.width;
      this.windowHeight = snapshot.height;
    }
    this.safeAreaTopInset = snapshot.safeAreaTopInset;
    this.safeAreaBottomInset = snapshot.safeAreaBottomInset;
    if (snapshot.densityPixels > 0) {
      this.densityPixels = snapshot.densityPixels;
    }
  }

  private async loadLocalData(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        return;
      }
      this.store = await PreferencesStore.open(context);
      this.markedDays = (await this.store.loadDays()).days;
      this.themeId = (await this.store.loadTheme()).themeId;
      if (!(await this.store.hasSeenWelcome()).seen) {
        await this.store.markWelcomeShown();
        this.showWelcomeDialog();
      }
    } catch (_error) {
    } finally {
      this.isLoading = false;
    }
  }

  private showWelcomeDialog(): void {
    this.welcomeDialogOpen = true;
  }

  private async selectTheme(themeId: ThemeId): Promise<void> {
    this.themeId = themeId;
    if (this.store !== undefined) {
      await this.store.saveTheme(themeId);
    }
  }

  private closeWelcomeDialog(): void {
    this.welcomeDialogOpen = false;
  }

  private async toggleDate(date: string): Promise<void> {
    if (this.isFutureDate(date)) {
      return;
    }
    if (this.hasDate(date)) {
      this.markedDays = this.markedDays.filter((item: MenstrualDay): boolean => item.date !== date);
    } else {
      this.markedDays = this.markedDays.concat([{ date: date, source: 'manual' }]);
    }
    this.dataRevision += 1;
    await this.persistDays();
  }

  private async persistDays(): Promise<void> {
    if (this.store !== undefined) {
      await this.store.saveDays(this.markedDays);
    }
  }

  private openTextImportDialog(): void {
    this.textImportInput = '';
    this.textImportNotice = '';
    this.jsonImportIssues = { invalidTokens: [], duplicateDates: [] };
    this.jsonCandidateLoaded = false;
    this.textImportDialogOpen = true;
  }

  private closeTextImportDialog(): void {
    this.textImportDialogOpen = false;
    this.textImportInput = '';
    this.textImportNotice = '';
    this.jsonImportIssues = { invalidTokens: [], duplicateDates: [] };
    this.jsonCandidateLoaded = false;
  }

  private async loadJsonIntoTextImport(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        this.textImportNotice = '无法打开文件选择器，请稍后重试';
        return;
      }
      const result: JsonCandidateLoadResult = await JsonTransfer.selectDateCandidates(context);
      if (result.status !== 'success' || result.candidates === undefined) {
        return;
      }
      const candidates: DateCandidateResult = result.candidates;
      this.textImportInput = candidates.dates.join('\n');
      this.jsonImportIssues = {
        invalidTokens: candidates.invalidTokens,
        duplicateDates: candidates.duplicateDates
      };
      this.jsonCandidateLoaded = true;
      const issueCount: number = candidates.invalidTokens.length + candidates.duplicateDates.length;
      this.textImportNotice = issueCount === 0
        ? `已加载 ${candidates.dates.length} 个日期，可继续校对`
        : `已加载 ${candidates.dates.length} 个日期，另有 ${issueCount} 项待确认`;
    } catch (_error) {
      this.textImportNotice = 'JSON 解析失败：请确认文件符合月迹 schema v1';
    }
  }

  private continueTextImport(): void {
    const validation: ImportValidationResult = validateTextImport({
      text: this.textImportInput,
      jsonIssues: this.jsonImportIssues,
      existingDates: this.markedDays.map((item: MenstrualDay): string => item.date),
      today: todayKey(),
      currentYear: new Date().getFullYear()
    });
    const allowEmptyJsonResult: boolean = this.jsonCandidateLoaded;
    this.jsonCandidateLoaded = false;
    if (validation.candidateDates.length === 0 && validation.invalidTokens.length === 0 && !allowEmptyJsonResult) {
      return;
    }
    this.importValidation = validation;
    this.textImportDialogOpen = false;
    this.importConfirmationOpen = true;
  }

  private closeImportConfirmation(): void {
    this.importConfirmationOpen = false;
    this.textImportDialogOpen = true;
  }

  private resetImportValidation(): void {
    this.importValidation = {
      candidateDates: [],
      validDates: [],
      futureDates: [],
      duplicateDates: [],
      existingDates: [],
      invalidTokens: []
    };
  }

  private async confirmImport(): Promise<void> {
    if (this.importConfirmationInProgress) {
      return;
    }
    this.importConfirmationInProgress = true;
    try {
      const days: Array<MenstrualDay> = createImportedDays(this.importValidation.validDates);
      if (days.length === 0) {
        return;
      }
      this.markedDays = this.markedDays.concat(days);
      this.dataRevision += 1;
      await this.persistDays();
      this.importConfirmationOpen = false;
      this.closeTextImportDialog();
      this.resetImportValidation();
    } finally {
      this.importConfirmationInProgress = false;
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        LoadingComponent({ theme: this.currentTheme() })
      } else {
        ResponsivePageShell({
          markedDays: this.markedDays,
          dataRevision: this.dataRevision,
          viewportWidth: this.windowWidth,
          viewportHeight: this.windowHeight,
          safeAreaTopInset: this.safeAreaTopInset,
          safeAreaBottomInset: this.safeAreaBottomInset,
          densityPixels: this.densityPixels,
          theme: this.currentTheme(),
          selectedThemeId: this.themeId,
          periodProbability: this.currentPeriodProbability(),
          onToggleDate: (date: string): void => {
            this.toggleDate(date);
          },
          onImport: (): void => this.openTextImportDialog(),
          onExport: (): void => {
            this.exportJson();
          },
          onAbout: (): void => {
            this.aboutDialogOpen = true;
          },
          onThemeChange: (themeId: ThemeId): void => {
            this.selectTheme(themeId);
          }
        })
      }
      if (this.textImportDialogOpen) {
        TextImportComponent({
          theme: this.currentTheme(),
          textImportInput: this.textImportInput,
          textImportNotice: this.textImportNotice,
          onInputChange: (value: string): void => {
            this.textImportInput = value;
            this.jsonCandidateLoaded = false;
          },
          onLoadJson: (): void => {
            this.loadJsonIntoTextImport();
          },
          onCancel: (): void => this.closeTextImportDialog(),
          onContinue: (): void => this.continueTextImport()
        })
      }
      if (this.importConfirmationOpen) {
        ImportConfirmationComponent({
          theme: this.currentTheme(),
          importValidation: this.importValidation,
          onBack: (): void => this.closeImportConfirmation(),
          onConfirm: (): void => {
            this.confirmImport();
          }
        })
      }
      if (this.welcomeDialogOpen) {
        WelcomeComponent({
          theme: this.currentTheme(),
          onStart: (): void => this.closeWelcomeDialog(),
          onImport: (): void => {
            this.closeWelcomeDialog();
            this.openTextImportDialog();
          }
        })
      }
      if (this.aboutDialogOpen) {
        AboutComponent({
          theme: this.currentTheme(),
          repositoryUrl: GITHUB_REPOSITORY_URL,
          onClose: (): void => {
            this.aboutDialogOpen = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentTheme().pageBackground)
  }

  private currentTheme(): ThemePalette {
    return resolveTheme(this.themeId);
  }

  private currentPeriodProbability(): Array<PeriodProbability> {
    const forecast = predictCycleForecast(derivePeriods(this.markedDays, todayKey()));
    if (forecast === undefined) {
      return [];
    }
    return forecast.periodProbability
      .slice()
      .sort((left: PeriodProbability, right: PeriodProbability): number => {
        return right.probability - left.probability;
      })
      .slice(0, 5)
      .sort((left: PeriodProbability, right: PeriodProbability): number => {
        return left.date < right.date ? -1 : (left.date > right.date ? 1 : 0);
      });
  }


  private async exportJson(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        return;
      }
      await JsonTransfer.export(context, this.markedDays);
    } catch (_error) {
    }
  }

  private hasDate(date: string): boolean {
    return this.markedDays.some((item: MenstrualDay): boolean => item.date === date);
  }

  private getAbilityContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      return undefined;
    }
    return hostContext as common.UIAbilityContext;
  }

  private isFutureDate(date: string): boolean {
    return date > todayKey();
  }
}
