# Notification Badge Implementation Plan

## Overview
Implement a red dot badge on the notification icon in the navbar that:
- Shows when there are unread notifications
- Hides when there are no unread notifications
- Updates in real-time when notifications change
- Works across all screens without affecting existing functionality

## Current State Analysis

### ✅ What's Already in Place:
1. **UI Component**: The red dot badge is already implemented in `_NotificationSegment` (lines 166-181 in `pal_bottom_nav_bar.dart`)
2. **Service Method**: `NotificationService.getUnreadCount()` exists and works correctly
3. **Database**: `notifications_history` table has `is_read` field for tracking unread status
4. **Real-time Infrastructure**: Supabase real-time subscriptions are already used in `NotificationsScreen`

### ❌ What Needs to be Fixed:
1. **Hardcoded Values**: `showNotificationDot` is hardcoded to `true` in multiple screens
2. **No State Management**: No centralized way to track unread count across screens
3. **No Real-time Updates**: Navbar doesn't update when notifications change on other screens
4. **No Initial Load**: Unread count is not fetched when screens first load

## Implementation Strategy

### Option 1: Lightweight State Management (Recommended)
Create a simple `ValueNotifier`-based notification count manager that:
- Tracks unread count globally
- Updates all navbar instances automatically
- Uses minimal resources
- No external dependencies

### Option 2: Service-Based with Manual Updates
Each screen fetches unread count independently and passes to navbar
- More code duplication
- Less efficient (multiple queries)
- Harder to maintain

**We'll use Option 1** for best UX and maintainability.

## Implementation Steps

### Phase 1: Create Notification Count Manager
**File**: `lib/services/notification_count_manager.dart` (NEW)

**Purpose**: Centralized state management for unread notification count

**Features**:
- `ValueNotifier<int>` to hold unread count
- Methods to fetch and update count
- Real-time Supabase subscription
- Automatic cleanup on dispose

**Key Methods**:
```dart
- int get unreadCount (read-only accessor)
- ValueNotifier<int> get notifier (for listening)
- Future<void> refreshCount() (fetch from database)
- void _setupRealtimeListener() (listen for changes)
- void dispose() (cleanup)
```

### Phase 2: Update NotificationService
**File**: `lib/services/notification_service.dart`

