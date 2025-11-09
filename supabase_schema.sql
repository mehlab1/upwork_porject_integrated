-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.account_deactivations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  reason_type USER-DEFINED NOT NULL,
  reason_text text CHECK (reason_text IS NULL OR char_length(reason_text) >= 10 AND char_length(reason_text) <= 500),
  deactivated_at timestamp with time zone DEFAULT now(),
  reactivated_at timestamp with time zone,
  is_active boolean DEFAULT true,
  CONSTRAINT account_deactivations_pkey PRIMARY KEY (id),
  CONSTRAINT account_deactivations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name character varying NOT NULL UNIQUE,
  slug character varying NOT NULL UNIQUE,
  description text,
  icon_url text,
  is_active boolean NOT NULL DEFAULT true,
  display_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.comment_reports (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  comment_id uuid NOT NULL,
  user_id uuid NOT NULL,
  reason text NOT NULL CHECK (reason = ANY (ARRAY['spam'::text, 'harassment'::text, 'inappropriate'::text, 'misinformation'::text, 'other'::text])),
  description text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'reviewed'::text, 'resolved'::text, 'dismissed'::text])),
  admin_notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  resolved_at timestamp with time zone,
  resolved_by uuid,
  CONSTRAINT comment_reports_pkey PRIMARY KEY (id),
  CONSTRAINT comment_reports_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id),
  CONSTRAINT comment_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT comment_reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.comment_votes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  comment_id uuid NOT NULL,
  user_id uuid NOT NULL,
  vote_type text NOT NULL CHECK (vote_type = ANY (ARRAY['upvote'::text, 'downvote'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT comment_votes_pkey PRIMARY KEY (id),
  CONSTRAINT comment_votes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id),
  CONSTRAINT comment_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.comments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  post_id uuid NOT NULL,
  user_id uuid NOT NULL,
  parent_id uuid,
  content text NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 500),
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'deleted'::text, 'hidden'::text])),
  upvote_count integer NOT NULL DEFAULT 0,
  downvote_count integer NOT NULL DEFAULT 0,
  reply_count integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  report_count integer NOT NULL DEFAULT 0,
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id)
);
CREATE TABLE public.hot_topics (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  description text,
  hashtag text,
  category_id uuid,
  location_id uuid,
  is_active boolean NOT NULL DEFAULT false,
  start_date timestamp with time zone NOT NULL DEFAULT now(),
  end_date timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT hot_topics_pkey PRIMARY KEY (id),
  CONSTRAINT hot_topics_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
  CONSTRAINT hot_topics_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id)
);
CREATE TABLE public.locations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name character varying NOT NULL,
  slug character varying NOT NULL UNIQUE,
  country character varying NOT NULL DEFAULT 'Nigeria'::character varying,
  state character varying,
  city character varying,
  latitude numeric,
  longitude numeric,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT locations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.mentions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  comment_id uuid NOT NULL,
  post_id uuid NOT NULL,
  mentioned_user_id uuid NOT NULL,
  mentioner_user_id uuid NOT NULL,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  read_at timestamp with time zone,
  CONSTRAINT mentions_pkey PRIMARY KEY (id),
  CONSTRAINT mentions_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id),
  CONSTRAINT mentions_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT mentions_mentioned_user_id_fkey FOREIGN KEY (mentioned_user_id) REFERENCES public.profiles(id),
  CONSTRAINT mentions_mentioner_user_id_fkey FOREIGN KEY (mentioner_user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.otp_verifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  email text,
  phone text,
  otp_code text NOT NULL,
  otp_type text NOT NULL CHECK (otp_type = ANY (ARRAY['email'::text, 'phone'::text, 'password_reset'::text])),
  verified boolean DEFAULT false,
  attempts integer DEFAULT 0,
  max_attempts integer DEFAULT 5,
  expires_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  verified_at timestamp with time zone,
  CONSTRAINT otp_verifications_pkey PRIMARY KEY (id),
  CONSTRAINT otp_verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.post_reports (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  post_id uuid NOT NULL,
  reported_by uuid NOT NULL,
  reason USER-DEFINED NOT NULL,
  description text CHECK (description IS NULL OR char_length(description) >= 10 AND char_length(description) <= 500),
  status USER-DEFINED NOT NULL DEFAULT 'pending'::report_status,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  resolution_notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT post_reports_pkey PRIMARY KEY (id),
  CONSTRAINT post_reports_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT post_reports_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES public.profiles(id),
  CONSTRAINT post_reports_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.post_votes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  post_id uuid NOT NULL,
  user_id uuid NOT NULL,
  vote_type USER-DEFINED NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT post_votes_pkey PRIMARY KEY (id),
  CONSTRAINT post_votes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id),
  CONSTRAINT post_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.posts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  category_id uuid,
  location_id uuid,
  content text NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 1000),
  image_url text,
  status USER-DEFINED NOT NULL DEFAULT 'active'::post_status,
  upvote_count integer NOT NULL DEFAULT 0,
  downvote_count integer NOT NULL DEFAULT 0,
  comment_count integer NOT NULL DEFAULT 0,
  engagement_score numeric NOT NULL DEFAULT 0,
  report_count integer NOT NULL DEFAULT 0,
  is_trending boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  hot_topic_id uuid,
  is_monthly_spotlight boolean DEFAULT false,
  CONSTRAINT posts_pkey PRIMARY KEY (id),
  CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT posts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
  CONSTRAINT posts_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id),
  CONSTRAINT posts_hot_topic_id_fkey FOREIGN KEY (hot_topic_id) REFERENCES public.hot_topics(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username character varying NOT NULL UNIQUE CHECK (char_length(username::text) >= 3),
  gender USER-DEFINED,
  birthday date NOT NULL CHECK (birthday <= (CURRENT_DATE - '13 years'::interval)),
  role USER-DEFINED NOT NULL DEFAULT 'user'::user_role,
  account_status USER-DEFINED NOT NULL DEFAULT 'active'::account_status,
  total_posts integer NOT NULL DEFAULT 0,
  total_upvotes_received integer NOT NULL DEFAULT 0,
  terms_accepted boolean NOT NULL DEFAULT false,
  privacy_accepted boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  otp_verified boolean DEFAULT false,
  otp_verified_at timestamp with time zone,
  profile_picture_url text,
  bio text,
  username_last_updated timestamp with time zone,
  is_deactivated boolean DEFAULT false,
  deactivated_at timestamp with time zone,
  deactivation_reason USER-DEFINED,
  is_early_adopter boolean DEFAULT false,
  early_adopter_number integer,
  badge_assigned_at timestamp with time zone,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.user_feedback (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  feedback_type USER-DEFINED NOT NULL,
  message text NOT NULL CHECK (char_length(message) >= 10 AND char_length(message) <= 2000),
  status USER-DEFINED DEFAULT 'pending'::feedback_status,
  admin_notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  resolved_at timestamp with time zone,
  CONSTRAINT user_feedback_pkey PRIMARY KEY (id),
  CONSTRAINT user_feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);