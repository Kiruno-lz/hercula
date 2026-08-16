import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { classifyLayoutMode } from '../domain/ResponsiveLayout';

export interface WindowMetricsSnapshot {
  width: number;
  height: number;
  safeAreaTopInset: number;
  safeAreaBottomInset: number;
  densityPixels: number;
}

export class WindowMetricsController {
  private readonly onChange: (snapshot: WindowMetricsSnapshot) => void;
  private appWindow: window.Window | undefined = undefined;
  private appliedOrientation: window.Orientation | undefined = undefined;
  private snapshot: WindowMetricsSnapshot = {
    width: 0,
    height: 0,
    safeAreaTopInset: 0,
    safeAreaBottomInset: 0,
    densityPixels: 1
  };
  private readonly onWindowSizeChange: (size: window.Size) => void = (size: window.Size): void => {
    this.updateSize(size.width, size.height);
  };
  private readonly onWindowRectChange: (options: window.RectChangeOptions) => void =
    (options: window.RectChangeOptions): void => {
      this.updateSize(options.rect.width, options.rect.height);
    };
  private readonly onAvoidAreaChange: (options: window.AvoidAreaOptions) => void =
    (options: window.AvoidAreaOptions): void => {
      if (options.type === window.AvoidAreaType.TYPE_SYSTEM) {
        this.updateSafeArea(options.area);
      }
    };

  constructor(onChange: (snapshot: WindowMetricsSnapshot) => void) {
    this.onChange = onChange;
  }

  async refresh(context: common.UIAbilityContext): Promise<void> {
    try {
      const currentWindow: window.Window = await window.getLastWindow(context);
      this.attach(currentWindow);
      const properties: window.WindowProperties = currentWindow.getWindowProperties();
      const rect: window.Rect = properties.windowRect;
      if (properties.displayId !== undefined) {
        const currentDisplay: display.Display = display.getDisplayByIdSync(properties.displayId);
        this.updateDensity(currentDisplay.densityPixels);
      }
      this.updateSafeArea(currentWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM));
      this.updateSize(rect.width, rect.height);
    } catch (_error) {
    }
  }

  detach(): void {
    if (this.appWindow !== undefined) {
      try {
        this.appWindow.off('windowSizeChange', this.onWindowSizeChange);
      } catch (_error) {}
      try {
        this.appWindow.off('windowRectChange', this.onWindowRectChange);
      } catch (_error) {}
      try {
        this.appWindow.off('avoidAreaChange', this.onAvoidAreaChange);
      } catch (_error) {}
      this.appWindow = undefined;
    }
    this.appliedOrientation = undefined;
  }

  private attach(currentWindow: window.Window): void {
    if (this.appWindow === currentWindow) {
      return;
    }
    this.detach();
    this.appWindow = currentWindow;
    try {
      currentWindow.on('windowSizeChange', this.onWindowSizeChange);
      currentWindow.on('windowRectChange', this.onWindowRectChange);
      currentWindow.on('avoidAreaChange', this.onAvoidAreaChange);
    } catch (_error) {
      this.appWindow = undefined;
    }
  }

  private updateSize(width: number, height: number): void {
    if (width <= 0 || height <= 0
      || (width === this.snapshot.width && height === this.snapshot.height)) {
      return;
    }
    this.snapshot.width = width;
    this.snapshot.height = height;
    this.emit();
    this.applyOrientation(width, height);
  }

  private updateSafeArea(area: window.AvoidArea): void {
    const topInset: number = Math.max(0, area.topRect.height);
    const bottomInset: number = Math.max(0, area.bottomRect.height);
    if (topInset === this.snapshot.safeAreaTopInset && bottomInset === this.snapshot.safeAreaBottomInset) {
      return;
    }
    this.snapshot.safeAreaTopInset = topInset;
    this.snapshot.safeAreaBottomInset = bottomInset;
    this.emit();
  }

  private updateDensity(density: number): void {
    if (density <= 0 || density === this.snapshot.densityPixels) {
      return;
    }
    this.snapshot.densityPixels = density;
    this.emit();
  }

  private emit(): void {
    this.onChange({
      width: this.snapshot.width,
      height: this.snapshot.height,
      safeAreaTopInset: this.snapshot.safeAreaTopInset,
      safeAreaBottomInset: this.snapshot.safeAreaBottomInset,
      densityPixels: this.snapshot.densityPixels
    });
  }

  private async applyOrientation(width: number, height: number): Promise<void> {
    if (this.appWindow === undefined) {
      return;
    }
    const orientation: window.Orientation = classifyLayoutMode(width, height) === 'scroll'
      ? window.Orientation.PORTRAIT
      : window.Orientation.AUTO_ROTATION;
    if (this.appliedOrientation === orientation) {
      return;
    }
    try {
      await this.appWindow.setPreferredOrientation(orientation);
      this.appliedOrientation = orientation;
    } catch (_error) {
    }
  }
}
