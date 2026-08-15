import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { PreferencesStore } from '../data/PreferencesStore';
import { JsonDateCandidateResult, JsonTransfer } from '../data/JsonTransfer';
import { MenstrualDay } from '../domain/MenstrualData';
import { formatShortDate, todayKey } from '../domain/DateUtils';
import { parseTextDates, TextDateParseResult } from '../domain/TextDateParser';
import { ImportValidationResult, validateImportDates } from '../domain/ImportValidator';
import { classifyLayoutMode } from '../domain/ResponsiveLayout';
import { ResponsivePageShell } from '../components/ResponsivePageShell';
import { WelcomeComponent } from '../components/WelcomeComponent';
import { LoadingComponent } from '../components/LoadingComponent';
import { AboutComponent } from '../components/AboutComponent';
import { TextImportComponent } from '../components/TextImportComponent';
import { ImportConfirmationComponent } from '../components/ImportConfirmationComponent';

const PINK_BACKGROUND: string = '#F8F2F3';
const GITHUB_REPOSITORY_URL: string = 'https://github.com/Kiruno-lz/hercula';
const SHOW_LAYOUT_MODE_DEBUG: boolean = false;

@Entry
@Preview
@Component
struct Index {
  @State private markedDays: Array<MenstrualDay> = [];
  @State private feedback: string = '';
  @State private welcomeDialogOpen: boolean = false;
  @State private aboutDialogOpen: boolean = false;
  @State private textImportDialogOpen: boolean = false;
  @State private textImportInput: string = '';
  @State private textImportNotice: string = '';
  @State private jsonImportIssues: TextDateParseResult = { dates: [], invalidTokens: [], duplicateDates: [] };
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
  @State private windowWidth: number = 1320;
  @State private windowHeight: number = 2120;
  private store: PreferencesStore | undefined = undefined;
  private appWindow: window.Window | undefined = undefined;
  private appliedOrientation: window.Orientation | undefined = undefined;
  private readonly onWindowSizeChange: (size: window.Size) => void =
    (size: window.Size): void => {
      this.updateWindowSize(size.width, size.height);
    };
  private readonly onWindowRectChange: (options: window.RectChangeOptions) => void =
    (options: window.RectChangeOptions): void => {
      this.updateWindowSize(options.rect.width, options.rect.height);
    };

  aboutToAppear(): void {
    this.loadLocalData();
  }

  onPageShow(): void {
    this.refreshWindowMetrics();
  }

  onPageHide(): void {
    if (this.appWindow !== undefined) {
      this.detachWindowListeners(this.appWindow);
      this.appWindow = undefined;
      this.appliedOrientation = undefined;
    }
  }

