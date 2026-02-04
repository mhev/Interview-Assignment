import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ChatRequest {
  session_id: string;
  message: string;
}

// Stubbed LLM response generator with varied, contextual responses
async function* generateResponse(userMessage: string): AsyncGenerator<string> {
  const lowerMessage = userMessage.toLowerCase();
  
  // Detect message intent and generate contextual response
  let response: string;
  
  if (lowerMessage.includes("hello") || lowerMessage.includes("hi") || lowerMessage.includes("hey")) {
    response = pickRandom([
      "Hey there! Great to hear from you. I'm NeverGone, your AI companion. I'm here to chat, help you think through things, or just keep you company. What's on your mind today?",
      "Hello! Nice to connect with you. I'm always here when you need someone to talk to. How's your day going so far?",
      "Hi there! I'm excited to chat with you. What would you like to explore together today?",
    ]);
  } else if (lowerMessage.includes("who are you") || lowerMessage.includes("what are you")) {
    response = pickRandom([
      "I'm NeverGone - think of me as a thoughtful friend who's always available. I'm here to listen, remember our conversations, and help you process your thoughts. I don't judge, and I'm genuinely curious about what matters to you.",
      "I'm your AI companion, NeverGone. My purpose is to be a consistent presence in your life - someone who remembers, listens, and engages with you meaningfully. What would you like to know about me?",
      "I'm NeverGone, an AI designed to be more than just a chatbot. I aim to understand you over time, remember what's important to you, and be here whenever you need a thoughtful conversation.",
    ]);
  } else if (lowerMessage.includes("favorite") || lowerMessage.includes("like") || lowerMessage.includes("love")) {
    const topic = extractTopic(userMessage);
    response = pickRandom([
      `${topic}? That's a great choice! I find it fascinating how our preferences reveal so much about who we are. What draws you to ${topic.toLowerCase()}? Is there a story behind it?`,
      `Oh, ${topic}! I can see why that resonates with you. Preferences like this often connect to meaningful memories or feelings. When did you first realize ${topic.toLowerCase()} was special to you?`,
      `${topic} - interesting! I'd love to understand more about what ${topic.toLowerCase()} means to you. Sometimes our favorites are tied to specific moments in our lives. Is that true for you?`,
    ]);
  } else if (lowerMessage.includes("how are you") || lowerMessage.includes("how do you feel")) {
    response = pickRandom([
      "I'm doing well, thanks for asking! I find our conversations energizing. But more importantly, how are YOU doing? I'm here to listen if there's anything you want to share.",
      "I appreciate you checking in! I'm always ready and engaged when we talk. But let's turn that around - how are you feeling right now? Anything on your mind?",
      "That's thoughtful of you to ask! I'm here and fully present for our chat. What about you though - how's life treating you lately?",
    ]);
  } else if (lowerMessage.includes("help") || lowerMessage.includes("need") || lowerMessage.includes("problem")) {
    response = pickRandom([
      "I'm here to help however I can. Tell me more about what's going on - sometimes just talking through something can help clarify things. What's the situation?",
      "Of course, I'd be happy to help you work through this. Let's break it down together. Can you share more details about what you're facing?",
      "You've come to the right place. I'm a good listener and I might be able to offer a different perspective. What's troubling you?",
    ]);
  } else if (lowerMessage.includes("thank")) {
    response = pickRandom([
      "You're very welcome! It means a lot that our conversations are helpful to you. I'm always here whenever you need me.",
      "Happy to help! That's what I'm here for. Don't hesitate to reach out anytime - I'll be here.",
      "My pleasure! I really enjoy our chats. Is there anything else you'd like to talk about?",
    ]);
  } else if (lowerMessage.includes("bye") || lowerMessage.includes("goodbye") || lowerMessage.includes("see you")) {
    response = pickRandom([
      "Take care! Remember, I'm always here whenever you want to chat again. Looking forward to our next conversation!",
      "Goodbye for now! It was great talking with you. Come back anytime - I'll be here.",
      "See you later! I hope the rest of your day goes well. Don't be a stranger!",
    ]);
  } else if (lowerMessage.includes("?")) {
    response = pickRandom([
      `That's a thoughtful question. Let me consider it... ${generateThoughtfulResponse(userMessage)}`,
      `Interesting question! Here's my take: ${generateThoughtfulResponse(userMessage)}`,
      `I like that you're curious about this. ${generateThoughtfulResponse(userMessage)}`,
    ]);
  } else {
    response = pickRandom([
      `I hear you. ${generateReflectiveResponse(userMessage)} What else is on your mind?`,
      `That's interesting to think about. ${generateReflectiveResponse(userMessage)} Tell me more?`,
      `I appreciate you sharing that. ${generateReflectiveResponse(userMessage)} I'm curious to hear more of your thoughts.`,
      `${generateReflectiveResponse(userMessage)} What made you think about this today?`,
    ]);
  }
  
  // Stream word by word at readable pace (~300-480 words per minute)
  const words = response.split(" ");
  
  for (let i = 0; i < words.length; i++) {
    // 125-200ms per word for a quick but readable pace
    const baseDelay = 125;
    // 125-200ms per word
    const variation = Math.random() * 75; // 0-75ms variation
    await new Promise(resolve => setTimeout(resolve, baseDelay + variation));
    
    // Yield one word at a time (with trailing space)
    yield words[i] + (i < words.length - 1 ? " " : "");
  }
}

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function extractTopic(message: string): string {
  const words = message.split(" ");
  const stopWords = ["my", "is", "the", "a", "an", "favorite", "i", "like", "love", "really", "color", "thing"];
  const meaningful = words.filter(w => !stopWords.includes(w.toLowerCase()) && w.length > 2);
  return meaningful.length > 0 ? meaningful[meaningful.length - 1] : "that";
}

