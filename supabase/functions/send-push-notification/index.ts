// =====================================================
// Edge Function: Send Push Notification
// Task: ADO-1220
// =====================================================
// Sends push notifications via Firebase Cloud Messaging (FCM)
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SendNotificationRequest {
  user_id: string;
  notification_type: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

// Helper function to get FCM access token using service account
async function getAccessToken(serviceAccount: any): Promise<string> {
  const jwtHeader = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  
  const now = Math.floor(Date.now() / 1000);
  const jwtClaimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };
  
  const jwtClaimSetEncoded = btoa(JSON.stringify(jwtClaimSet));
  const signatureInput = `${jwtHeader}.${jwtClaimSetEncoded}`;
  
  // Import private key
  const privateKeyPem = serviceAccount.private_key;
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKeyPem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");
  
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
  
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );
  
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signatureInput)
  );
  
  const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  
  const jwt = `${signatureInput}.${signatureBase64}`;
  
  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  
  const tokenData = await tokenResponse.json();
  
  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }
  
  return tokenData.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const requestData: SendNotificationRequest = await req.json();

    console.log(`[PUSH_NOTIFICATION] Sending to user: ${requestData.user_id}`);
    console.log(`[PUSH_NOTIFICATION] Type: ${requestData.notification_type}`);

    // 1. Check if user has push notifications enabled
    const { data: preferences } = await supabaseClient
      .from("notification_preferences")
      .select("*")
      .eq("user_id", requestData.user_id)
      .single();

    if (!preferences || !preferences.push_notifications_enabled) {
      console.log(`[PUSH_NOTIFICATION] User has disabled push notifications`);
      return new Response(
        JSON.stringify({
          success: false,
          message: "User has disabled push notifications",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 2. Check specific notification type preference
    const typeCheckMap: Record<string, string> = {
      post_reply: "post_reply_enabled",
      comment_reply: "comment_reply_enabled",
      post_upvote: "post_vote_enabled",
      post_downvote: "post_vote_enabled",
      comment_upvote: "comment_vote_enabled",
      comment_downvote: "comment_vote_enabled",
      mention: "mention_enabled",
      post_trending: "post_achievement_enabled",
      post_hot: "post_achievement_enabled",
      post_top: "post_achievement_enabled",
      account_suspended: "account_status_enabled",
      account_reactivated: "account_status_enabled",
    };

    const prefKey = typeCheckMap[requestData.notification_type];
    if (prefKey && !preferences[prefKey]) {
      console.log(
        `[PUSH_NOTIFICATION] User has disabled ${requestData.notification_type} notifications`
      );
      return new Response(
        JSON.stringify({
          success: false,
          message: `User has disabled ${requestData.notification_type} notifications`,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 3. Get user's active devices
    const { data: devices } = await supabaseClient
      .from("push_notification_devices")
      .select("device_token, device_type")
      .eq("user_id", requestData.user_id)
      .eq("is_active", true);

    if (!devices || devices.length === 0) {
      console.log(`[PUSH_NOTIFICATION] No active devices found for user`);
      return new Response(
        JSON.stringify({
          success: false,
          message: "No active devices found",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[PUSH_NOTIFICATION] Found ${devices.length} active devices`);

    // 4. Get FCM access token using service account
    const fcmServiceAccount = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    
    if (!fcmServiceAccount) {
      console.error("[PUSH_NOTIFICATION] FCM service account not configured");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Push notification service not configured",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const serviceAccount = JSON.parse(fcmServiceAccount);
    const accessToken = await getAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;

    // 5. Send notification via FCM to each device
    let successCount = 0;
    let failedCount = 0;

    for (const device of devices) {
      try {
        const fcmPayload = {
          message: {
            token: device.device_token,
            notification: {
              title: requestData.title,
              body: requestData.body,
            },
            data: requestData.data ? 
              Object.fromEntries(
                Object.entries(requestData.data).map(([k, v]) => [k, String(v)])
              ) : {},
            // Platform-specific configuration
            android: {
              priority: "high",
              notification: {
                sound: "default",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
            apns: {
              headers: {
                "apns-priority": "10",
              },
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          },
        };

        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify(fcmPayload),
          }
        );

        const fcmResult = await fcmResponse.json();

        if (!fcmResponse.ok) {
          console.error(`[PUSH_NOTIFICATION] FCM error for token ${device.device_token.substring(0, 10)}...`, fcmResult);
          
          // Handle invalid tokens
          if (fcmResult.error?.details?.[0]?.errorCode === "UNREGISTERED" || 
              fcmResult.error?.details?.[0]?.errorCode === "INVALID_ARGUMENT") {
            console.log(`[PUSH_NOTIFICATION] Deactivating invalid token`);
            await supabaseClient
              .from("push_notification_devices")
              .update({ is_active: false })
              .eq("device_token", device.device_token);
          }
          failedCount++;
        } else {
          console.log(`[PUSH_NOTIFICATION] Sent successfully to ${device.device_type} device`);
          successCount++;
        }
      } catch (error) {
        console.error(`[PUSH_NOTIFICATION] Error sending to device:`, error);
        failedCount++;
      }
    }

    console.log(
      `[PUSH_NOTIFICATION] Sent to ${successCount}/${devices.length} devices`
    );

    // 5. Save to notification history
    await supabaseClient.from("notifications_history").insert({
      user_id: requestData.user_id,
      notification_type: requestData.notification_type,
      title: requestData.title,
      body: requestData.body,
      data: requestData.data || {},
    });

    return new Response(
      JSON.stringify({
        success: true,
        recipients: successCount,
        failed: failedCount,
        total: devices.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[PUSH_NOTIFICATION] Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: "Failed to send push notification",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
