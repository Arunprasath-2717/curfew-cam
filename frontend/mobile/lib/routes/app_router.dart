import 'package:flutter/material.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_one_screen.dart';
import '../screens/auth/onboarding_two_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';


import '../screens/student/dashboard_screen.dart';
import '../screens/student/request_step_1_screen.dart';
import '../screens/student/request_step_2_screen.dart';
import '../screens/student/request_submitted_screen.dart';
import '../screens/student/active_qr_screen.dart';
import '../screens/student/history_screen.dart';
import '../screens/student/outpass_detail_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/student_profile_screen.dart';
import '../screens/student/dashboard_empty_screen.dart';
import '../screens/student/edit_profile_screen.dart';
import '../screens/student/settings_screen.dart';
import '../screens/student/return_verification_screen.dart';
import '../screens/student/late_warning_screen.dart';
import '../screens/student/pass_rejected_screen.dart';
import '../screens/student/pass_expired_screen.dart';
import '../screens/student/help_faq_screen.dart';

import '../screens/warden/analytics_overview_screen.dart';
import '../screens/warden/approve_confirmation_screen.dart';
import '../screens/warden/approved_history_warden_screen.dart';
import '../screens/warden/bulk_approve_screen.dart';
import '../screens/warden/daily_report_screen.dart';
import '../screens/warden/emergency_alert_screen.dart';
import '../screens/warden/late_returns_alert_screen.dart';
import '../screens/warden/notifications_warden_screen.dart';
import '../screens/warden/outside_students_screen.dart';
import '../screens/warden/pass_violation_record_screen.dart';
import '../screens/warden/pending_requests_screen.dart';
import '../screens/warden/reject_with_reason_screen.dart';
import '../screens/warden/reports_dashboard_screen.dart';
import '../screens/warden/request_detail_approval_screen.dart';
import '../screens/warden/search_students_screen.dart';
import '../screens/warden/student_directory_screen.dart';
import '../screens/warden/student_profile_warden_screen.dart';
import '../screens/warden/warden_dashboard_screen.dart';
import '../screens/warden/warden_profile_screen.dart';
import '../screens/warden/warden_settings_screen.dart';
import '../screens/warden/warden_detection_screen.dart';
import '../screens/warden/manage_accounts_screen.dart';
import '../screens/warden/manage_wardens_screen.dart';

