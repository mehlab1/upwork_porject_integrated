get Profile :
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-profile
Code : 
// =====================================================
// Edge Function: Get User Profile
// Task: ADO-966
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get viewer (current user) if authenticated
    const authHeader = req.headers.get("Authorization") || "";
    const accessToken = authHeader.startsWith("Bearer ")
      ? authHeader.substring("Bearer ".length)
      : "";

    let viewerId: string | null = null;

    if (accessToken) {
      const {
        data: { user },
      } = await supabaseClient.auth.getUser(accessToken);
      if (user) {
        viewerId = user.id;
      }
    }

    // Get user_id from query params or body
    let userId: string | null = null;
    let includePosts = false;
    let postsLimit = 20;
    let postsOffset = 0;

    if (req.method === "GET") {
      const url = new URL(req.url);
      userId = url.searchParams.get("user_id");
      includePosts = url.searchParams.get("include_posts") === "true";
      postsLimit = parseInt(url.searchParams.get("limit") || "20");
      postsOffset = parseInt(url.searchParams.get("offset") || "0");
    } else if (req.method === "POST") {
      const body = await req.json();
      userId = body.user_id;
      includePosts = body.include_posts || false;
      postsLimit = body.limit || 20;
      postsOffset = body.offset || 0;
    }

    // If no user_id provided, use viewer's ID (view own profile)
    if (!userId) {
      if (!viewerId) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "User ID is required or you must be authenticated",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      userId = viewerId;
    }

    console.log(`[PROFILE] Fetching profile for user: ${userId} (viewer: ${viewerId || 'anonymous'})`);

    // Get user profile with stats
    const { data: profile, error: profileError } = await supabaseClient
      .rpc("get_user_profile", {
        p_user_id: userId,
        p_viewer_id: viewerId,
      })
      .single();

    if (profileError) {
      console.error("[PROFILE] Error fetching profile:", profileError);
      
      if (profileError.message.includes("not found")) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "User profile not found",
          }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          message: "Failed to fetch profile",
          details: profileError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[PROFILE] Found profile: ${profile.username} (${profile.post_count} posts, ${profile.total_upvotes} upvotes)`);

    const response: any = {
      success: true,
      profile,
    };

    // Optionally include user's posts
    if (includePosts) {
      const { data: posts, error: postsError } = await supabaseClient
        .rpc("get_user_posts", {
          p_user_id: userId,
          p_viewer_id: viewerId,
          p_limit: postsLimit,
          p_offset: postsOffset,
        });

      if (postsError) {
        console.error("[PROFILE] Error fetching user posts:", postsError);
      } else {
        response.posts = posts || [];
        console.log(`[PROFILE] Fetched ${posts?.length || 0} user posts`);
      }
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[PROFILE] Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        message: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Get user's posts : 
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-user-posts
Code : 
// Supabase Edge Function: Get User Posts with Full Details
// Returns all posts for a specific user including comments and vote counts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface GetUserPostsRequest {
  user_id: string;
  limit?: number;
  offset?: number;
}

interface ErrorResponse {
  success: false;
  error: string;
  details?: string;
}

interface SuccessResponse {
  success: true;
  user_id: string;
  total_posts: number;
  posts: Post[];
}

interface Post {
  id: string;
  user_id: string;
  username: string;
  avatar_url: string | null;
  profile_picture_url: string | null;
  category_id: string | null;
  category_name: string | null;
  location_id: string | null;
  location_name: string | null;
  content: string;
  image_url: string | null;
  status: string;
  upvote_count: number;
  downvote_count: number;
  net_score: number;
  comment_count: number;
  engagement_score: number;
  user_vote: string | null;
  has_reported: boolean;
  created_at: string;
  updated_at: string;
  comments: Comment[];
}

interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  username: string;
  avatar_url: string | null;
  parent_id: string | null;
  content: string;
  upvote_count: number;
  downvote_count: number;
  net_score: number;
  reply_count: number;
  user_vote: string | null;
  created_at: string;
  updated_at: string;
  replies: Comment[];
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    let viewerId: string | null = null;

    // Extract viewer ID from JWT if authenticated
    if (authHeader) {
      const token = authHeader.replace("Bearer ", "");
      const {
        data: { user },
        error: authError,
      } = await supabase.auth.getUser(token);

      if (!authError && user) {
        viewerId = user.id;
        console.log(`[GET_USER_POSTS] Authenticated viewer: ${viewerId}`);
      }
    }

    // Parse request body
    const requestData: GetUserPostsRequest = await req.json();

    // Validate required fields
    if (!requestData.user_id) {
      console.error("[GET_USER_POSTS] Missing user_id");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing required field: user_id",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const limit = requestData.limit || 20;
    const offset = requestData.offset || 0;

    console.log(
      `[GET_USER_POSTS] Fetching posts for user ${requestData.user_id}, limit: ${limit}, offset: ${offset}`
    );

    // Get user posts with full details
    const { data: postsData, error: postsError } = await supabase.rpc(
      "get_user_posts_with_comments",
      {
        p_user_id: requestData.user_id,
        p_viewer_id: viewerId,
        p_limit: limit,
        p_offset: offset,
      }
    );

    if (postsError) {
      console.error("[GET_USER_POSTS] Database error:", postsError);
      
      // Check if it's a "function does not exist" error
      if (postsError.message?.includes("does not exist")) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "Database function not found. Please run migration 20241122000002_get_user_posts_with_comments.sql",
            details: postsError.message,
          } as ErrorResponse),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          error: "Failed to fetch user posts",
          details: postsError.message,
        } as ErrorResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!postsData || postsData.length === 0) {
      console.log(`[GET_USER_POSTS] No posts found for user ${requestData.user_id}`);
      return new Response(
        JSON.stringify({
          success: true,
          user_id: requestData.user_id,
          total_posts: 0,
          posts: [],
        } as SuccessResponse),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[GET_USER_POSTS] Retrieved ${postsData.length} posts with comments`
    );

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        user_id: requestData.user_id,
        total_posts: postsData.length,
        posts: postsData,
      } as SuccessResponse),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[GET_USER_POSTS] Unexpected error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: "An unexpected error occurred",
        details: error instanceof Error ? error.message : String(error),
      } as ErrorResponse),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Get Upvoted Posts :
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-upvoted-posts
Code : 
// Supabase Edge Function: Get Upvoted Posts
// Returns all posts that a user has upvoted with complete post information

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ErrorResponse {
  success: false;
  error: string;
  details?: string;
}

