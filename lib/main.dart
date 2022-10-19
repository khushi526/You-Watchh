// ignore_for_file: avoid_unnecessary_containers
import 'package:cinemax/constants/theme_data.dart';
import 'package:cinemax/provider/darktheme_provider.dart';
import 'package:cinemax/provider/default_home_provider.dart';
import 'package:cinemax/provider/imagequality_provider.dart';
import 'package:cinemax/provider/mixpanel_provider.dart';
import 'package:cinemax/screens/discover.dart';
import 'package:cinemax/screens/landing_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/tv_widgets.dart';
import 'package:flutter/material.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'screens/common_widgets.dart';
import 'screens/movie_widgets.dart';
import 'screens/search_view.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'provider/adultmode_provider.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  // print('background message ${message.notification!.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  runApp(const Cinemax());
}

class Cinemax extends StatefulWidget {
  const Cinemax({Key? key}) : super(key: key);

  @override
  State<Cinemax> createState() => _CinemaxState();
}

class _CinemaxState extends State<Cinemax>
    with ChangeNotifier, WidgetsBindingObserver {
  bool? isFirstLaunch;
  AdultmodeProvider adultmodeProvider = AdultmodeProvider();
  DarkthemeProvider themeChangeProvider = DarkthemeProvider();
  ImagequalityProvider imagequalityProvider = ImagequalityProvider();
  MixpanelProvider mixpanelProvider = MixpanelProvider();
  DeafultHomeProvider deafultHomeProvider = DeafultHomeProvider();
  late Mixpanel mixpanel;
  // late FirebaseMessaging messaging;

  void firstTimeCheck() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getBool('isFirstRun') == null) {
        isFirstLaunch = true;
      } else {
        isFirstLaunch = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      // print("message recieved");
      // print(event.notification!.body);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      //  print('Message clicked!');
    });
    firstTimeCheck();
    mixpanelProvider.initMixpanel();
    getCurrentImageQuality();
    getCurrentAdultMode();
    getCurrentThemeMode();
    getCurrentDefaultScreen();
  }

  void getCurrentAdultMode() async {
    adultmodeProvider.isAdult =
        await adultmodeProvider.adultModePreferences.getAdultMode();
  }

  void getCurrentThemeMode() async {
    themeChangeProvider.darktheme =
        await themeChangeProvider.themeModePreferences.getThemeMode();
  }

  void getCurrentImageQuality() async {
    imagequalityProvider.imageQuality =
        await imagequalityProvider.imagePreferences.getImageQuality();
  }

  void getCurrentDefaultScreen() async {
    deafultHomeProvider.defaultValue =
        await deafultHomeProvider.defaultHomePreferences.getDefaultHome();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) {
            return adultmodeProvider;
          }),
          ChangeNotifierProvider(create: (_) {
            return themeChangeProvider;
          }),
          ChangeNotifierProvider(create: (_) {
            return imagequalityProvider;
          }),
          ChangeNotifierProvider(create: (_) {
            return mixpanelProvider;
          }),
          ChangeNotifierProvider(create: (_) {
            return deafultHomeProvider;
          })
        ],
        child: Consumer5<AdultmodeProvider, DarkthemeProvider,
                ImagequalityProvider, MixpanelProvider, DeafultHomeProvider>(
            builder: (context,
                adultmodeProvider,
                themeChangeProvider,
                imagequalityProvider,
                mixpanelProvider,
                defaultHomeProvider,
                snapshot) {
          final isDark = Provider.of<DarkthemeProvider>(context).darktheme;
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'You-Watch',
              theme: Styles.themeData(themeChangeProvider.darktheme, context),
              home: isFirstLaunch == null
                  ? Scaffold(
                      body: Container(
                        color: isDark
                            ? const Color(0xFF202124)
                            : const Color(0xFFF7F7F7),
                        child: const Center(
                          child: SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF7D3C98))),
                        ),
                      ),
                    )
                  : isFirstLaunch == true
                      ? const LandingScreen()
                      : const CinemaxHomePage());
        }));
  }
}

class CinemaxHomePage extends StatefulWidget {
  const CinemaxHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<CinemaxHomePage> createState() => _CinemaxHomePageState();
}

class _CinemaxHomePageState extends State<CinemaxHomePage>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;

  @override
  void initState() {
    defHome();
    super.initState();
  }

  void defHome() {
    final defaultHome =
        Provider.of<DeafultHomeProvider>(context, listen: false).defaultValue;
    setState(() {
      _selectedIndex = defaultHome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkthemeProvider>(context).darktheme;
    final mixpanel = Provider.of<MixpanelProvider>(context).mixpanel;

    return Provider.of<AdultmodeProvider?>(context) == null ||
            Provider.of<ImagequalityProvider?>(context) == null ||
            Provider.of<DarkthemeProvider?>(context) == null ||
            Provider.of<MixpanelProvider?>(context)?.mixpanel == null ||
            Provider.of<DeafultHomeProvider?>(context)?.defaultValue == null
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            drawer: const DrawerWidget(),
            appBar: AppBar(
              title: const Text(
                'You-Watch',
                style: TextStyle(
                  fontFamily: 'PoppinsSB',
                ),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      showSearch(
                          context: context,
                          delegate: Search(
                              mixpanel: mixpanel,
                              includeAdult: Provider.of<AdultmodeProvider>(
                                      context,
                                      listen: false)
                                  .isAdult));
                    },
                    icon: const Icon(Icons.search)),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                color: const Color(0xFF7D3C98),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(.1),
                  )
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                  child: GNav(
                    rippleColor: Colors.grey[300]!,
                    hoverColor: Colors.grey[100]!,
                    gap: 8,
                    activeColor: Colors.black,
                    iconSize: 24,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    duration: const Duration(milliseconds: 400),
                    tabBackgroundColor: Colors.grey[100]!,
                    color: Colors.black,
                    tabs: const [
                      GButton(
                        icon: FontAwesomeIcons.clapperboard,
                        text: 'Movies',
                      ),
                      GButton(
                        icon: FontAwesomeIcons.tv,
                        text: ' TV Shows',
                      ),
                      GButton(
                        icon: FontAwesomeIcons.compass,
                        text: 'Discover',
                      ),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ),
            body: Container(
              color: isDark ? const Color(0xFF202124) : const Color(0xFFF7F7F7),
              child: IndexedStack(
                index: _selectedIndex,
                children: const <Widget>[
                  MainMoviesDisplay(),
                  MainTVDisplay(),
                  DiscoverPage(),
                ],
              ),
            ));
  }
}