import '../screens/watchman/watchman_dashboard_screen.dart';
import '../screens/watchman/qr_scanner_screen.dart';
import '../screens/watchman/scan_exit_screen.dart';
import '../screens/watchman/scan_return_screen.dart';
import '../screens/watchman/scan_invalid_screen.dart';
import '../screens/watchman/scan_not_found_screen.dart';
import '../screens/watchman/manual_verification_screen.dart';
import '../screens/watchman/gate_log_screen.dart';
import '../screens/watchman/active_passes_watchman_screen.dart';
import '../screens/watchman/overdue_students_screen.dart';
import '../screens/watchman/shift_summary_screen.dart';
import '../screens/watchman/watchman_profile_screen.dart';
import '../screens/watchman/watchman_settings_screen.dart';
import '../screens/watchman/offline_mode_notice_screen.dart';
import '../screens/watchman/help_support_watchman_screen.dart';
import '../screens/warden/gate_monitor_screen.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String onboarding1 = '/onboarding1';
  static const String onboarding2 = '/onboarding2';
  
  static const String login = '/login';
  static const String register = '/register';

  
  static const String studentDashboard = '/student-dashboard';
  static const String requestStep1 = '/request-step1';
  static const String requestStep2 = '/request-step2';
  static const String requestSubmitted = '/request-submitted';
  static const String activeQr = '/active-qr';
  static const String history = '/history';
  static const String outpassDetail = '/outpass-detail';
  static const String notifications = '/notifications';
  static const String studentProfile = '/student-profile';
  static const String dashboardEmpty = '/dashboard-empty';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String returnVerification = '/return-verification';
  static const String lateWarning = '/late-warning';
  static const String passRejected = '/pass-rejected';
  static const String passExpired = '/pass-expired';
  static const String helpFaq = '/help-faq';
  
  static const String wardenDashboard = '/warden-dashboard';
  static const String pendingRequests = '/pending-requests';
  static const String requestDetail = '/request-detail';
  static const String rejectReason = '/reject-reason';
  static const String approveConfirm = '/approve-confirm';
  static const String outsideStudents = '/outside-students';
  static const String lateReturnsAlert = '/late-returns-alert';
  static const String approvedHistory = '/approved-history';
  static const String studentProfileWarden = '/student-profile-warden';
  static const String reportsDashboard = '/reports-dashboard';
  static const String dailyReport = '/daily-report';
  static const String notificationsWarden = '/notifications-warden';
  static const String searchStudents = '/search-students';
  static const String studentDirectory = '/student-directory';
  static const String bulkApprove = '/bulk-approve';
  static const String analytics = '/analytics';
  static const String violations = '/violations';
  static const String emergencyAlert = '/emergency-alert';
  static const String wardenProfile = '/warden-profile';
  static const String wardenSettings = '/warden-settings';
  static const String wardenDetections = '/warden-detections';
  static const String manageAccounts = '/manage-accounts';
  static const String manageWardens = '/manage-wardens';
  
  static const String watchmanDashboard = '/watchman-dashboard';
  static const String qrScanner = '/qr-scanner';
  static const String scanExit = '/scan-exit';
  static const String scanReturn = '/scan-return';
  static const String scanInvalid = '/scan-invalid';
  static const String scanNotFound = '/scan-not-found';
  static const String manualVerification = '/manual-verification';
  static const String gateLog = '/gate-log';
  static const String activePasses = '/active-passes';
  static const String overdueStudents = '/overdue-students';
  static const String shiftSummary = '/shift-summary';
  static const String watchmanProfile = '/watchman-profile';
  static const String watchmanSettings = '/watchman-settings';
  static const String offlineMode = '/offline-mode';
  static const String helpWatchman = '/help-watchman';
  static const String gateMonitor = '/gate-monitor';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding1: (context) => const OnboardingOneScreen(),
        onboarding2: (context) => const OnboardingTwoScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),

        studentDashboard: (context) => const StudentDashboardScreen(),
        requestStep1: (context) => const RequestStep1Screen(),
        requestStep2: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return RequestStep2Screen(
            requestData: args is Map ? Map<String, dynamic>.from(args) : null,
          );
        },
        requestSubmitted: (context) => const RequestSubmittedScreen(),
        activeQr: (context) => const ActiveQrScreen(),
        history: (context) => const HistoryScreen(),
        outpassDetail: (context) => const OutpassDetailScreen(),
        notifications: (context) => const NotificationsScreen(),
        studentProfile: (context) => const StudentProfileScreen(),
        dashboardEmpty: (context) => const DashboardEmptyScreen(),
        editProfile: (context) => const EditProfileScreen(),
        settings: (context) => const SettingsScreen(),
        returnVerification: (context) => const ReturnVerificationScreen(),
        lateWarning: (context) => const LateWarningScreen(),
        passRejected: (context) => const PassRejectedScreen(),
        passExpired: (context) => const PassExpiredScreen(),
        helpFaq: (context) => const HelpFaqScreen(),
        
        wardenDashboard: (context) => const WardenDashboardScreen(),
        pendingRequests: (context) => const PendingRequestsScreen(),
        requestDetail: (context) => const RequestDetailApprovalScreen(),
        rejectReason: (context) => const RejectWithReasonScreen(),
        approveConfirm: (context) => const ApproveConfirmationScreen(),
        outsideStudents: (context) => const OutsideStudentsScreen(),
        lateReturnsAlert: (context) => const LateReturnsAlertScreen(),
        approvedHistory: (context) => const ApprovedHistoryWardenScreen(),
        studentProfileWarden: (context) => const StudentProfileWardenScreen(),
        reportsDashboard: (context) => const ReportsDashboardScreen(),
        dailyReport: (context) => const DailyReportScreen(),
        notificationsWarden: (context) => const NotificationsWardenScreen(),
        searchStudents: (context) => const SearchStudentsScreen(),
        studentDirectory: (context) => const StudentDirectoryScreen(),
        bulkApprove: (context) => const BulkApproveScreen(),
        analytics: (context) => const AnalyticsOverviewScreen(),
        violations: (context) => const PassViolationRecordScreen(),
        emergencyAlert: (context) => const EmergencyAlertScreen(),
        wardenProfile: (context) => const WardenProfileScreen(),
        wardenSettings: (context) => const WardenSettingsScreen(),
        wardenDetections: (context) => const WardenDetectionScreen(),
        manageAccounts: (context) => const ManageAccountsScreen(),
        manageWardens: (context) => const ManageWardensScreen(),
        
        watchmanDashboard: (context) => const WatchmanDashboardScreen(),
        qrScanner: (context) => const QrScannerScreen(),
        scanExit: (context) => const ScanExitScreen(),
        scanReturn: (context) => const ScanReturnScreen(),
        scanInvalid: (context) => const ScanInvalidScreen(),
        scanNotFound: (context) => const ScanNotFoundScreen(),
        manualVerification: (context) => const ManualVerificationScreen(),
        gateLog: (context) => const GateLogScreen(),
        activePasses: (context) => const ActivePassesWatchmanScreen(),
        overdueStudents: (context) => const OverdueStudentsScreen(),
        shiftSummary: (context) => const ShiftSummaryScreen(),
        watchmanProfile: (context) => const WatchmanProfileScreen(),
        watchmanSettings: (context) => const WatchmanSettingsScreen(),
        offlineMode: (context) => const OfflineModeNoticeScreen(),
        helpWatchman: (context) => const HelpSupportWatchmanScreen(),
        gateMonitor: (context) => const GateMonitorScreen(),
      };
}
