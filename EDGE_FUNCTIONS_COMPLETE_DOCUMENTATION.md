# Edge Functions Complete Documentation

**Total Functions**: 106  
**Last Updated**: January 25, 2026  
**Project**: K2MVP Supabase Backend  
**Base URL**: `https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/`

> **Note**: Replace `<YOUR_PROJECT_REF>` with your actual Supabase project reference ID.

---

## Table of Contents
- [Role-Based Categories](#role-based-categories)
- [Admin Functions (28)](#admin-functions)
- [Staff/Moderator Functions (17)](#staffmoderator-functions)
- [Authenticated User Functions (46)](#authenticated-user-functions)
- [Public Functions (17)](#public-functions)
- [System/Internal Functions (6)](#systeminternal-functions)
- [Function Reference (A-Z)](#function-reference-a-z)
- [Common Patterns & Notes](#common-patterns--notes)

---

## Role-Based Categories

### Role Hierarchy
1. **admin** - Full system access
2. **moderator** - Content moderation, user management
3. **junior_moderator** - Limited moderation
4. **reviewer** - Content review only
5. **user** - Standard user access

### Permission Summary
- **Admin-Only (28 functions)**: Complete control over users, content, and system configuration
- **Staff/Moderator (17 functions)**: Content moderation and user management tools
- **Authenticated User (46 functions)**: Standard user operations (post, comment, vote, profile)
- **Public (17 functions)**: Browse content, authentication, validation
- **System/Internal (6 functions)**: Scheduled tasks, auth hooks

---

## Admin Functions

Functions requiring **admin** role only:

### 1. **assign-early-adopter-badges**
- **URL**: `POST /assign-early-adopter-badges`
- **Purpose**: Assigns early adopter badges to eligible users
- **Request**: No body parameters required
- **Response**: `{ success: boolean, count: number, message: string }`
- **RPC Calls**: `assign_early_adopter_badges()`
- **Notes**: ADO-989

### 2. **assign-role**
- **URL**: `POST /assign-role`
- **Purpose**: Assigns roles to users (admin, moderator, junior_moderator, reviewer, user)
- **Request**: 
  ```json
  {
    "target_user_id": "uuid",
    "new_role": "admin | moderator | junior_moderator | reviewer | user"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `assign_role(p_admin_id, p_target_user_id, p_new_role)`
- **Notes**: ADO-1163, logs role changes to audit table

### 3. **ban-user**
- **URL**: `POST /ban-user`
- **Purpose**: Ban, suspend, or temporarily ban users
- **Request**: 
  ```json
  {
    "user_id": "uuid",
    "action_type": "suspend | ban | temporary_ban",
    "reason": "harassment | spam | hate_speech | violence | inappropriate_content | misinformation | copyright_violation | scam | other",
    "custom_reason": "string (optional)",
    "ban_duration_hours": "number (for temporary_ban)"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `ban_user(p_admin_id, p_user_id, p_action_type, p_reason, p_custom_reason, p_ban_duration_hours)`
- **Notes**: ADO-1160, uses standardized error handling

### 4. **delete-flagged-content**
- **URL**: `POST /delete-flagged-content`
- **Purpose**: Delete flagged content (posts or comments) as part of admin moderation
- **Request**: 
  ```json
  {
    "content_id": "uuid",
    "content_type": "post | comment",
    "delete_type": "soft | hard",
    "reason": "harassment | spam | hate_speech | violence | inappropriate_content | misinformation | copyright_violation | scam | other",
    "custom_reason": "string (optional)"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `delete_flagged_content(p_admin_id, p_content_id, p_content_type, p_delete_type, p_reason, p_custom_reason)`
- **Notes**: ADO-1160, soft delete can be restored

### 5. **get-analytics-data**
- **URL**: `GET /get-analytics-data`
- **Purpose**: Get platform analytics and statistics
- **Request**: Query params: `?metric=users|posts|comments|engagement&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`
- **Response**: 
  ```json
  {
    "metric": "string",
    "data": [...],
    "summary": { ... }
  }
  ```
- **RPC Calls**: Various analytics RPCs

### 6. **get-announcements**
- **URL**: `GET /get-announcements`
- **Purpose**: Get all announcements (including archived)
- **Response**: Array of announcement objects
- **RPC Calls**: Queries `announcements` table

### 7. **get-blocked-content-stats**
- **URL**: `GET /get-blocked-content-stats`
- **Purpose**: Get blocked content statistics
- **Request**: Query params: `?time_period=day|week|month&content_type=post|comment`
- **Response**: 
  ```json
  {
    "total_blocked": number,
    "by_reason": { ... },
    "timeline": [...]
  }
  ```
- **RPC Calls**: `get_blocked_content_stats(p_time_period, p_content_type)`
- **Notes**: ADO-1160

### 8. **get-early-adopters**
- **URL**: `GET /get-early-adopters`
- **Purpose**: Get list of early adopters
- **Response**: Array of user profiles with early_adopter badge
- **RPC Calls**: Queries profiles with early_adopter badge

### 9. **get-feedback-history**
- **URL**: `GET /get-feedback-history`
- **Purpose**: Get user feedback history
- **Request**: Query params: `?user_id=uuid&limit=50&offset=0`
- **Response**: Array of feedback submissions
- **RPC Calls**: Queries feedback table

### 10. **get-rate-limit-configs**
- **URL**: `GET /get-rate-limit-configs`
- **Purpose**: Get rate limit configurations
- **Response**: Array of rate limit config objects
- **RPC Calls**: Queries rate_limit_configs table

### 11. **get-role-stats**
- **URL**: `GET /get-role-stats`
- **Purpose**: Get role distribution statistics
- **Response**: 
  ```json
  {
    "admin": number,
    "moderator": number,
    "junior_moderator": number,
    "reviewer": number,
    "user": number
  }
  ```
- **RPC Calls**: Aggregates from profiles table

### 12. **get-violation-statistics**
- **URL**: `GET /get-violation-statistics`
- **Purpose**: Get content violation statistics
- **Request**: Query params: `?time_period=day|week|month`
- **Response**: 
  ```json
  {
    "total_violations": number,
    "by_type": { ... },
    "trends": [...]
  }
  ```
- **RPC Calls**: Aggregates from moderation tables

### 13. **get-wod-stats**
- **URL**: `GET /get-wod-stats`
- **Purpose**: Get Word of the Day statistics
- **Response**: 
  ```json
  {
    "total_opted_in": number,
    "participation_rate": number,
    "recent_words": [...]
  }
  ```
- **RPC Calls**: Aggregates WOD participation

### 14. **pin-post**
- **URL**: `POST /pin-post`
- **Purpose**: Pin a post to the top of feed
- **Request**: 
  ```json
  {
    "post_id": "uuid",
    "pin_duration_hours": "number (optional, default 24)"
  }
  ```
- **Response**: `{ success: boolean, expires_at: timestamp }`
- **RPC Calls**: `pin_post(p_post_id, p_pinned_by, p_pin_duration_hours)`
- **Notes**: ADO-1355, max 3 pinned posts at a time

### 15. **push-announcement**
- **URL**: `POST /push-announcement`
- **Purpose**: Push announcement notification to users
- **Request**: 
  ```json
  {
    "announcement_id": "uuid",
    "target_users": ["uuid"] // optional, all users if not specified
  }
  ```
- **Response**: `{ success: boolean, sent_count: number }`

### 16. **register-admin**
- **URL**: `POST /register-admin`
- **Purpose**: Register admin account with admin code
- **Request**: 
  ```json
  {
    "email": "email@example.com",
    "password": "string",
    "username": "string",
    "admin_code": "string" // ADMIN_REGISTRATION_CODE from env
  }
  ```
- **Response**: 
  ```json
  {
    "user": { ... },
    "session": { access_token, refresh_token }
  }
  ```
- **Notes**: ADO-1163, auto-confirms email, bypasses OTP

### 17. **set-manual-boost**
- **URL**: `POST /set-manual-boost`
- **Purpose**: Manually boost a post's algorithm score
- **Request**: 
  ```json
  {
    "post_id": "uuid",
    "boost_multiplier": "number (1.0-10.0)"
  }
  ```
- **Response**: `{ success: boolean, new_score: number }`
- **RPC Calls**: `set_manual_boost(p_post_id, p_boost_multiplier, p_admin_id)`

### 18. **suspend-account**
- **URL**: `POST /suspend-account`
- **Purpose**: Suspend user account
- **Request**: 
  ```json
  {
    "user_id": "uuid",
    "reason": "string",
    "duration_days": "number (optional)"
  }
  ```
- **Response**: `{ success: boolean }`
- **RPC Calls**: Updates profile suspension status

### 19. **unpin-post**
- **URL**: `POST /unpin-post`
- **Purpose**: Unpin a post
- **Request**: `{ "post_id": "uuid" }`
- **Response**: `{ success: boolean }`
- **RPC Calls**: `unpin_post(p_post_id, p_unpinned_by)`
- **Notes**: ADO-1355

### 20. **unsuspend-account**
- **URL**: `POST /unsuspend-account`
- **Purpose**: Unsuspend user account
- **Request**: `{ "user_id": "uuid" }`
- **Response**: `{ success: boolean }`
- **RPC Calls**: Updates profile suspension status

### 21. **update-algorithm-config**
- **URL**: `POST /update-algorithm-config`
- **Purpose**: Update feed algorithm configuration
- **Request**: 
  ```json
  {
    "config_key": "string",
    "config_value": "any"
  }
  ```
- **Response**: `{ success: boolean }`
- **RPC Calls**: Updates algorithm_config table

### 22. **update-rate-limit-config**
- **URL**: `POST /update-rate-limit-config`
- **Purpose**: Update rate limit configuration
- **Request**: 
  ```json
  {
    "action": "string",
    "hourly_limit": "number",
    "daily_limit": "number"
  }
  ```
- **Response**: `{ success: boolean }`
- **RPC Calls**: `update_rate_limit_config(p_action, p_hourly_limit, p_daily_limit)`

### 23. **create-announcement**
- **URL**: `POST /create-announcement`
- **Purpose**: Create system-wide announcement
- **Request**: 
  ```json
  {
    "title": "string",
    "content": "string",
    "type": "info | warning | critical | maintenance",
    "expires_at": "timestamp (optional)"
  }
  ```
- **Response**: `{ success: boolean, announcement_id: uuid }`
- **RPC Calls**: `create_announcement(p_admin_id, p_title, p_content, p_type, p_expires_at)`
- **Notes**: Types: info (blue), warning (yellow), critical (red), maintenance (purple)

### 24. **check-user-exists**
- **URL**: `POST /check-user-exists`
- **Purpose**: Check if user exists by email or user_id (uses service role)
- **Request**: `{ "email": "string" }` or `{ "user_id": "uuid" }`
- **Response**: 
  ```json
  {
    "exists": boolean,
    "user_id": "uuid (if exists)",
    "email": "string (if exists)"
  }
  ```
- **Notes**: Used for registration validation

### 25. **send-push-notification**
- **URL**: `POST /send-push-notification`
- **Purpose**: Send push notification via FCM
- **Request**: 
  ```json
  {
    "user_ids": ["uuid"],
    "title": "string",
    "body": "string",
    "data": { ... }
  }
  ```
- **Response**: `{ success: boolean, sent_count: number }`
- **Notes**: Uses Firebase Cloud Messaging

### 26. **get-suspended-users**
- **URL**: `GET /get-suspended-users`
- **Purpose**: Get list of suspended users
- **Request**: Query params: `?limit=50&offset=0`
- **Response**: Array of suspended user profiles
- **RPC Calls**: Queries profiles with suspension status

### 27. **get-deleted-posts**
- **URL**: `GET /get-deleted-posts`
- **Purpose**: Get soft-deleted posts (admin moderation)
- **Request**: Query params: `?limit=50&offset=0`
- **Response**: Array of deleted posts
- **RPC Calls**: `get_deleted_posts(p_limit, p_offset)`

### 28. **restore-post**
- **URL**: `POST /restore-post`
- **Purpose**: Restore soft-deleted post
- **Request**: `{ "post_id": "uuid" }`
- **Response**: `{ success: boolean, post: { ... } }`
- **RPC Calls**: `restore_post(p_post_id, p_admin_id)`

---

## Staff/Moderator Functions

Functions requiring **admin** or **moderator** role:

### 29. **register-staff**
- **URL**: `POST /register-staff`
- **Purpose**: Register moderator/reviewer accounts
- **Request**: 
  ```json
  {
    "email": "email@example.com",
    "password": "string",
    "username": "string",
    "role": "moderator | junior_moderator | reviewer"
  }
  ```
- **Response**: 
  ```json
  {
    "user": { ... },
    "message": "string"
  }
  ```
- **Notes**: ADO-1163. Admin can create all roles. Moderator can only create junior_moderator/reviewer.

### 30. **get-auto-flagged-content**
- **URL**: `GET /get-auto-flagged-content`
- **Purpose**: Get automatically flagged content
- **Request**: Query params: `?content_type=post|comment&status=pending|reviewed&limit=50&offset=0`
- **Response**: Array of flagged content objects
- **RPC Calls**: `get_auto_flagged_content(p_content_type, p_status, p_limit, p_offset)`

### 31. **get-flagged-content**
- **URL**: `GET /get-flagged-content`
- **Purpose**: Get flagged content for moderation
- **Request**: Query params: `?content_type=post|comment&status=pending|reviewed&limit=50&offset=0`
- **Response**: 
  ```json
  [
    {
      "content_id": "uuid",
      "content_type": "post | comment",
      "flag_count": number,
      "reasons": [...],
      "content": { ... }
    }
  ]
  ```
- **RPC Calls**: `get_flagged_content(p_content_type, p_status, p_limit, p_offset)`
- **Notes**: ADO-1160

### 32. **mark-content-safe**
- **URL**: `POST /mark-content-safe`
- **Purpose**: Mark flagged content as safe (dismiss flags)
- **Request**: 
  ```json
  {
    "content_id": "uuid",
    "content_type": "post | comment"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `mark_content_safe(p_moderator_id, p_content_id, p_content_type)`
- **Notes**: ADO-1160

### 33. **get-moderation-reports**
- **URL**: `GET /get-moderation-reports`
- **Purpose**: Get moderation reports
- **Request**: Query params: `?report_type=post|comment&status=pending|reviewed&limit=50`
- **Response**: Array of moderation reports
- **RPC Calls**: `get_moderation_reports(p_report_type, p_status, p_limit, p_offset)`

### 34. **get-blocking-stats**
- **URL**: `GET /get-blocking-stats`
- **Purpose**: Get blocking statistics
- **Response**: 
  ```json
  {
    "total_blocks": number,
    "most_blocked_users": [...],
    "block_trends": [...]
  }
  ```
- **RPC Calls**: `get_blocking_stats()`

### 35. **search-users** (Enhanced Access)
- **URL**: `GET /search-users`
- **Purpose**: Search for users by username (moderators get additional info)
- **Request**: Query param: `?query=<search_term>&limit=20`
- **Response**: Array of user profiles (with moderation info for staff)
- **Notes**: Regular users can also use this but see limited info

---

## Authenticated User Functions

Functions requiring authentication (any logged-in user):

### 36. **create-post**
- **URL**: `POST /create-post`
- **Purpose**: Create a new post with content moderation
- **Request**: 
  ```json
  {
    "content": "string (max 1000 chars)",
    "category_id": "uuid",
    "location_id": "uuid (optional)",
    "is_monthly_spotlight": "boolean (optional)"
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "post_id": "uuid",
    "post": { ... }
  }
  ```
- **RPC Calls**: 
  - `check_rate_limit_enhanced(user_id, 'create_post')`
  - `check_duplicate_content(user_id, content)`
  - `validate_category_id(category_id)`
  - `validate_location_id(location_id)`
  - `can_mark_as_monthly_spotlight(user_id)`
  - `create_post(...)`
- **Rate Limits**: 5 posts/hour, 20 posts/day
- **Notes**: ADO-1161. Blocks banned/suspended users. Content moderation via trigger-word-scanner. Duplicate detection (24h window).

### 37. **create-comment**
- **URL**: `POST /create-comment`
- **Purpose**: Create comment or reply with content moderation
- **Request**: 
  ```json
  {
    "post_id": "uuid",
    "content": "string (max 500 chars)",
    "parent_comment_id": "uuid (optional, for replies)"
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "comment_id": "uuid",
    "comment": { ... }
  }
  ```
- **RPC Calls**: 
  - `check_rate_limit_enhanced(user_id, 'create_comment')`
  - `create_comment(user_id, post_id, content, parent_comment_id)`
- **Rate Limits**: 5 comments/hour, 50 comments/day
- **Notes**: ADO-1002, 1161, 1173, 1226, 1227. Blocks banned/suspended users. Content moderation via trigger-word-scanner.

### 38. **vote-post**
- **URL**: `POST /vote-post`
- **Purpose**: Vote on post (upvote/downvote)
- **Request**: 
  ```json
  {
    "post_id": "uuid",
    "vote_type": "upvote | downvote | remove"
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "new_vote_count": number,
    "user_vote": "upvote | downvote | null"
  }
  ```
- **RPC Calls**: `vote_on_post(user_id, post_id, vote_type)`
- **Notes**: ADO-908. Toggle behavior - voting same type removes vote. Can switch between upvote/downvote. Score never negative in UI.

### 39. **vote-comment**
- **URL**: `POST /vote-comment`
- **Purpose**: Vote on comment (upvote/downvote)
- **Request**: 
  ```json
  {
    "comment_id": "uuid",
    "vote_type": "upvote | downvote | remove"
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "new_vote_count": number,
    "user_vote": "upvote | downvote | null"
  }
  ```
- **RPC Calls**: `vote_on_comment(user_id, comment_id, vote_type)`
- **Notes**: Toggle behavior, can switch votes

### 40. **delete-post**
- **URL**: `POST /delete-post`
- **Purpose**: Delete post (soft delete)
- **Request**: `{ "post_id": "uuid" }`
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `delete_post(user_id, post_id)`
- **Notes**: Only post author or admin can delete. Soft delete - can be restored by admins.

### 41. **delete-comment**
- **URL**: `POST /delete-comment`
- **Purpose**: Delete comment (soft delete)
- **Request**: `{ "comment_id": "uuid" }`
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `delete_comment(user_id, comment_id)`
- **Notes**: ADO-1002. Only comment author or admin can delete.

### 42. **report-post**
- **URL**: `POST /report-post`
- **Purpose**: Report a post for violating community guidelines
- **Request**: 
  ```json
  {
    "post_id": "uuid",
    "reason": "spam | harassment | hate_speech | violence | inappropriate_content | misinformation | copyright_violation | scam | other",
    "custom_reason": "string (optional, required if reason is 'other')"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `report_post(user_id, post_id, reason, custom_reason)`
- **Notes**: ADO-909. One report per user per post. Auto-flags content after threshold (default 5 reports).

### 43. **report-comment**
- **URL**: `POST /report-comment`
- **Purpose**: Report a comment for violating community guidelines
- **Request**: 
  ```json
  {
    "comment_id": "uuid",
    "reason": "spam | harassment | hate_speech | violence | inappropriate_content | misinformation | copyright_violation | scam | other",
    "custom_reason": "string (optional)"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `report_comment(user_id, comment_id, reason, custom_reason)`
- **Notes**: One report per user per comment. Auto-flags after threshold.

### 44. **block-user**
- **URL**: `POST /block-user`
- **Purpose**: Block another user
- **Request**: `{ "blocked_user_id": "uuid" }`
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `block_user(blocker_id, blocked_user_id)`
- **Notes**: ADO-1358. Bidirectional blocking - both users can't see each other's content.

### 45. **unblock-user**
- **URL**: `POST /unblock-user`
- **Purpose**: Unblock a user
- **Request**: `{ "blocked_user_id": "uuid" }`
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `unblock_user(blocker_id, blocked_user_id)`
- **Notes**: ADO-1358

### 46. **get-blocked-users**
- **URL**: `GET /get-blocked-users`
- **Purpose**: Get list of users you've blocked
- **Request**: Query params: `?limit=50&offset=0`
- **Response**: Array of blocked user profiles
- **RPC Calls**: `get_blocked_users(user_id, limit, offset)`
- **Notes**: ADO-1358

### 47. **check-block-status**
- **URL**: `GET /check-block-status`
- **Purpose**: Check if there's a block between two users
- **Request**: Query param: `?other_user_id=uuid`
- **Response**: 
  ```json
  {
    "is_blocked": boolean,
    "blocked_by_me": boolean,
    "blocked_by_them": boolean
  }
  ```
- **RPC Calls**: `check_block_status(user_id, other_user_id)`
- **Notes**: ADO-1358. Checks both directions.

### 48. **update-profile**
- **URL**: `POST /update-profile`
- **Purpose**: Update user profile
- **Request**: 
  ```json
  {
    "bio": "string (optional, max 500 chars)",
    "location_id": "uuid (optional)",
    "website": "string (optional)",
    "instagram_handle": "string (optional)",
    "twitter_handle": "string (optional)"
  }
  ```
- **Response**: `{ success: boolean, profile: { ... } }`
- **RPC Calls**: Updates profiles table with validation
- **Notes**: Profile picture updated via separate endpoint

### 49. **update-username**
- **URL**: `POST /update-username`
- **Purpose**: Update username
- **Request**: `{ "username": "string (3-20 chars)" }`
- **Response**: 
  ```json
  {
    "success": boolean,
    "message": string,
    "cooldown_ends_at": "timestamp (if cooldown active)"
  }
  ```
- **RPC Calls**: `update_username(user_id, username)`
- **Notes**: 30-day cooldown between changes. Checks availability and format.

### 50. **update-birthday**
- **URL**: `POST /update-birthday`
- **Purpose**: Update user birthday
- **Request**: `{ "birthday": "YYYY-MM-DD" }`
- **Response**: 
  ```json
  {
    "success": boolean,
    "message": string,
    "cooldown_ends_at": "timestamp (if cooldown active)"
  }
  ```
- **RPC Calls**: `update_user_birthday(user_id, birthday)`
- **Notes**: 30-day cooldown between changes. Validates age (13+).

### 51. **upload-profile-picture**
- **URL**: `POST /upload-profile-picture`
- **Purpose**: Upload profile picture to storage
- **Request**: Multipart form data with image file
- **Response**: 
  ```json
  {
    "success": boolean,
    "profile_picture_url": "string"
  }
  ```
- **Notes**: Max 5MB, formats: jpg, png, webp. Uploads to Supabase Storage bucket `profile-pictures`.

### 52. **deactivate-account**
- **URL**: `POST /deactivate-account`
- **Purpose**: Deactivate user account
- **Request**: 
  ```json
  {
    "confirm": true,
    "reason_type": "privacy_concerns | not_useful | too_many_notifications | found_alternative | too_much_time | harassment_issues | technical_problems | other",
    "custom_reason": "string (optional)"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `deactivate_account(user_id, reason_type, custom_reason)`
- **Notes**: ADO-1206. Requires explicit confirmation. Hides profile and content. Can be reactivated within 30 days.

### 53. **reactivate-account**
- **URL**: `POST /reactivate-account`
- **Purpose**: Reactivate deactivated account
- **Request**: No body parameters
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `reactivate_account(user_id)`
- **Notes**: ADO-1206. Can reactivate within 30 days of deactivation.

### 54. **check-account-status**
- **URL**: `GET /check-account-status`
- **Purpose**: Check if account is deactivated
- **Request**: No body parameters
- **Response**: 
  ```json
  {
    "is_deactivated": boolean,
    "deactivated_at": "timestamp (if deactivated)",
    "can_reactivate": boolean
  }
  ```
- **RPC Calls**: `check_account_status(user_id)`
- **Notes**: ADO-1206

### 55. **check-deactivation-status**
- **URL**: `GET /check-deactivation-status`
- **Purpose**: Check deactivation status and sign out if deactivated
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "is_deactivated": boolean,
    "signed_out": boolean
  }
  ```
- **Notes**: Auto-signs out deactivated users

### 56. **logout**
- **URL**: `POST /logout`
- **Purpose**: Sign out user and clear session
- **Request**: No body parameters
- **Response**: `{ success: boolean, message: string }`
- **Notes**: Clears session, revokes refresh token

### 57. **get-liked-posts** / **get-upvoted-posts**
- **URL**: `GET /get-liked-posts` or `GET /get-upvoted-posts`
- **Purpose**: Get posts user has upvoted
- **Request**: Query params: `?limit=20&offset=0`
- **Response**: Array of post objects
- **RPC Calls**: `get_user_liked_posts(user_id, limit, offset)`

### 58. **get-user-posts**
- **URL**: `GET /get-user-posts`
- **Purpose**: Get posts by user
- **Request**: Query params: `?user_id=uuid&limit=20&offset=0`
- **Response**: Array of post objects
- **RPC Calls**: `get_user_posts(user_id, target_user_id, limit, offset)`
- **Notes**: Respects blocks - can't see blocked users' posts

### 59. **get-mentions**
- **URL**: `GET /get-mentions`
- **Purpose**: Get mentions of authenticated user
- **Request**: Query params: `?limit=20&offset=0&unread_only=false`
- **Response**: 
  ```json
  [
    {
      "mention_id": "uuid",
      "post_id": "uuid",
      "comment_id": "uuid (optional)",
      "mentioned_by": { ... },
      "is_read": boolean,
      "created_at": "timestamp"
    }
  ]
  ```
- **RPC Calls**: `get_user_mentions(user_id, limit, offset, unread_only)`

### 60. **get-unread-mention-count**
- **URL**: `GET /get-unread-mention-count`
- **Purpose**: Get count of unread mentions
- **Request**: No parameters
- **Response**: `{ count: number }`
- **RPC Calls**: `get_unread_mention_count(user_id)`

### 61. **mark-mention-read**
- **URL**: `POST /mark-mention-read`
- **Purpose**: Mark mention as read
- **Request**: `{ "mention_id": "uuid" }`
- **Response**: `{ success: boolean }`
- **RPC Calls**: `mark_mention_read(user_id, mention_id)`

### 62. **update-notification-preferences**
- **URL**: `POST /update-notification-preferences`
- **Purpose**: Update notification preferences
- **Request**: 
  ```json
  {
    "email_notifications": boolean,
    "push_notifications": boolean,
    "mention_notifications": boolean,
    "reply_notifications": boolean,
    "vote_notifications": boolean,
    "announcement_notifications": boolean
  }
  ```
- **Response**: `{ success: boolean, preferences: { ... } }`
- **RPC Calls**: Updates profiles or notification_preferences table

### 63. **register-device**
- **URL**: `POST /register-device`
- **Purpose**: Register device for push notifications
- **Request**: 
  ```json
  {
    "device_token": "string (FCM token)",
    "device_type": "ios | android | web",
    "device_name": "string (optional)"
  }
  ```
- **Response**: `{ success: boolean, device_id: uuid }`
- **RPC Calls**: `register_device(user_id, device_token, device_type, device_name)`

### 64. **submit-feedback**
- **URL**: `POST /submit-feedback`
- **Purpose**: Submit user feedback
- **Request**: 
  ```json
  {
    "feedback_type": "bug | feature_request | improvement | other",
    "message": "string",
    "category": "string (optional)",
    "rating": "number 1-5 (optional)"
  }
  ```
- **Response**: `{ success: boolean, feedback_id: uuid }`
- **RPC Calls**: Inserts into feedback table

### 65. **check-permission**
- **URL**: `GET /check-permission`
- **Purpose**: Check if user has a specific permission
- **Request**: Query param: `?permission=permission_name`
- **Response**: 
  ```json
  {
    "has_permission": boolean,
    "role": "string"
  }
  ```
- **RPC Calls**: `check_permission(user_id, permission_name)`
- **Notes**: ADO-1163. RBAC system.

### 66. **get-user-role**
- **URL**: `GET /get-user-role`
- **Purpose**: Get user's role
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "role": "admin | moderator | junior_moderator | reviewer | user",
    "permissions": [...]
  }
  ```
- **Notes**: ADO-1163

### 67. **get-username-status**
- **URL**: `GET /get-username-status`
- **Purpose**: Check username change cooldown status
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "can_change": boolean,
    "last_changed": "timestamp (if ever changed)",
    "cooldown_ends_at": "timestamp (if in cooldown)"
  }
  ```
- **RPC Calls**: `get_username_status(user_id)`

### 68. **check-wod-status**
- **URL**: `GET /check-wod-status`
- **Purpose**: Check if user is opted into Word of the Day
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "is_opted_in": boolean,
    "opted_in_at": "timestamp (if opted in)"
  }
  ```
- **RPC Calls**: `check_wod_status(user_id)`
- **Notes**: ADO-1355

### 69. **wod-opt-in**
- **URL**: `POST /wod-opt-in`
- **Purpose**: Opt into Word of the Day
- **Request**: No body parameters
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `wod_opt_in(user_id)`
- **Notes**: ADO-1355

### 70. **wod-opt-out**
- **URL**: `POST /wod-opt-out`
- **Purpose**: Opt out of Word of the Day
- **Request**: No body parameters
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `wod_opt_out(user_id)`
- **Notes**: ADO-1355

### 71. **toggle-monthly-spotlight**
- **URL**: `POST /toggle-monthly-spotlight`
- **Purpose**: Toggle monthly spotlight status for own post
- **Request**: `{ "post_id": "uuid" }`
- **Response**: 
  ```json
  {
    "success": boolean,
    "is_monthly_spotlight": boolean
  }
  ```
- **RPC Calls**: `toggle_monthly_spotlight(user_id, post_id)`
- **Notes**: Only post author can toggle. Limited to eligible users.

### 72. **get-monthly-spotlight-status**
- **URL**: `GET /get-monthly-spotlight-status`
- **Purpose**: Check if user can mark posts as monthly spotlight
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "can_use": boolean,
    "remaining_this_month": number
  }
  ```
- **RPC Calls**: `can_mark_as_monthly_spotlight(user_id)`

### 73. **batch-operations**
- **URL**: `POST /batch-operations`
- **Purpose**: Batch fetch posts, comments, profiles, and check votes
- **Request**: 
  ```json
  {
    "operation": "fetch_posts | fetch_comments | fetch_profiles | check_post_votes | check_comment_votes",
    "ids": ["uuid", "uuid", ...] // max 100
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "data": [...]
  }
  ```
- **RPC Calls**: `batch_fetch_posts`, `batch_fetch_comments`, `batch_fetch_profiles`, `batch_check_post_votes`, `batch_check_comment_votes`
- **Notes**: Max 100 items per batch. Some operations require auth for user-specific data.

### 74. **generate-invitation-link**
- **URL**: `POST /generate-invitation-link`
- **Purpose**: Generate invitation link for user
- **Request**: 
  ```json
  {
    "for_user_id": "uuid (optional, admin only)"
  }
  ```
- **Response**: 
  ```json
  {
    "invitation_link": "string",
    "invitation_token": "string"
  }
  ```
- **RPC Calls**: `generate_invitation_token(user_id)`
- **Notes**: Users can generate their own link. Admins can generate for any user. Tokens don't expire by default.

### 75. **search-users**
- **URL**: `GET /search-users`
- **Purpose**: Search for users by username
- **Request**: Query param: `?query=<search_term>&limit=20`
- **Response**: Array of user profiles
- **RPC Calls**: `search_users(query, limit, user_id)`
- **Notes**: Respects blocks - can't see blocked users

### 76. **get-profile**
- **URL**: `GET /get-profile`
- **Purpose**: Get user profile with stats (can view own or others')
- **Request**: Query params: `?username=string` or `?user_id=uuid`
- **Response**: 
  ```json
  {
    "user_id": "uuid",
    "username": "string",
    "bio": "string",
    "profile_picture_url": "string",
    "location": { ... },
    "stats": {
      "post_count": number,
      "comment_count": number,
      "vote_count": number
    },
    "badges": [...],
    "is_blocked": boolean,
    "created_at": "timestamp"
  }
  ```
- **RPC Calls**: `get_profile(username, user_id, viewer_id)`
- **Notes**: ADO-966. Returns null if blocked.

### 77. **get-user-badges**
- **URL**: `GET /get-user-badges`
- **Purpose**: Get user's badges
- **Request**: Query param: `?user_id=uuid`
- **Response**: Array of badge objects
- **RPC Calls**: Queries user_badges table

### 78. **get-comments**
- **URL**: `GET /get-comments`
- **Purpose**: Get comments for a post (auth optional for user votes)
- **Request**: Query params: `?post_id=uuid&sort=top|latest&limit=50&offset=0`
- **Response**: 
  ```json
  [
    {
      "comment_id": "uuid",
      "content": "string",
      "author": { ... },
      "vote_count": number,
      "user_vote": "upvote | downvote | null",
      "reply_count": number,
      "created_at": "timestamp"
    }
  ]
  ```
- **RPC Calls**: `get_post_comments(post_id, user_id, sort, limit, offset)`
- **Notes**: Sort options: top (by vote_count), latest (by created_at)

### 79. **get-role-permissions**
- **URL**: `GET /get-role-permissions`
- **Purpose**: Get permissions for a role
- **Request**: Query param: `?role=admin|moderator|junior_moderator|reviewer|user`
- **Response**: 
  ```json
  {
    "role": "string",
    "permissions": [...]
  }
  ```
- **RPC Calls**: `get_role_permissions(role)`
- **Notes**: ADO-1163. Public endpoint for transparency.

### 80. **get-post**
- **URL**: `GET /get-post`
- **Purpose**: Get single post by ID (auth optional for user votes)
- **Request**: Query param: `?post_id=uuid`
- **Response**: 
  ```json
  {
    "post_id": "uuid",
    "content": "string",
    "author": { ... },
    "category": { ... },
    "location": { ... },
    "vote_count": number,
    "comment_count": number,
    "user_vote": "upvote | downvote | null",
    "is_pinned": boolean,
    "is_monthly_spotlight": boolean,
    "created_at": "timestamp"
  }
  ```
- **RPC Calls**: `get_post_by_id(post_id, user_id)`

### 81. **get-feed** (Enhanced with Auth)
- **URL**: `GET /get-feed`
- **Purpose**: Get personalized feed when authenticated
- **Request**: Query params: `?sort=hot|top|latest&time_filter=all|today|week|month&limit=20&offset=0`
- **Response**: 
  ```json
  {
    "posts": [...],
    "total_count": number,
    "has_more": boolean
  }
  ```
- **RPC Calls**: `get_cached_feed`, `get_unified_feed`, `get_total_posts_count`
- **Notes**: Authenticated users get personalized feed excluding blocked users' posts

---

## Public Functions

Functions that don't require authentication:

### 82. **send-otp**
- **URL**: `POST /send-otp`
- **Purpose**: Send OTP for phone/email verification
- **Request**: 
  ```json
  {
    "phone_number": "string (+234...)" OR "email": "string",
    "purpose": "registration | login"
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "message": "OTP sent",
    "otp_code": "string (dev only)"
  }
  ```
- **RPC Calls**: `check_otp_rate_limit(identifier)`, `generate_otp_code(identifier, purpose)`
- **Rate Limits**: 3 requests/15min per identifier
- **Notes**: ADO-893. OTP expires in 10min. Sent via SendGrid/SMS provider.

### 83. **verify-otp**
- **URL**: `POST /verify-otp`
- **Purpose**: Verify OTP code
- **Request**: 
  ```json
  {
    "phone_number": "string" OR "email": "string",
    "otp_code": "string (6 digits)",
    "username": "string (for registration)",
    "referral_token": "string (optional)"
  }
  ```
- **Response**: 
  ```json
  {
    "success": boolean,
    "user": { ... },
    "session": {
      "access_token": "string",
      "refresh_token": "string"
    },
    "is_new_user": boolean
  }
  ```
- **RPC Calls**: `verify_otp_code(identifier, otp_code)`
- **Notes**: ADO-893. Creates profile if doesn't exist. Generates auth tokens.

### 84. **resend-otp**
- **URL**: `POST /resend-otp`
- **Purpose**: Resend OTP code
- **Request**: 
  ```json
  {
    "phone_number": "string" OR "email": "string"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **Notes**: Same rate limits as send-otp

### 85. **forgot-password**
- **URL**: `POST /forgot-password`
- **Purpose**: Request password reset OTP
- **Request**: `{ "email": "string" }`
- **Response**: 
  ```json
  {
    "success": boolean,
    "message": "Password reset OTP sent",
    "otp_code": "string (dev only)"
  }
  ```
- **RPC Calls**: `generate_password_reset_otp(email)`
- **Rate Limits**: 3 requests/hour
- **Notes**: ADO-963. OTP expires in 15min. Sent via SendGrid.

### 86. **reset-password**
- **URL**: `POST /reset-password`
- **Purpose**: Reset password using OTP
- **Request**: 
  ```json
  {
    "email": "string",
    "otp_code": "string",
    "new_password": "string"
  }
  ```
- **Response**: `{ success: boolean, message: string }`
- **RPC Calls**: `verify_password_reset_otp(email, otp_code)`, updates auth.users
- **Notes**: ADO-963. OTP expires in 15min.

### 87. **check-username**
- **URL**: `POST /check-username`
- **Purpose**: Check username availability and format validation
- **Request**: 
  - Single: `{ "username": "string" }`
  - Batch: `{ "usernames": ["string", "string"] }` (max 10)
- **Response**: 
  ```json
  {
    "available": boolean,
    "valid": boolean,
    "suggestions": ["string"] // if not available,
    "error": "string (if invalid format)"
  }
  ```
- **RPC Calls**: `validate_username_format(username)`, `check_username_availability(username)`, `batch_check_usernames(usernames)`
- **Notes**: Real-time validation. Provides 3-5 suggestions if taken.

### 88. **get-feed**
- **URL**: `GET /get-feed`
- **Purpose**: Get paginated feed with posts
- **Request**: Query params: `?sort=hot|top|latest&time_filter=all|today|week|month&category_id=uuid&location_id=uuid&limit=20&offset=0`
- **Response**: 
  ```json
  {
    "posts": [
      {
        "post_id": "uuid",
        "content": "string",
        "author": { ... },
        "category": { ... },
        "location": { ... },
        "vote_count": number,
        "comment_count": number,
        "created_at": "timestamp"
      }
    ],
    "total_count": number,
    "has_more": boolean
  }
  ```
- **RPC Calls**: `get_cached_feed`, `get_unified_feed`, `get_total_posts_count`
- **Notes**: ADO-910. Max 100 per page. Caching enabled. Sort: hot (algorithm), top (votes), latest (time).

### 89. **get-feed-cached**
- **URL**: `GET /get-feed-cached`
- **Purpose**: Cached version of feed for better performance
- **Notes**: Same as get-feed but with aggressive caching

### 90. **get-post**
- **URL**: `GET /get-post`
- **Purpose**: Get single post by ID
- **Notes**: See entry #80 (can be used without auth)

### 91. **get-comments**
- **URL**: `GET /get-comments`
- **Purpose**: Get comments for a post
- **Notes**: See entry #78 (can be used without auth, but without user_vote)

### 92. **get-categories**
- **URL**: `GET /get-categories`
- **Purpose**: Get all post categories
- **Request**: No parameters
- **Response**: 
  ```json
  [
    {
      "category_id": "uuid",
      "name": "string",
      "description": "string",
      "icon": "string",
      "post_count": number
    }
  ]
  ```
- **Notes**: Cached, refreshes every 5 minutes

### 93. **get-locations**
- **URL**: `GET /get-locations`
- **Purpose**: Get all locations
- **Request**: No parameters
- **Response**: 
  ```json
  [
    {
      "location_id": "uuid",
      "name": "string",
      "city": "string",
      "state": "string",
      "country": "string"
    }
  ]
  ```
- **Notes**: Cached

### 94. **get-active-announcements**
- **URL**: `GET /get-active-announcements`
- **Purpose**: Get currently active announcements
- **Request**: No parameters
- **Response**: Array of active announcements
- **RPC Calls**: Queries `announcements` table where is_active=true and not expired

### 95. **get-pinned-posts**
- **URL**: `GET /get-pinned-posts`
- **Purpose**: Get currently pinned posts
- **Request**: No parameters
- **Response**: Array of pinned posts (max 3)
- **RPC Calls**: `get_pinned_posts()`
- **Notes**: ADO-1355

### 96. **get-monthly-spotlight-posts**
- **URL**: `GET /get-monthly-spotlight-posts`
- **Purpose**: Get posts marked for monthly spotlight
- **Request**: Query params: `?limit=20&offset=0`
- **Response**: Array of spotlight posts
- **RPC Calls**: `get_monthly_spotlight_posts(limit, offset)`

### 97. **get-hot-topic**
- **URL**: `GET /get-hot-topic`
- **Purpose**: Get current hot topic
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "topic": "string",
    "post_count": number,
    "posts": [...]
  }
  ```
- **RPC Calls**: `get_current_hot_topic()`

### 98. **get-hottest-post**
- **URL**: `GET /get-hottest-post`
- **Purpose**: Get the hottest post of the day
- **Request**: No parameters
- **Response**: Post object
- **RPC Calls**: Algorithm-based selection

### 99. **get-top-post**
- **URL**: `GET /get-top-post`
- **Purpose**: Get top post by score
- **Request**: Query params: `?time_period=today|week|month|all`
- **Response**: Post object
- **RPC Calls**: Algorithm-based selection

### 100. **get-top-posts-leaderboard**
- **URL**: `GET /get-top-posts-leaderboard`
- **Purpose**: Get top posts leaderboard
- **Request**: Query params: `?time_period=week&limit=10`
- **Response**: 
  ```json
  [
    {
      "rank": number,
      "post": { ... },
      "score": number
    }
  ]
  ```
- **RPC Calls**: `get_top_posts_leaderboard(time_period, limit)`

### 101. **get-post-timestamp**
- **URL**: `GET /get-post-timestamp`
- **Purpose**: Get post creation timestamp
- **Request**: Query param: `?post_id=uuid`
- **Response**: `{ created_at: "timestamp" }`

### 102. **verify-timestamps**
- **URL**: `GET /verify-timestamps`
- **Purpose**: Verify server timestamp (for client-server time sync)
- **Request**: No parameters
- **Response**: 
  ```json
  {
    "server_time": "timestamp",
    "timezone": "UTC"
  }
  ```
- **Notes**: Used for client-server time sync

---

## System/Internal Functions

Functions for system operations (scheduled tasks, hooks):

### 103. **auth-hook-deactivated-check**
- **URL**: Internal Auth Hook (automatically triggered)
- **Purpose**: Auth hook that prevents deactivated users from logging in
- **Request**: Hook payload from Supabase Auth
- **Response**: 
  ```json
  {
    "decision": "reject | continue",
    "message": "string (if rejected)"
  }
  ```
- **Notes**: Runs automatically on login. Fails open for availability.

### 104. **auto-unpin-expired**
- **URL**: Internal Cron Job (automatically triggered)
- **Purpose**: Scheduled task to automatically unpin expired posts
- **Request**: No parameters (triggered by cron)
- **Response**: `{ unpinned_count: number }`
- **RPC Calls**: `unpin_expired_posts()`
- **Notes**: ADO-1355. Runs hourly via cron schedule.

### 105. **process-notifications**
- **URL**: Internal Cron Job (automatically triggered)
- **Purpose**: Process pending notifications (scheduled task)
- **Request**: No parameters (triggered by cron)
- **Response**: `{ processed_count: number }`
- **Notes**: Background job for batch processing notifications

### 106. **update-trending**
- **URL**: Internal Cron Job (automatically triggered)
- **Purpose**: Update trending posts calculation (scheduled task)
- **Request**: No parameters (triggered by cron)
- **Response**: `{ updated_count: number }`
- **RPC Calls**: `update_trending_posts()`
- **Notes**: Scheduled task, runs periodically to update trending scores

---

## Function Reference (A-Z)

Quick alphabetical index with role requirements:

| Function | Role Required | Category |
|----------|--------------|----------|
| assign-early-adopter-badges | Admin | Admin |
| assign-role | Admin | Admin |
| auth-hook-deactivated-check | System | System |
| auto-unpin-expired | System | System |
| ban-user | Admin | Admin |
| batch-operations | Auth (partial) | User |
| block-user | Auth | User |
| check-account-status | Auth | User |
| check-block-status | Auth | User |
| check-deactivation-status | Auth | User |
| check-permission | Auth | User |
| check-user-exists | Admin | Admin |
| check-username | Public | Public |
| check-wod-status | Auth | User |
| create-announcement | Admin | Admin |
| create-comment | Auth | User |
| create-comment-optimized | Auth | User |
| create-comment-v2 | Auth | User |
| create-post | Auth | User |
| create-post-optimized | Auth | User |
| deactivate-account | Auth | User |
| delete-comment | Auth/Admin | User |
| delete-flagged-content | Admin | Admin |
| delete-post | Auth/Admin | User |
| forgot-password | Public | Public |
| generate-invitation-link | Auth/Admin | User |
| get-active-announcements | Public | Public |
| get-analytics-data | Admin | Admin |
| get-announcements | Admin | Admin |
| get-auto-flagged-content | Staff | Staff |
| get-blocked-content-stats | Admin | Admin |
| get-blocked-users | Auth | User |
| get-blocking-stats | Staff | Staff |
| get-categories | Public | Public |
| get-comments | Public | Public |
| get-deleted-posts | Staff | Staff |
| get-early-adopters | Admin | Admin |
| get-feed | Public | Public |
| get-feed-cached | Public | Public |
| get-feedback-history | Admin | Admin |
| get-flagged-content | Staff | Staff |
| get-hot-topic | Public | Public |
| get-hottest-post | Public | Public |
| get-liked-posts | Auth | User |
| get-locations | Public | Public |
| get-mentions | Auth | User |
| get-moderation-reports | Staff | Staff |
| get-monthly-spotlight-posts | Public | Public |
| get-monthly-spotlight-status | Auth | User |
| get-pinned-posts | Public | Public |
| get-post | Public | Public |
| get-post-timestamp | Public | Public |
| get-profile | Public | Public |
| get-rate-limit-configs | Admin | Admin |
| get-role-permissions | Public | Public |
| get-role-stats | Admin | Admin |
| get-suspended-users | Staff | Staff |
| get-top-post | Public | Public |
| get-top-posts-leaderboard | Public | Public |
| get-unread-mention-count | Auth | User |
| get-upvoted-posts | Auth | User |
| get-user-badges | Public | Public |
| get-user-posts | Public | Public |
| get-user-role | Auth | User |
| get-username-status | Auth | User |
| get-violation-statistics | Admin | Admin |
| get-wod-stats | Admin | Admin |
| logout | Auth | User |
| mark-content-safe | Staff | Staff |
| mark-mention-read | Auth | User |
| pin-post | Admin | Admin |
| process-notifications | System | System |
| push-announcement | Admin | Admin |
| reactivate-account | Auth | User |
| register-admin | Public* | Admin |
| register-device | Auth | User |
| register-staff | Staff | Staff |
| report-comment | Auth | User |
| report-post | Auth | User |
| resend-otp | Public | Public |
| reset-password | Public | Public |
| restore-post | Staff | Staff |
| search-users | Auth | User |
| send-otp | Public | Public |
| send-push-notification | Admin | Admin |
| set-manual-boost | Admin | Admin |
| submit-feedback | Auth | User |
| suspend-account | Admin | Admin |
| toggle-monthly-spotlight | Auth | User |
| unblock-user | Auth | User |
| unpin-post | Admin | Admin |
| unsuspend-account | Admin | Admin |
| update-algorithm-config | Admin | Admin |
| update-birthday | Auth | User |
| update-notification-preferences | Auth | User |
| update-profile | Auth | User |
| update-rate-limit-config | Admin | Admin |
| update-trending | System | System |
| update-username | Auth | User |
| upload-profile-picture | Auth | User |
| verify-otp | Public | Public |
| verify-timestamps | Public | Public |
| vote-comment | Auth | User |
| vote-post | Auth | User |
| wod-opt-in | Auth | User |
| wod-opt-out | Auth | User |

*Requires ADMIN_REGISTRATION_CODE environment variable

---

## Common Patterns & Notes

### Authentication Patterns
- **JWT Tokens**: Most endpoints use `Authorization: Bearer <token>` header
- **Service Role**: System functions use service role key for elevated access
- **Auth Hooks**: `auth-hook-deactivated-check` runs on every login attempt

### Rate Limiting
- **Post Creation**: 5/hour, 20/day per user
- **Comment Creation**: 5/hour, 50/day per user
- **OTP Requests**: 3/15min per identifier
- **Password Reset**: 3/hour per email
- Rate limits stored in `rate_limit_configs` table, configurable by admins

### Content Moderation
- **Trigger Word Scanner**: Automatic scanning on post/comment creation
- **Auto-Flagging**: Content auto-flags after threshold (default 5 reports)
- **Perspective API**: AI-powered toxicity detection (optional)
- **Moderation Queue**: Flagged content goes to moderation queue for review

### Cooldowns
- **Username Change**: 30-day cooldown
- **Birthday Change**: 30-day cooldown
- **Post Pinning**: Max 24-hour duration
- Cooldown tracking in profiles table

### Security Features
- **Account Deactivation**: Users can't log in if deactivated
- **Ban/Suspension**: Banned users blocked from creating content
- **Bidirectional Blocking**: Blocked users can't see each other's content
- **RLS Policies**: Row-level security on all tables
- **Audit Logging**: Role changes and moderation actions logged

### Performance Optimization
- **Caching**: Feed caching, category/location caching
- **Batch Operations**: `batch-operations` for bulk data fetching
- **Optimized Variants**: Some functions have `-optimized` variants
- **Pagination**: Standard limit/offset pagination (max 100 items)

### Error Handling
- **Standardized Responses**: All functions return `{ success, message, data? }`
- **HTTP Status Codes**: 200 (OK), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 500 (Server Error)
- **Fail Open**: Auth hooks fail open for availability
- **Rate Limit Headers**: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

### ADO References
Functions reference Azure DevOps work items:
- ADO-893: OTP Authentication
- ADO-908: Voting System
- ADO-909: Reporting System
- ADO-910: Feed Algorithm
- ADO-963: Password Reset
- ADO-966: User Profiles
- ADO-1002: Comments System
- ADO-1160: Moderation System
- ADO-1161: Content Creation
- ADO-1163: RBAC System
- ADO-1173, 1226, 1227: Comment Enhancements
- ADO-1206: Account Deactivation
- ADO-1355: Post Pinning & WOD
- ADO-1358: User Blocking

### Special Features
- **Monthly Spotlight**: Limited feature for eligible users
- **Word of the Day (WOD)**: Opt-in feature for daily prompts
- **Early Adopter Badges**: Special badges for early users
- **Invitation System**: Users can generate invitation links
- **Hot Topic**: Algorithmic detection of trending topics
- **Leaderboard**: Top posts ranking system

---

## Environment Variables Required

### Authentication
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ADMIN_REGISTRATION_CODE` (for admin registration)

### Email/SMS
- `SENDGRID_API_KEY`
- `SENDGRID_FROM_EMAIL`
- `SMS_PROVIDER_API_KEY` (if using SMS OTP)

### Push Notifications
- `FCM_SERVER_KEY`
- `FCM_PROJECT_ID`

### Content Moderation
- `PERSPECTIVE_API_KEY` (optional, for AI moderation)

### Other
- `NODE_ENV` (development|production)
- `RATE_LIMIT_BYPASS_KEY` (for testing)

---

**Documentation Version**: 1.0  
**Last Updated**: January 25, 2026  
**Maintained By**: K2MVP Backend Team

For questions or issues, please refer to the project's main documentation or contact the development team.
