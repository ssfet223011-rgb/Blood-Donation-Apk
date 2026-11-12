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
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const authHeader = req.headers.get("Authorization");

    const client = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader || "" } },
    });

    const body = await req.json();
    const {
      blood_group,
      latitude,
      longitude,
      max_radius_km = 50.0,
      division,
      district,
      upazila,
      availability_only = true,
      limit = 50,
      offset = 0,
    } = body;

    // Call secure PostGIS RPC
    const { data, error } = await client.rpc("search_nearby_donors", {
      p_blood_group: blood_group || null,
      p_latitude: latitude ?? null,
      p_longitude: longitude ?? null,
      p_max_radius_km: max_radius_km,
      p_division: division || null,
      p_district: district || null,
      p_upazila: upazila || null,
      p_availability_only: availability_only,
      p_limit: limit,
      p_offset: offset,
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ donors: data, count: data?.length || 0 }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
