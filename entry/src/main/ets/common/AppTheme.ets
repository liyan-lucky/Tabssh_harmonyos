import { THEME_DARK } from './AppSettings';

export class AppTheme {
  static isDark(mode: string): boolean {
    return mode === THEME_DARK;
  }

  static pageBg(mode: string): string {
    return mode === THEME_DARK ? '#171A1E' : '#F0F4FA';
  }

  static cardBg(mode: string): string {
    return mode === THEME_DARK ? '#20242B' : '#FFFFFF';
  }

  static elevatedBg(mode: string): string {
    return mode === THEME_DARK ? '#252A33' : '#F7FAFF';
  }

  static textPrimary(mode: string): string {
    return mode === THEME_DARK ? '#F8FAFC' : '#171A1E';
  }

  static textSecond(mode: string): string {
    return mode === THEME_DARK ? '#AAB2C5' : '#5C6675';
  }

  static textMuted(mode: string): string {
    return mode === THEME_DARK ? '#7E879A' : '#7B8491';
  }

  static line(mode: string): string {
    return mode === THEME_DARK ? '#303642' : '#DDE4EF';
  }

  static chipBg(mode: string): string {
    return mode === THEME_DARK ? '#252A33' : '#E9EEF7';
  }

  static iconSoftBg(mode: string): string {
    return mode === THEME_DARK ? '#1E2C42' : '#EAF3FF';
  }

  static bottomNavBg(mode: string): string {
    return mode === THEME_DARK ? '#20000000' : '#30FFFFFF';
  }

  static bottomNavBorder(mode: string): string {
    return mode === THEME_DARK ? '#18FFFFFF' : '#28FFFFFF';
  }

  static bottomNavInactive(mode: string): string {
    return mode === THEME_DARK ? '#AAB2C5' : '#5C6675';
  }

  static shadow(mode: string): string {
    return mode === THEME_DARK ? '#30000000' : '#10000000';
  }

  static bottomNavShadow(mode: string): string {
    return '#18000000';
  }
}
