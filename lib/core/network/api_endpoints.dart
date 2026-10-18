class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Users & Preferences
  static const String userMe = '/users/me';
  static const String userMyProfile = '/users/me';
  static const String userUpdateProfile = '/users/me';
  static const String userUpdateFcmToken = '/users/update-fcm-token';
  static const String userDeleteMyAccount = '/users/me';
  static const String userPreferences = '/users/me/preferences';
  static const String userDarkMode = '/users/me/dark-mode';
  static const String userAvatar = '/users/me/avatar';
  static const String userProfileAnalytics = '/users/me/stats';

  // Search & Discovery
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';
  static const String searchPopular = '/search/popular';
  static const String searchRecent = '/search/recent';
  static const String searchFacets = '/search/facets';

  // Visual / Image Search
  static const String imageSearch = '/image-search';
  static const String imageSearchVisual = '/image-search/visual';
  static const String imageSearchRecent = '/image-search/recent';
  static const String aiAnalyzeImage = '/ai/analyze-image';

  // Watch Models & Catalog
  static const String brands = '/brands';
  static const String watchModels = '/watch-models';

  // Listings, Posts & Trader Hub
  static const String listings = '/listings';
  static const String myListings = '/listings';
  static const String posts = '/listings';
  static const String postsCreate = '/listings';
  static const String postsGetAll = '/listings';
  static const String postsMy = '/listings';
  static const String postsView = '/listings';
  static const String postsDelete = '/listings';
  static const String postsToggleSave = '/saved-products';
  static const String postsSaved = '/saved-products';
  static const String traderCollection = '/trader-collection';
  static const String traderFeatured = '/trader-collection/featured';

  // Recommendations & Analytics
  static const String recommendationsHome = '/recommendations/home';
  static const String recommendationsForYou = '/recommendations/for-you';
  static const String recommendationsTrending = '/recommendations/trending';
  static const String analyticsMarketInsights = '/analytics/market-insights';
  static const String analyticsPriceTrend = '/analytics/watch-models';

  // Bookmarks & Saved Searches
  static const String savedProducts = '/saved-products';
  static const String savedListings = '/saved-products';
  static const String savedSearches = '/saved-searches';

  // Notifications & Alerts
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationPreferences = '/notification-preferences';

  // Subscriptions & Payments
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionUsage = '/subscriptions/me/usage';
  static const String subscriptionChangePlan = '/subscriptions/change-plan';
  static const String subscriptionCheckout = '/subscriptions/checkout-session';
  static const String plansAll = '/plans/all-plans';
  static const String plansMyActive = '/plans/my-active-plan';
  static const String paymentsCheckout = '/payments/create-checkout-session';
  static const String paymentsTransactions = '/payments/my-transactions';

  // Real-Time Chat & Messaging (Support Tickets / Messaging Gateway)
  static const String chats = '/support/tickets';
  static const String messages = '/support/tickets';

  // eBay Marketplace
  static const String ebayStatus = '/ebay/status';
  static const String ebayDisconnect = '/ebay/disconnect';
}