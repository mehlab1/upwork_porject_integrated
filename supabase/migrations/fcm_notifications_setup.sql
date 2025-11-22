-- ============================================================================
-- FCM Push Notifications Setup - ALTERNATIVE TRIGGERS
-- ============================================================================
-- ⚠️ WARNING: This file creates ALTERNATIVE triggers that will CONFLICT with
-- the existing triggers in migration 20241112000015_push_notification_triggers.sql
-- 
-- BEFORE RUNNING THIS FILE:
-- 1. DROP all existing notification triggers from migration 20241112000015
-- 2. Enable pg_net extension: CREATE EXTENSION IF NOT EXISTS pg_net;
--
-- This approach calls the Edge Function directly via pg_net instead of
-- relying on a cron job to process notifications_history records.
-- ============================================================================

-- Enable pg_net extension for HTTP calls
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Note: The service_role_key setting requires superuser permissions.
-- Instead, we'll pass it directly in the function using Supabase secrets.
-- The service role key will be available via current_setting() after being set
-- by your database administrator or through Supabase dashboard.

-- ============================================================================
-- DROP EXISTING TRIGGERS (from migration 20241112000015)
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_notify_post_reply ON public.comments;
DROP TRIGGER IF EXISTS trigger_notify_comment_reply ON public.comments;
DROP TRIGGER IF EXISTS trigger_notify_post_vote ON public.post_votes;
DROP TRIGGER IF EXISTS trigger_notify_post_achievement ON public.posts;
DROP TRIGGER IF EXISTS trigger_notify_account_status_change ON public.profiles;

-- Drop new trigger names
DROP TRIGGER IF EXISTS trigger_notify_new_comment ON public.comments;
DROP TRIGGER IF EXISTS trigger_notify_reply_to_comment ON public.comments;
DROP TRIGGER IF EXISTS trigger_notify_post_upvote ON public.post_votes;
DROP TRIGGER IF EXISTS trigger_notify_comment_upvote ON public.comment_votes;
DROP TRIGGER IF EXISTS trigger_notify_mention_in_comment ON public.mentions;
DROP TRIGGER IF EXISTS trigger_notify_post_hot ON public.posts;

-- Drop old functions if they exist
DROP FUNCTION IF EXISTS notify_post_reply();
DROP FUNCTION IF EXISTS notify_comment_reply();
DROP FUNCTION IF EXISTS notify_post_vote();
DROP FUNCTION IF EXISTS notify_post_achievement();
DROP FUNCTION IF EXISTS notify_account_status_change();

-- Drop new function names
DROP FUNCTION IF EXISTS notify_new_comment();
DROP FUNCTION IF EXISTS notify_reply_to_comment();
DROP FUNCTION IF EXISTS notify_post_upvote();
DROP FUNCTION IF EXISTS notify_comment_upvote();
DROP FUNCTION IF EXISTS notify_mention_in_comment();
DROP FUNCTION IF EXISTS notify_post_hot();
-- ============================================================================
-- 1. HELPER FUNCTIONS
-- ============================================================================

