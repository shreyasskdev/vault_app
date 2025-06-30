import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const textColor = Colors.black;
const backgroundColor = Colors.white;
const primaryColor = Colors.black;
const primaryFgColor = Colors.white;
const secondaryColor = Colors.black;
const secondaryFgColor = Colors.white;
const accentColor = Colors.black;
const accentFgColor = Colors.white;

const MaterialColor backgroundShade = MaterialColor(
  50,
  <int, Color>{
    50: Color.fromARGB(255, 255, 255, 255),
    100: Color.fromARGB(255, 245, 245, 245),
    200: Color.fromARGB(255, 235, 235, 235),
    300: Color.fromARGB(255, 225, 225, 225),
    400: Color.fromARGB(255, 215, 215, 215),
    500: Color.fromARGB(255, 200, 200, 200),
    600: Color.fromARGB(255, 180, 180, 180),
    700: Color.fromARGB(255, 160, 160, 160),
    800: Color.fromARGB(255, 140, 140, 140),
    900: Color.fromARGB(255, 120, 120, 120),
  },
);

ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.light,
  surface: backgroundColor,
  //
  surfaceBright: backgroundShade.shade50,
  surfaceContainer: backgroundShade.shade200,
  surfaceContainerHigh: backgroundShade.shade300,
  surfaceContainerHighest: backgroundShade.shade400,
  surfaceContainerLow: backgroundShade.shade100,
  surfaceContainerLowest: backgroundShade.shade50,
  surfaceDim: backgroundShade.shade500,
  //
  onSurface: textColor,
  primary: primaryColor,
  onPrimary: primaryFgColor,
  secondary: secondaryColor,
  onSecondary: secondaryFgColor,
  tertiary: accentColor,
  onTertiary: accentFgColor,
  error: Brightness.light == Brightness.light
      ? const Color(0xffB3261E)
      : const Color(0xffF2B8B5),
  onError: Brightness.light == Brightness.light
      ? const Color(0xffFFFFFF)
      : const Color(0xff601410),
);

ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: colorScheme.surface,
  colorScheme: colorScheme,
  appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface),
  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    bodySmall: TextStyle(color: colorScheme.onSurface),
    bodyMedium: TextStyle(color: colorScheme.onSurface),
    bodyLarge: TextStyle(color: colorScheme.onSurface),
    labelSmall: TextStyle(color: colorScheme.onSurface),
    labelMedium: TextStyle(color: colorScheme.onSurface),
    labelLarge: TextStyle(color: colorScheme.onSurface),
    displaySmall: TextStyle(color: colorScheme.onSurface),
    displayMedium: TextStyle(color: colorScheme.onSurface),
    displayLarge: TextStyle(color: colorScheme.onSurface),
  ),
  fontFamily: GoogleFonts.poppins().fontFamily,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  ),
  inputDecorationTheme: InputDecorationTheme(
    contentPadding: const EdgeInsets.only(left: 15),
    hintStyle: TextStyle(
      color: colorScheme.surfaceDim,
      fontWeight: FontWeight.w600,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.surfaceContainer, width: 2),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.surfaceContainer, width: 2),
      borderRadius: const BorderRadius.all(Radius.circular(20)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: colorScheme.onPrimary,
      backgroundColor: colorScheme.primary,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: colorScheme.surfaceContainerHighest,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.surface; // Thumb color when ON
      }
      return colorScheme.surfaceDim; // Thumb color when OFF
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary; // Track color when ON
      }
      return colorScheme.surface; // Track color when OFF
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary; // Outline color when ON
      }
      return colorScheme.surfaceDim; // Outline color when OFF
    }),
  ),
);