interface SuccessResponse {
  success: true;
  total_upvoted_posts: number;
  posts: any[];
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing authorization header",
        } as ErrorResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create client with auth context
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // Extract and verify user
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("[GET_UPVOTED_POSTS] Authentication failed:", authError);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Unauthorized",
        } as ErrorResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[GET_UPVOTED_POSTS] User ${user.id} requesting upvoted posts`);

    // Parse query parameters
    const url = new URL(req.url);
    const limit = parseInt(url.searchParams.get("limit") || "20");
    const offset = parseInt(url.searchParams.get("offset") || "0");

    // Validate pagination parameters
    if (limit < 1 || limit > 100) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Limit must be between 1 and 100",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (offset < 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Offset must be 0 or greater",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call database function to get upvoted posts
    const { data: result, error: fetchError } = await supabase.rpc(
      "get_upvoted_posts",
      {
        p_user_id: user.id,
        p_viewer_id: user.id,
        p_limit: limit,
        p_offset: offset,
      }
    );

    if (fetchError) {
      console.error("[GET_UPVOTED_POSTS] Database error:", fetchError);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Failed to fetch upvoted posts",
          details: fetchError.message,
        } as ErrorResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse the JSON result
    const posts = Array.isArray(result) ? result : [];
    
    console.log(
      `[GET_UPVOTED_POSTS] Found ${posts.length} upvoted posts for user ${user.id}`
    );

    // Get total count of upvoted posts
    const { count: totalCount, error: countError } = await supabase
      .from("post_votes")
      .select("*", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("vote_type", "upvote");

    const total = totalCount ?? posts.length;

    return new Response(
      JSON.stringify({
        success: true,
        total_upvoted_posts: total,
        posts: posts,
      } as SuccessResponse),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[GET_UPVOTED_POSTS] Unexpected error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: "An unexpected error occurred",
        details: error instanceof Error ? error.message : String(error),
      } as ErrorResponse),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Update Username : 
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-username
Code : 
// Supabase Edge Function: Update Username Only
// Enforces 30-day cooldown between username changes

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface UpdateUsernameRequest {
  username: string;
}

interface ErrorResponse {
  success: false;
  error: string;
  details?: string;
  username_can_update_at?: string;
}

interface SuccessResponse {
  success: true;
  message: string;
  username: string;
  profile: any;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing authorization header",
        } as ErrorResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create client with auth context
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // Extract and verify user
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("[UPDATE_USERNAME] Authentication failed:", authError);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Unauthorized",
        } as ErrorResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[UPDATE_USERNAME] User ${user.id} attempting username update`);

    // Parse request body
    const requestData: UpdateUsernameRequest = await req.json();

    // Validate required field
    if (!requestData.username) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing required field: username",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { username } = requestData;

    // Validate username length
    if (username.length < 3 || username.length > 50) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Username must be between 3 and 50 characters",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate username format (alphanumeric and underscore only)
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(username)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Username can only contain letters, numbers, and underscores",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Update username using database function
    console.log(`[UPDATE_USERNAME] Calling update_user_profile for user ${user.id} with username: ${username}`);
    
    const { data: result, error: updateError } = await supabase
      .rpc("update_user_profile", {
        p_user_id: user.id,
        p_username: username,
      })
      .single();

    console.log(`[UPDATE_USERNAME] RPC result:`, { result, updateError });

    if (updateError) {
      console.error("[UPDATE_USERNAME] Database error:", updateError);

      // Check for username taken error
      if (updateError.message.includes("already taken")) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "Username is already taken",
          } as ErrorResponse),
          {
            status: 409,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          error: "Failed to update username",
          details: updateError.message,
        } as ErrorResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check if username cooldown blocked the update
    console.log(`[UPDATE_USERNAME] Checking result.success:`, result?.success);
    
    if (result && !result.success) {
      console.log(
        `[UPDATE_USERNAME] Username cooldown active for user ${user.id}`
      );
      return new Response(
        JSON.stringify({
          success: false,
          error: result.message,
          username_can_update_at: result.username_can_update_at,
        } as ErrorResponse),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[UPDATE_USERNAME] Username updated successfully for user ${user.id} to: ${username}`
    );

    // Get updated profile
    const { data: updatedProfile } = await supabase
      .rpc("get_user_profile", {
        p_user_id: user.id,
        p_viewer_id: user.id,
      })
      .single();

    return new Response(
      JSON.stringify({
        success: true,
        message: "Username updated successfully",
        username: username,
        profile: updatedProfile,
      } as SuccessResponse),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[UPDATE_USERNAME] Unexpected error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: "An unexpected error occurred",
        details: error instanceof Error ? error.message : String(error),
      } as ErrorResponse),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Update Birthday : 
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-birthday
Code : 
// Supabase Edge Function: Update Birthday Only
// No cooldown for birthday updates (can be updated anytime)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface UpdateBirthdayRequest {
  birthday: string; // Format: YYYY-MM-DD
}

interface ErrorResponse {
  success: false;
  error: string;
  details?: string;
}

interface SuccessResponse {
  success: true;
  message: string;
  birthday: string;
  profile: any;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing authorization header",
        } as ErrorResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create client with auth context
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // Extract and verify user
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("[UPDATE_BIRTHDAY] Authentication failed:", authError);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Unauthorized",
        } as ErrorResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[UPDATE_BIRTHDAY] User ${user.id} attempting birthday update`);

    // Parse request body
    const requestData: UpdateBirthdayRequest = await req.json();

    // Validate required field
    if (!requestData.birthday) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing required field: birthday",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { birthday } = requestData;

    // Validate birthday format (YYYY-MM-DD)
    const birthdayRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!birthdayRegex.test(birthday)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Birthday must be in YYYY-MM-DD format",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate birthday is not in the future
    const birthdayDate = new Date(birthday);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    if (birthdayDate > today) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Birthday cannot be in the future",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate age (must be at least 13 years old)
    const minAgeDate = new Date();
    minAgeDate.setFullYear(minAgeDate.getFullYear() - 13);
    
    if (birthdayDate > minAgeDate) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "You must be at least 13 years old",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate reasonable age (not older than 120 years)
    const maxAgeDate = new Date();
    maxAgeDate.setFullYear(maxAgeDate.getFullYear() - 120);
    
    if (birthdayDate < maxAgeDate) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Birthday must be within the last 120 years",
        } as ErrorResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Update birthday using database function
    const { data: result, error: updateError } = await supabase
      .rpc("update_user_profile", {
        p_user_id: user.id,
        p_birthday: birthday,
      })
      .single();

    if (updateError) {
      console.error("[UPDATE_BIRTHDAY] Database error:", updateError);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Failed to update birthday",
          details: updateError.message,
        } as ErrorResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[UPDATE_BIRTHDAY] Birthday updated successfully for user ${user.id} to: ${birthday}`
    );

    // Get updated profile
    const { data: updatedProfile } = await supabase
      .rpc("get_user_profile", {
        p_user_id: user.id,
        p_viewer_id: user.id,
      })
      .single();

    return new Response(
      JSON.stringify({
        success: true,
        message: "Birthday updated successfully",
        birthday: birthday,
        profile: updatedProfile,
      } as SuccessResponse),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[UPDATE_BIRTHDAY] Unexpected error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: "An unexpected error occurred",
        details: error instanceof Error ? error.message : String(error),
      } as ErrorResponse),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Update Notification Prefrences : 
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/update-notification-preferences
Code : 
// =====================================================
// Edge Function: Update Notification Preferences
// Task: ADO-1220
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface UpdatePreferencesRequest {
  push_notifications_enabled?: boolean;
  post_reply_enabled?: boolean;
  comment_reply_enabled?: boolean;
  post_vote_enabled?: boolean;
  comment_vote_enabled?: boolean;
  mention_enabled?: boolean;
  post_achievement_enabled?: boolean;
  account_status_enabled?: boolean;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get authenticated user
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const requestData: UpdatePreferencesRequest = await req.json();

    console.log(
      `[UPDATE_PREFERENCES] User ${user.id} updating notification preferences`
    );

    // Update preferences
    const { data: preferences, error: updateError } = await supabaseClient
      .from("notification_preferences")
      .update({
        ...requestData,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", user.id)
      .select()
      .single();

    if (updateError) {
      console.error("[UPDATE_PREFERENCES] Error:", updateError);
      return new Response(
        JSON.stringify({
          error: "Failed to update preferences",
          details: updateError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[UPDATE_PREFERENCES] Preferences updated successfully`);

    return new Response(
      JSON.stringify({
        success: true,
        preferences,
        message: "Notification preferences updated successfully",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[UPDATE_PREFERENCES] Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Submit Feedback : 
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/submit-feedback
Code : // =====================================================
// Edge Function: Submit User Feedback
// Task: ADO-1205
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type FeedbackType = "feedback" | "feature_request" | "bug_report";

interface SubmitFeedbackRequest {
  feedback_type: FeedbackType;
  message: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Authenticate user
    const authHeader = req.headers.get("Authorization") || "";
    const accessToken = authHeader.startsWith("Bearer ")
      ? authHeader.substring("Bearer ".length)
      : "";

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser(accessToken);

    if (authError || !user) {
      console.error("[SUBMIT_FEEDBACK] Authentication failed:", authError);
      return new Response(
        JSON.stringify({ success: false, message: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const requestData: SubmitFeedbackRequest = await req.json();
    const { feedback_type, message } = requestData;

    // Validate input
    if (!feedback_type || !message) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Feedback type and message are required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate feedback type
    const validTypes: FeedbackType[] = ["feedback", "feature_request", "bug_report"];
    if (!validTypes.includes(feedback_type)) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Invalid feedback type. Must be 'feedback', 'feature_request', or 'bug_report'",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate message length
    const trimmedMessage = message.trim();
    if (trimmedMessage.length < 10) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Feedback message must be at least 10 characters",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (trimmedMessage.length > 2000) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Feedback message must be 2000 characters or less",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[SUBMIT_FEEDBACK] User ${user.id} submitting ${feedback_type}`
    );

    // Submit feedback using database function
    const { data: result, error: submitError } = await supabaseClient
      .rpc("submit_user_feedback", {
        p_user_id: user.id,
        p_feedback_type: feedback_type,
        p_message: trimmedMessage,
      })
      .single();

    if (submitError) {
      console.error("[SUBMIT_FEEDBACK] Database error:", submitError);

      // Check for specific error messages
      if (submitError.message.includes("at least 10 characters")) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "Feedback message must be at least 10 characters",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (submitError.message.includes("2000 characters or less")) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "Feedback message must be 2000 characters or less",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          message: "Failed to submit feedback",
          details: submitError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[SUBMIT_FEEDBACK] Feedback submitted successfully by user ${user.id}, ID: ${result.feedback_id}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: result.message,
        feedback_id: result.feedback_id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[SUBMIT_FEEDBACK] Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        message: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Get Blocked Users : 
url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-blocked-users
Code : 
// =====================================================
// Edge Function: Get Blocked Users
// Task: ADO-1358
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Unauthorized",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get pagination parameters from query
    const url = new URL(req.url);
    const limit = parseInt(url.searchParams.get("limit") || "20", 10);
    const offset = parseInt(url.searchParams.get("offset") || "0", 10);

    console.log(`[GET_BLOCKED] Fetching blocked users for ${user.id} (limit: ${limit}, offset: ${offset})`);

    // Call get_blocked_users function
    const { data: blockedUsers, error: fetchError } = await supabaseClient
      .rpc("get_blocked_users", {
        p_user_id: user.id,
        p_limit: limit,
        p_offset: offset,
      })
      .single();

    if (fetchError) {
      console.error("[GET_BLOCKED] Error:", fetchError);
      return new Response(
        JSON.stringify({
          success: false,
          message: "Failed to fetch blocked users",
          details: fetchError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[GET_BLOCKED] Found ${blockedUsers?.length || 0} blocked users`);

    return new Response(
      JSON.stringify({
        success: true,
        blocked_users: blockedUsers || [],
        limit,
        offset,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[GET_BLOCKED] Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        message: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Unblock users : 
Url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/unblock-user
Code : 
// =====================================================
// Edge Function: Unblock User
// Task: ADO-1358
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface UnblockUserRequest {
  blocked_user_id: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Unauthorized",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body: UnblockUserRequest = await req.json();

    if (!body.blocked_user_id) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "blocked_user_id is required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[UNBLOCK_USER] User ${user.id} attempting to unblock ${body.blocked_user_id}`);

    // Call unblock_user function
    const { data: result, error: unblockError } = await supabaseClient
      .rpc("unblock_user", {
        p_blocker_id: user.id,
        p_blocked_id: body.blocked_user_id,
      })
      .single();

    if (unblockError) {
      console.error("[UNBLOCK_USER] Error:", unblockError);
      return new Response(
        JSON.stringify({
          success: false,
          message: "Failed to unblock user",
          details: unblockError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check if operation was successful
    if (!result.success) {
      return new Response(
        JSON.stringify(result),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[UNBLOCK_USER] Success: User ${result.unblocked_user} unblocked`);

    return new Response(
      JSON.stringify(result),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[UNBLOCK_USER] Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        message: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Deactivate account : 
url : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/deactivate-account
Code : 
// =====================================================
// Edge Function: Deactivate Account
// Task: ADO-1206
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type DeactivationReasonType =
  | "privacy_concerns"
  | "not_useful"
  | "too_many_notifications"
  | "found_alternative"
  | "too_much_time"
  | "harassment_issues"
  | "technical_problems"
  | "other";

interface DeactivateAccountRequest {
  reason_type: DeactivationReasonType;
  reason_text?: string;
  confirm: boolean; // User must explicitly confirm
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Authenticate user
    const authHeader = req.headers.get("Authorization") || "";
    const accessToken = authHeader.startsWith("Bearer ")
      ? authHeader.substring("Bearer ".length)
      : "";

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser(accessToken);

    if (authError || !user) {
      console.error("[DEACTIVATE_ACCOUNT] Authentication failed:", authError);
      return new Response(
        JSON.stringify({ success: false, message: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const requestData: DeactivateAccountRequest = await req.json();
    const { reason_type, reason_text, confirm } = requestData;

    // Validate input
    if (!reason_type) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Deactivation reason is required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // User must explicitly confirm deactivation
    if (confirm !== true) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "You must confirm account deactivation",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate reason type
    const validReasons: DeactivationReasonType[] = [
      "privacy_concerns",
      "not_useful",
      "too_many_notifications",
      "found_alternative",
      "too_much_time",
      "harassment_issues",
      "technical_problems",
      "other",
    ];

    if (!validReasons.includes(reason_type)) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Invalid deactivation reason",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate reason text if provided
    if (reason_text) {
      const trimmedText = reason_text.trim();
      if (trimmedText.length < 10) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "Reason text must be at least 10 characters",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (trimmedText.length > 500) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "Reason text must be 500 characters or less",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    console.log(
      `[DEACTIVATE_ACCOUNT] User ${user.id} initiating account deactivation. Reason: ${reason_type}`
    );

    // Deactivate account using database function
    const { data: result, error: deactivateError } = await supabaseClient
      .rpc("deactivate_user_account", {
        p_user_id: user.id,
        p_reason_type: reason_type,
        p_reason_text: reason_text?.trim() || null,
      })
      .single();

    if (deactivateError) {
      console.error("[DEACTIVATE_ACCOUNT] Database error:", deactivateError);

      // Check for specific error messages
      if (deactivateError.message.includes("already deactivated")) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "Your account is already deactivated",
          }),
          {
            status: 409,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (deactivateError.message.includes("at least 10 characters")) {
        return new Response(
          JSON.stringify({
            success: false,
            message: "Reason text must be at least 10 characters",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          message: "Failed to deactivate account",
          details: deactivateError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[DEACTIVATE_ACCOUNT] Account deactivated successfully for user ${user.id}`
    );

    // Sign out the user (invalidate session)
    await supabaseClient.auth.signOut();

    return new Response(
      JSON.stringify({
        success: true,
        message: result.message,
        note: "Your account has been deactivated. You have been logged out.",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[DEACTIVATE_ACCOUNT] Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        message: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

Logout : 
URL : https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/logout
Code : 
// =====================================================
// Edge Function: Logout
// Task: ADO-1207
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Authenticate user
    const authHeader = req.headers.get("Authorization") || "";
    const accessToken = authHeader.startsWith("Bearer ")
      ? authHeader.substring("Bearer ".length)
      : "";

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser(accessToken);

    if (authError || !user) {
      console.error("[LOGOUT] Authentication failed:", authError);
      // Even if authentication fails, return success
      // This handles cases where the token is already invalid
      return new Response(
        JSON.stringify({
          success: true,
          message: "Logged out successfully",
          note: "Session was already invalid or expired",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[LOGOUT] User ${user.id} initiating logout`);

    // Deactivate push notification device tokens (mark as inactive instead of deleting)
    const { error: deactivateError } = await supabaseClient
      .from("push_notification_devices")
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq("user_id", user.id)
      .eq("is_active", true);

    if (deactivateError) {
      console.error("[LOGOUT] Failed to deactivate device tokens:", deactivateError);
      // Don't fail logout if device deactivation fails
    } else {
      console.log(`[LOGOUT] Deactivated push notification devices for user ${user.id}`);
    }

    // Sign out the user (invalidate the session)
    const { error: signOutError } = await supabaseClient.auth.signOut();

    if (signOutError) {
      console.error("[LOGOUT] Sign out error:", signOutError);
      return new Response(
        JSON.stringify({
          success: false,
          message: "Failed to sign out",
          details: signOutError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[LOGOUT] User ${user.id} logged out successfully`);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Logged out successfully",
        user_id: user.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[LOGOUT] Unexpected error:", error);
    
    // Even on error, we should consider logout successful
    // to prevent users from being stuck in a logged-in state
    return new Response(
      JSON.stringify({
        success: true,
        message: "Logged out successfully",
        note: "Session cleared despite error",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});


