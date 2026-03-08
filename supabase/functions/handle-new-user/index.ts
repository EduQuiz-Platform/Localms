import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { user_id, email, full_name, role, phone } = await req.json();

    if (!user_id || !email || !full_name || !role) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create profile
    const { data: profile, error: profileError } = await supabaseClient
      .from("profiles")
      .insert({
        id: user_id,
        email: email.toLowerCase(),
        full_name,
        role,
        phone,
        active: true,
        failed_attempts: 0,
        lockouts: 0,
        flagged: false,
      })
      .select()
      .single();

    if (profileError) {
      return new Response(JSON.stringify({ error: profileError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create welcome notification
    await supabaseClient.from("notifications").insert({
      user_id,
      type: "welcome",
      message: `Welcome to SmartLMS, ${full_name}! Your ${role} account has been created successfully.`,
      read: false,
    });

    // Log activity
    await supabaseClient.from("activities").insert({
      user_id,
      action: "user_registered",
      description: `New ${role} account created`,
      metadata: { email, full_name },
    });

    return new Response(
      JSON.stringify({ success: true, profile }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});