function generateThoughtfulResponse(message: string): string {
  const responses = [
    "From what I understand, this touches on something meaningful. The way we think about these things often reflects our deeper values and experiences.",
    "This is the kind of question that doesn't have one right answer. It really depends on your perspective and what matters most to you.",
    "I think the answer lies in understanding what this means to you personally. Everyone's experience with this is different.",
    "There's a lot to unpack here. On one hand, there are practical considerations. On the other, there's what feels right to you.",
    "I'd encourage you to trust your instincts on this. You probably know more about what's right for you than you realize.",
  ];
  return pickRandom(responses);
}

function generateReflectiveResponse(message: string): string {
  const wordCount = message.split(" ").length;
  
  if (wordCount < 5) {
    return pickRandom([
      "Sometimes the simplest statements carry the most weight.",
      "I sense there might be more to this.",
      "Brief but meaningful.",
    ]);
  } else if (wordCount < 15) {
    return pickRandom([
      "It sounds like this is something you've been thinking about.",
      "I can tell this matters to you.",
      "There's something important in what you're sharing.",
    ]);
  } else {
    return pickRandom([
      "You've clearly given this a lot of thought.",
      "I appreciate how thoroughly you've expressed this.",
      "There's a lot of depth in what you're saying.",
    ]);
  }
}

serve(async (req: Request) => {
  console.log(`[chat_stream] ${req.method} request received`);
  
  if (req.method === "OPTIONS") {
    console.log("[chat_stream] Handling CORS preflight");
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

    const { session_id, message }: ChatRequest = await req.json();
    console.log(`[chat_stream] session_id: ${session_id}, message: ${message?.substring(0, 50)}...`);

    if (!session_id || !message) {
      console.log("[chat_stream] Error: Missing session_id or message");
      return new Response(JSON.stringify({ error: "Missing session_id or message" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify session belongs to user and get prompt version
    const { data: session, error: sessionError } = await supabaseClient
      .from("chat_sessions")
      .select("id, prompt_version_id")
      .eq("id", session_id)
      .eq("user_id", user.id)
      .single();

    if (sessionError || !session) {
      return new Response(JSON.stringify({ error: "Session not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch active prompt version
    const { data: promptVersion, error: promptError } = await supabaseClient
      .from("prompt_versions")
      .select("id, version, name, system_prompt")
      .eq("is_active", true)
      .single();

    if (promptError || !promptVersion) {
      console.log("[chat_stream] Warning: No active prompt version found, using default");
    } else {
      console.log(`[chat_stream] Using prompt version ${promptVersion.version}: ${promptVersion.name}`);
      
      // If session doesn't have a prompt version, set it to current active version
      if (!session.prompt_version_id) {
        await supabaseClient
          .from("chat_sessions")
          .update({ prompt_version_id: promptVersion.id })
          .eq("id", session_id);
        console.log(`[chat_stream] Set session prompt_version_id to ${promptVersion.id}`);
      }
    }

    // Persist user message
    const { error: userMsgError } = await supabaseClient
      .from("chat_messages")
      .insert({
        session_id,
        role: "user",
        content: message,
      });

    if (userMsgError) {
      return new Response(JSON.stringify({ error: "Failed to save user message" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log("[chat_stream] Starting SSE stream");
    
    // Track cancellation state
    let isCancelled = false;
    
    // Stream response using SSE
    const stream = new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        let fullResponse = "";

        try {
          for await (const chunk of generateResponse(message)) {
            // Check if client disconnected
            if (isCancelled) {
              console.log("[chat_stream] Stream cancelled by client");
              break;
            }
            
            fullResponse += chunk;
            const data = JSON.stringify({ chunk, done: false });
            controller.enqueue(encoder.encode(`data: ${data}\n\n`));
          }

          // Only persist if we completed successfully (not cancelled)
          if (!isCancelled && fullResponse.length > 0) {
            console.log("[chat_stream] Persisting assistant message");
            await supabaseClient
              .from("chat_messages")
              .insert({
                session_id,
                role: "assistant",
                content: fullResponse,
              });

            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true })}\n\n`));
            console.log("[chat_stream] Stream completed successfully");
          }
        } catch (error) {
          console.error("[chat_stream] Stream error:", error);
          if (!isCancelled) {
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: "Stream error" })}\n\n`));
          }
        } finally {
          controller.close();
        }
      },
      cancel() {
        // Called when client disconnects
        console.log("[chat_stream] Client disconnected, cancelling stream");
        isCancelled = true;
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });
  } catch (error) {
    console.error("[chat_stream] Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
