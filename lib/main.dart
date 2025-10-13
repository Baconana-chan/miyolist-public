import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'core/services/auth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/image_cache_service.dart';
import 'core/services/crash_reporter.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'features/common/widgets/crash_report_dialog.dart';
import 'features/welcome/presentation/pages/welcome_page.dart';

void main() async {
  // Initialize bindings first, before any zones
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize crash reporter
  final crashReporter = CrashReporter();
  await crashReporter.initialize();
  await crashReporter.markSessionStart();

  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    crashReporter.log(
      'Flutter Error: ${details.exception}',
      level: LogLevel.error,
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Initialize window manager for desktop platforms (before zone)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 800), // Размер окна по умолчанию
      minimumSize: Size(800, 600), // Минимальный размер
      center: true, // Центрировать окно
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // Initialize local storage
  await LocalStorageService.init();
  
  // Initialize Supabase
  final supabaseService = SupabaseService();
  await supabaseService.init();
  
  // Initialize image cache service
  await ImageCacheService().initialize();
  
  // Catch async errors with zone
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(LocalStorageService()),
          ),
        ],
        child: MyApp(
          authService: AuthService(),
          localStorageService: LocalStorageService(),
          supabaseService: supabaseService,
          crashReporter: crashReporter,
        ),
      ),
    );
  }, (error, stackTrace) {
    crashReporter.log(
      'Unhandled Error: $error',
      level: LogLevel.fatal,
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;
  final CrashReporter crashReporter;

  const MyApp({
    super.key,
    required this.authService,
    required this.localStorageService,
    required this.supabaseService,
    required this.crashReporter,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _crashCheckCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Mark graceful shutdown
    widget.crashReporter.markGracefulShutdown();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Mark graceful shutdown when app is paused/detached
    if (state == AppLifecycleState.detached || 
        state == AppLifecycleState.paused) {
      widget.crashReporter.markGracefulShutdown();
    }
  }

  Future<void> _checkForCrash(BuildContext context) async {
    if (_crashCheckCompleted) return;
    _crashCheckCompleted = true;
    
    // Wait for next frame to ensure MaterialApp is fully built
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    await CrashReportDialog.showIfNeeded(context);
  }

  Future<void> _checkWelcomeScreen(BuildContext context) async {
    // Wait a bit to ensure everything is loaded
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Check if user has seen welcome screen
    final settings = await widget.localStorageService.getUserSettings();
    
    if (settings != null && !settings.hasSeenWelcomeScreen) {
      // Show welcome screen
      if (!mounted) return;
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WelcomePage(),
          fullscreenDialog: true,
        ),
      );
      
      // Mark as seen
      final updatedSettings = settings.copyWith(hasSeenWelcomeScreen: true);
      await widget.localStorageService.saveUserSettings(updatedSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MiyoList - AniList Client',
          theme: themeProvider.currentTheme,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) {
              // Check for crash after MaterialApp is built
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkForCrash(context);
                _checkWelcomeScreen(context);
              });
              
              return FutureBuilder<bool>(
                future: widget.authService.isAuthenticated(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final isAuthenticated = snapshot.data ?? false;
                  
                  if (isAuthenticated) {
                    return MainPage(
                      authService: widget.authService,
                      localStorageService: widget.localStorageService,
                      supabaseService: widget.supabaseService,
                    );
                  } else {
                    return LoginPage(
                      authService: widget.authService,
                      localStorageService: widget.localStorageService,
                      supabaseService: widget.supabaseService,
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
