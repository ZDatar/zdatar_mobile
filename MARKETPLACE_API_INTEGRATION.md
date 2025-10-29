# Marketplace API Integration

## Overview
This document describes the integration of the ZDatar backend deals API with the mobile app's Marketplace page and Deal Detail page.

## API Endpoints Used

### 1. Get All Deals
```
GET http://localhost:3000/deals
```
**Response:**
```json
{
  "deals": [...],
  "total": 6
}
```

### 2. Get Deal Details
```
GET http://localhost:3000/deals/{deal_id}
```
**Response:**
```json
{
  "deal_id": "...",
  "status": "created",
  "buyer_wallet": "...",
  "seller_wallet": null,
  "deal_meta": {
    "currency": "SOL",
    "data_type": "Location",
    "price": "1",
    "request_description": "Test"
  },
  "solana_tx_hash": "...",
  "dataset_id": null,
  "created_at": "2025-10-28T14:30:52.110893Z",
  "updated_at": "2025-10-28T14:30:52.110893Z",
  "expires_at": "2025-11-04T14:30:52.110893Z"
}
```

## Implementation Details

### Files Created

#### 1. `lib/models/deal.dart`
Data models for Deal, DealMeta, and DealsResponse.
- **Deal**: Main deal object with all fields from API
- **DealMeta**: Metadata including price, currency, data_type, and description
- **DealsResponse**: Wrapper for list of deals with total count

#### 2. `lib/services/deals_service.dart`
Service singleton for API communication:
- `fetchDeals()`: Get all deals
- `fetchDealById(dealId)`: Get specific deal details
- `acceptDeal(dealId, sellerWallet)`: Accept a deal (placeholder API)

**Configuration:**
- Base URL: `http://localhost:3000` (update this for production)
- Timeout: 5 seconds per request
- Uses `http` package for REST calls
- Includes logging via `logger` package

### Files Modified

#### 1. `lib/screens/market_place_page.dart`
**Changes:**
- Converted from `StatelessWidget` to `StatefulWidget`
- Added **automatic polling every 1 second** to fetch latest deals
- Displays real deals from API instead of hardcoded data
- Shows deal count and loading indicator
- Maps data types to appropriate icons
- Displays deal status badges
- Shows "time ago" for each deal
- Empty state when no deals available

**Features:**
- Real-time updates (1-second polling)
- Loading indicator during first fetch
- Graceful error handling
- Clean card design with status badges

#### 2. `lib/screens/deal_detail_page.dart`
**Changes:**
- Converted from `StatelessWidget` to `StatefulWidget`
- Accepts `dealId` parameter instead of static data
- Fetches deal details from API on page load
- Displays comprehensive deal information:
  - Data type and icon
  - Price and currency
  - Status badge
  - Description
  - Deal ID, buyer wallet, transaction hash
  - Created and expiration dates
- Accept Deal button (enabled only for "created" status)
- Loading state while fetching
- Error state if deal not found

**Features:**
- Dynamic data loading
- Accept deal functionality (TODO: needs wallet integration)
- Formatted dates using `intl` package
- Disabled button for non-created deals
- Loading spinner on accept action

#### 3. `pubspec.yaml`
**Added dependencies:**
```yaml
http: ^1.2.0      # For API calls
intl: ^0.19.0     # For date formatting
```

## Configuration Required

### Backend URL
Update the base URL in `lib/services/deals_service.dart`:
```dart
static const String _baseUrl = 'http://localhost:3000';
```

For production, change to your actual backend URL:
```dart
static const String _baseUrl = 'https://api.zdatar.com';
```

### Wallet Integration
The accept deal functionality currently uses a placeholder wallet:
```dart
const sellerWallet = 'YOUR_WALLET_ADDRESS_HERE';
```

**TODO:** Integrate with actual wallet authentication system to get the seller's wallet address.

## Polling Behavior

The Marketplace page polls the API **every 1 second** to check for new deals or updates.

**Performance considerations:**
- Polling only happens when the Marketplace page is active
- Timer is cancelled when page is disposed
- Network requests have 5-second timeout
- Failed requests don't crash the app

**To adjust polling frequency**, modify this line in `market_place_page.dart`:
```dart
_pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  _fetchDeals();
});
```

## Data Type to Icon Mapping

The app maps deal data types to appropriate Material Icons:
- `location` → `Icons.location_on`
- `health` → `Icons.favorite`
- `app usage` / `app` → `Icons.apps`
- `motion` / `sensor` → `Icons.sensors`
- Default → `Icons.data_usage`

Add more mappings in the `_getIconForDataType()` method as needed.

## Status Handling

Deal statuses are displayed with colored badges:
- **created** → Green badge, "New" label, Accept button enabled
- **accepted** → Blue badge, "Active" label, Accept button disabled
- **completed** → Blue badge, "Done" label, Accept button disabled

## Error Handling

- **Network errors:** Logged but app continues to function
- **Deal not found:** Shows error screen with back button
- **Accept deal failure:** Shows red snackbar notification
- **Loading states:** Displays loading indicator

## Testing

### Manual Testing Steps

1. **Start the backend server:**
   ```bash
   # In your backend directory
   # Make sure the deals API is running on http://localhost:3000
   ```

2. **Run the Flutter app:**
   ```bash
   cd /Users/johnnguyen/Nextcloud/John/02-Src/zdatar/zdatar_mobile
   flutter run --release --device-id=YOUR_DEVICE_ID
   ```

3. **Navigate to Marketplace tab**
   - Should see deals loading from API
   - Deal count should match API response
   - Cards should update every second

4. **Tap on a deal**
   - Should navigate to detail page
   - Should see all deal information
   - Accept button should work (if status is "created")

5. **Test with no deals**
   - Empty API response should show "No deals available" message

## Future Enhancements

1. **Pull-to-refresh** instead of automatic polling
2. **WebSocket connection** for real-time updates
3. **Pagination** for large numbers of deals
4. **Filtering** by data type, price, status
5. **Search functionality**
6. **Wallet integration** for accept deal functionality
7. **Deal history** page for accepted/completed deals
8. **Push notifications** for new deals

## Notes

- The current implementation polls every 1 second which may be aggressive for production
- Consider implementing exponential backoff or WebSocket for better performance
- Wallet integration is required before the accept deal functionality can work
- Update the base URL before deploying to production
- Add proper error handling for specific HTTP status codes (401, 403, 404, etc.)
