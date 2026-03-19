# Moderation Edge Functions — Complete Reference
**Project:** K2 MVP · `wvkyzhnzwijfxpzsrguj`  
**Base URL:** `https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1`  
**All functions:** `verify_jwt = true` · POST (unless noted) · `Authorization: Bearer <token>` required

---

## Role Hierarchy

```
user  <  reviewer  <  junior_moderator  <  moderator  <  admin
```

---

## Feature Matrix

| # | Feature | URL | Roles | Status |
|---|---------|-----|-------|--------|
| 1 | View User's Profile | RPC `mod_view_user_profile` — via `mod-view-profile` edge fn | moderator, admin | ✅ Built |
| 2 | Pin / Unpin Post | `POST /pin-post` | moderator, admin | ✅ Built |
| 3 | Escalate to Administrator | `POST /escalate-to-admin` | moderator | ✅ Built |
| 4 | Mute Post | `POST /mute-post` | moderator, admin | ✅ Built |
| 5 | Edit Post | `POST /admin-edit-post` | admin | ✅ Built |
| 6 | Warn Post | `POST /warn-post` | admin | ✅ Built |
| 7 | Hide Post | `POST /hide-post` | admin | ✅ Built |
| 8 | Nominate WOD | `GET+POST /nominate-wod` | reviewer | ✅ Built |
| 9 | Block User | `POST /block-user` | reviewer, junior_moderator | ✅ Pre-existing |
| 10 | Escalate to Moderator | `POST /escalate-to-moderator` | reviewer, junior_moderator | ✅ Pre-existing |
| 11 | Report Post | `POST /report-post` | all authenticated users | ✅ Pre-existing |
| 12 | Flag Post | `POST /flag-post` | reviewer, junior_moderator, moderator, admin | ✅ Pre-existing |
| 13 | Delete Post | `POST /delete-post` | own post (all) · any post (admin) | ✅ Pre-existing |
| 14 | Change Category | `POST /change-category` | moderator, admin | ✅ Pre-existing |

---


## 1. View User's Profile — `mod-view-profile`

| Field | Value |
|-------|-------|
| **URL** | `POST /mod-view-profile` |
| **Roles** | moderator, admin |
| **Permission** | `view_any_user_profile` |
| **Migration** | `20260302000004_mod_view_user_profile.sql` |
| **DB Function** | `mod_view_user_profile(p_caller_id, p_target_user_id)` |
| **Notes** | Bypasses block filters intentionally. Junior moderators do **not** have access. Caller ID is always taken from the JWT — never from body. |

