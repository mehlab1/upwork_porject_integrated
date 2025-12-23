# 🔔 FCM Push Notifications - Complete Setup Guide

## Overview

This document describes the complete FCM push notification system implementation for all user interaction triggers, post achievements, moderation, and system notifications.

## 📋 Table of Contents

1. [Database Setup](#database-setup)
2. [Edge Function Setup](#edge-function-setup)
3. [Notification Triggers](#notification-triggers)
4. [Testing](#testing)
5. [Troubleshooting](#troubleshooting)

---

## 🗄️ Database Setup

### Step 1: Run Migration

Execute the SQL migration file to create all necessary tables, functions, and triggers:

```bash
# In Supabase SQL Editor or via CLI
psql -h your-db-host -U postgres -d postgres -f supabase/migrations/fcm_notifications_setup.sql
```

Or copy and paste the contents of `supabase/migrations/fcm_notifications_setup.sql` into the Supabase SQL Editor.

### Step 2: Enable Required Extensions

```sql
-- Enable pg_net extension for HTTP requests from database
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Or use http extension if pg_net is not available
-- CREATE EXTENSION IF NOT EXISTS http;
```

### Step 3: Set Service Role Key

```sql
-- Set service role key for Edge Function authentication
ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key-here';
```

**⚠️ Important:** Replace `your-service-role-key-here` with your actual Supabase service role key from the Supabase Dashboard → Settings → API.

---

## ⚡ Edge Function Setup

### Step 1: Deploy Edge Function

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Deploy the function
supabase functions deploy send-push-notification
```

### Step 2: Configure Environment Variables

In Supabase Dashboard → Edge Functions → `send-push-notification` → Settings:

1. **FCM_SERVICE_ACCOUNT_JSON** (Optional - for FCM v1 API)
   - Get from Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Paste the entire JSON content

2. **FCM_SERVER_KEY** (Recommended - simpler setup)
   - Get from Firebase Console → Project Settings → Cloud Messaging
   - Copy the "Server key"
   - Paste as `FCM_SERVER_KEY`

3. **SUPABASE_URL** (Auto-set)
   - Automatically set by Supabase

4. **SUPABASE_SERVICE_ROLE_KEY** (Auto-set)
   - Automatically set by Supabase

**Note:** The Edge Function currently uses the legacy FCM API with `FCM_SERVER_KEY` for simplicity. For production, consider implementing FCM v1 API with proper JWT signing.

---

## 🔔 Notification Triggers

### User Interaction Triggers

| Trigger | Table | Condition | Notification Type |
|---------|-------|-----------|------------------|
| New Comment | `comments` | Insert (parent_id IS NULL) | `new_comment` |
| Reply to Comment | `comments` | Insert (parent_id IS NOT NULL) | `reply_to_comment` |
| Post Upvote | `post_votes` | Insert (vote_type = 'upvote') | `post_upvote` |
| Comment Upvote | `comment_votes` | Insert (vote_type = 'upvote') | `comment_upvote` |
| Mention in Comment | `mentions` | Insert | `mention_in_comment` |
| Mention in Post | Manual call | Application code | `mention_in_post` |

### Post Achievement Triggers

| Trigger | Table | Condition | Notification Type |
|---------|-------|-----------|------------------|
| Post Getting Hot | `posts` | `is_trending` changes to `true` | `post_hot` |
| Post Reaching Top | `posts` | `is_monthly_spotlight` changes to `true` | `post_top` |
| Post Trending in Location | Manual call | Scheduled job | `post_trending` |

### Moderation/System Triggers

| Trigger | Table | Condition | Notification Type |
|---------|-------|-----------|------------------|
| Report Status Update (Post) | `post_reports` | `status` changes | `report_under_review`, `report_resolved` |
| Report Status Update (Comment) | `comment_reports` | `status` changes | `report_under_review`, `report_resolved` |
| Account Suspension | `profiles` | `account_status` = 'suspended' | `account_suspended` |
| Account Warning | `profiles` | `warnings_count` increases | `account_warning` |
| Account Deactivation | `profiles` | `is_deactivated` = `true` | `account_suspended` |

---

## 📝 Manual Notification Functions

### Mention in Post

When a user is mentioned in a post, call this function from your application code:

```sql
SELECT public.notify_mention_in_post(
  p_post_id := 'post-uuid-here',
  p_mentioned_user_id := 'user-uuid-here',
  p_mentioner_user_id := 'mentioner-uuid-here'
);
```

### Post Trending in Location

For location-based trending notifications, call from a scheduled job:

```sql
SELECT public.notify_post_trending_location(
  p_post_id := 'post-uuid-here',
  p_user_id := 'user-uuid-here',
  p_location_name := 'Lagos, Nigeria'
);
```

---

## 🧪 Testing

### Test 1: Test FCM Token Storage

```sql
-- Insert a test FCM token
INSERT INTO public.user_fcm_tokens (user_id, fcm_token, platform)
VALUES ('user-uuid-here', 'test-fcm-token-here', 'android')
ON CONFLICT (user_id, platform) DO UPDATE
SET fcm_token = EXCLUDED.fcm_token, updated_at = NOW();
```

### Test 2: Test Notification Function

```sql
-- Send a test notification
SELECT public.send_notification(
  p_user_id := 'user-uuid-here',
  p_notification_type := 'new_comment',
  p_title := 'Test Notification',
  p_body := 'This is a test notification',
  p_data := '{"test": true}'::jsonb
);
```

### Test 3: Test Edge Function Directly

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "user-uuid",
    "notification_id": "test-id",
    "notification_type": "new_comment",
    "title": "Test",
    "body": "Test notification",
    "fcm_tokens": ["fcm-token-here"]
  }'
```

### Test 4: Test Trigger

```sql
-- Create a test comment to trigger notification
INSERT INTO public.comments (post_id, user_id, content)
VALUES ('post-uuid-here', 'commenter-uuid-here', 'Test comment');
```

---

## 🔧 Troubleshooting

### Issue: Notifications not being sent

**Check:**
1. FCM tokens are stored in `user_fcm_tokens` table
2. Edge Function is deployed and environment variables are set
3. `pg_net` extension is enabled
4. Service role key is configured
5. Check Edge Function logs in Supabase Dashboard

### Issue: pg_net not available

**Solution:** Use HTTP extension or call Edge Function from application code instead of database triggers.

### Issue: FCM authentication errors

**Check:**
1. `FCM_SERVER_KEY` is correctly set in Edge Function environment variables
2. Server key is from the correct Firebase project
3. Firebase project has FCM enabled

### Issue: Notifications sent but not received

**Check:**
1. App has notification permissions granted
2. FCM token is valid and not expired
3. Device is connected to internet
4. Check device notification settings

---

## 📊 Notification Types Reference

All notification types must match the `notification_type` enum in your database:

- `mention_in_comment`
- `mention_in_post`
- `post_upvote`
- `comment_upvote`
- `new_comment`
- `reply_to_comment`
- `post_hot`
- `post_trending`
- `post_top`
- `report_under_review`
- `report_resolved`
- `account_suspended`
- `account_warning`

---

## 🔐 Security Notes

1. **Service Role Key**: Never expose the service role key in client-side code
2. **FCM Server Key**: Keep the FCM server key secure in environment variables
3. **RLS Policies**: Ensure proper RLS policies on `user_fcm_tokens` table
4. **Rate Limiting**: Consider implementing rate limiting for notifications

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Supabase Database Functions](https://supabase.com/docs/guides/database/functions)

---

## ✅ Checklist

- [ ] Database migration executed
- [ ] `pg_net` extension enabled
- [ ] Service role key configured
- [ ] Edge Function deployed
- [ ] Environment variables set (FCM_SERVER_KEY)
- [ ] Test notification sent successfully
- [ ] All triggers working
- [ ] FCM tokens being stored correctly
- [ ] Notifications received on test device

---

**Last Updated:** 2024
**Version:** 1.0

