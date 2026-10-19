# ⌚ The Watch Box (WatchSphere)

> **Enterprise-Grade Luxury Timepiece Intelligence, Multi-Marketplace Aggregation & Peer-to-Peer Trading Platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.1-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![GetX](https://img.shields.io/badge/State-GetX_4.7.3-8A2BE2)](https://pub.dev/packages/get)
[![SQLite](https://img.shields.io/badge/Offline--First-SQLite_2.4.3-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)
[![Socket.io](https://img.shields.io/badge/Realtime-Socket.io_3.1.6-010101?logo=socketdotio&logoColor=white)](https://socket.io)
[![Backend](https://img.shields.io/badge/Backend-Node.js_22_Express-339933?logo=nodedotjs&logoColor=white)](file:///d:/nahid/watchBox-Backend)
[![MongoDB](https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb&logoColor=white)](https://mongodb.com)
[![Postman](https://img.shields.io/badge/API_Collection-419_Endpoints-FF6C37?logo=postman&logoColor=white)](file:///d:/nahid/the_watch_box/the_watch_box/collection.json)

---

## 📑 Table of Contents
1. [📖 Executive Summary & Core Value Proposition](#-executive-summary--core-value-proposition)
2. [🏛️ System Architecture & Data Flow](#️-system-architecture--data-flow)
   - [High-Level Architecture](#high-level-architecture)
   - [Real-Time Messaging & Socket Gateway Flow](#real-time-messaging--socket-gateway-flow)
   - [eBay OAuth 2.0 & Cross-Marketplace Sync Flow](#ebay-oauth-20--cross-marketplace-sync-flow)
3. [✨ Key Features & Capabilities](#-key-features--capabilities)
   - [1. Multi-Platform Watch Search & Filter Engine](#1-multi-platform-watch-search--filter-engine)
   - [2. Gemini AI Visual Vision & Image Search](#2-gemini-ai-visual-vision--image-search)
   - [3. eBay OAuth 2.0 & Dealer Inventory Sync](#3-ebay-oauth-20--dealer-inventory-sync)
   - [4. Real-Time Dealer & Seller Messaging](#4-real-time-dealer--seller-messaging)
   - [5. Vector Cubic Bezier Price Trend Analytics](#5-vector-cubic-bezier-price-trend-analytics)
   - [6. Geolocation Radar Service Map](#6-geolocation-radar-service-map)
   - [7. In-App Subscriptions & Tier Quota Checks](#7-in-app-subscriptions--tier-quota-checks)
   - [8. Peer-to-Peer Trading & Invoicing](#8-peer-to-peer-trading--invoicing)
   - [9. Real-Time Watch Price Alerts](#9-real-time-watch-price-alerts)
   - [10. Admin Management & Feature Toggles](#10-admin-management--feature-toggles)
4. [🌐 Network & Service Layer Architecture](#-network--service-layer-architecture)
5. [📁 Complete Project Directory Tree](#-complete-project-directory-tree)
6. [📬 Postman API Collection (`collection.json`)](#-postman-api-collection-collectionjson)
7. [🗺️ Complete Feature-to-API Mapping Matrix](#️-complete-feature-to-api-mapping-matrix)
8. [🗄️ Local SQLite Database Schema (`watch_sphere.db`)](#️-local-sqlite-database-schema-watch_spheredb)
9. [🚀 Prerequisites & Getting Started](#-prerequisites--getting-started)
   - [Mobile App Execution](#1-mobile-app-execution-flutter)
   - [Backend Service Execution](#2-backend-service-execution-nodejs--docker)
   - [Environment Variables Configuration](#3-environment-variables-configuration)
10. [🧪 Quality Assurance & Testing](#-quality-assurance--testing)

---

## 📖 Executive Summary & Core Value Proposition

**The Watch Box (WatchSphere)** is an enterprise-grade luxury horology ecosystem designed to bring radical transparency, valuation intelligence, and streamlined trading to the luxury watch marketplace.

### The Problem It Solves
- **Fragmented Liquidity Data:** Luxury watch prices fluctuate significantly across Chrono24, eBay, and private dealers. Buyers and sellers have no single source of truth for fair market value.
- **Counterfeit & Reference Ambiguity:** Identifying exact reference numbers, bezel variants, dial materials, and hands requires expert knowledge.
- **Tedious Multi-Channel Selling:** Professional dealers waste hours cross-posting the same inventory between private trader networks and major global marketplaces.
- **Unstructured Communication:** Dealer-to-buyer transactions often occur over unencrypted, disorganized messaging apps with no paper trail or invoice integration.

### The Watch Box Solution
The Watch Box unifies all facets of luxury watch ownership and dealership into a unified Flutter mobile application backed by a distributed Node.js/MongoDB infrastructure:
1. **Aggregates live inventory** from **eBay**, **Chrono24**, and internal trader collections in real time.
2. **Identifies watches visually** via camera shutter using **Gemini AI Vision** and vector embeddings.
3. **Synchronizes dealer listings directly with eBay** via an integrated OAuth 2.0 gateway.
4. **Provides direct in-app peer communication** between dealers and collectors through a dedicated Socket.io gateway with automatic REST fallback.
5. **Draws dynamic vector price trends** using custom cubic Bezier curves and calculated 90-day moving average spreads.
6. **Maintains offline-first resilience** via SQLite, allowing users to browse saved inventory, searches, and cached listings without connectivity.

---

## 🏛️ System Architecture & Data Flow

### High-Level Architecture

```mermaid
flowchart TD
    subgraph Client["Flutter Mobile Client (iOS / Android / Web)"]
        UI["UI Layer\n(GetX Views & Screens)"]
        Controllers["Controllers Layer\n(AuthController, SearchController, ChatController, etc.)"]
        Services["Domain API Services\n(AuthApi, SearchApi, ChatApi, EbayApi, VisualSearchApi)"]
        Network["Network Client & Socket\n(ApiClient with JWT Auto-Refresh + SocketService)"]
        LocalDB[("Local SQLite Database\n(watch_sphere.db)")]
        Prefs["Local Shared Preferences\n(PrefManager)"]

        UI --> Controllers
        Controllers --> Services
        Controllers --> LocalDB
        Controllers --> Prefs
        Services --> Network
        Network <--> Prefs
    end

    subgraph Backend["WatchBox Backend Microservices"]
        Gateway["Express API Gateway & Router\n(http://localhost:4000 or https://api.mywatchbox.net)"]
        AuthMiddleware["Auth & RBAC Middleware\n(Customer & Admin JWT Verification)"]
        RealtimeGW["Socket.io Gateway\n(Realtime Messaging & Broadcasts)"]
        
        MongoDB[("MongoDB Database\n(Users, Listings, Orders, Messages)")]
        RedisCache[("Redis 7 Cache\n(Session Store, Search Cache, Rate Limits)")]
        RabbitMQ[("RabbitMQ Broker\n(Async Jobs, Price Scrapers, Email Queue)")]

        Gateway --> AuthMiddleware
        AuthMiddleware --> MongoDB
        Gateway --> RedisCache
        Gateway --> RabbitMQ
        RealtimeGW <--> RedisCache
    end

    subgraph External["External Services & Marketplaces"]
        eBayAPI["eBay Browse & Inventory APIs\n(OAuth 2.0 & Listing Sync)"]
        Chrono24["Chrono24 Marketplace\n(Scraper & Price Index)"]
        StripeAPI["Stripe API\n(Checkout Sessions & Escrow)"]
        GeminiAI["Gemini AI Vision API\n(Dial & Spec Detection)"]
    end

    Network -- "REST (JSON / Multipart)" --> Gateway
    Network -- "WebSocket (WSS)" --> RealtimeGW
    Gateway --> eBayAPI
    Gateway --> Chrono24
    Gateway --> StripeAPI
    Gateway --> GeminiAI
```

---

### Real-Time Messaging & Socket Gateway Flow

```mermaid
sequenceDiagram
    autonumber
    actor Dealer as Dealer (User A)
    participant AppA as Mobile App A
    participant SocketGW as Socket.io Gateway
    participant Backend as Express REST API
    participant DB as MongoDB
    participant AppB as Mobile App B
    actor Buyer as Buyer (User B)

    Dealer->>AppA: Open Chat Screen & Type Message
    AppA->>SocketGW: emit('typing', { chatId, isTyping: true })
    SocketGW-->>AppB: on('user_typing', { isTyping: true })
    AppB-->>Buyer: Show "Dealer is typing..." indicator

    Dealer->>AppA: Click "Send"
    alt WebSocket Connected
        AppA->>SocketGW: emit('send_message', { chatId, content, listingId })
        SocketGW->>DB: Persist Message Record
        SocketGW-->>AppB: on('new_message', MessageModel)
        SocketGW-->>AppA: emit('message_sent', { status: 'delivered', id })
    else WebSocket Disconnected / Failed
        AppA->>Backend: POST /api/v1/chat/messages (REST Fallback)
        Backend->>DB: Save Message
        Backend-->>AppA: 201 Created (MessageModel)
    end
    AppB-->>Buyer: Play incoming message chime & update unread badge
```

---

### eBay OAuth 2.0 & Cross-Marketplace Sync Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Collector / Dealer
    participant App as Mobile App
    participant Backend as Backend Gateway
    participant eBay as eBay OAuth & Inventory API

    User->>App: Tap "Connect eBay" in Profile Tab
    App->>Backend: GET /api/v1/ebay/connect?response=json
    Backend-->>App: { authorizationUrl: "https://auth.ebay.com/oauth2/authorize?..." }
    App->>eBay: Launch In-App Browser / Custom Tab
    User->>eBay: Review Scopes & Click "Agree & Continue"
    eBay->>Backend: Redirect GET /api/v1/ebay/oauth/callback?code=AUTH_CODE
    Backend->>eBay: POST /identity/v1/oauth2/token (Exchange Code)
    eBay-->>Backend: Return { access_token, refresh_token, ebay_username }
    Backend->>Backend: Store Encrypted Token in MongoDB
    Backend-->>App: Deep-link redirect: watchbox://oauth/ebay?status=success
    App->>Backend: GET /api/v1/ebay/status
    Backend-->>App: { connected: true, ebayUsername: "luxury_dealer_nyc" }
    App-->>User: Display Green "Connected (luxury_dealer_nyc)" Badge

    opt Publish Listing to eBay
        User->>App: Tap "Sync to eBay" on Watch Detail Screen
        App->>Backend: POST /api/v1/dealer/listings/:listingId/publish-to-ebay
        Backend->>eBay: Create Inventory Item & Offer (eBay Merchant API)
        Backend-->>App: { success: true, ebayListingId: "1234567890" }
        App-->>User: Show Success Notification with eBay Live Link
    end
```

---

## ✨ Key Features & Capabilities

### 1. Multi-Platform Watch Search & Filter Engine
- **Aggregated Queries:** Search simultaneously across Chrono24, eBay, and internal in-app listings.
- **Deep Filtering:** Filter by brand (Rolex, Omega, Patek Philippe, Audemars Piguet, Cartier, etc.), model, condition (Unworn, Excellent, Good, Fair), manufacturing year range, location radius, and price brackets.
- **Autocompletion & Facets:** Instant predictive search suggestions and facet counters display matching inventory counts before applying filters.
- **Free Tier Quota (5 Searches/mo):** Automatic client-side tracking and server-side verification (`/subscriptions/me/usage`) with an intuitive upgrade prompt when exhausted.

### 2. Gemini AI Visual Vision & Image Search
- **Dial & Component Detection:** Captures watch photos via camera or gallery and transmits them to Gemini AI Vision to detect brand, model, dial color, bezel material, and reference number.
- **Vector Feature Embeddings:** Visual search converts images into embeddings to find closest matches across external marketplaces.
- **Listing Auto-Fill:** Dealers taking watch photos have the title, brand, and specifications automatically populated when creating a new listing.

### 3. eBay OAuth 2.0 & Dealer Inventory Sync
- **Seamless OAuth Flow:** Users authorize The Watch Box to manage their eBay inventory through official eBay User Consent protocols.
- **Real-Time Status Monitoring:** Profile tab displays connection state, linked eBay username, and token renewal indicators.
- **One-Tap Listing Push:** Dealers can push any in-app peer listing to eBay as an active marketplace listing (`/dealer/listings/:listingId/publish-to-ebay`).

### 4. Real-Time Dealer & Seller Messaging
- **Dedicated Listings Menu Navigation:** Users can access their conversations directly from the listings tab header icon.
- **Full Chat Experience:** Real-time messages, typing indicators, read receipts, and listing attachment cards showing the watch photo, title, and asking price.
- **Socket.io with REST Fallback:** When WebSockets are unavailable due to restrictive firewalls or sleeping background state, communications gracefully degrade to standard REST endpoints.

### 5. Vector Cubic Bezier Price Trend Analytics
- **Handcrafted Vector Painter:** Custom Flutter `CustomPainter` rendering smooth cubic Bezier trendlines with gradient fills, grid lines, and interactive price highlight tooltips.
- **Valuation Metrics:** Displays 90-day moving averages, historical lowest/highest sold prices, and liquidity/volatility scores.

### 6. Geolocation Radar Service Map
- **Animated Radar Sweep:** Dynamic rotating sweep radar drawing nearby certified luxury watch service centers, watchmakers, and authorized retail boutiques.
- **Detailed Service Center Cards:** Tap pins to view workshop rating, address, distance (miles/km), and direct phone/directions action buttons.

### 7. In-App Subscriptions & Tier Quota Checks
- **Tiers:** Free Tier (5 searches/month), Premium Tier ($29/month - unlimited searches, price alerts, AI vision), VIP Dealer Tier (unlimited listings, direct eBay push, priority placement).
- **Stripe Integration:** Seamless checkout session creation and customer billing portal redirection.

### 8. Peer-to-Peer Trading & Invoicing
- **User Listings:** Create watch listings with high-resolution multi-photo galleries (`/listings/:id/images`).
- **Escrow Buy Now Intent:** Buyers can initiate formal purchase offers with Stripe PaymentIntent escrow holding funds until verification.
- **PDF Invoice Generation:** Instant standard luxury watch invoice generation with buyer/seller details, serial number, and pricing breakdown.

### 9. Real-Time Watch Price Alerts
- **Custom Alert Triggers:** Set triggers for specific watch models when price drops below a target amount.
- **Background Scanner:** Automated worker scans marketplace feeds and pushes notifications via Firebase Cloud Messaging (FCM) and in-app alert badges.

### 10. Admin Management & Feature Toggles
- **Admin Dashboard:** High-level overview of active users, search metrics, monthly recurring revenue, and hardware latency.
- **Dynamic Feature Toggles:** Enable or disable eBay scraping, Chrono24 ingestion, AI image search, and ads on the fly without redeploying code.
- **Staff RBAC:** Role-based access control for superadmins, moderators, and financial auditors.

---

## 🌐 Network & Service Layer Architecture

The Flutter application relies on a clean, decoupled network architecture built on top of **GetConnect**:

```
lib/core/network/
├── api_client.dart           # Master HTTP client with automatic JWT injection & refresh
├── api_endpoints.dart        # Type-safe constants for all 419 backend endpoints
├── socket_service.dart       # Socket.io client for real-time chat, typing, and alerts
└── services/
    ├── auth_api_service.dart            # Login, register, token refresh, password recovery
    ├── search_api_service.dart          # Multi-platform search, facets, history
    ├── visual_search_api_service.dart   # Camera upload, Gemini AI vision analysis
    ├── listings_api_service.dart        # Peer listings, photo gallery upload, status
    ├── recommendations_api_service.dart # Personalized AI watch recommendations
    ├── alerts_api_service.dart          # Price drop alerts, trigger execution, notifications
    ├── subscriptions_api_service.dart   # Stripe checkout, plan status, quota check
    ├── chat_api_service.dart            # REST conversation list, messages, mark-as-read
    └── ebay_api_service.dart            # eBay OAuth connect URL, status, publish listing
```

### Automatic Token Refresh Lifecycle
1. `ApiClient` intercepts outgoing requests and adds `Authorization: Bearer <accessToken>`.
2. When the backend returns a `401 Unauthorized`, `ApiClient` automatically pauses pending requests.
3. It dispatches a refresh request using `refreshToken` to `POST /api/v1/auth/refresh`.
4. Upon receiving the new token, it updates `PrefManager`, updates the header, and transparently replays the failed request without logging out the user.

---

## 📁 Complete Project Directory Tree

```
lib/
├── main.dart                               # App entry point, service locator bindings & routes
├── core/
│   ├── db/
│   │   └── db_helper.dart                  # SQLite helper, migrations, schema & seed data
│   ├── network/
│   │   ├── api_client.dart                 # Base HTTP client with JWT interceptor & auto-refresh
│   │   ├── api_endpoints.dart              # REST endpoints inventory & path builders
│   │   ├── socket_service.dart             # Socket.io client with REST fallback
│   │   └── services/                       # 9 specialized domain network services
│   ├── prefs/
│   │   └── pref_manager.dart               # SharedPreferences wrapper for tokens & settings
│   └── theme/
│       ├── app_colors.dart                 # Luxury navy, dial blue, gold, and slate palette
│       └── app_theme.dart                  # High-contrast Dark & Light ThemeData definitions
├── models/
│   ├── alert_model.dart                    # Notification & price drop alert entity
│   ├── bookmark_model.dart                 # Saved listing bookmark reference
│   ├── conversation_model.dart             # Chat thread header with last message & unread count
│   ├── message_model.dart                  # Individual chat message with sender, time & media
│   ├── org_marker_model.dart               # Service center & dealer map marker coordinates
│   ├── search_query_model.dart             # Bookmarked search queries & JSON filter filters
│   ├── user_model.dart                     # User profile entity with role, plan & avatar
│   └── watch_model.dart                    # Canonical watch listing entity
├── controllers/
│   ├── admin_controller.dart               # Admin metrics, user status & feature toggles
│   ├── alert_controller.dart               # Notifications feed, unread counters & push events
│   ├── auth_controller.dart                # User authentication, profile session & plan state
│   ├── bookmark_controller.dart            # Saved listings & saved search queries
│   ├── chat_controller.dart                # Real-time conversations, messaging & typing status
│   ├── map_controller.dart                 # Radar map markers, location radius & selection
│   ├── onboarding_controller.dart          # 3-step feature onboarding carousel
│   └── search_controller.dart              # Multi-marketplace search, filters & quota check
└── views/
    ├── splash/splash_screen.dart           # Rotating watermark gear dials & loading bar
    ├── onboarding/onboarding_screen.dart   # Interactive 3-step feature introduction
    ├── auth/
    │   ├── login_screen.dart               # Login with developer mockup profile switcher
    │   └── sign_up_screen.dart             # Registration with direct avatar image upload
    ├── home/
    │   ├── home_screen.dart                # Main container with 5-tab floating navigation bar
    │   ├── watch_detail_screen.dart        # Hero view, vector price curve, specs & buy sheet
    │   ├── traders_collections_screen.dart # Peer-to-peer watch marketplace
    │   └── tabs/
    │       ├── home_tab.dart               # Dashboard with market indices & trending watches
    │       ├── search_tab.dart             # Search grid with filter drawer & platform chips
    │       ├── listings_tab.dart           # In-app market, my listings & dealer chat access
    │       ├── alerts_tab.dart             # Price drops, new listing alerts & event history
    │       ├── map_tab.dart                # Animated radar map with service center pins
    │       └── profile_tab.dart            # Profile stats, eBay connection badge, settings
    ├── chat/
    │   ├── conversations_screen.dart       # List of dealer & seller message threads
    │   └── chat_screen.dart                # Real-time message thread with watch listing card
    ├── profile/
    │   ├── account_settings_screen.dart    # Profile detail editor & session revocation
    │   ├── change_password_screen.dart     # Password modification view
    │   ├── invoice_preview_screen.dart     # PDF luxury invoice preview & download
    │   ├── my_listings_screen.dart         # Active & sold trader listings management
    │   ├── notifications_screen.dart       # Expanded notification preferences
    │   └── subscription_plans_screen.dart  # Free vs Premium vs VIP plan tier selector
    ├── search/image_search_screen.dart     # Camera shutter AI visual search
    ├── admin/admin_dashboard.dart          # Admin control center & marketplace toggles
    └── widgets/
        ├── custom_chart.dart               # CustomPainter cubic Bezier PriceTrendChart
        ├── create_listing_sheet.dart       # Bottom sheet for creating watch listings
        ├── watch_background.dart           # Luxury radial gradient background scaffold
        └── navbar/custom_navbar.dart       # Floating navy navigation bar with badge dots
```

---

## 📬 Postman API Collection (`collection.json`)

A complete, fully verified **Postman Collection (v2.1.0)** is included in the project root:
👉 [`collection.json`](file:///d:/nahid/the_watch_box/the_watch_box/collection.json)

### Collection Overview:
- **Total Requests:** **419 endpoints**
- **Categorized Modules:** **17 Top-Level Folders, 33 Subfolders**
- **Authentication:** Auto-configured `Bearer {{accessToken}}` or `Bearer {{adminToken}}` with public route exceptions.

### Module Breakdown:
| Folder | Category | Requests | Key Features |
| :---: | :--- | :---: | :--- |
| **01** | `Authentication & Sessions` | 12 | Customer login, registration, refresh token, password reset, active sessions |
| **02** | `User Profile & Preferences` | 15 | Profile details, multipart avatar upload, dark mode, currency, nearby users |
| **03** | `Search & Discovery` | 7 | Multi-platform aggregated search, suggestions, trending keywords, facets |
| **04** | `Image Search & AI Detection` | 14 | Gemini AI dial analysis, vector embedding search, direct eBay/Chrono24 image search |
| **05** | `Watch Details & Catalog` | 17 | Brands, reference models, specifications, price history, affiliate outbound links |
| **06** | `Price Trend & Market Analytics` | 33 | 90-day price trends, liquidity scores, volatility index, portfolio value tracking |
| **07** | `Bookmarks & Watchlists` | 14 | Saved watches, custom watchlists, personalized AI watch recommendations |
| **08** | `Saved Searches & Search Alerts` | 14 | Saved queries, background watch price alerts, instant match trigger scan |
| **09** | `Notifications & Price Drop Alerts` | 12 | Notification feeds, unread badge counter, SSE stream, push token registration |
| **10** | `Peer-to-Peer Marketplace & Trader Listings` | 39 | Trader collections, active/sold listings, multi-photo gallery uploads |
| **11** | `In-App Orders & Transactions` | 17 | Purchase orders, escrow payment intents, payment confirmation, reviews |
| **12** | `Subscriptions & Quota (5 Searches/mo Check)` | 14 | Free quota verification, Stripe checkout session, customer billing portal |
| **13** | `Support, Content & Reports` | 13 | Support tickets, messaging, suspicious listing reports, privacy policy & terms |
| **14** | `Admin Panel & Controls` | 164 | Admin auth, user management, staff RBAC, promotions, earnings, marketplace toggles |
| **15** | `Platform Webhooks` | 5 | Stripe payments, eBay account deletion challenge (`GET/POST /webhooks/ebay`), push |
| **16** | `eBay & External Marketplaces` | 23 | eBay OAuth connect URL, connection status, dealer sync, Chrono24 price indices |
| **17** | `System Health & Gateway` | 6 | Kubernetes liveness/readiness probes, Mongo/Redis/RabbitMQ health checks |

---

## 🗺️ Complete Feature-to-API Mapping Matrix

| App Feature / Screen | Mobile Implementation (`lib/`) | Backend REST API Endpoint | Auth Type | Status & Implementation Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Customer Registration** | `AuthController.register()` / `sign_up_screen.dart` | `POST /api/v1/auth/register` | Public | **Connected**. Registers user with email, password, name, phone & country. |
| **Direct Avatar Upload** | `AuthController.uploadAvatar()` / `ProfileTab` | `POST /api/v1/users/me/avatar` | Customer Bearer | **Connected**. Multipart/form-data direct image upload to storage. |
| **Customer Login** | `AuthController.login()` / `login_screen.dart` | `POST /api/v1/auth/login` | Public | **Connected**. Returns JWT access token, refresh token, and account object. |
| **Refresh Token** | `ApiClient` automatic 401 interceptor | `POST /api/v1/auth/refresh` | Public | **Connected**. Exchanges refresh token for fresh JWT access token. |
| **Multi-Platform Search** | `WatchSearchController.executeSearch()` | `GET /api/v1/search` | Customer Bearer | **Connected**. Aggregates eBay, Chrono24, and internal peer listings. |
| **AI Vision Detection** | `VisualSearchApiService.analyzeImage()` | `POST /api/v1/ai/analyze-image` | Customer Bearer | **Connected**. Gemini AI dial, bezel, and reference detection. |
| **AI Visual Search** | `VisualSearchApiService.createSearch()` | `POST /api/v1/ai/search` | Customer Bearer | **Connected**. Multimodal visual vector matching across platforms. |
| **eBay OAuth Connect URL** | `EbayApiService.getConnectUrl()` / `ProfileTab` | `GET /api/v1/ebay/connect?response=json` | Customer Bearer | **Connected**. Returns eBay User Consent authorization URL. |
| **eBay Connection Status** | `EbayApiService.getStatus()` / `ProfileTab` | `GET /api/v1/ebay/status` | Customer Bearer | **Connected**. Returns connected state, linked username, and expiration. |
| **Disconnect eBay** | `EbayApiService.disconnect()` / `ProfileTab` | `POST /api/v1/ebay/disconnect` | Customer Bearer | **Connected**. Revokes stored credentials and terminates eBay link. |
| **Publish to eBay** | `EbayApiService.publishListing()` | `POST /api/v1/dealer/listings/:id/publish-to-ebay` | Customer Bearer | **Connected**. Pushes in-app watch listing directly to eBay inventory. |
| **Dealer Conversations List**| `ChatApiService.getConversations()` / `conversations_screen.dart`| `GET /api/v1/chat/conversations` | Customer Bearer | **Connected**. Returns list of active chat threads with latest messages. |
| **Fetch Chat Messages** | `ChatApiService.getMessages()` / `chat_screen.dart` | `GET /api/v1/chat/:chatId/messages` | Customer Bearer | **Connected**. Returns paginated message history for a conversation. |
| **Send Chat Message** | `SocketService.sendMessage()` (fallback: `ChatApiService`)| `POST /api/v1/chat/:chatId/messages` | Customer Bearer | **Connected**. Transmits chat message via WebSocket (or REST fallback). |
| **Price Trend Curve** | `CustomPriceChart` / `watch_detail_screen.dart` | `GET /api/v1/analytics/watch-models/:id/price-trend` | Customer Bearer | **Connected**. Historical valuation data for vector Bezier rendering. |
| **Watch Market Summary** | `WatchDetailScreen` (Spread badge) | `GET /api/v1/watch-models/:id/market-summary` | Customer Bearer | **Connected**. Returns lowest, highest, and 90-day average market prices. |
| **Create Watch Price Alert**| `AlertsApiService.createAlert()` / `BookmarksTab` | `POST /api/v1/watch-alerts` | Customer Bearer | **Connected**. Configures background price drop notification trigger. |
| **Run Alert Scan** | `AlertsApiService.runScan()` | `POST /api/v1/watch-alerts/run` | Customer Bearer | **Connected**. Triggers instant scan of inventory for price alert matches. |
| **Check Monthly Quota** | `SubscriptionsApiService.getUsage()` | `GET /api/v1/subscriptions/me/usage` | Customer Bearer | **Connected**. Verifies 5 searches/month consumption for Free users. |
| **Stripe Checkout** | `SubscriptionsApiService.createCheckout()` | `POST /api/v1/subscription/checkout` | Customer Bearer | **Connected**. Generates Stripe Checkout Session for plan upgrades. |
| **Billing Portal** | `SubscriptionsApiService.createPortal()` | `POST /api/v1/subscription/portal` | Customer Bearer | **Connected**. Opens Stripe customer portal for card & invoice management. |
| **Listing Photos Upload** | `ListingsApiService.uploadImages()` | `POST /api/v1/listings/:id/images` | Customer Bearer | **Connected**. Multipart upload of high-resolution watch photographs. |
| **Buy Now Payment Intent** | `ListingsApiService.createPaymentIntent()` | `POST /api/v1/payments/products/:id/payment-intent` | Customer Bearer | **Connected**. Creates Stripe PaymentIntent for instant escrow purchase. |

---

## 🗄️ Local SQLite Database Schema (`watch_sphere.db`)

The mobile client maintains a fully independent local SQLite database for offline caching and demo simulation:

```sql
-- 1. Users Table
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  plan TEXT DEFAULT 'free',
  status TEXT DEFAULT 'active'
);

-- 2. Listings Table
CREATE TABLE listings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  title TEXT NOT NULL,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  price REAL NOT NULL,
  platform TEXT NOT NULL,
  year INTEGER,
  condition TEXT,
  location TEXT,
  is_sold INTEGER DEFAULT 0,
  timestamp TEXT
);

-- 3. Bookmarks Table
CREATE TABLE bookmarks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  listing_id INTEGER NOT NULL
);

-- 4. Saved Searches Table
CREATE TABLE saved_searches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  query_text TEXT NOT NULL,
  filters_json TEXT
);

-- 5. Alerts Table
CREATE TABLE alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  is_read INTEGER DEFAULT 0
);

-- 6. Invoices Table
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  listing_id INTEGER NOT NULL,
  buyer_name TEXT NOT NULL,
  buyer_email TEXT NOT NULL,
  invoice_no TEXT NOT NULL,
  date TEXT NOT NULL,
  price REAL NOT NULL
);
```

---

## 🚀 Prerequisites & Getting Started

### 1. Mobile App Execution (Flutter)

#### Prerequisites
- **Flutter SDK:** `>=3.44.0` (Channel stable)
- **Dart SDK:** `>=3.12.1`
- **Android Studio / Xcode:** For emulator or physical device testing

#### Steps
```bash
# 1. Clone repository
git clone https://github.com/nahidshuvo1802/watch-box.git
cd watch-box

# 2. Install Flutter packages
flutter pub get

# 3. Verify Flutter setup
flutter doctor

# 4. Launch on connected device or emulator
flutter run
```

---

### 2. Backend Service Execution (Node.js & Docker)

#### Prerequisites
- **Node.js:** `>=22.11.0`
- **Docker Desktop:** Running (for MongoDB, Redis, and RabbitMQ containers)

#### Steps
```bash
# 1. Navigate to backend project directory
cd d:/nahid/watchBox-Backend

# 2. Start backing services via Docker Compose
npm run docker:up

# 3. Install npm packages
npm install

# 4. Start backend in development mode
npm run dev
```
> The API server will boot up at `http://localhost:4000`. RabbitMQ Management is accessible at `http://localhost:15672` (User: `watchbox`, Pass: `change-me`).

---

### 3. Environment Variables Configuration

#### Backend `.env` Settings:
```env
PORT=4000
API_PREFIX=/api/v1
MONGODB_URI=mongodb://localhost:27017/watchbox
REDIS_URL=redis://default:change-me@localhost:6379
RABBITMQ_URL=amqp://watchbox:change-me@localhost:5672/watchbox

# eBay Developer Integration
EBAY_CLIENT_ID=your-ebay-app-id
EBAY_CLIENT_SECRET=your-ebay-cert-id
EBAY_REDIRECT_URI=https://api.mywatchbox.net/api/v1/ebay/oauth/callback
EBAY_ENVIRONMENT=PRODUCTION

# Stripe Payments
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Gemini AI Vision
GEMINI_API_KEY=AIzaSy...
```

#### Flutter App Base URL Configuration:
In [`lib/core/prefs/pref_manager.dart`](file:///d:/nahid/the_watch_box/the_watch_box/lib/core/prefs/pref_manager.dart), the application automatically resolves the base URL:
- **Production Server:** `https://api.mywatchbox.net/api/v1`
- **Android Emulator Localhost:** `http://10.0.2.2:4000/api/v1`
- **iOS Simulator / Desktop / Web:** `http://localhost:4000/api/v1`

---

## 🧪 Quality Assurance & Testing

```bash
# Run all unit and controller tests
flutter test

# Verify static analysis & linter rules
flutter analyze
```

---

## 📄 License & Attribution

This project is licensed under the MIT License - see the [LICENSE](file:///d:/nahid/the_watch_box/the_watch_box/LICENSE) file for details.

Developed with ❤️ by **Nahid Khan Shuvo** and the Horology Engineering Team.
For inquiries, partnership, or API access, contact: `nahid.sparktech@gmail.com`.