import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/landing_page.dart';
import 'components/main_navigation.dart';
import 'components/main_navigation_perusahaan.dart';
import 'components/main_navigation_admin.dart';
import 'auth/login_page.dart';

// ViewModels — imported as they are created per commit
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/explore_viewmodel.dart';
import 'viewmodels/volunteer_viewmodel.dart';
import 'viewmodels/proposal_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/aksi_viewmodel.dart';
import 'viewmodels/kegiatan_volunteer_viewmodel.dart';
import 'viewmodels/daftar_proposal_viewmodel.dart';
import 'viewmodels/company_profile_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ExploreViewModel()),
        ChangeNotifierProvider(create: (_) => VolunteerViewModel()),
        ChangeNotifierProvider(create: (_) => ProposalViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => AksiViewModel()),
        ChangeNotifierProvider(create: (_) => KegiatanVolunteerViewModel()),
        ChangeNotifierProvider(create: (_) => DaftarProposalViewModel()),
        ChangeNotifierProvider(create: (_) => CompanyProfileViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
      ],
      child: MaterialApp(
        title: 'TemuAksi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D1B4E),
            primary: const Color(0xFF0D1B4E),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LandingPage();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            if (roleSnapshot.hasError) {
              return const LandingPage();
            }

            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const LandingPage();
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>?;

            final role = (data?['role'] ?? 'individu').toString().toLowerCase();

            if (role == 'perusahaan') {
              return const MainNavigationPerusahaan();
            } else if (role == 'admin') {
              return const MainNavigationAdmin();
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0D1B4E),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
