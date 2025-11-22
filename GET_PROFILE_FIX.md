# 🚀 Get-Profile Function - 2-Minute Fix

## ⚠️ Error
```
structure of query does not match function result type
Status: 500 Internal Server Error
```

## 🔍 Step 1: Test with Postman (30 seconds)

**Request:**
- **Method**: `POST`
- **URL**: `https://wvkyzhnzwijfxpzsrguj.supabase.co/functions/v1/get-profile`
- **Headers**:
  ```
  Content-Type: application/json
  apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2a3l6aG56d2lqZnhwenNyZ3VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDI5OTksImV4cCI6MjA3NzY3ODk5OX0.k4Z4MgL0jOahkkO3MKgINRM6rNJ6g7Mwsv8NE2TFmyY
  Authorization: Bearer YOUR_ACCESS_TOKEN
  ```
- **Body**: `{}`

**Expected Response:**
```json
{
  "success": true,
  "profile": {
    "id": "...",
    "username": "...",
    "post_count": 0,
    ...
  }
}
```

## ✅ Step 2: The EXACT Fix (90 seconds)

### **Most Likely Cause:**
Your edge function calls a PostgreSQL RPC function that has `RETURNS SETOF profiles`, but the query returns extra columns (like `post_count` from a JOIN).

### **Solution A: Fix the Edge Function (RECOMMENDED)**

Go to **Supabase Dashboard → Edge Functions → get-profile**

Replace the function code with this:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { data: { user } } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ success: false, message: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ✅ FIX: Query profiles directly (no RPC function)
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError) throw profileError

    // Get post count separately
    const { count } = await supabaseClient
      .from('posts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)

    return new Response(
      JSON.stringify({
        success: true,
        profile: {
          ...profile,
          post_count: count || 0,
        },
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Failed to fetch profile',
        details: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

### **Solution B: If you MUST use an RPC function**

Go to **Supabase Dashboard → SQL Editor** and run:

```sql
-- Drop the old function if it exists
DROP FUNCTION IF EXISTS get_user_profile(UUID);

-- Create new function that returns JSON (not SETOF profiles)
CREATE OR REPLACE FUNCTION get_user_profile(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_profile JSON;
  v_post_count INTEGER;
BEGIN
  -- Get profile
  SELECT row_to_json(p.*) INTO v_profile
  FROM profiles p
  WHERE p.id = p_user_id;
  
  -- Get post count
  SELECT COUNT(*) INTO v_post_count
  FROM posts
  WHERE user_id = p_user_id;
  
  -- Return JSON with post_count included
  RETURN json_build_object(
    'id', (v_profile->>'id')::UUID,
    'username', v_profile->>'username',
    'post_count', v_post_count,
    'total_posts', (v_profile->>'total_posts')::INTEGER,
    'total_upvotes_received', (v_profile->>'total_upvotes_received')::INTEGER,
    'bio', v_profile->>'bio',
    'avatar_url', v_profile->>'avatar_url',
    'profile_picture_url', v_profile->>'profile_picture_url',
    'display_name', v_profile->>'display_name',
    'location_id', v_profile->>'location_id',
    'created_at', v_profile->>'created_at',
    'updated_at', v_profile->>'updated_at',
    'is_new_user', (v_profile->>'is_new_user')::BOOLEAN,
    'reward_points', (v_profile->>'reward_points')::INTEGER,
    'badges', v_profile->'badges',
    'interests', v_profile->'interests',
    'gender', v_profile->>'gender',
    'birthday', v_profile->>'birthday',
    'role', v_profile->>'role',
    'account_status', v_profile->>'account_status',
    'otp_verified', (v_profile->>'otp_verified')::BOOLEAN,
    'account_type', v_profile->>'account_type'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Then update your edge function to handle JSON response:
```typescript
const { data, error } = await supabaseClient.rpc('get_user_profile', { 
  p_user_id: user.id 
})

if (error) throw error

return new Response(
  JSON.stringify({
    success: true,
    profile: data, // Already includes post_count
  }),
  { headers: { 'Content-Type': 'application/json' } }
)
```

## 🎯 Why This Works

The error happens because:
- ❌ Function defined as `RETURNS SETOF profiles` (only profile columns)
- ❌ Query returns `profiles.*` + `post_count` (extra column)
- ✅ **Fix**: Return `JSON` type OR query directly without RPC

## ✅ Step 3: Test Again

1. Deploy the edge function
2. Test in Postman → Should return 200
3. Test in Flutter app → Should work!

**Total time: ~2 minutes** ⏱️

