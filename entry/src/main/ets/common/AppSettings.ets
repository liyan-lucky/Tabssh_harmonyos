import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import i18n from '@ohos.i18n';

export const APP_THEME_KEY: string = 'appThemeMode';
export const APP_LANGUAGE_KEY: string = 'appLanguage';
export const THEME_LIGHT: string = 'light';
export const THEME_DARK: string = 'dark';
export const LANG_SYSTEM: string = 'system';
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
      const languageValue: string = this.normalizeLanguage(this.store.getSync(APP_LANGUAGE_KEY, LANG_SYSTEM) as string);
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
    return this.normalizeLanguage(AppStorage.get<string>(APP_LANGUAGE_KEY) || LANG_SYSTEM);
  }

  effectiveLanguage(language: string = this.currentLanguage()): string {
    return resolveEffectiveLanguage(language);
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
    AppStorage.setOrCreate<string>(APP_LANGUAGE_KEY, LANG_SYSTEM);
  }

  private normalizeTheme(mode: string): string {
    return mode === THEME_DARK ? THEME_DARK : THEME_LIGHT;
  }

  private normalizeLanguage(language: string): string {
    if (language === LANG_SYSTEM || language === LANG_EN) {
      return language;
    }
    return LANG_ZH;
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

export function resolveEffectiveLanguage(language: string): string {
  if (language === LANG_SYSTEM) {
    const systemLanguage: string = currentSystemSupportedLanguage();
    return systemLanguage.length > 0 ? systemLanguage : LANG_ZH;
  }
  return language === LANG_EN ? LANG_EN : LANG_ZH;
}

function currentSystemSupportedLanguage(): string {
  try {
    const firstPreferred: string = i18n.System.getFirstPreferredLanguage();
    const matched: string = matchSupportedLanguage(firstPreferred);
    if (matched.length > 0) {
      return matched;
    }
  } catch (error) {
  }
  try {
    const preferredLanguages: string[] = i18n.System.getPreferredLanguageList();
    for (let i = 0; i < preferredLanguages.length; i++) {
      const matched: string = matchSupportedLanguage(preferredLanguages[i]);
      if (matched.length > 0) {
        return matched;
      }
    }
  } catch (error) {
  }
  try {
    const matched: string = matchSupportedLanguage(i18n.System.getSystemLanguage());
    if (matched.length > 0) {
      return matched;
    }
  } catch (error) {
  }
  try {
    return matchSupportedLanguage(i18n.System.getSystemLocale());
  } catch (error) {
  }
  return '';
}

function matchSupportedLanguage(languageTag: string): string {
  const tag: string = languageTag.toLowerCase().replace('_', '-');
  if (tag === LANG_EN || tag.startsWith('en-')) {
    return LANG_EN;
  }
  if (tag === LANG_ZH || tag.startsWith('zh-')) {
    return LANG_ZH;
  }
  return '';
}
