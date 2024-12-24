import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// const textColor = Color(0xFFe9e2e4);
// const backgroundColor = Color(0xFF080606);
// const primaryColor = Color(0xFFc9b0b5);
// const primaryFgColor = Color(0xFF080606);
// const secondaryColor = Color(0xFF6b444b);
// const secondaryFgColor = Color(0xFFe9e2e4);
// const accentColor = Color(0xFFa96f7a);
// const accentFgColor = Color(0xFF080606);

const textColor = Colors.white;
const backgroundColor = Colors.black;
const primaryColor = Colors.white;
const primaryFgColor = Colors.black;
const secondaryColor = Colors.white;
const secondaryFgColor = Colors.black;
const accentColor = Colors.white;
const accentFgColor = Colors.black;

const MaterialColor backgroundShade = MaterialColor(
  900,
  <int, Color>{
    50: Color.fromARGB(255, 120, 120, 120),
    100: Color.fromARGB(255, 90, 90, 90),
    200: Color.fromARGB(255, 80, 80, 80),
    300: Color.fromARGB(255, 70, 70, 70),
    400: Color.fromARGB(255, 60, 60, 60),
    500: Color.fromARGB(255, 50, 50, 50),
    600: Color.fromARGB(255, 40, 40, 40),
    700: Color.fromARGB(255, 30, 30, 30),
    800: Color.fromARGB(255, 20, 20, 20),
    900: Color.fromARGB(255, 10, 10, 10),
  },
);

// Color getBackgroundColor900() {
//   return backgroundColor.shade900;
// }

ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  surface: backgroundColor,
  //
  surfaceBright: backgroundShade.shade100,
  surfaceContainer: backgroundShade.shade400,
  surfaceContainerHigh: backgroundShade.shade500,
  surfaceContainerHighest: backgroundShade.shade600,
  surfaceContainerLow: backgroundShade.shade700,
  surfaceContainerLowest: backgroundShade.shade800,
  surfaceDim: backgroundShade.shade900,
  //
  onSurface: textColor,
  primary: primaryColor,
  onPrimary: primaryFgColor,
  secondary: secondaryColor,
  onSecondary: secondaryFgColor,
  tertiary: accentColor,
  onTertiary: accentFgColor,
  error: Brightness.dark == Brightness.light
      ? Color(0xffB3261E)
      : Color(0xffF2B8B5),
  onError: Brightness.dark == Brightness.light
      ? Color(0xffFFFFFF)
      : Color(0xff601410),
);

ThemeData darkTheme = ThemeData(
  scaffoldBackgroundColor: colorScheme.surface,
  colorScheme: ColorScheme.fromSeed(
    seedColor: colorScheme.primary,
    error: colorScheme.error,
    brightness: colorScheme.brightness,

    primary: colorScheme.primary,
    //
    surfaceBright: colorScheme.surfaceBright,
    surfaceContainer: colorScheme.surfaceContainer,
    surfaceContainerHigh: colorScheme.surfaceContainerHigh,
    surfaceContainerHighest: colorScheme.surfaceContainerHighest,
    surfaceContainerLow: colorScheme.surfaceContainerLow,
    surfaceContainerLowest: colorScheme.surfaceContainerLowest,
    surfaceDim: colorScheme.surfaceDim,
  ),
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
      color: colorScheme.surfaceBright,
      fontWeight: FontWeight.w600,
    ),
    // enabledBorder: UnderlineInputBorder(
    //   borderSide: BorderSide(color: colorScheme.surfaceContainer, width: 2),
    // ),
    // focusedBorder: UnderlineInputBorder(
    //   borderSide: BorderSide(color: backgroundShade.shade50, width: 2),
    // ),
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
  )),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: colorScheme.surfaceContainerHighest,
  ),
);
