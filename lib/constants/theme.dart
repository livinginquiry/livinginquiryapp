import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    visualDensity: VisualDensity(vertical: 0.5, horizontal: 0.5),
    primarySwatch: MaterialColor(
      0xFFF5E0C3,
      <int, Color>{
        50: Color(0x1aF5E0C3),
        100: Color(0xa1F5E0C3),
        200: Color(0xaaF5E0C3),
        300: Color(0xafF5E0C3),
        400: Color(0xffF5E0C3),
        500: Color(0xffEDD5B3),
        600: Color(0xffDEC29B),
        700: Color(0xffC9A87C),
        800: Color(0xffB28E5E),
        900: Color(0xff936F3E)
      },
    ),
    primaryColor: Color(0xffEDD5B3),
    primaryColorBrightness: Brightness.light,
    primaryColorLight: Color(0x1aF5E0C3),
    primaryColorDark: Color(0xff936F3E),
    canvasColor: Color(0xffe5dbe8),
    // accentColor: Color(0xff789aad),
    // accentColorBrightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xffd0dbe5),
    bottomAppBarColor: Color(0xff6D42CE),
    cardColor: Color(0xaaF5E0C3),
    dividerColor: Color(0x1f6D42CE),
    focusColor: Color(0x1aF5E0C3),
    hoverColor: Color(0xffDEC29B),
    highlightColor: Color(0xff936F3E),
    splashColor: Color(0xff457BE0),
//  splashFactory: # override create method from  InteractiveInkFeatureFactory
    selectedRowColor: Colors.grey,
    unselectedWidgetColor: Colors.grey.shade400,
    disabledColor: Colors.grey.shade200,
    buttonTheme: ButtonThemeData(
        //button themes
        ),
    toggleButtonsTheme: ToggleButtonsThemeData(
        //toggle button theme
        ),
    secondaryHeaderColor: Colors.grey,
    textSelectionTheme: TextSelectionThemeData(selectionColor: Color(0xffE09E45)),
    backgroundColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    indicatorColor: Color(0xff457BE0),
    hintColor: Colors.grey,
    errorColor: Colors.red,
    toggleableActiveColor: Color(0xff6D42CE),
    textTheme: TextTheme(
        //text themes that contrast with card and canvas
        ),
    primaryTextTheme: TextTheme(
        //text theme that contrast with primary color
        ),
    inputDecorationTheme: InputDecorationTheme(
        // default values for InputDecorator, TextField, and TextFormField
        ),
    iconTheme: IconThemeData(
        //icon themes that contrast with card and canvas
        ),
    primaryIconTheme: IconThemeData(
        //icon themes that contrast primary color
        ),
    // accentIconTheme: IconThemeData(
    //     //icon themes that contrast accent color
    //     ),
    sliderTheme: SliderThemeData(
        // slider themes
        ),
    tabBarTheme: TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xff666666),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        )
        // tab bar theme
        ),
    tooltipTheme: TooltipThemeData(
        // tool tip theme
        ),
    cardTheme: CardTheme(
        // card theme
        ),
    chipTheme: ChipThemeData(
        backgroundColor: Color(0xff936F3E),
        disabledColor: Color(0xaaF5E0C3),
        shape: StadiumBorder(),
        brightness: Brightness.light,
        labelPadding: EdgeInsets.all(8),
        labelStyle: TextStyle(),
        padding: EdgeInsets.all(8),
        secondaryLabelStyle: TextStyle(),
        secondarySelectedColor: Colors.white38,
        selectedColor: Colors.white
        // chip theme
        ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    applyElevationOverlayColor: true,
    pageTransitionsTheme: PageTransitionsTheme(
        //page transition theme
        ),
    appBarTheme: AppBarTheme(color: Colors.white
        //app bar theme
        ),
    bottomAppBarTheme: BottomAppBarTheme(
        // bottom app bar theme
        ),
    colorScheme: ColorScheme(
        primary: Color(0xFF07053B),
        secondary: Color(0xff789aad),
        brightness: Brightness.light,
        background: Colors.white,
        error: Colors.red,
        onBackground: Color(0xFF1B1E23),
        onError: Colors.red,
        onPrimary: Color(0xffEDD5B3),
        onSecondary: Color(0xffC9A87C),
        onSurface: Color(0xFF09111F),
        surface: Color(0xff457BE0)),
    snackBarTheme: SnackBarThemeData(
        // snack bar theme
        ),
    dialogTheme: DialogTheme(
        // dialog theme
        ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        // floating action button theme
        ),
    navigationRailTheme: NavigationRailThemeData(
        // navigation rail theme
        ),
    typography: Typography.material2018(),
    cupertinoOverrideTheme: CupertinoThemeData(
        //cupertino theme
        ),
    bottomSheetTheme: BottomSheetThemeData(
        //bottom sheet theme
        ),
    popupMenuTheme: PopupMenuThemeData(
        //pop menu theme
        ),
    bannerTheme: MaterialBannerThemeData(
        // material banner theme
        ),
    dividerTheme: DividerThemeData(
        //divider, vertical divider theme
        ),
    buttonBarTheme: ButtonBarThemeData(buttonTextTheme: ButtonTextTheme.normal
        // button bar theme
        ),
    fontFamily: 'ROBOTO',
    splashFactory: InkSplash.splashFactory);