**Changes**:
- Add method to get unread count efficiently (already exists, verify it's optimal)
- Ensure `markAsRead()` and `markAllAsRead()` work correctly (already implemented)

**Verification**:
- Check that `getUnreadCount()` uses proper indexing (should query `is_read = false`)
- Verify it handles edge cases (no user, network errors)

### Phase 3: Integrate Manager in Main App
**File**: `lib/main.dart`

**Changes**:
- Initialize `NotificationCountManager` in `_PalAppState`
- Start real-time listener when user is logged in
- Dispose manager when app closes
- Pass manager instance to screens that need it (via constructor or static accessor)

**Lifecycle**:
- Initialize on app start (if user logged in)
- Refresh count on login
- Clear count on logout
- Dispose on app close

### Phase 4: Update Navbar Widget
**File**: `lib/widgets/pal_bottom_nav_bar.dart`

**Changes**:
- Replace `showNotificationDot` boolean parameter with `unreadCount` int parameter
- Calculate `showDot` internally: `unreadCount > 0 && !_notificationsActive`
- Make navbar listen to `NotificationCountManager` using `ValueListenableBuilder`
- Ensure smooth animations (fade in/out for badge)

**UI Behavior**:
- Badge appears when `unreadCount > 0`
- Badge hides when `unreadCount == 0`
- Badge hides when notifications tab is active (existing behavior)
- Smooth fade animation (200ms)

### Phase 5: Update All Screen Usages
**Files to Update**:
1. `lib/screens/feed/feed_home_screen.dart`
2. `lib/screens/notifications/notifications_screen.dart`
3. `lib/screens/settings/settings_screen.dart`
4. `lib/screens/admin/*.dart` (all admin screens)
5. `lib/screens/moderator/*.dart` (all moderator screens)

**Changes**:
- Remove hardcoded `showNotificationDot: true`
- Pass `unreadCount` from `NotificationCountManager` to navbar
- Use `ValueListenableBuilder` to rebuild navbar when count changes

### Phase 6: Update Notifications Screen
**File**: `lib/screens/notifications/notifications_screen.dart`

**Changes**:
- When notifications are marked as read, update `NotificationCountManager`
- When screen opens and marks all as read, refresh manager count
- Ensure real-time updates sync with manager

**Behavior**:
- On screen open: Mark all as read → Update manager count to 0
- On notification tap: Mark as read → Decrement manager count
- Real-time listener: Update manager when new notifications arrive

### Phase 7: Handle Edge Cases

**Scenarios to Handle**:
1. **User logs out**: Clear count to 0
2. **User logs in**: Fetch initial count
3. **Network error**: Show last known count (don't show error)
4. **App backgrounded**: Pause real-time listener (save battery)
5. **App foregrounded**: Resume listener and refresh count
6. **Multiple navbar instances**: All update simultaneously (ValueNotifier handles this)

### Phase 8: Performance Optimizations

**Optimizations**:
1. **Debounce real-time updates**: Don't update UI on every database change (wait 100ms)
2. **Cache count**: Only fetch from DB when necessary
3. **Lazy initialization**: Only start listener when navbar is visible
4. **Efficient queries**: Use `count()` instead of fetching all records (if Supabase supports it)

## Backend Requirements

### ✅ Already Implemented:
- `notifications_history` table with `is_read` boolean field
- `user_id` field for filtering
- Real-time subscriptions enabled on table

### ⚠️ Verification Needed:
1. **Database Index**: Ensure there's an index on `(user_id, is_read)` for fast queries
   ```sql
   CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
   ON notifications_history(user_id, is_read) 
   WHERE is_read = false;
   ```

2. **Real-time Permissions**: Verify RLS policies allow users to subscribe to their own notifications
   ```sql
   -- Should already exist, but verify:
   -- Users can only see their own notifications
   ```

3. **Query Performance**: Test `getUnreadCount()` with large datasets (1000+ notifications)
   - Should return in < 100ms
   - Consider using `count()` aggregation if available

## Testing Checklist

### Functional Tests:
- [ ] Badge shows when unread count > 0
- [ ] Badge hides when unread count = 0
- [ ] Badge hides when notifications tab is active
- [ ] Badge updates when notification is read
- [ ] Badge updates when new notification arrives
- [ ] Badge updates when all notifications marked as read
- [ ] Badge persists across screen navigation
- [ ] Badge updates in real-time (test with 2 devices)

### Edge Case Tests:
- [ ] User logs out → Badge disappears
- [ ] User logs in → Badge shows correct count
- [ ] Network error → Shows last known count (graceful degradation)
- [ ] App backgrounded → Listener pauses
- [ ] App foregrounded → Count refreshes
- [ ] Multiple navbars visible → All update simultaneously
- [ ] Rapid notification updates → No UI flickering

### Performance Tests:
- [ ] Initial load time < 200ms
- [ ] Real-time update latency < 500ms
- [ ] No memory leaks (test with 100+ screen navigations)
- [ ] Battery impact minimal (test with app in background for 1 hour)

## User Experience Considerations

### Smooth Animations:
- Badge fade-in: 200ms ease-in
- Badge fade-out: 200ms ease-out
- No jarring transitions

### Visual Design:
- Red dot color: `#E7000B` (already implemented)
- White border: 1px (already implemented)
- Size: 10px (already implemented)
- Position: Top-right corner (already implemented)

### Behavior:
- Badge appears immediately when count > 0
- Badge disappears immediately when count = 0
- Badge hidden when viewing notifications (user already sees them)
- No flickering during rapid updates

## Implementation Order

1. ✅ Create `NotificationCountManager` service
2. ✅ Integrate manager in `main.dart`
3. ✅ Update navbar to use `ValueListenableBuilder`
4. ✅ Update all screen usages
5. ✅ Update notifications screen to sync with manager
6. ✅ Add edge case handling
7. ✅ Performance optimizations
8. ✅ Testing

## Risk Assessment

### Low Risk:
- UI component already exists
- Service method already exists
- Real-time infrastructure already in place

### Medium Risk:
- Need to ensure all screens updated
- Need to test real-time updates work correctly
- Need to verify no memory leaks

### Mitigation:
- Incremental implementation (one screen at a time)
- Comprehensive testing at each phase
- Code review before merging

## Questions for Client

1. **Backend**: Do you want me to verify/create the database index, or will you handle that?
2. **Performance**: Should we use a count aggregation query, or is the current `getUnreadCount()` method sufficient?
3. **Real-time**: Should the badge update immediately on new notifications, or is a 1-2 second delay acceptable?
4. **Offline**: How should the badge behave when the user is offline? (Show last known count or hide?)
5. **Animation**: Do you want any specific animation style for the badge appearance/disappearance?

## Estimated Implementation Time

- Phase 1-2: 1 hour (Manager + Service updates)
- Phase 3-4: 1 hour (Main app + Navbar)
- Phase 5: 2 hours (All screens)
- Phase 6: 1 hour (Notifications screen)
- Phase 7-8: 1 hour (Edge cases + Optimizations)
- Testing: 1 hour

**Total: ~7 hours**

## Success Criteria

✅ Badge shows/hides correctly based on unread count
✅ Badge updates in real-time across all screens
✅ No performance degradation
✅ No UI glitches or flickering
✅ Works correctly in all edge cases
✅ Follows Flutter best practices
✅ Code is maintainable and well-documented
