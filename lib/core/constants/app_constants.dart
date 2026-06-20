class AppConstants {
  AppConstants._();

  static const String supabaseUrl = 'https://ylvrejzavxglibfydudi.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlsdnJlanphdnhnbGliZnlkdWRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NTgzODQsImV4cCI6MjA5NzIzNDM4NH0.uBIROs8wSVtHzUMZVfxc6NpvTWTHB95HBaM2zRC7eHE';

  static const String appName = 'Copiloto Financiero';

  static const int maxTransactionsContext = 30;

  static const Duration sessionDuration = Duration(days: 7);
}
