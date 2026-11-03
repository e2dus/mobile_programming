import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:individual_project/api_keys.dart';
import 'package:individual_project/pages/direct_message_page.dart';
import 'package:individual_project/pages/main_page.dart';
import 'package:individual_project/pages/post_detail_page.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/utils/supabase_diagnostics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  await supabaseConnectivityCheck();
  await supabaseDumpTables(limit: 3);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(800, 1280),
      minTextAdapt: true,
      builder: (context, child) {
        final ColorScheme baseScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF1628DA),
          brightness: Brightness.light,
        );
        final ColorScheme colorScheme = baseScheme.copyWith(
          primary: const Color(0xFF1628DA),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF1628DA),
          onPrimaryContainer: Colors.white,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            primaryColor: colorScheme.primary,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
              surfaceTintColor: Colors.transparent,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
            pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: const _FullSlidePageTransitionsBuilder(),
                TargetPlatform.iOS: const _FullSlidePageTransitionsBuilder(),
                TargetPlatform.linux: const _FullSlidePageTransitionsBuilder(),
                TargetPlatform.macOS: const _FullSlidePageTransitionsBuilder(),
                TargetPlatform.windows: const _FullSlidePageTransitionsBuilder(),
              },
            ),
          ),
          home: const AppInitializer(),
          onGenerateRoute: (settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/directMessage':
                builder = (_) => DirectMessagePage(currentUserName: 'uiyeon');
                return DmListRoute(builder: builder, settings: settings, duration: const Duration(milliseconds: 420));
              case '/postDetail':
                final args = settings.arguments as Map<String, dynamic>?;
                final postId = args?['postId'] as String? ?? '';
                final openComments = args?['openComments'] as bool? ?? false;
                builder = (_) => PostDetailPage(postId: postId, openComments: openComments);
                return FullSlidePageRoute(builder: builder, settings: settings, duration: const Duration(milliseconds: 420));
              default:
                builder = (_) => MainPage();
            }
            return FullSlidePageRoute(builder: builder, settings: settings, duration: const Duration(milliseconds: 420));
          },
        );
      },
    );
  }
}

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);

    return initState.when(
      data: (initialized) {
        if (initialized) {
          return const MainPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(appInitializationProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FullSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const Curve curve = Curves.linear;
    final Animation<Offset> incoming = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: curve)).animate(animation);

    final Animation<Offset> outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).chain(CurveTween(curve: curve)).animate(secondaryAnimation);

    return SlideTransition(
      position: outgoing,
      child: SlideTransition(
        position: incoming,
        child: child,
      ),
    );
  }
}

class FullSlidePageRoute<T> extends PageRouteBuilder<T> {
  FullSlidePageRoute({required WidgetBuilder builder, super.settings, required this.duration})
      : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.linear;
            final incoming = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: curve))
                .animate(animation);
            final outgoing = Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
                .chain(CurveTween(curve: curve))
                .animate(secondaryAnimation);
            return SlideTransition(
              position: outgoing,
              child: SlideTransition(position: incoming, child: child),
            );
          },
        );

  final Duration duration;
}

class DmListRoute<T> extends PageRouteBuilder<T> {
  DmListRoute({required WidgetBuilder builder, super.settings, required this.duration})
      : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.linear;
            final selfEnter = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: curve))
                .animate(animation);
            final slightLeft = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.10, 0))
                .chain(CurveTween(curve: curve))
                .animate(secondaryAnimation);
            return SlideTransition(
              position: slightLeft,
              child: SlideTransition(position: selfEnter, child: child),
            );
          },
        );

  final Duration duration;
}