-- Helper function to check if user is blocked
CREATE OR REPLACE FUNCTION public.is_user_blocked(
  blocker_id UUID,
  blocked_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- Check if there's a blocked_users table (adjust table name if different)
  -- For now, return false if table doesn't exist
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql STABLE;

-- Helper function to call Edge Function via pg_net
CREATE OR REPLACE FUNCTION public.send_fcm_notification(
  p_user_id UUID,
  p_notification_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjEwMjk5OSwiZXhwIjoyMDc3Njc4OTk5fQ.MQpMtVsAxjN6zXbqqFi14K5B5H4qiHzOw45MB0cZtV4';
  v_request_id BIGINT;
BEGIN
  -- Call Edge Function asynchronously via pg_net
  -- The Edge Function will:
  -- 1. Check user's notification preferences
  -- 2. Get active device tokens from push_notification_devices
  -- 3. Send FCM notifications to all devices
  -- 4. Record in notifications_history
  -- 5. Deactivate invalid tokens
  SELECT net.http_post(
    url := 'https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key,
      'apikey', v_service_role_key
    ),
    body := jsonb_build_object(
      'user_id', p_user_id::TEXT,
      'notification_type', p_notification_type,
      'title', p_title,
      'body', p_body,
      'data', COALESCE(p_data, '{}'::jsonb)
    )
  ) INTO v_request_id;
  
  -- Log the request ID for debugging
  RAISE NOTICE 'FCM notification queued with request_id: %', v_request_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the transaction
    RAISE WARNING 'Error calling FCM Edge Function: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 2. TRIGGERS FOR USER INTERACTION NOTIFICATIONS
-- ============================================================================

-- ============================================================================
-- 2.1 New Comment on Post (top-level comments only)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_new_comment()
RETURNS TRIGGER AS $$
DECLARE
  v_post_owner_id UUID;
  v_commenter_username TEXT;
  v_post_content TEXT;
BEGIN
  -- Get post owner and commenter info
  SELECT p.user_id, prof.username, SUBSTRING(p.content, 1, 50)
  INTO v_post_owner_id, v_commenter_username, v_post_content
  FROM public.posts p
  INNER JOIN public.profiles prof ON prof.id = NEW.user_id
  WHERE p.id = NEW.post_id;

  -- Don't notify if commenter is the post owner
  IF v_post_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Check if user is blocked (if blocked_users table exists)
  -- IF public.is_user_blocked(v_post_owner_id, NEW.user_id) THEN
  --   RETURN NEW;
  -- END IF;

  -- Send notification via Edge Function
  PERFORM public.send_fcm_notification(
    p_user_id := v_post_owner_id,
    p_notification_type := 'new_comment',
    p_title := 'New Comment',
    p_body := v_commenter_username || ' commented on your post',
    p_data := jsonb_build_object(
      'post_id', NEW.post_id::TEXT,
      'comment_id', NEW.id::TEXT,
      'commenter_id', NEW.user_id::TEXT,
      'commenter_username', v_commenter_username,
      'post_content', v_post_content
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_new_comment
  AFTER INSERT ON public.comments
  FOR EACH ROW
  WHEN (NEW.parent_id IS NULL) -- Only for top-level comments
  EXECUTE FUNCTION public.notify_new_comment();

-- ============================================================================
-- 2.2 Reply to Comment
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_reply_to_comment()
RETURNS TRIGGER AS $$
DECLARE
  v_parent_comment_owner_id UUID;
  v_replier_username TEXT;
  v_post_content TEXT;
BEGIN
  -- Only process if this is a reply (has parent_id)
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get parent comment owner, replier info, and post content
  SELECT c.user_id, prof.username, LEFT(p.content, 100)
  INTO v_parent_comment_owner_id, v_replier_username, v_post_content
  FROM public.comments c
  INNER JOIN public.profiles prof ON prof.id = NEW.user_id
  INNER JOIN public.posts p ON p.id = NEW.post_id
  WHERE c.id = NEW.parent_id;

  -- Don't notify if replier is the parent comment owner
  IF v_parent_comment_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Check if user is blocked
  -- IF public.is_user_blocked(v_parent_comment_owner_id, NEW.user_id) THEN
  --   RETURN NEW;
  -- END IF;

  -- Send notification via Edge Function
  PERFORM public.send_fcm_notification(
    p_user_id := v_parent_comment_owner_id,
    p_notification_type := 'reply_to_comment',
    p_title := 'New Reply',
    p_body := v_replier_username || ' replied to your comment',
    p_data := jsonb_build_object(
      'post_id', NEW.post_id::TEXT,
      'comment_id', NEW.id::TEXT,
      'parent_comment_id', NEW.parent_id::TEXT,
      'replier_id', NEW.user_id::TEXT,
      'replier_username', v_replier_username,
      'post_content', v_post_content
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_reply_to_comment
  AFTER INSERT ON public.comments
  FOR EACH ROW
  WHEN (NEW.parent_id IS NOT NULL) -- Only for replies
  EXECUTE FUNCTION public.notify_reply_to_comment();

-- ============================================================================
-- 2.3 Post Upvote (every 5th vote milestone)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_post_upvote()
RETURNS TRIGGER AS $$
DECLARE
  v_post_owner_id UUID;
  v_voter_username TEXT;
  v_post_upvotes INTEGER;
  v_post_content TEXT;
  v_vote_threshold INTEGER := 5; -- Notify every 5 votes
BEGIN
  -- Only notify for upvotes
  IF NEW.vote_type != 'upvote' THEN
    RETURN NEW;
  END IF;

  -- Get post owner, voter info, upvote count, and post content
  SELECT p.user_id, prof.username, p.upvote_count, LEFT(p.content, 100)
  INTO v_post_owner_id, v_voter_username, v_post_upvotes, v_post_content
  FROM public.posts p
  INNER JOIN public.profiles prof ON prof.id = NEW.user_id
  WHERE p.id = NEW.post_id;

  -- Don't notify if voter is the post owner
  IF v_post_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Check if user is blocked
  -- IF public.is_user_blocked(v_post_owner_id, NEW.user_id) THEN
  --   RETURN NEW;
  -- END IF;

  -- Only notify on milestones (every 5th vote)
  IF v_post_upvotes % v_vote_threshold = 0 THEN
    PERFORM public.send_fcm_notification(
      p_user_id := v_post_owner_id,
      p_notification_type := 'post_upvote',
      p_title := 'Post Upvoted',
      p_body := v_voter_username || ' upvoted your post',
      p_data := jsonb_build_object(
        'post_id', NEW.post_id::TEXT,
        'voter_id', NEW.user_id::TEXT,
        'voter_username', v_voter_username,
        'upvote_count', v_post_upvotes,
        'post_content', v_post_content
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_post_upvote
  AFTER INSERT ON public.post_votes
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_post_upvote();

-- ============================================================================
-- 2.4 Comment Upvote
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_comment_upvote()
RETURNS TRIGGER AS $$
DECLARE
  v_comment_owner_id UUID;
  v_voter_username TEXT;
  v_post_id UUID;
  v_post_content TEXT;
  v_comment_content TEXT;
BEGIN
  -- Only notify for upvotes
  IF NEW.vote_type != 'upvote' THEN
    RETURN NEW;
  END IF;

  -- Get comment owner, voter info, post_id, post content, and comment content
  SELECT c.user_id, prof.username, c.post_id, LEFT(p.content, 100), LEFT(c.content, 100)
  INTO v_comment_owner_id, v_voter_username, v_post_id, v_post_content, v_comment_content
  FROM public.comments c
  INNER JOIN public.profiles prof ON prof.id = NEW.user_id
  INNER JOIN public.posts p ON p.id = c.post_id
  WHERE c.id = NEW.comment_id;

  -- Don't notify if voter is the comment owner
  IF v_comment_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Check if user is blocked
  -- IF public.is_user_blocked(v_comment_owner_id, NEW.user_id) THEN
  --   RETURN NEW;
  -- END IF;

  -- Send notification via Edge Function
  PERFORM public.send_fcm_notification(
    p_user_id := v_comment_owner_id,
    p_notification_type := 'comment_upvote',
    p_title := 'Comment Upvoted',
    p_body := v_voter_username || ' upvoted your comment',
    p_data := jsonb_build_object(
      'comment_id', NEW.comment_id::TEXT,
      'post_id', v_post_id::TEXT,
      'voter_id', NEW.user_id::TEXT,
      'voter_username', v_voter_username,
      'post_content', v_post_content,
      'comment_content', v_comment_content
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_comment_upvote
  AFTER INSERT ON public.comment_votes
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_comment_upvote();

-- ============================================================================
-- 2.5 Mention in Comment (already tracked in mentions table)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_mention_in_comment()
RETURNS TRIGGER AS $$
DECLARE
  v_mentioner_username TEXT;
  v_post_content TEXT;
BEGIN
  -- Don't notify if user mentioned themselves
  IF NEW.mentioned_user_id = NEW.mentioner_user_id THEN
    RETURN NEW;
  END IF;

  -- Get mentioner username and post content
  SELECT prof.username, LEFT(p.content, 100)
  INTO v_mentioner_username, v_post_content
  FROM public.profiles prof
  INNER JOIN public.posts p ON p.id = NEW.post_id
  WHERE prof.id = NEW.mentioner_user_id;

  -- Send notification via Edge Function
  PERFORM public.send_fcm_notification(
    p_user_id := NEW.mentioned_user_id,
    p_notification_type := 'mention_in_comment',
    p_title := 'You were mentioned',
    p_body := v_mentioner_username || ' mentioned you in a comment',
    p_data := jsonb_build_object(
      'comment_id', NEW.comment_id::TEXT,
      'post_id', NEW.post_id::TEXT,
      'mentioner_id', NEW.mentioner_user_id::TEXT,
      'mentioner_username', v_mentioner_username,
      'post_content', v_post_content
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_mention_in_comment
  AFTER INSERT ON public.mentions
  FOR EACH ROW
  WHEN (NEW.comment_id IS NOT NULL)
  EXECUTE FUNCTION public.notify_mention_in_comment();

-- ============================================================================
-- 3. TRIGGERS FOR POST ACHIEVEMENT NOTIFICATIONS
-- ============================================================================

-- ============================================================================
-- 3.1 Post Getting Hot (is_trending changes to true)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_post_hot()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify when is_trending changes from false to true
  IF OLD.is_trending = FALSE AND NEW.is_trending = TRUE THEN
    PERFORM public.send_fcm_notification(
      p_user_id := NEW.user_id,
      p_notification_type := 'post_hot',
      p_title := 'Your post is getting hot!',
      p_body := 'Your post is getting hot and trending',
      p_data := jsonb_build_object(
        'post_id', NEW.id::TEXT,
        'post_content', LEFT(NEW.content, 100)
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_post_hot
  AFTER UPDATE OF is_trending ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_post_hot();

-- ============================================================================
-- 3.2 Post Reaching Top Posts (engagement milestone)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_post_achievement()
RETURNS TRIGGER AS $$
DECLARE
  v_achievement_type TEXT;
  v_achievement_title TEXT;
  v_achievement_body TEXT;
BEGIN
  -- Check if post reached high engagement (hot)
  IF OLD.engagement_score < 50 AND NEW.engagement_score >= 50 THEN
    v_achievement_type := 'post_hot';
    v_achievement_title := 'Your post is getting hot!';
    v_achievement_body := 'Your post is getting hot and trending';
  
  -- Check if post reached top (high net score)
  ELSIF (NEW.upvote_count - NEW.downvote_count) >= 100 AND 
        (OLD.upvote_count - OLD.downvote_count) < 100 THEN
    v_achievement_type := 'post_top';
    v_achievement_title := 'Your post reached Top Posts this week!';
    v_achievement_body := 'Your post made it to the monthly spotlight';
  ELSE
    -- No achievement reached
    RETURN NEW;
  END IF;

  -- Send achievement notification via Edge Function
  PERFORM public.send_fcm_notification(
    p_user_id := NEW.user_id,
    p_notification_type := v_achievement_type,
    p_title := v_achievement_title,
    p_body := v_achievement_body,
    p_data := jsonb_build_object(
      'post_id', NEW.id::TEXT,
      'upvote_count', NEW.upvote_count,
      'comment_count', NEW.comment_count,
      'engagement_score', NEW.engagement_score,
      'post_content', LEFT(NEW.content, 100)
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_post_achievement
  AFTER UPDATE OF engagement_score, upvote_count, downvote_count ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_post_achievement();

-- ============================================================================
-- 4. TRIGGERS FOR MODERATION/SYSTEM NOTIFICATIONS
-- ============================================================================

-- ============================================================================
-- 4.1 Account Status Change (Suspension/Reactivation)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_account_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Notify when account_status changes to suspended
  IF OLD.account_status != 'suspended' AND NEW.account_status = 'suspended' THEN
    PERFORM public.send_fcm_notification(
      p_user_id := NEW.id,
      p_notification_type := 'account_suspended',
      p_title := 'Account Suspended',
      p_body := 'Your account has been suspended due to policy violations. Contact support for more information.',
      p_data := jsonb_build_object(
        'user_id', NEW.id,
        'previous_status', OLD.account_status,
        'new_status', NEW.account_status
      )
    );
  
  -- Notify when account is reactivated
  ELSIF OLD.account_status = 'suspended' AND NEW.account_status = 'active' THEN
    PERFORM public.send_fcm_notification(
      p_user_id := NEW.id,
      p_notification_type := 'account_reactivated',
      p_title := 'Account Reactivated',
      p_body := 'Welcome back! Your account has been reactivated.',
      p_data := jsonb_build_object(
        'user_id', NEW.id,
        'previous_status', OLD.account_status,
        'new_status', NEW.account_status
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_account_status_change
  AFTER UPDATE OF account_status ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_account_status_change();

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. ⚠️ This file will REPLACE the existing triggers from migration 20241112000015
--    You must DROP the old triggers before running this file to avoid conflicts
--
-- 2. This approach uses pg_net to call the Edge Function directly when events occur
--    The Edge Function then sends FCM and records in notifications_history
--
-- 3. Setup requirements:
--    a) Enable pg_net: CREATE EXTENSION IF NOT EXISTS pg_net;
--    b) Service role key is embedded in send_fcm_notification() function
--
-- 4. To drop existing triggers, run:
--    DROP TRIGGER IF EXISTS trigger_notify_post_reply ON public.comments;
--    DROP TRIGGER IF EXISTS trigger_notify_comment_reply ON public.comments;
--    DROP TRIGGER IF EXISTS trigger_notify_post_vote ON public.post_votes;
--    DROP TRIGGER IF EXISTS trigger_notify_post_achievement ON public.posts;
--    DROP TRIGGER IF EXISTS trigger_notify_account_status_change ON public.profiles;
--
-- 5. Alternative: Keep the existing triggers from migration 20241112000015 and
--    create a cron job to periodically call send-push-notification for unsent
--    notifications (where sent_at IS NULL)
-- ============================================================================