import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/wedding_setup/wedding_setup_screen.dart';
import '../screens/home/home_dashboard_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/guests/guests_screen.dart';
import '../screens/vendors/vendors_screen.dart';
import '../screens/events/wedding_vendor_discovery_screen.dart';
import '../screens/events/birthday_vendor_discovery_screen.dart';
import '../screens/birthday/birthday_home_screen.dart';
import '../screens/birthday/birthday_service_selection_screen.dart';
import '../screens/birthday/birthday_booking_calendar_screen.dart';
import '../screens/birthday/birthday_checkout_screen.dart';
import '../screens/birthday/birthday_booking_history_screen.dart';
import '../screens/wedding_module/wedding_wizard_host_screen.dart';
import '../screens/wedding_module/main_wedding_dashboard_view.dart';
import '../screens/wedding_ecosystem/join_wedding_screen.dart';
import '../screens/wedding_ecosystem/guest_wedding_page_screen.dart';
import '../screens/wedding_ecosystem/service_provider_marketplace_screen.dart';
import '../screens/wedding_ecosystem/service_provider_profile_screen.dart';
import '../screens/wedding_ecosystem/service_provider_dashboard_screen.dart';
import '../screens/wedding_ecosystem/wedding_gallery_screen.dart';
import '../screens/wedding_ecosystem/wedding_schedule_screen.dart';
import '../screens/checklist/checklist_screen.dart';
import '../screens/timeline/timeline_screen.dart';
import '../screens/seating/seating_planner_screen.dart';
import '../screens/inspiration/inspiration_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/legal/terms_privacy_screen.dart';
import '../screens/conference/c_landingpage.dart';
import '../screens/conference/hall/c_hall_page.dart';
import '../screens/conference/c_food_page.dart';
import '../screens/conference/c_sound_page.dart';
import '../screens/conference/c_decoration_page.dart';
import '../screens/conference/c_photography_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String weddingSetup = '/wedding-setup';
  static const String home = '/home';
  static const String budget = '/budget';
  static const String guests = '/guests';
  static const String vendors = '/vendors';
  static const String weddingVendors = '/wedding-vendors';
  static const String birthdayVendors = '/birthday-vendors';
  static const String birthdayStudio = '/birthday-studio';
  static const String birthdayServiceSelection = '/birthday-service-selection';
  static const String birthdayBookingCalendar = '/birthday-booking-calendar';
  static const String birthdayCheckout = '/birthday-checkout';
  static const String birthdayBookingHistory = '/birthday-booking-history';
  static const String weddingManager = '/wedding-manager';
  static const String weddingDashboard = '/wedding-dashboard';
  static const String joinWedding = '/join-wedding';
  static const String guestWeddingPage = '/guest-wedding-page';
  static const String serviceProviderMarketplace = '/service-provider-marketplace';
  static const String serviceProviderProfile = '/service-provider-profile';
  static const String serviceProviderDashboard = '/service-provider-dashboard';
  static const String weddingGallery = '/wedding-gallery';
  static const String weddingSchedule = '/wedding-schedule';
  static const String checklist = '/checklist';
  static const String timeline = '/timeline';
  static const String seating = '/seating';
  static const String inspiration = '/inspiration';
  static const String profile = '/profile';
  static const String termsPrivacy = '/terms-privacy';
  static const String cLandingPage = '/conference';
  static const String conferenceHall = '/conference/hall';
  static const String hallList = '/hall-list';
  static const String conferenceFood = '/conference/food';
  static const String conferenceSound = '/conference/sound';
  static const String conferenceDecoration = '/conference/decoration';
  static const String conferencePhotography = '/conference/photography';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      resetPassword: (context) => const ResetPasswordScreen(),
      weddingSetup: (context) => const WeddingSetupScreen(),
      home: (context) => const HomeDashboardScreen(),
      budget: (context) => const BudgetScreen(),
      guests: (context) => const GuestsScreen(),
      vendors: (context) => const VendorsScreen(),
      weddingVendors: (context) => const WeddingVendorDiscoveryScreen(),
      birthdayVendors: (context) => const BirthdayVendorDiscoveryScreen(),
      birthdayStudio: (context) => const BirthdayHomeScreen(),
      birthdayServiceSelection: (context) => const BirthdayServiceSelectionScreen(),
      birthdayBookingCalendar: (context) => const BirthdayBookingCalendarScreen(),
      birthdayCheckout: (context) => const BirthdayCheckoutScreen(),
      birthdayBookingHistory: (context) => const BirthdayBookingHistoryScreen(),
      weddingManager: (context) => const WeddingWizardHostScreen(),
      weddingDashboard: (context) => const MainWeddingDashboardView(),
      joinWedding: (context) => const JoinWeddingScreen(),
      guestWeddingPage: (context) => const GuestWeddingPageScreen(),
      serviceProviderMarketplace: (context) => const ServiceProviderMarketplaceScreen(),
      serviceProviderProfile: (context) => const ServiceProviderProfileScreen(),
      serviceProviderDashboard: (context) => const ServiceProviderDashboardScreen(),
      weddingGallery: (context) => const WeddingGalleryScreen(),
      weddingSchedule: (context) => const WeddingScheduleScreen(),
      checklist: (context) => const ChecklistScreen(),
      timeline: (context) => const TimelineScreen(),
      seating: (context) => const SeatingPlannerScreen(),
      inspiration: (context) => const InspirationScreen(),
      profile: (context) => const ProfileScreen(),
      termsPrivacy: (context) => const TermsPrivacyScreen(),
      cLandingPage: (context) => const ConferenceLandingPage(),
      conferenceHall: (context) => const CHallPage(),
      hallList: (context) => const CHallPage(),
      conferenceFood: (context) => const ConferenceFoodPage(),
      conferenceSound: (context) => const ConferenceSoundPage(),
      conferenceDecoration: (context) => const ConferenceDecorationPage(),
      conferencePhotography: (context) => const ConferencePhotographyPage(),
    };
  }
}