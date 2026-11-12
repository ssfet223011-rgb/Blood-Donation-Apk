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
    const client = createClient(supabaseUrl, supabaseAnonKey);

    const url = new URL(req.url);
    let donorIdNumber = url.searchParams.get("id");

    if (!donorIdNumber && req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      donorIdNumber = body.donor_id_number;
    }

    if (!donorIdNumber) {
      return new Response(JSON.stringify({ error: "Missing donor_id_number" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Call verify_donor_id RPC (safely strips all PII)
    const { data, error } = await client.rpc("verify_donor_id", {
      p_donor_id_number: donorIdNumber.trim().toUpperCase(),
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!data || data.length === 0) {
      return new Response(
        JSON.stringify({
          is_valid: false,
          message: "No verified donor found matching this ID number.",
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({
        is_valid: true,
        donor: data[0],
        verified_by: "BloodBond Bangladesh National Registry",
        timestamp: new Date().toISOString(),
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
