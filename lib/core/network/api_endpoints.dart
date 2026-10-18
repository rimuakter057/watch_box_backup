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
  static const String userMyProfile = '/users/my-profile';
  static const String userUpdateProfile = '/users/update-profile';
  static const String userUpdateFcmToken = '/users/update-fcm-token';
  static const String userDeleteMyAccount = '/users/delete-my-account';
  static const String userPreferences = '/users/me/preferences';
  static const String userDarkMode = '/users/me/dark-mode';
  static const String userAvatar = '/users/me/avatar';
  static const String userProfileAnalytics = '/users/get-profile-analytics';

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
  static const String myListings = '/me/listings';
  static const String posts = '/posts';
  static const String postsCreate = '/posts/create-post';
  static const String postsGetAll = '/posts/get-all-posts';
  static const String postsMy = '/posts/my-posts';
  static const String postsView = '/posts/view-post';
  static const String postsDelete = '/posts/delete-post';
  static const String postsToggleSave = '/posts/toggle-save';
  static const String postsSaved = '/posts/saved-posts';
  static const String traderCollection = '/trader-collection';
  static const String traderFeatured = '/trader-collection/featured';

  // Recommendations & Analytics
  static const String recommendationsHome = '/recommendations/home';
  static const String recommendationsForYou = '/recommendations/for-you';
  static const String recommendationsTrending = '/recommendations/trending';
  static const String analyticsMarketInsights = '/analytics/market-insights';
  static const String analyticsPriceTrend = '/analytics/watch-models';

  // Bookmarks & Saved Searches
  static const String savedListings = '/me/saved-listings';
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

  // Real-Time Chat & Messaging
  static const String chats = '/chats';
  static const String messages = '/messages';

  // eBay Marketplace
  static const String ebayStatus = '/ebay/status';
  static const String ebayDisconnect = '/ebay/disconnect';
}