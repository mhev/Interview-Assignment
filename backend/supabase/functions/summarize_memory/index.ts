import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SummarizeRequest {
  session_id: string;
}

// Stubbed summarization function (would use LLM in production)
function generateSummary(messages: Array<{ role: string; content: string }>): string {
  const userMessages = messages.filter(m => m.role === "user");
  const topics = userMessages.slice(0, 3).map(m => m.content.slice(0, 50));
  
  if (topics.length === 0) {
    return "Empty conversation session.";
  }
  
  return `Conversation summary: User discussed topics including "${topics.join('", "')}". Total of ${messages.length} messages exchanged.`;
}

serve(async (req: Request) => {
  console.log(`[summarize_memory] ${req.method} request received`);
  
  if (req.method === "OPTIONS") {
    console.log("[summarize_memory] Handling CORS preflight");
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { session_id }: SummarizeRequest = await req.json();

    if (!session_id) {
      return new Response(JSON.stringify({ error: "Missing session_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify session belongs to user
    const { data: session, error: sessionError } = await supabaseClient
      .from("chat_sessions")
      .select("id, user_id")
      .eq("id", session_id)
      .eq("user_id", user.id)
      .single();

    if (sessionError || !session) {
      return new Response(JSON.stringify({ error: "Session not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch all messages from session
    const { data: messages, error: messagesError } = await supabaseClient
      .from("chat_messages")
      .select("role, content")
      .eq("session_id", session_id)
      .order("created_at", { ascending: true });

    if (messagesError) {
      return new Response(JSON.stringify({ error: "Failed to fetch messages" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate summary
    const summary = generateSummary(messages || []);

    console.log(`[summarize_memory] Generated summary: ${summary.substring(0, 100)}...`);
    
    // Insert into memories table
    const { data: memory, error: memoryError } = await supabaseClient
      .from("memories")
      .insert({
        user_id: user.id,
        session_id,
        summary,
      })
      .select()
      .single();

    if (memoryError) {
      console.error("[summarize_memory] Failed to save memory:", memoryError);
      return new Response(JSON.stringify({ error: "Failed to save memory" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`[summarize_memory] Memory saved with id: ${memory.id}`);
    return new Response(JSON.stringify({ memory }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[summarize_memory] Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
