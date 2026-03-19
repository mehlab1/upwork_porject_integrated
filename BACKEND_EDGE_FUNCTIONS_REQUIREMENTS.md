# Backend Edge Functions Requirements for Post Menus

## Overview

The app has 4 role-based three-dot menus on post cards: **Admin**, **Moderator**, **Reviewer**, and **Junior Moderator**. Each role has specific actions that need backend edge functions. This document lists every action, what the frontend sends, and what the backend should do.

---

## Already Existing Edge Functions (Can Reuse)

These are already deployed and working:

| Action | Edge Function | Used By |
|--------|--------------|---------|
| Block User | `block-user` | Reviewer, Junior Moderator |
| Report Post | `report-post` | Reviewer, Junior Moderator (as "Report Conversation") |
| Delete Post | `delete-post` | All roles |
| Pin Post | `pin-post` | Admin, Moderator |
| Unpin Post | `unpin-post` | Admin, Moderator |

---

## NEW Edge Functions Needed

### 1. `nominate-wod` — Nominate a Post as Wahala of the Day

**Used by:** Reviewer

**Request:**
```json
{
  "post_id": "uuid",
  "nominated_by": "uuid (reviewer's user_id)"
}
```

**What it should do:**
- Insert a row into a `wod_nominations` table (needs to be created)
- Check if the post is already nominated (prevent duplicates by the same reviewer)
- Optionally notify the moderator/admin that a new WOD nomination was submitted

**Suggested new table: `wod_nominations`**
```sql
CREATE TABLE public.wod_nominations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  post_id uuid NOT NULL,
  nominated_by uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT wod_nominations_pkey PRIMARY KEY (id),
  CONSTRAINT wod_nominations_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT wod_nominations_nominated_by_fkey FOREIGN KEY (nominated_by) REFERENCES public.profiles(id),
  CONSTRAINT wod_nominations_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id),
  CONSTRAINT wod_nominations_unique UNIQUE (post_id, nominated_by)
);
```

**Response:**
```json
{
  "success": true,
  "message": "Post nominated as WOD successfully",
  "nomination_id": "uuid"
}
```

---

### 2. `escalate-to-moderator` — Escalate Post to Moderator

**Used by:** Reviewer, Junior Moderator

**Request:**
```json
{
  "post_id": "uuid",
  "escalated_by": "uuid (user_id of reviewer/JM)",
  "escalated_by_role": "reviewer" | "junior_moderator",
  "reason": "optional text"
}
```

**What it should do:**
- Insert a row into an `escalations` table (needs to be created)
- Send a notification to all users with role `moderator` (via `send-push-notification`)
- Mark the post with an `escalated` flag or status so moderators see it in their queue

**Suggested new table: `escalations`**
```sql
CREATE TABLE public.escalations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  post_id uuid NOT NULL,
  escalated_by uuid NOT NULL,
  escalated_by_role text NOT NULL CHECK (escalated_by_role IN ('reviewer', 'junior_moderator', 'moderator')),
  escalated_to_role text NOT NULL CHECK (escalated_to_role IN ('moderator', 'admin')),
  reason text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'resolved', 'dismissed')),
  resolved_by uuid,
  resolved_at timestamp with time zone,
  resolution_notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT escalations_pkey PRIMARY KEY (id),
  CONSTRAINT escalations_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT escalations_escalated_by_fkey FOREIGN KEY (escalated_by) REFERENCES public.profiles(id),
  CONSTRAINT escalations_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id)
);
```

**Response:**
```json
{
  "success": true,
  "message": "Post escalated to moderator",
  "escalation_id": "uuid"
}
```

---

### 3. `escalate-to-admin` — Escalate Post to Administrator

**Used by:** Moderator

**Request:**
```json
{
  "post_id": "uuid",
  "escalated_by": "uuid (moderator's user_id)",
  "escalated_by_role": "moderator",
  "reason": "optional text"
}
```

**What it should do:**
- Same as `escalate-to-moderator` but with `escalated_to_role = 'admin'`
- Uses the same `escalations` table
- Send a notification to all users with role `admin`

**Note:** Can be the same edge function as #2 — just pass `escalated_to_role: "admin"` instead of `"moderator"`. You could have a single `escalate-post` function that handles both.

**Response:**
```json
{
  "success": true,
  "message": "Post escalated to administrator",
  "escalation_id": "uuid"
}
```

---

### 4. `mute-post` — Mute/Silence a Conversation