### Request body
```json
{
  "target_user_id": "uuid"
}
```
### Response
```json
{
  "success": true,
  "profile": { "id", "username", "role", "avatar_url", "bio", "trust_score", "is_suspended", "is_banned", ... },
  "post_stats": { "total_posts", "active_posts", "deleted_posts", "reported_posts" },
  "moderation_summary": { "total_actions", "active_actions", "warnings", "mutes", "suspensions", "bans" },
  "role_history": [ { "role", "changed_at", "changed_by", "changed_by_username" } ],
  "recent_actions": [ { "action_type", "reason", "issued_by", "created_at", "is_active" } ]
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks `view_any_user_profile` permission |
| 400 | `target_user_id` missing · user not found |

---

## 2. Pin / Unpin Post — `pin-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /pin-post` |
| **Roles** | moderator, admin |
| **Permission** | `pin_posts` |
| **Migration** | `20260302000003_pin_unpin_post.sql` |
| **DB Functions** | `pin_post(p_post_id, p_pinned_by, p_expires_at)` · `unpin_post(p_post_id, p_unpinned_by)` |

### Request body
```json
{
  "action":     "pin" | "unpin",
  "post_id":    "uuid",
  "expires_at": "ISO8601 (pin only, optional — null = no expiry)"
}
```
### Responses
**pin:** `{ success, pin_id, post_id, pinned_by, expires_at, pinned_at }`  
**unpin:** `{ success, post_id, unpinned_by, unpinned_at }`

### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks `pin_posts` permission |
| 400 | Missing fields · post not found · already pinned / not pinned |

---

## 3. Escalate to Administrator — `escalate-to-admin`

| Field | Value |
|-------|-------|
| **URL** | `POST /escalate-to-admin` |
| **Roles** | moderator |
| **Permission** | `escalate_to_admin` |
| **Migration** | `20260302000001_escalate_to_admin.sql` |
| **DB Function** | `escalate_post_author_to_admin(p_escalator_id, p_post_id, p_reason)` |

### Request body
```json
{
  "post_id": "uuid",
  "reason":  "string (required)"
}
```
### Response
```json
{
  "success":       true,
  "post_id":       "uuid",
  "promoted_user": "uuid",
  "escalated_by":  "uuid",
  "escalated_at":  "ISO8601"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks `escalate_to_admin` permission |
| 400 | `post_id` missing · post not found |

---

## 4. Mute Post — `mute-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /mute-post` |
| **Roles** | moderator, admin |
| **Permission** | `mute_post` |
| **Migration** | `20260302000005_mute_post.sql` |
| **DB Functions** | `mute_post(p_moderator_id, p_post_id, p_reason, p_details, p_expires_at)` · `unmute_post(p_moderator_id, p_post_id)` |
| **Denormalized column** | `posts.is_muted BOOLEAN` — partial index `idx_posts_is_muted` |

### Request body
```json
{
  "action":     "mute" | "unmute",
  "post_id":    "uuid",
  "reason":     "see Valid Reasons below (mute only, required)",
  "details":    "optional string (mute only)",
  "expires_at": "ISO8601 (mute only, optional — null = indefinite)"
}
```
### Responses
**mute:** `{ success, action_id, post_id, reason, expires_at, muted_by, muted_at }`  
**unmute:** `{ success, post_id, unmuted_by, unmuted_at }`

### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks `mute_post` permission |
| 400 | Missing fields · invalid reason · post not found · already muted / no active mute |

---

## 5. Edit Post — `admin-edit-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /admin-edit-post` |
| **Roles** | admin |
| **Permission** | `edit_any_post` |
| **Migration** | `20260302000002_admin_edit_post.sql` |
| **DB Function** | `admin_edit_post(p_admin_id, p_post_id, p_content, p_image_url)` |

### Request body
```json
{
  "post_id":   "uuid",
  "content":   "updated text (max 1000 chars, required)",
  "image_url": "https://... (optional — omit or null to clear)"
}
```
### Response
```json
{
  "success":    true,
  "post_id":    "uuid",
  "updated_by": "uuid",
  "updated_at": "ISO8601"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller is not admin |
| 400 | `post_id` or `content` missing · content > 1000 chars · post not found |

---

## 6. Warn Post — `warn-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /warn-post` |
| **Roles** | admin |
| **Permission** | `warn_post` |
| **Migration** | `20260302000007_warn_post.sql` |
| **DB Functions** | `warn_post(p_admin_id, p_post_id, p_reason, p_details)` · `unwarn_post(p_admin_id, p_post_id)` |
| **Denormalized column** | `posts.is_warned BOOLEAN` — partial index `idx_posts_is_warned` |

### Request body
```json
{
  "action":  "warn" | "unwarn",
  "post_id": "uuid",
  "reason":  "see Valid Reasons below (warn only, required)",
  "details": "optional string (warn only)"
}
```
### Responses
**warn:** `{ success, action_id, post_id, reason, warned_by, warned_at }`  
**unwarn:** `{ success, post_id, unwarned_by, unwarned_at }`

### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller is not admin |
| 400 | Missing fields · invalid reason · post not found · already warned / no active warning |

---

## 7. Hide Post — `hide-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /hide-post` |
| **Roles** | admin |
| **Permission** | `hide_post` |
| **Migration** | `20260302000008_hide_post.sql` |
| **DB Functions** | `hide_post(p_admin_id, p_post_id, p_reason, p_details)` · `unhide_post(p_admin_id, p_post_id)` |
| **Denormalized column** | `posts.is_hidden BOOLEAN` — partial index `idx_posts_is_hidden` |
| **State change** | `posts.visibility_state` → `'hidden'` on hide · `'visible'` on unhide |

### Request body
```json
{
  "action":  "hide" | "unhide",
  "post_id": "uuid",
  "reason":  "see Valid Reasons below (hide only, required)",
  "details": "optional string (hide only)"
}
```
### Responses
**hide:** `{ success, action_id, post_id, reason, hidden_by, hidden_at }`  
**unhide:** `{ success, post_id, unhidden_by, unhidden_at }`

### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller is not admin |
| 400 | Missing fields · invalid reason · post not found · already hidden / not currently hidden |

---

## 8. Nominate WOD — `nominate-wod`

| Field | Value |
|-------|-------|
| **URL** | `POST /nominate-wod` · `GET /nominate-wod` |
| **Roles** | reviewer, admin |
| **Permission** | `nominate_wod` |

### POST — Nominate a post
```json
{
  "post_id": "uuid",
  "note":    "optional reason"
}
```
**Response:** `{ success, nomination_id, post_id, nominated_by, nominated_at }`

### GET — List nominations
```
GET /nominate-wod?status=pending&limit=20&offset=0
```
`status`: `pending` · `approved` · `rejected`  
**Response:** `{ success, nominations: [...], pagination: { limit, offset, total_count, has_more } }`

### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks `nominate_wod` permission |
| 400 | `post_id` missing · post not found |

---

## 9. Block User — `block-user`

| Field | Value |
|-------|-------|
| **URL** | `POST /block-user` |
| **Roles** | reviewer, junior_moderator (and any authenticated user blocking another) |
| **Notes** | Blocks the user who uploaded the target post. Uses caller's JWT — no privilege escalation. |

### Request body
```json
{
  "blocked_user_id": "uuid",
  "reason":          "optional string"
}
```
### Response
```json
{
  "success":    true,
  "message":    "User blocked successfully",
  "blocked_id": "uuid"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 400 | `blocked_user_id` missing · cannot block yourself · already blocked |

---

## 10. Escalate to Moderator — `escalate-to-moderator`

| Field | Value |
|-------|-------|
| **URL** | `POST /escalate-to-moderator` |
| **Roles** | reviewer, junior_moderator |
| **Notes** | Promotes the post's author to the `moderator` role. Logs to `role_changes`. |

### Request body
```json
{
  "post_id": "uuid",
  "reason":  "optional string"
}
```
### Response
```json
{
  "success":   true,
  "post_id":   "uuid",
  "user_id":   "uuid",
  "username":  "string",
  "old_role":  "string",
  "new_role":  "moderator"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks escalation permission |
| 400 | `post_id` missing · post not found · user already moderator or higher |

---

## 11. Report Post — `report-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /report-post` |
| **Roles** | all authenticated users |
| **Notes** | One report per user per post. Auto-flags post after threshold is reached. |

### Request body
```json
{
  "post_id":     "uuid",
  "reason":      "see Valid Reasons below (required)",
  "description": "optional detail string"
}
```
### Response
```json
{
  "success":   true,
  "message":   "Post reported successfully",
  "report_id": "uuid"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 400 | `post_id` or `reason` missing · invalid reason · already reported by this user |

---

## 12. Flag Post — `flag-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /flag-post` |
| **Roles** | reviewer, junior_moderator, moderator, admin |
| **Notes** | Flags post for moderator queue review. Updates `moderation_flagged` status on post. |

### Request body
```json
{
  "post_id": "uuid",
  "reason":  "optional string"
}
```
### Response
```json
{
  "success":    true,
  "post_id":    "uuid",
  "old_status": "string",
  "new_status": "flagged",
  "reason":     "string"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller lacks flag permission |
| 400 | `post_id` missing · post not found · already flagged |

---

## 13. Delete Post — `delete-post`

| Field | Value |
|-------|-------|
| **URL** | `POST /delete-post` |
| **Roles** | any authenticated user (own post) · admin (any post) |
| **Notes** | Soft delete — sets `status = 'deleted'`. Does not physically remove the row. |

### Request body
```json
{
  "post_id": "uuid"
}
```
### Response
```json
{
  "success":    true,
  "message":    "Post deleted successfully",
  "post_id":    "uuid"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller does not own the post and is not admin |
| 400 | `post_id` missing · post not found · already deleted |

---

## 14. Change Category — `change-category`

| Field | Value |
|-------|-------|
| **URL** | `POST /change-category` |
| **Roles** | moderator, admin |
| **Notes** | Reassigns a post to a different category by slug. |

### Request body
```json
{
  "post_id":       "uuid",
  "category_slug": "general"
}
```
### Response
```json
{
  "success":      true,
  "post_id":      "uuid",
  "old_category": "string",
  "new_category": "string"
}
```
### Errors
| Status | Meaning |
|--------|---------|
| 401 | Missing / invalid token |
| 403 | Caller is not moderator or admin |
| 400 | `post_id` or `category_slug` missing · post not found · invalid category slug |

---

## Quick Reference

| # | Function | URL | Method | Min Role | Permission |
|---|----------|-----|--------|----------|------------|
| 1 | mod-view-profile | `/mod-view-profile` | POST | moderator | `view_any_user_profile` |
| 2 | pin-post | `/pin-post` | POST | moderator | `pin_posts` |
| 3 | escalate-to-admin | `/escalate-to-admin` | POST | moderator | `escalate_to_admin` |
| 4 | mute-post | `/mute-post` | POST | moderator | `mute_post` |
| 5 | admin-edit-post | `/admin-edit-post` | POST | admin | `edit_any_post` |
| 6 | warn-post | `/warn-post` | POST | admin | `warn_post` |
| 7 | hide-post | `/hide-post` | POST | admin | `hide_post` |
| 8 | nominate-wod | `/nominate-wod` | GET / POST | reviewer | `nominate_wod` |
| 9 | block-user | `/block-user` | POST | reviewer | — |
| 10 | escalate-to-moderator | `/escalate-to-moderator` | POST | reviewer | — |
| 11 | report-post | `/report-post` | POST | any auth user | — |
| 12 | flag-post | `/flag-post` | POST | reviewer | — |
| 13 | delete-post | `/delete-post` | POST | any auth user | — |
| 14 | change-category | `/change-category` | POST | moderator | — |

---

## Valid Reasons (all post-moderation actions)

```
harassment · spam · hate_speech · violence · inappropriate_content
misinformation · copyright_violation · scam · other
```

---

## Denormalized Post Flags

| Column | Default | Partial Index | Managed by |
|--------|---------|---------------|------------|
| `posts.is_muted` | `FALSE` | `idx_posts_is_muted` | `mute_post()` / `unmute_post()` |
| `posts.is_warned` | `FALSE` | `idx_posts_is_warned` | `warn_post()` / `unwarn_post()` |
| `posts.is_hidden` | `FALSE` | `idx_posts_is_hidden` | `hide_post()` / `unhide_post()` |
