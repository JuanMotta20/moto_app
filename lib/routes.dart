import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/driver_dashboard.dart';
import 'screens/client_dashboard.dart';
import 'screens/request_ride_screen.dart';
import 'screens/user_detail_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const WelcomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const HomeScreen(),
  '/admin': (context) => const AdminDashboard(),
  '/driver': (context) => const DriverDashboard(),
  '/client': (context) => const ClientDashboard(),
  '/request_ride': (context) => const RequestRideScreen(),
  '/user_detail': (context) => const UserDetailScreen(),
};
