class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
}