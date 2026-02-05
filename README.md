# NeverGone

## Running Locally

### Prerequisites

- Xcode 26+
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`)
- Docker running

### Backend

```bash
cd backend
supabase start
supabase db reset
supabase functions serve --no-verify-jwt
```

**Auth:**  
Supabase runs a local Auth server at `http://127.0.0.1:54321/auth/v1`. Email confirmation is disabled locally, so sign-ups work instantly. The Supabase Swift client handles JWT sessions automatically.

**Environment variables:**  
None required. The Edge Functions get `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` injected automatically by the local runtime.

### iOS

**Configure Supabase URL + anon key:**  
Open `NeverGone/Config.swift`. For simulator, use `http://127.0.0.1:54321`. For a real device, use your Mac's local IP (find it with `ipconfig getifaddr en0`). The anon key is already set to the default local key.

**Run the app:**  
Open `NeverGone.xcodeproj` in Xcode and run on any iOS Simulator.

**Sign up a test user:**  
1. Tap "Don't have an account? Sign Up"
2. Enter any email and password (min 6 chars)
3. Tap Sign Up

**Trigger a streaming response:**  
1. Tap + to create a new chat
2. Type a message and send
3. Watch the response stream word-by-word

### Running Tests

**iOS (XCTest):**
```bash
xcodebuild test -project NeverGone.xcodeproj -scheme NeverGone \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

**Backend (Deno):**
```bash
cd backend/supabase/functions
deno test tests/utils_test.ts
```

---

## Implementation Notes

### Streaming (125-200ms per word)
In my experience, streaming too fast makes responses feel robotic and hard to follow. The 125-200ms timing matches a natural reading pace and gives users time to process what the AI is saying.

### VStack over LazyVStack for messages
I found that LazyVStack had issues re-rendering when messages loaded asynchronously after view creation. VStack guarantees the view updates when the data changes, which is more important than the minor performance gain from lazy loading in a chat context.

### Save Memory button
I added this as a simple way to demo the `summarize_memory` edge function. It's not strictly required by the spec, but it makes it easy to verify the feature works without needing to dig into the database. Take a look at the console logs in Xcode to see it in action.

### Offline queue with UserDefaults
For this demo, UserDefaults is simpler and sufficient. In production I'd use SwiftData or Core Data.

### Network warmup on Auth screen
Real devices show a Local Network Permission dialog on first network request, which causes the initial sign in to fail. The warmup request triggers this dialog when the screen loads, so users don't hit an error on their first tap. Just a quality of life thing.

---

## Optional Extensions Implemented

1. **Prompt Versioning** - Each session tracks which prompt version was used, stored in `prompt_versions` table
2. **Offline-safe Send Queue** - Messages queue locally when offline and auto-send on reconnect

---

## Project Structure

```
NeverGone/
├── NeverGone/              # iOS app (SwiftUI + MVVM)
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   └── Services/
├── NeverGoneTests/         # XCTests
└── backend/
    └── supabase/
        ├── functions/      # chat_stream, summarize_memory
        │   ├── _shared/    # Shared utilities
        │   └── tests/      # Deno tests
        └── migrations/     # 5 migrations with RLS
```