  private async refreshWindowMetrics(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        return;
      }
      const currentWindow: window.Window = await window.getLastWindow(context);
      if (this.appWindow !== currentWindow) {
        if (this.appWindow !== undefined) {
          this.detachWindowListeners(this.appWindow);
        }
        this.appWindow = currentWindow;
        this.appWindow.on('windowSizeChange', this.onWindowSizeChange);
        this.appWindow.on('windowRectChange', this.onWindowRectChange);
      }
      const rect: window.Rect = currentWindow.getWindowProperties().windowRect;
      this.updateWindowSize(rect.width, rect.height);
    } catch (_error) {
      // Previewer may not provide a real application window; keep preview defaults.
    }
  }

  private updateWindowSize(width: number, height: number): void {
    if (width > 0 && height > 0
      && (width !== this.windowWidth || height !== this.windowHeight)) {
      this.windowWidth = width;
      this.windowHeight = height;
      this.applyOrientationPolicy(width, height);
    }
  }

  private async applyOrientationPolicy(width: number, height: number): Promise<void> {
    if (this.appWindow === undefined) {
      return;
    }
    const targetOrientation: window.Orientation = classifyLayoutMode(width, height) === 'scroll'
      ? window.Orientation.PORTRAIT
      : window.Orientation.AUTO_ROTATION;
    if (this.appliedOrientation === targetOrientation) {
      return;
    }
    try {
      await this.appWindow.setPreferredOrientation(targetOrientation);
      this.appliedOrientation = targetOrientation;
    } catch (_error) {
      // Keep the last valid orientation policy when the current window rejects a change.
    }
  }

  private async loadLocalData(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        return;
      }
      this.store = await PreferencesStore.open(context);
      this.markedDays = await this.store.loadDays();
      if (!(await this.store.hasSeenWelcome())) {
        await this.store.markWelcomeShown();
        this.showWelcomeDialog();
      }
    } catch (_error) {
      this.feedback = '本地记录读取失败，当前仅显示空白记录';
    } finally {
      this.isLoading = false;
    }
  }

  private showWelcomeDialog(): void {
    this.welcomeDialogOpen = true;
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
      this.feedback = `${formatShortDate(date)} 已取消`;
    } else {
      this.markedDays = this.markedDays.concat([{ date: date, source: 'manual' }]);
      this.feedback = `${formatShortDate(date)} 已记录`;
    }
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
    this.jsonImportIssues = { dates: [], invalidTokens: [], duplicateDates: [] };
    this.textImportDialogOpen = true;
  }

  private closeTextImportDialog(): void {
    this.textImportDialogOpen = false;
    this.textImportInput = '';
    this.textImportNotice = '';
    this.jsonImportIssues = { dates: [], invalidTokens: [], duplicateDates: [] };
  }

  private async loadJsonIntoTextImport(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        this.textImportNotice = '无法打开文件选择器，请稍后重试';
        return;
      }
      const result: JsonDateCandidateResult | undefined = await JsonTransfer.selectDateCandidates(context);
      if (result === undefined) {
        this.textImportNotice = '未选择文件，当前输入内容未改变';
        return;
      }
      this.textImportInput = result.dates.join('\n');
      this.jsonImportIssues = {
        dates: result.dates,
        invalidTokens: result.invalidTokens,
        duplicateDates: result.duplicateDates
      };
      const issueCount: number = result.invalidTokens.length + result.duplicateDates.length;
      this.textImportNotice = issueCount === 0
        ? `已加载 ${result.dates.length} 个日期，可继续校对`
        : `已加载 ${result.dates.length} 个日期，另有 ${issueCount} 项待确认`;
    } catch (_error) {
      this.textImportNotice = 'JSON 解析失败：请确认文件符合月迹 schema v1';
    }
  }

  private continueTextImport(): void {
    const result: TextDateParseResult = parseTextDates(this.textImportInput);
    const validation: ImportValidationResult = validateImportDates({
      dates: result.dates,
      invalidTokens: result.invalidTokens.concat(this.jsonImportIssues.invalidTokens),
      duplicateDates: result.duplicateDates.concat(this.jsonImportIssues.duplicateDates),
      existingDates: this.markedDays.map((item: MenstrualDay): string => item.date),
      today: todayKey()
    });
    if (validation.candidateDates.length === 0 && validation.invalidTokens.length === 0) {
      this.feedback = '请输入至少一个明确格式的日期';
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
    const days: Array<MenstrualDay> = this.importValidation.validDates.map((date: string): MenstrualDay => {
      return { date: date, source: 'import' };
    });
    if (days.length === 0) {
      this.feedback = '没有可导入的新日期';
      return;
    }
    this.markedDays = this.markedDays.concat(days);
    await this.persistDays();
    this.importConfirmationOpen = false;
    this.closeTextImportDialog();
    this.resetImportValidation();
    this.feedback = `已导入并合并 ${days.length} 个日期`;
  }

  build() {
    Stack() {
      if (this.isLoading) {
        LoadingComponent()
      } else {
        ResponsivePageShell({
          markedDays: this.markedDays,
          viewportWidth: this.windowWidth,
          viewportHeight: this.windowHeight,
          showLayoutModeDebug: SHOW_LAYOUT_MODE_DEBUG,
          onToggleDate: (date: string): void => {
            this.toggleDate(date);
          },
          onImport: (): void => this.openTextImportDialog(),
          onExport: (): void => {
            this.exportJson();
          },
          onAbout: (): void => {
            this.aboutDialogOpen = true;
          }
        })
      }
      if (this.textImportDialogOpen) {
        TextImportComponent({
          textImportInput: this.textImportInput,
          textImportNotice: this.textImportNotice,
          onInputChange: (value: string): void => {
            this.textImportInput = value;
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
          importValidation: this.importValidation,
          onBack: (): void => this.closeImportConfirmation(),
          onConfirm: (): void => {
            this.confirmImport();
          }
        })
      }
      if (this.welcomeDialogOpen) {
        WelcomeComponent({
          onStart: (): void => this.closeWelcomeDialog(),
          onImport: (): void => {
            this.closeWelcomeDialog();
            this.openTextImportDialog();
          }
        })
      }
      if (this.aboutDialogOpen) {
        AboutComponent({
          repositoryUrl: GITHUB_REPOSITORY_URL,
          onClose: (): void => {
            this.aboutDialogOpen = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND)
  }


  private async exportJson(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined = this.getAbilityContext();
      if (context === undefined) {
        this.feedback = '导出失败，请稍后重试';
        return;
      }
      const saved: boolean = await JsonTransfer.export(context, this.markedDays);
      this.feedback = saved ? '已导出月迹 JSON' : '已取消导出';
    } catch (_error) {
      this.feedback = '导出失败，请稍后重试';
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

  private detachWindowListeners(targetWindow: window.Window): void {
    try {
      targetWindow.off('windowSizeChange', this.onWindowSizeChange);
    } catch (_error) {
      // The window may already be disposed during a page transition.
    }
    try {
      targetWindow.off('windowRectChange', this.onWindowRectChange);
    } catch (_error) {
      // The window may already be disposed during a page transition.
    }
  }

  private isFutureDate(date: string): boolean {
    return date > todayKey();
  }
}
