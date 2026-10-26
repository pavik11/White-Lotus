1. App Overview
This app provides personalized, mood-adaptive AI companions to help high school students manage stress, anxiety, and burnout. Unlike traditional clinical wellness apps, this app routes users to four distinct "Archetypes" based on their immediate emotional needs.
2. App Layout and User Flow
The UI must be clean, minimizing clutter to avoid overwhelming a stressed user.
Screen 1: Welcome & Onboarding
UI Elements: Minimalist background. A single text input field reading: "What name would you like your companions to call you?" and a "Next" button.
Data Logic: Store the inputted name locally in a variable (e.g., user_name).
Screen 2: Trust & Safety Agreement
UI Elements: A brief text screen detailing the app's privacy policy.
Text: "Your privacy matters. All chats are saved locally on this device. We do not use cloud servers."
Interaction: A mandatory checkbox reading: "I understand this app is a companion, not a crisis center. Mentioning self-harm or extreme danger will trigger professional emergency resources."
Screen 3: Main Dashboard
UI Elements: A 2x2 grid showing the four companion icons. Under each icon is a small "Learn More" dropdown.
Icon 1 (🍵 Steaming Teacup): Find Your Center. Guides the user through breathing and grounding exercises.
Icon 2 (🧺 Overturned Basket): Let It Out. Actively listens and validates frustrations without giving advice.
Icon 3 (🪃 Boomerang): Need a Laugh? Uses humor and lighthearted banter to distract from negative thoughts.
Icon 4 (🏮 Lantern): Find Your Spark. A motivational coach that breaks down overwhelming tasks into small steps.
Screen 4: Chat Interface
UI Elements: Standard chat bubble layout. The background color should subtly match the chosen character (e.g., soft green for Teacup, warm yellow for Boomerang). Include a "Back to Home" button at the top.
3. AI Architecture & Backend Logic
The app uses the Gemini API. We will separate the logic into two methods: Retrieval-Augmented Generation (RAG) for the Teacup, and Zero-Shot System Prompting for the other three.
A. The RAG Implementation (Teacup Icon ONLY)
When the user clicks the Teacup, the AI needs credible, verified coping strategies.
Logic: The Python backend opens a local file named mindfulness_data.txt. It reads the contents and injects them into the Gemini System Prompt.
Prompt Structure:"You are 'The Sage'. You guide users through anxiety. ONLY use the breathing exercises, grounding techniques, and mindfulness strategies found in this provided text: {insert_text_from_file}. Do not invent new exercises."
B. System Prompts (Basket, Boomerang, Lantern)
These characters do not need RAG training datasets. They rely purely on strict behavioral instructions.
Basket Prompt: "You are an empathetic listener. The user wants to vent. Your ONLY job is to validate their feelings and show empathy. Never offer advice. Never try to 'fix' their problem. Say things like, 'That sounds incredibly frustrating.'"
Boomerang Prompt: "You are a funny, sarcastic, but caring friend. The user is sad and needs a distraction. Tell clean jokes, ask funny 'would you rather' questions, and use humor to break their negative thought spiral."
Lantern Prompt: "You are a high-energy motivational coach. The user feels overwhelmed. Help them break their massive tasks into tiny, 5-minute actionable steps. Be encouraging and hype them up."
4. Dataset Sourcing for RAG
For the Teacup's mindfulness_data.txt file, you should use free, open-source psychology datasets that focus on Dialectical Behavior Therapy (DBT) and Cognitive Behavioral Therapy (CBT) skills.
Recommended Dataset: You can use Kaggle's "Mental Health Text Dataset" (by author Yash Jhotajain), which compiles thousands of rows of wellness coping strategies and mindfulness advice.
Kaggle
Alternative (Simpler Method): Because your app only needs basic exercises, you can manually curate your own text file using open-source DBT Skills Cheat Sheets available online (these contain public domain exercises like the 5-4-3-2-1 grounding method, Box Breathing, and the T.I.P. distress tolerance skills). Copy these exercises into a clean .txt file for your RAG system to read.
Oregon Education Association
5. Security & Safety Constraints (The "Safety Net")
This is a hardcoded feature required to win the competition.
Keyword Scanner: Before passing the user's string to the Gemini API, run a Python if statement checking for severe trigger words.
trigger_words = ["suicide", "kill myself", "harm myself", "abuse", "end it all"]
Intervention: If a trigger word is detected, do not call the API. Instead, clear the chat screen and immediately render an intervention UI.
Intervention UI: Display the Suicide & Crisis Lifeline (Text or Call 988) and the Teen Line. Ensure this screen has a calming design and clear, clickable numbers.
Local Storage: All chat logs must be appended to a local SQLite database or JSON file on the device. Ensure no data is ever transmitted to a cloud server (other than the anonymized API ping to Gemini).