# 🎯 FCM Frontend Integration - Testing Guide

## ✅ What Has Been Integrated

### 1. **Enhanced FCM Service** (`lib/services/fcm_service.dart`)
- ✅ Added notification tap handling
- ✅ Added navigation callback system
- ✅ Enhanced message handlers for all app states (foreground, background, terminated)
- ✅ Proper notification data parsing

### 2. **Main App Navigation** (`lib/main.dart`)
- ✅ Added global navigator key for notification navigation
- ✅ Set up notification tap callback
- ✅ Added navigation handler for different notification types
- ✅ Handles navigation to appropriate screens based on notification data

### 3. **Test Service** (`lib/services/notification_test_service.dart`)
- ✅ `sendTestNotification()` - Send test notifications
- ✅ `getFCMTokenStatus()` - Check FCM token registration
- ✅ `getRecentNotifications()` - View notification history

### 4. **Settings Screen Integration** (`lib/screens/settings/settings_screen.dart`)
- ✅ Added "Testing" section with:
  - **Test Notification** button - Sends a test push notification
  - **FCM Token Status** button - Shows FCM token registration status

---

## 🧪 How to Test

### Step 1: Verify FCM Token Registration

1. **Login to the app**
   - FCM service will automatically initialize
   - Token will be saved to Supabase `user_fcm_tokens` table

2. **Check Token Status**
   - Go to **Settings** screen
   - Tap **"FCM Token Status"**
   - Verify:
     - ✅ Registered Tokens: Should show 1 or more
     - ✅ Has Tokens: Should be "Yes ✅"
     - ✅ FCM Initialized: Should be "Yes ✅"
     - Current Token: Should display your FCM token

### Step 2: Send Test Notification

1. **From Settings Screen**
   - Go to **Settings** screen
   - Scroll to **"Testing"** section
   - Tap **"Test Notification"**
   - You should receive a push notification within a few seconds

2. **Verify Notification**
   - Check if notification appears in notification tray
   - Tap the notification
   - App should open (if closed) or come to foreground
   - Check console logs for notification data

### Step 3: Test Real Triggers

The following actions will automatically trigger notifications (via database triggers):

#### Test New Comment Notification
1. Create a post (as User A)
2. Login as different user (User B)
3. Comment on User A's post
4. User A should receive "New Comment" notification

#### Test Reply Notification
1. User A comments on a post
2. User B replies to User A's comment
3. User A should receive "New Reply" notification

#### Test Upvote Notifications
1. User A creates a post
2. User B upvotes the post
3. User A should receive "Post Upvoted" notification

#### Test Post Achievement Notifications
- These are triggered when:
  - Post becomes trending (`is_trending` = true)
  - Post reaches monthly spotlight (`is_monthly_spotlight` = true)

---

## 📱 Notification Navigation

When a notification is tapped, the app will navigate based on notification type:

| Notification Type | Navigation Target |
|------------------|-------------------|
| `new_comment` | Home screen (highlights post) |
| `reply_to_comment` | Home screen (highlights post) |
| `post_upvote` | Home screen (highlights post) |
| `comment_upvote` | Home screen (highlights post & comment) |
| `post_hot` | Home screen (highlights post) |
| `post_top` | Home screen (highlights post) |
| `post_trending` | Home screen (highlights post) |
| `mention_in_comment` | Home screen (highlights post & comment) |
| `mention_in_post` | Home screen (highlights post) |
| `report_under_review` | Notifications screen |
| `report_resolved` | Notifications screen |
| `account_suspended` | Settings screen |
| `account_warning` | Settings screen |

---

## 🔍 Debugging

### Check Console Logs

Look for these log messages:

```
[FCMService] FCM Token: <token>
[FCMService] Token saved to Supabase
[FCMService] Foreground message received: <message_id>
[FCMService] Notification data: {notification_type: ..., post_id: ..., ...}
[PalApp] Handling notification navigation: type=..., postId=..., commentId=...
```

### Common Issues

#### Issue: No notifications received
**Check:**
1. FCM token is registered (use "FCM Token Status" in Settings)
2. Edge Function is deployed and `FCM_SERVER_KEY` is set
3. Database triggers are active
4. Check Supabase Edge Function logs

#### Issue: Notification received but app doesn't navigate
**Check:**
1. Notification data contains required fields (`post_id`, `notification_type`)
2. App is in foreground when notification is tapped
3. Check console logs for navigation errors

#### Issue: Token not saving
**Check:**
1. User is logged in
2. `user_fcm_tokens` table exists in Supabase
3. RLS policies allow user to insert/update their tokens
4. Check console for error messages

---

## 📊 Testing Checklist

- [ ] FCM token registered after login
- [ ] Test notification sent from Settings
- [ ] Test notification received on device
- [ ] Notification tap opens app
- [ ] Navigation works correctly
- [ ] Real comment triggers notification
- [ ] Real reply triggers notification
- [ ] Real upvote triggers notification
- [ ] Foreground notifications show correctly
- [ ] Background notifications work
- [ ] Terminated state notifications work

---

## 🚀 Next Steps

1. **Test all notification types** using the test button
2. **Test real triggers** by performing actions (comments, upvotes, etc.)
3. **Verify navigation** works for each notification type
4. **Check Edge Function logs** in Supabase Dashboard if notifications fail
5. **Monitor database** to see notifications being created in `notifications_history`

---

## 📝 Notes

- Notifications are saved to `notifications_history` table even if push fails
- Multiple FCM tokens per user are supported (different devices)
- Token refresh is handled automatically
- Notifications work in foreground, background, and terminated states

---

**Last Updated**: 2024
**Version**: 1.0
