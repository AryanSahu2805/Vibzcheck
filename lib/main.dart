import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'firebase_options.dart';
import 'utils/logger.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  Logger.info('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Logger.error('Flutter Error: ${details.exception}', details.exception, details.stack);
  };
  
  // Platform error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    Logger.error('Platform Error: $error', error, stack);
    return true;
  };
  
  try {
    // Load environment variables (REQUIRED)
    try {
      await dotenv.load(fileName: ".env");
      Logger.success('Environment variables loaded');
      // Log partial credentials for debugging (safety: show only first 10 chars)
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
      if (clientId != null && clientId.isNotEmpty) {
        final preview = clientId.substring(0, clientId.length.clamp(0, 10));
        Logger.info('📱 Spotify Client ID: $preview...');
      }
      
      // Validate required environment variables
      final requiredVars = [
        'SPOTIFY_CLIENT_ID',
        'SPOTIFY_CLIENT_SECRET',
        'SPOTIFY_REDIRECT_URI',
        'CLOUDINARY_CLOUD_NAME',
        'CLOUDINARY_API_KEY',
        'CLOUDINARY_UPLOAD_PRESET',
      ];
      
      final missingVars = <String>[];
      for (final varName in requiredVars) {
        if (dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty) {
          missingVars.add(varName);
        }
      }
      
      if (missingVars.isNotEmpty) {
        throw Exception(
          'Missing required environment variables: ${missingVars.join(", ")}\n'
          'Please check your .env file and ensure all variables are set.'
        );
      }
      
      Logger.success('✅ All required environment variables present');
    } catch (e) {
      Logger.error('Environment variables error: $e', e);
      _showErrorScreen(
        'Configuration Error',
        'Failed to load environment variables:\n\n$e\n\n'
        'Please ensure your .env file exists in the project root with all required variables.',
      );
      return;
    }
    
    // Initialize Firebase (REQUIRED)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.success('Firebase initialized');
    } catch (e) {
      Logger.error('Firebase initialization error: $e', e);
      _showErrorScreen(
        'Firebase Error',
        'Failed to initialize Firebase:\n\n$e\n\n'
        'Please check your Firebase configuration and try again.',
      );
      return;
    }
    
    // Setup FCM background handler (REQUIRED)
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      Logger.success('FCM background handler registered');
    } catch (e) {
      Logger.warning('FCM background handler setup failed: $e');
      // Non-critical, continue
    }
    
    // Set preferred orientations
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      Logger.warning('Could not set preferred orientations: $e');
    }
    
    // Set system UI overlay style
    try {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF121212),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } catch (e) {
      Logger.warning('Could not set system UI overlay style: $e');
    }
    
    // Run the app inside a guarded zone so uncaught errors (including TypeError
    // from platform channels) are logged and don't crash the app silently.
    runZonedGuarded(() {
      runApp(
        const ProviderScope(
          child: VibzcheckApp(),
        ),
      );
    }, (error, stack) {
      Logger.error('Uncaught zone error', error, stack);
    });
  } catch (e, stackTrace) {
    Logger.error('Critical initialization error: $e', e, stackTrace);
    
      _showErrorScreen(
        'App Initialization Error',
        'Failed to initialize the app:\n\n$e\n\n'
        'Please check your configuration and try again.',
      );
  }
}

  // Helper function to show error screen
  void _showErrorScreen(String title, String message) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFE22134),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB3B3B3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

class VibzcheckApp extends StatelessWidget {
  const VibzcheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibzcheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.splash,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}