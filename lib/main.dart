import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/daily_word_service.dart';
import 'services/dictionary_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/search_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initFuture;
  late DictionaryService _dictionaryService;
  late DailyWordService _dailyWordService;

  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    // For sharing or opening when the app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        _navigateToSearch(value.first.path);
      }
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing or opening when the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        _navigateToSearch(value.first.path);
      }
    });
  }

  void _navigateToSearch(String query) {
    // Use a small delay to ensure navigator is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => SearchScreen(initialQuery: query),
        ),
      );
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await dotenv.load(fileName: ".env");
    _dictionaryService = DictionaryService();
    _dailyWordService = DailyWordService();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return MaterialApp(
              theme: AppTheme.softDarkTheme,
              home: Scaffold(
                body: Center(
                  child: Text(
                    "Initialization Error\nPlease restart the app\n\n${snapshot.error}",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          return MultiProvider(
            providers: [
              Provider.value(value: _dailyWordService),
              Provider.value(value: _dictionaryService),
            ],
            child: MaterialApp(
              title: 'Vocabra',
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.softDarkTheme,
              builder: (context, child) {
                return GestureDetector(
                  onTap: () {
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus && 
                        currentFocus.focusedChild != null) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                  },
                  child: child,
                );
              },
              home: const SplashScreen(),
            ),
          );
        }

        // LOADING FALLBACK UI
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.softDarkTheme,
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        );
      },
    );
  }
}
