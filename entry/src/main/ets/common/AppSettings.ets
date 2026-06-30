import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';

export const APP_THEME_KEY: string = 'appThemeMode';
export const APP_LANGUAGE_KEY: string = 'appLanguage';
export const THEME_LIGHT: string = 'light';
export const THEME_DARK: string = 'dark';
export const LANG_ZH: string = 'zh';
export const LANG_EN: string = 'en';

const PREFERENCES_NAME: string = 'opentabssh_app_settings';

class AppSettingsStore {
  private store: dataPreferences.Preferences | undefined = undefined;
  private initialized: boolean = false;

  initialize(context: common.Context): void {
    this.ensureStorageDefaults();
    if (this.initialized) {
      return;
    }
    try {
      this.store = dataPreferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      const themeValue: string = this.normalizeTheme(this.store.getSync(APP_THEME_KEY, THEME_LIGHT) as string);
      const languageValue: string = this.normalizeLanguage(this.store.getSync(APP_LANGUAGE_KEY, LANG_ZH) as string);
      AppStorage.setOrCreate<string>(APP_THEME_KEY, themeValue);
      AppStorage.setOrCreate<string>(APP_LANGUAGE_KEY, languageValue);
      this.initialized = true;
    } catch (error) {
      this.store = undefined;
      this.initialized = true;
    }
  }

  currentThemeMode(): string {
    return this.normalizeTheme(AppStorage.get<string>(APP_THEME_KEY) || THEME_LIGHT);
  }

  currentLanguage(): string {
    return this.normalizeLanguage(AppStorage.get<string>(APP_LANGUAGE_KEY) || LANG_ZH);
  }

  setThemeMode(mode: string): void {
    const nextMode: string = this.normalizeTheme(mode);
    AppStorage.setOrCreate<string>(APP_THEME_KEY, nextMode);
    this.persist(APP_THEME_KEY, nextMode);
  }

  setLanguage(language: string): void {
    const nextLanguage: string = this.normalizeLanguage(language);
    AppStorage.setOrCreate<string>(APP_LANGUAGE_KEY, nextLanguage);
    this.persist(APP_LANGUAGE_KEY, nextLanguage);
  }

  private ensureStorageDefaults(): void {
    AppStorage.setOrCreate<string>(APP_THEME_KEY, THEME_LIGHT);
    AppStorage.setOrCreate<string>(APP_LANGUAGE_KEY, LANG_ZH);
  }

  private normalizeTheme(mode: string): string {
    return mode === THEME_DARK ? THEME_DARK : THEME_LIGHT;
  }

  private normalizeLanguage(language: string): string {
    return language === LANG_EN ? LANG_EN : LANG_ZH;
  }

  private persist(key: string, value: string): void {
    const store: dataPreferences.Preferences | undefined = this.store;
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(key, value);
      store.flushSync();
    } catch (error) {
    }
  }
}

export const AppSettingsRepository: AppSettingsStore = new AppSettingsStore();