**Used by:** Admin, Moderator

**Request:**
```json
{
  "post_id": "uuid",
  "muted_by": "uuid",
  "muted_by_role": "admin" | "moderator",
  "duration_hours": 24 | 48 | 72 | null  (null = permanent)
}
```

**What it should do:**
- Set post `status` to `'muted'` (or add a new `is_muted` boolean column to `posts` table)
- Disable commenting on the post while muted
- Optionally set an expiry time for auto-unmute
- Notify the post author that their conversation has been muted

**Suggested columns to add to `posts` table:**
```sql
ALTER TABLE public.posts
  ADD COLUMN is_muted boolean DEFAULT false,
  ADD COLUMN muted_at timestamp with time zone,
  ADD COLUMN muted_by uuid,
  ADD COLUMN mute_expires_at timestamp with time zone;
```

**Response:**
```json
{
  "success": true,
  "message": "Conversation muted",
  "muted_until": "2026-03-02T12:00:00Z" | null
}
```

---

### 5. `change-post-category` — Change a Post's Category

**Used by:** Moderator

**Request:**
```json
{
  "post_id": "uuid",
  "new_category_id": "uuid",
  "changed_by": "uuid (moderator's user_id)"
}
```

**What it should do:**
- Update `posts.category_id` to the new category
- Log the change in a `moderation_actions` table (see below)
- Optionally notify the post author of the category change

**Response:**
```json
{
  "success": true,
  "message": "Category changed successfully",
  "old_category": "Category Name",
  "new_category": "New Category Name"
}
```

---

### 6. `warn-user` — Send a Warning to a User

**Used by:** Admin

**Request:**
```json
{
  "user_id": "uuid (the post author being warned)",
  "post_id": "uuid (the post that triggered the warning)",
  "warned_by": "uuid (admin's user_id)",
  "reason": "text describing the warning",
  "warning_type": "content_violation" | "spam" | "harassment" | "other"
}
```

**What it should do:**
- Insert a row into a `user_warnings` table (needs to be created)
- Increment `profiles.warnings_count` (column already exists)
- Send a push notification to the user with the warning message
- If warnings_count reaches a threshold (e.g., 3), auto-suspend the account

**Suggested new table: `user_warnings`**
```sql
CREATE TABLE public.user_warnings (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  warned_by uuid NOT NULL,
  post_id uuid,
  reason text NOT NULL,
  warning_type text NOT NULL CHECK (warning_type IN ('content_violation', 'spam', 'harassment', 'other')),
  acknowledged boolean DEFAULT false,
  acknowledged_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_warnings_pkey PRIMARY KEY (id),
  CONSTRAINT user_warnings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_warnings_warned_by_fkey FOREIGN KEY (warned_by) REFERENCES public.profiles(id),
  CONSTRAINT user_warnings_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
```

**Response:**
```json
{
  "success": true,
  "message": "Warning sent to user",
  "warning_id": "uuid",
  "total_warnings": 2
}
```

---

### 7. `hide-post` — Hide a Post from Feed

**Used by:** Admin

**Request:**
```json
{
  "post_id": "uuid",
  "hidden_by": "uuid (admin's user_id)",
  "reason": "optional text"
}
```

**What it should do:**
- Set post `status` to `'hidden'` (value already exists in `post_status` enum per the schema)
- The post should no longer appear in feeds but still be accessible from admin dashboard
- Log in `moderation_actions` table
- Optionally notify the post author

**Response:**
```json
{
  "success": true,
  "message": "Post hidden from feed"
}
```

---

### 8. `flag-post` — Flag a Post for Review

**Used by:** Admin, Reviewer, Junior Moderator

**Request:**
```json
{
  "post_id": "uuid",
  "flagged_by": "uuid",
  "flagged_by_role": "admin" | "reviewer" | "junior_moderator",
  "reason": "text",
  "flag_category": "spam" | "harassment" | "inappropriate" | "misinformation" | "other"
}
```

**What it should do:**
- Set `posts.moderation_flagged = true`
- Increment `posts.report_count`
- Insert into `post_reports` table (already exists)
- This is conceptually similar to `report-post` but done by staff rather than regular users

**Note:** The existing `report-post` function may already handle this. If so, just ensure it accepts a `role` parameter so staff reports have higher priority.

**Response:**
```json
{
  "success": true,
  "message": "Post flagged for review"
}
```

---

## Suggested: `moderation_actions` Audit Log Table

All moderation actions should be logged for accountability:

