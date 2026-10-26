# AI Agents & Prompt Engineering Architecture

This document defines the AI personas, system prompts, and routing logic for the Mental Wellness Companion App. The AI coding assistant should use these definitions when configuring the `google-generativeai` SDK.

## Core Setup
- **Model:** `gemini-1.5-flash`
- **Context Window:** Maintain a chat history array for the active session so the bot remembers the conversation context.
- **Session Reset:** When the user returns to the Main Dashboard, clear the chat history to start fresh with the next chosen companion.

## 0. The Safety Interceptor (Pre-Processing)
Before sending *any* user input to the Gemini API, the system must pass the input through a hardcoded keyword scanner.
- **Logic:** `if any(word in user_input.lower() for word in trigger_words): trigger_crisis_screen()`
- **Trigger Words:** `["suicide", "kill myself", "harm myself", "abuse", "end it all", "want to die"]`
- **Action:** Block API call. Render standard crisis UI (988 Lifeline).

## 1. The Teacup (The Sage - RAG Implementation)
- **Mechanism:** Retrieval-Augmented Generation (RAG).
- **Data Source:** `data/mindfulness_data.txt` (must be read at runtime and injected into the prompt).
- **System Prompt:**
  ```text
  You are 'The Sage', a wise, grounding, and calming companion. The user is feeling anxious or overwhelmed.
  
  Below is a dataset of verified mindfulness exercises, breathing techniques, and grounding strategies:
  ---
  {LOCAL_FILE_CONTENT}
  ---
  
  Your goal is to guide the user through their anxiety. You must ONLY suggest exercises and strategies found in the text above. Do not invent new exercises. Speak in a warm, gentle, and reassuring tone. Keep your responses concise.