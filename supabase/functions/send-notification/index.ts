import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const client = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();
    const { user_id, category, title, body: msgBody, data = {} } = body;

    if (!user_id || !title || !msgBody) {
      return new Response(JSON.stringify({ error: "Missing required fields (user_id, title, body)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Insert in-app notification
    const { data: notif, error: notifErr } = await client
      .from("notifications")
      .insert({
        user_id,
        category: category || "SYSTEM_ANNOUNCEMENT",
        title,
        body: msgBody,
        data,
      })
      .select()
      .single();

    if (notifErr) {
      return new Response(JSON.stringify({ error: notifErr.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Fetch user's registered FCM device tokens
    const { data: devices } = await client
      .from("device_tokens")
      .select("token")
      .eq("user_id", user_id);

    const tokens = devices?.map((d: any) => d.token) || [];

    return new Response(
      JSON.stringify({
        success: true,
        notification: notif,
        fcm_tokens_dispatched: tokens.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