```sql
CREATE TABLE public.moderation_actions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  post_id uuid,
  target_user_id uuid,
  action_by uuid NOT NULL,
  action_by_role text NOT NULL CHECK (action_by_role IN ('admin', 'moderator', 'reviewer', 'junior_moderator')),
  action_type text NOT NULL CHECK (action_type IN (
    'nominate_wod', 'escalate_to_moderator', 'escalate_to_admin',
    'mute_post', 'unmute_post', 'change_category', 'warn_user',
    'hide_post', 'unhide_post', 'flag_post', 'delete_post',
    'pin_post', 'unpin_post', 'block_user', 'unblock_user'
  )),
  details jsonb DEFAULT '{}',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT moderation_actions_pkey PRIMARY KEY (id),
  CONSTRAINT moderation_actions_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT moderation_actions_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.profiles(id),
  CONSTRAINT moderation_actions_action_by_fkey FOREIGN KEY (action_by) REFERENCES public.profiles(id)
);
```

---

## Summary: Actions by Role

### Admin Menu
| Action | Edge Function | Status |
|--------|--------------|--------|
| Edit Post | Frontend only (opens edit modal) | ✅ Working |
| View User's Profile | Frontend only (navigates) | ✅ Working |
| Pin Post | `pin-post` | ✅ Exists |
| Warn Conversation | `warn-user` | ❌ **NEW — Need #6** |
| Mute Conversation | `mute-post` | ❌ **NEW — Need #4** |
| Hide Conversation | `hide-post` | ❌ **NEW — Need #7** |
| Flag Conversation | `flag-post` / `report-post` | ⚠️ May reuse `report-post` — **Need #8** |
| Delete Conversation | `delete-post` | ✅ Exists |

### Moderator Menu
| Action | Edge Function | Status |
|--------|--------------|--------|
| Change Category | `change-post-category` | ❌ **NEW — Need #5** |
| View User's Profile | Frontend only (navigates) | ✅ Working |
| Pin Post | `pin-post` | ✅ Exists |
| Escalate to Administrator | `escalate-to-admin` | ❌ **NEW — Need #3** |
| Mute Conversation | `mute-post` | ❌ **NEW — Need #4** |
| Delete Conversation | `delete-post` | ✅ Exists |

### Reviewer Menu
| Action | Edge Function | Status |
|--------|--------------|--------|
| Nominate WOD | `nominate-wod` | ❌ **NEW — Need #1** |
| Block User | `block-user` | ✅ Exists |
| Escalate to Moderator | `escalate-to-moderator` | ❌ **NEW — Need #2** |
| Report Conversation | `report-post` | ✅ Exists |
| Flag Conversation | `flag-post` / `report-post` | ⚠️ May reuse `report-post` — **Need #8** |
| Delete Conversation | `delete-post` | ✅ Exists |

### Junior Moderator Menu
| Action | Edge Function | Status |
|--------|--------------|--------|
| Block User | `block-user` | ✅ Exists |
| Escalate to Moderator | `escalate-to-moderator` | ❌ **NEW — Need #2** |
| Report Conversation | `report-post` | ✅ Exists |
| Flag Conversation | `flag-post` / `report-post` | ⚠️ May reuse `report-post` — **Need #8** |
| Delete Conversation | `delete-post` | ✅ Exists |

---

## New Database Tables Needed

1. **`wod_nominations`** — For WOD nomination tracking
2. **`escalations`** — For escalation workflow between roles
3. **`user_warnings`** — For tracking warnings issued to users
4. **`moderation_actions`** — Audit log for all moderation actions

## Columns to Add to Existing Tables

- **`posts`** table: `is_muted`, `muted_at`, `muted_by`, `mute_expires_at`

---

## New Edge Functions Count: 8

| # | Function Name | Priority |
|---|--------------|----------|
| 1 | `nominate-wod` | High |
| 2 | `escalate-to-moderator` | High |
| 3 | `escalate-to-admin` (or combine with #2 as `escalate-post`) | High |
| 4 | `mute-post` | Medium |
| 5 | `change-post-category` | Medium |
| 6 | `warn-user` | Medium |
| 7 | `hide-post` | Medium |
| 8 | `flag-post` (or extend `report-post`) | Low (may reuse existing) |

**Optimization:** Functions #2 and #3 can be combined into a single `escalate-post` function. Function #8 may be handled by extending the existing `report-post` function. This reduces it to **6 truly new functions**.
