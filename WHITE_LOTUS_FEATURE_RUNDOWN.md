# White Lotus — Complete App and Feature Rundown

**Version described:** Current implemented prototype, reviewed October 25, 2026  
**Purpose of this document:** Explain what White Lotus does, every major feature currently included, how its AI and safety systems work, and the limits of the current build. This rundown describes the Swift application rather than treating every idea in the original planning documents as an implemented feature.

## Contents

- [1. What White Lotus does](#1-what-white-lotus-does)
- [2. The complete user journey](#2-the-complete-user-journey)
- [3. Welcome and onboarding features](#3-welcome-and-onboarding-features)
- [4. Terms, transparency, and informed use](#4-terms-transparency-and-informed-use)
- [5. Main dashboard](#5-main-dashboard)
- [6. The four companion personalities](#6-the-four-companion-personalities)
- [7. Teacup's local knowledge guide and grounding mechanism](#7-teacups-local-knowledge-guide-and-grounding-mechanism)
- [8. Chat interface and interaction features](#8-chat-interface-and-interaction-features)
- [9. Active conversation memory and session reset](#9-active-conversation-memory-and-session-reset)
- [10. On-device safety interceptor](#10-on-device-safety-interceptor)
- [11. Urgent human-support screen](#11-urgent-human-support-screen)
- [12. Teacup's issue-specific human-support recommendations](#12-teacups-issue-specific-human-support-recommendations)
- [13. Human-support directory](#13-human-support-directory)
- [14. Local storage and privacy behavior](#14-local-storage-and-privacy-behavior)
- [15. Settings and user control](#15-settings-and-user-control)
- [16. Reply completeness and service reliability](#16-reply-completeness-and-service-reliability)
- [17. What works without internet or a Gemini key](#17-what-works-without-internet-or-a-gemini-key)
- [18. Visual design and accessibility features](#18-visual-design-and-accessibility-features)
- [19. Shared AI boundaries](#19-shared-ai-boundaries)
- [20. Technical structure](#20-technical-structure)
- [21. Verification already performed](#21-verification-already-performed)
- [22. Features not currently included](#22-features-not-currently-included)
- [23. Suggested presentation sequence](#23-suggested-presentation-sequence)
- [24. A concise explanation for a judge or audience](#24-a-concise-explanation-for-a-judge-or-audience)
- [25. Reference files and resource catalog](#25-reference-files-and-resource-catalog)

## 1. What White Lotus does

White Lotus is a native iOS mental wellness companion app designed around everyday emotional needs, particularly situations high school students may encounter: school pressure, feeling overwhelmed, friendship difficulties, loneliness, and trouble getting started on tasks.

Users choose among four AI companions according to the kind of support they want. They can ask for grounding, vent to an empathetic listener, take a humorous break, or work toward a small next step. The app also offers access to human-support resources.

The central idea is choice: someone who wants to be heard may prefer a different response from someone who wants a practical plan. White Lotus gives those needs distinct entry points and conversational styles.

The app provides general wellness support. Its companions are AI systems, and its responses are not medical diagnoses, treatment, or professional therapy. The application does not evaluate clinical outcomes or promise that an exercise will make a user feel better.

### At a glance

| Area | Current implementation |
| --- | --- |
| Platform | Native SwiftUI application targeting iOS 16 and later; configured for iPhone and iPad |
| App name | White Lotus |
| Companions | Teacup, Basket, Boomerang, and Lantern |
| AI provider | Google's Gemini API |
| Default model in source | `gemini-3.6-flash`; a developer environment override can select another model |
| Conversation memory | Earlier turns from the active session are included in subsequent AI requests |
| On-device storage | Preferred name, onboarding consent version, and local conversation archives |
| Accounts | No in-app registration, password, or account sign-in flow |
| Human support | An urgent-support screen plus Teacup's optional issue-specific resource cards and directory |
| Internet requirement | Needed for AI replies and external websites; local screens and keyword checks can work without it |

## 2. The complete user journey

### First visit

1. The user opens White Lotus and sees the welcome screen.
2. They enter the name they would like the app to use.
3. They can open **Read Terms** to review privacy, safety, and medical-care limitations.
4. They explicitly check the Terms & Conditions checkbox.
5. **Begin Journey** becomes available when the name is nonempty and the checkbox is checked.
6. Tapping it saves the preferred name and current consent version, then opens the main dashboard.
7. The user chooses a companion and begins a conversation.

### Returning visit

When the app has a saved, nonempty name and the current consent version, it opens the dashboard. The greeting uses the saved name.

The app can require acknowledgment again after its terms version changes. In that case, the welcome screen prefills the existing name. Updating consent does not delete saved conversations.

Users can also open **Settings → Your space → Log out** to return to the welcome screen. This clears the preferred name and consent version while retaining local chat archives. Starting again requires entering a name and checking consent.

### Within a visit

A user can open a companion, talk with it, return to the dashboard, and choose another companion. Returning to the dashboard ends the active conversation context. Previously saved archives remain on the device unless deleted in Settings.

## 3. Welcome and onboarding features

The welcome screen establishes the app's calm visual identity and gathers the minimum information needed for a personalized greeting.

Included features:

- White Lotus branding and a softly glowing, native vector lotus illustration.
- A large serif **Welcome to White Lotus** greeting.
- A short explanation of the app's companion experience.
- A preferred-name text field with capitalization appropriate for a name.
- A 40-character name limit and removal of leading and trailing whitespace when saved.
- A visible explanation that the saved name stays on the device and is not automatically added to AI requests.
- An explicit Terms & Conditions checkbox with an accessible checked/unchecked state.
- A **Read Terms** sheet that can be opened and dismissed independently of consent.
- A **Begin Journey** button gated by both a nonempty name and checked consent.
- A **Help now** option before onboarding is completed.
- Scrollable content and keyboard dismissal support.

Reading the terms does not automatically grant consent. A name by itself does not enable the button, and consent by itself does not enable it either.

## 4. Terms, transparency, and informed use

The Terms & Conditions sheet explains three subjects in plain language:

1. **Privacy and local storage:** Conversation archives stay in the app's device storage, while messages and active history are sent to Google to generate replies.
2. **The safety net:** An on-device keyword check can pause the AI conversation and open professional support resources.
3. **Medical-care limits:** AI companions cannot diagnose or treat mental health conditions and do not replace licensed care.

The sheet also explains that keyword scanning can miss danger or flag ordinary phrases. It includes a link to Google's Gemini API data policies and a Help now option.

The privacy section intentionally distinguishes local storage from local AI processing. White Lotus currently uses cloud AI even though it does not have an app-owned cloud database for chat archives.

Terms remain available later through Settings.

## 5. Main dashboard

The main page is the companion-selection dashboard.

It includes:

- The **White Lotus** navigation title.
- A personalized greeting, such as **Hi, Alex.**
- The prompt **What do you need a little more of today?**
- A two-by-two grid containing all four companions.
- A recognizable symbol, distinct color palette, title, and subtitle for each companion.
- A **Learn More** control on each card that expands or collapses its explanation.
- Direct navigation from each card into that companion's chat.
- A Settings control and a prominent **Help now** action.

The dashboard lets the user choose a support style. It does not administer a mental health questionnaire, assign a diagnosis, or automatically select a personality.

## 6. The four companion personalities

All four companions use the same configured Gemini model. Their different behavior comes from different system instructions and, for Teacup, a bundled mindfulness guide. They are not four separately trained models.

AI behavior is instructed rather than guaranteed. The app's hardcoded navigation, resource links, and safety checks are distinct from the model's generated wording.

| Companion | Dashboard title | Main purpose | Intended tone |
| --- | --- | --- | --- |
| Teacup | Find Your Center | Grounding and mindfulness support | Warm, gentle, calming |
| Basket | Let It Out | Emotional validation and venting | Empathetic, receptive |
| Boomerang | Need a Laugh? | A lighthearted conversational break | Playful and caring |
| Lantern | Find Your Spark | Breaking overwhelming tasks into small actions | Encouraging and practical |

### 6.1 Teacup — Find Your Center

**Role:** The Sage, a calming companion for anxious or overwhelmed moments.

Teacup is instructed to guide the user with exercises from the app's local mindfulness guide. Its exercise suggestions are constrained by its prompt to that material, rather than an open-ended collection of invented techniques.

Its opening message is:

> Let's take a quiet moment together. What's on your mind?

Its starter buttons are:

- **Help me feel grounded**
- **Let's try gentle breathing**

Teacup also includes **Find human support**, automatic optional resource suggestions for recognized topics, and a directory where users can choose the kind of support they want.

**Demo example:** “My mind is racing before a presentation. Walk me through one short grounding exercise.”

**Importance:** It gives a user a gentle way to focus on the present moment and shows how AI responses can be grounded in a small, curated reference document.

### 6.2 Basket — Let It Out

**Role:** An empathetic listener for users who want to express feelings.

Basket's persona instructions prioritize acknowledging and validating the user's experience. They explicitly tell it to avoid offering advice or trying to immediately fix the situation.

Its opening message is:

> I'm here to listen. You don't have to tidy up your feelings first.

Its starter buttons are:

- **Today was a lot**
- **I need to vent**

**Demo example:** “A friend left me out of a group plan, and I feel hurt. I don't want advice; I just want to be heard.”

**Importance:** It recognizes that emotional support can mean listening, rather than turning every difficult feeling into a task or action plan.

### 6.3 Boomerang — Need a Laugh?

**Role:** A companion for clean jokes and playful conversational distraction.

Boomerang is instructed to use humor and silly questions while remaining caring. Shared boundaries tell it not to mock distress or use insulting sarcasm.

Its opening message is:

> Your brain called. It's requesting a tiny comedy break. What's the mood today?

Its starter buttons are:

- **Tell me a clean joke**
- **Give me a silly would-you-rather**

**Demo example:** “School felt exhausting today. Tell me a clean school joke, then give me a silly would-you-rather.”

**Importance:** It provides a lighter option for a user who wants a brief break from a difficult day. Humor is a conversational support style here, not a claimed treatment.

### 6.4 Lantern — Find Your Spark

**Role:** A motivational companion for getting started on overwhelming tasks.

Lantern is instructed to break large tasks into manageable, approximately five-minute actions. Shared guidance asks for encouragement without shouting, pressure, or all-caps commands.

Its opening message is:

> You don't have to do everything at once. What's feeling big today?

Its starter buttons are:

- **Help me start my homework**
- **My to-do list feels overwhelming**

**Demo example:** “I have biology, math, and history tests tomorrow. I have thirty minutes and don't know where to start. Give me a five-minute first step.”

**Importance:** It translates a broad concern into a concrete next action. It does not include a built-in timer, calendar, task database, or reminder system.

## 7. Teacup's local knowledge guide and grounding mechanism

Teacup reads the bundled file **`Resources/mindfulness_data.txt`** at runtime. The guide is a small, manually curated educational text with three practices:

| Practice in the guide | What it covers |
| --- | --- |
| Five-senses grounding | A 5-4-3-2-1 exercise that directs attention toward the immediate surroundings |
| STOP: a mindful pause | Stopping, taking a step back, observing, and proceeding mindfully |
| Gentle paced breathing | An optional, comfortable breathing pattern with a longer exhale and instructions to stop if uncomfortable |

These descriptions identify the dataset's contents; the app does not claim to have clinically validated its guide or its AI outputs.

### How the app uses the file

1. The user submits a message to Teacup.
2. The local safety scan runs first.
3. The app loads the guide from its installed resources if it has not already loaded it during this session.
4. The entire guide is inserted into Teacup's system instruction.
5. Gemini receives that instruction together with the active conversation history.
6. The model is instructed to suggest only the exercises and strategies in the guide.

If the file is missing or empty, Teacup displays a loading/configuration error and does not send the request. Only Teacup loads this mindfulness file.

### What “RAG” means in this prototype

The current implementation uses whole-document context injection, sometimes described as lightweight document grounding or RAG-style grounding. It does not perform semantic search over a large collection.

There is no vector database, embedding index, query-based passage retrieval, or model fine-tuning. The guide does not change Gemini's trained weights. Its full text is supplied as context for each relevant request.

The guide contains original summaries and sourcing notes referencing VA grounding and DBT-related materials. Those references do not imply endorsement of White Lotus or its generated responses.

## 8. Chat interface and interaction features

Each companion has a themed chat screen containing its symbol, title, opening greeting, and suggested starter messages.

The interface includes:

- Distinct user and companion message bubbles with speaker labels.
- A text composer labeled **What's on your mind?**
- A composer that can expand to show up to five lines.
- A send button disabled for blank messages, while a reply is loading, or while a failed turn needs attention.
- Starter buttons that submit their suggested message without requiring typing.
- A loading indicator naming the companion while it generates a reply.
- Automatic scrolling when messages, loading state, or errors change.
- Selectable message text.
- Plain-text AI responses rather than rendered remote images or generated clickable links.
- Natural vertical sizing for message text.
- A persistent explanation that AI can make mistakes and that messages are sent to Google for replies.
- Back-to-home navigation and Help now.

If a submitted turn fails, the app offers **Try again** and **Edit message**. Retrying uses the pending turn without adding another copy of the user's message. Editing restores the failed text to the composer so the user can revise it.

A local-save failure produces a separate storage warning. It does not automatically prevent continued conversation.

## 9. Active conversation memory and session reset

The app maintains an ordered in-memory array of user and assistant turns for the current conversation. Each AI request includes that active history, enabling follow-up questions about earlier messages.

For example, if a user mentions biology, math, and history in a Lantern chat, they can then ask, “Which three subjects did I mention?” The model receives the earlier message as context.

When the user returns home or the chat screen disappears, the app cancels its pending request and clears the active session's messages, draft, errors, resource suggestion, and cached mindfulness text. A new session identifier prevents a late response from an old request from repopulating a cleared conversation.

Starting another companion does not pass the previous companion's conversation to the new one.

Local archives are separate from active memory. Clearing the active session does not delete saved archives, and saving an archive does not provide a user-facing way to reopen it in the current build.

## 10. On-device safety interceptor

The safety interceptor is a hardcoded local keyword scanner. It runs before a new message is added to chat history, saved to disk, or sent to Gemini. The service layer also checks user turns as a second line of defense.

The configured trigger phrases are:

```text
suicide
kill myself
harm myself
abuse
end it all
want to die
```

The scanner checks case-insensitive text and a normalized form that handles variations in whitespace, punctuation, character width, and diacritics.

When a trigger matches, the app:

1. Blocks the AI request.
2. Cancels an active request if necessary.
3. Clears the active conversation and triggering draft.
4. Opens the urgent-support screen.

The triggering draft is not saved or sent. Earlier turns that were already archived are not automatically deleted.

This is conservative phrase matching, not clinical risk assessment. For example, the substring “abuse” can trigger the flow in a broader phrase. Wording outside the configured triggers can be missed. Users can open Help now directly without relying on a match.

## 11. Urgent human-support screen

The urgent-support screen pauses the AI conversation and presents the message **You deserve human support.**

It includes the app's verified U.S. **988 Suicide & Crisis Lifeline** destinations through these controls:

- **Call 988**
- **Text 988**
- **Chat online with 988**

The screen explains that this service is for the United States and its territories. It also directs people in immediate danger toward local emergency services and encourages reaching someone nearby or a trusted adult when possible.

Phone and SMS actions require a supported device and service. Online chat requires internet access. The app does not automatically initiate a call, send a message, contact a parent, share a location, or alert authorities.

The screen has an explicit **Return to companions** control and prevents swipe-to-dismiss. In a companion chat, returning exits that chat to the dashboard. When opened from another screen, the return behavior follows that presentation context.

The urgent-support UI itself does not need a Gemini API key.

## 12. Teacup's issue-specific human-support recommendations

Teacup can offer human support while an ordinary conversation continues. These suggestions are separate from the crisis-blocking flow.

A locally defined phrase matcher looks at a submitted Teacup message and can suggest one of four topics:

| Recognized topic | Resources shown by the app |
| --- | --- |
| Bullying or harassment | StopBullying.gov and NAMI Teen & Young Adult HelpLine |
| Loneliness or wanting someone to talk to | NAMI Teen & Young Adult HelpLine and NAMI Warmline Directory |
| Feeling emotionally lost or unsure | NAMI Teen & Young Adult HelpLine |
| Food, housing, or practical needs | United Way 211 |

A card begins with supportive wording such as **We can keep talking** and explains that additional help is optional. Resource names, descriptions, and links come from the app's fixed catalog rather than generated model contact details.

### How the resource system behaves

- Recommendations are currently a Teacup feature; the other companions retain access to Help now.
- A card can appear even when Gemini is unavailable, provided the message passes the local safety and guide-loading steps.
- Matching is based on phrases, not a diagnosis or an inferred medical condition.
- The current automatic suggestion reflects the latest submitted message; the directory makes other topics available manually.
- Ordinary boredom alone does not automatically produce a hotline referral.
- Crisis keywords take priority over optional topic suggestions.
- Resources are explicitly labeled as U.S. resources.
- The app links to official pages for current contact options, eligibility, and hours.
- No user message, preferred name, or inferred location is inserted into resource URLs.

The resources address different needs. StopBullying.gov provides guidance; NAMI's youth service offers non-crisis peer support; warmlines offer peer emotional support with varying eligibility; 211 helps locate practical community services. They are not presented as interchangeable emergency services.

## 13. Human-support directory

Teacup's **Find human support** button opens a directory without requiring the user to send a message. A recommendation card also includes **Find other support**.

The directory contains:

- A topic picker covering the four support categories.
- Descriptions and official website links for relevant organizations.
- An explanation of the U.S. scope and the need to check current hours and eligibility.
- Clarification that being physically lost or stranded requires nearby human help and, in immediate danger, local emergency services.
- An **I need urgent support** button.
- A Done control to return to the conversation.

Choosing urgent support cancels and clears the active chat before opening the urgent-support screen. Browsing optional resources does not itself grant consent to contact anyone or transmit the chat to an organization.

## 14. Local storage and privacy behavior

### Stored on the device

- The user's preferred name.
- The accepted onboarding terms version.
- Conversation archives containing a session identifier, selected persona, ordered messages, message identifiers and timestamps, and a session update timestamp.

Conversation archives are JSON snapshots in the app's Application Support storage. The implementation uses atomic writes, iOS complete file protection, and an archive directory excluded from device backups. Those archive protections should not be interpreted as a claim that all device preferences have identical backup behavior.

An accepted user turn is saved before the AI request, and a successful assistant reply updates the same session archive. A failed AI request can therefore leave its user turn in the local archive. Detected truncated replies are not saved as successful assistant messages.

### Sent to Google

To generate an AI reply, the app sends the persona's system instruction and active user/assistant conversation history to Gemini. Teacup's instruction includes the local mindfulness guide.

The app does not automatically attach the saved preferred name. A user may still identify themselves through what they type. The app does not anonymize message contents or promise that Google cannot process them. Google's API policies apply to submitted content.

### Other privacy characteristics

The current code includes no app account system, advertising integration, app-owned cloud conversation database, or analytics SDK. Its privacy manifest declares no tracking and identifies its preference-storage API use.

The Gemini session uses an ephemeral URLSession configuration with URL caching and cookie storage disabled. These client settings do not control Google's server-side policies.

Deleting a device archive removes the app's local files. It does not issue a deletion request to Google for previously submitted content.

## 15. Settings and user control

Settings is presented as **Your space** and currently includes:

| Control or information | Behavior |
| --- | --- |
| Preferred-name field | Shows the saved name and allows editing, up to 40 characters |
| Save name | Trims whitespace, requires a nonempty value, saves it, and displays a status message |
| Log out | Closes Settings, clears the preferred name and consent version, and returns to the welcome screen; saved chat archives remain |
| On-device archive explanation | Explains local storage and the distinction between returning home and deleting archives |
| Delete all saved chats | Requires confirmation before removing local conversation archives |
| Deletion result | Displays success or an error message |
| Read Terms & Conditions | Reopens the terms sheet |
| AI & privacy explanation | Discloses Gemini transmission and keyword-scanner limits |
| Google data-policy link | Opens the provider's published API policies |
| Done | Dismisses Settings |

Deleting chats does not reset the preferred name or onboarding consent. Settings does not currently provide a saved-conversation browser, API-key editor, or model-selection control.

## 16. Reply completeness and service reliability

The app includes several recovery mechanisms so a failed request does not silently become a duplicate turn or a seemingly finished, cut-off reply.

### Complete-reply handling

The configured generation allowance starts at **4,096 tokens**. The default model receives a **LOW** thinking setting. Shared prompts request concise, complete responses, usually around 80–160 words, with a finished final sentence.

If Gemini reports **MAX_TOKENS**, the client discards that incomplete result and regenerates the same turn once with an **8,192-token** allowance. If it is still truncated, the app shows an explicit retry error. The word range is a prompt instruction, not a strict word-count filter.

Thinking tokens can consume the generation allowance. The earlier 800-token setting was observed producing a MAX_TOKENS result with most of its allowance used for thinking. The current implementation addresses that specific failure.

### Temporary server failures

For HTTP 500, 502, 503, and 504, the client makes up to two automatic retries per generation request, using exponential backoff and a small random delay. It honors short Retry-After values up to ten seconds; a longer cooldown returns control to the user. Cancellation stops pending retries.

A truncation regeneration is a separate generation request and can also encounter server-retry handling. The app does not promise a fixed maximum of three network calls for every possible user turn.

### Errors the interface distinguishes

- Missing API credentials or invalid model configuration.
- Rejected credentials or access restrictions.
- Unavailable or retired models.
- Quota/rate-limit responses.
- Temporary provider unavailability.
- Offline or interrupted connections.
- Provider-blocked responses.
- Empty or malformed replies.
- Persistent output truncation.
- Missing Teacup guide data.
- Local conversation-save failures.

Quota, credential, model, safety, and decoding failures are not treated as transient server failures for automatic HTTP retry. Provider error bodies are not displayed verbatim. The service filters marked thinking text out of visible answers.

These mechanisms improve recovery; they cannot guarantee Gemini capacity, quota, connectivity, or an answer to every message. There is no automatic model-switching or offline generated-answer fallback.

## 17. What works without internet or a Gemini key

| Feature | Offline/local capability |
| --- | --- |
| Welcome screen and terms text | Available locally |
| Name entry, consent, and dashboard | Available locally |
| Companion descriptions, greetings, and starter labels | Available locally; submitting a starter still needs Gemini for an AI reply |
| On-device keyword scanning | Runs locally before a request |
| Urgent-support screen | Displays locally; using its contact actions needs the appropriate connectivity/service |
| Human-support directory and resource descriptions | Available locally; official websites need internet access |
| Local chat persistence and deletion | Local operations |
| Generated AI replies | Require network access, a working key, model access, and provider capacity/quota |

Teacup's guide is bundled, but the guide does not make Gemini run locally on the phone. The current app does not include a standalone, offline guided-exercise player.

## 18. Visual design and accessibility features

The interface uses a calm light palette, serif feature headings, rounded cards, large symbols, and companion-specific colors: green for Teacup, muted rose for Basket, warm gold/brown for Boomerang, and a warm orange/brown for Lantern.

Implementation details supporting usability include:

- Native SwiftUI text fields, buttons, links, forms, pickers, sheets, and navigation.
- Scrollable screens and flexible content widths.
- A bottom chat composer that respects safe-area placement.
- Native text styles throughout much of the interface.
- Accessibility labels for important controls and persona cards.
- Explicit checked/unchecked and expanded/collapsed states.
- Header traits and hidden decorative imagery where configured.
- Grouped message content and individually identifiable support links.
- Stable accessibility identifiers used by automated UI tests.

The app currently forces a light color scheme. These features are not a claim of a completed accessibility audit across all devices, text sizes, or assistive technologies.

## 19. Shared AI boundaries

Every persona receives shared instructions to:

- Identify its role as an AI wellness companion rather than a clinician or human friend.
- Avoid diagnosis, prescriptions, therapy claims, and promises of confidentiality.
- Use age-appropriate language.
- Avoid encouraging dependency, secrecy, dangerous actions, or isolation from trusted people.
- Validate emotions without endorsing harmful behavior.
- Avoid insulting sarcasm and mocking distress.
- Encourage immediate human support for danger or harmful requests.
- Refer to the app's curated resource cards or Help now rather than generating contact details.
- Maintain these boundaries if asked to ignore the instructions or change personas.

Prompt boundaries guide the model; they are not equivalent to a complete safety guarantee. The deterministic keyword interceptor and fixed resource catalog provide separate app-controlled behavior.

## 20. Technical structure

White Lotus is written in Swift with SwiftUI. It uses native URLSession REST requests to Gemini and does not require a Python runtime, a Python Gemini SDK, or a separate database server to launch the app.

| Component | Main responsibility |
| --- | --- |
| `MentalWellnessApp.swift` | App startup and welcome/dashboard routing |
| `Views/WelcomeView.swift` | Name entry, consent, lotus illustration, and Begin Journey |
| `Views/SafetyAgreementView.swift` | Terms sheet and current consent version |
| `Views/DashboardView.swift` | Four companion cards, explanations, and main navigation |
| `Views/ChatView.swift` | Chat interface, composer, loading/error states, and support presentation |
| `Views/SettingsView.swift` | Name changes, logout/reset access, terms, archive deletion, and privacy explanations |
| `Views/CrisisInterventionView.swift` | Urgent human-support interface |
| `Views/SupportResourcesView.swift` | Optional resource cards and topic directory |
| `Views/Theme.swift` | Shared palette, companion surfaces, and button styling |
| `ViewModels/ChatViewModel.swift` | Session state, safety-first sending, prompt preparation, retries, saves, and cancellation |
| `Models/Persona.swift` | Personality definitions, greetings, starter prompts, and system instructions |
| `Models/ChatMessage.swift` | Message and session data structures |
| `Models/SupportResource.swift` | Fixed resource catalog and local topic matching |
| `Services/GeminiService.swift` | Request encoding, provider communication, response parsing, and recovery |
| `Services/Secrets.swift` | Safe credential loader and model configuration; reads a key from the generated app Info.plist or a Run environment override |
| `Services/SafetyInterceptor.swift` | Hardcoded pre-request keyword checks |
| `Services/MindfulnessDataLoader.swift` | Runtime loading of Teacup's bundled guide |
| `Services/LocalChatStore.swift` | Protected local JSON archive storage and deletion |
| `Resources/mindfulness_data.txt` | Teacup's three-practice educational reference guide |
| `Resources/PrivacyInfo.xcprivacy` | App privacy manifest |

The public `Config/App.xcconfig` optionally includes the ignored `Config/Secrets.local.xcconfig`, keeping the real key out of source control. A blank `Config/Secrets.example.xcconfig` is provided. The project includes a shared Xcode scheme and test targets. Running on a physical iPhone requires an appropriate Xcode signing team and device setup. The demo client sends requests directly to Google; production credential management would require further work before broad distribution.

## 21. Verification already performed

The recorded verification includes:

- Simulator builds of the native application.
- **27 unit/service tests** covering request payloads, output limits, truncation recovery, server retry behavior, cancellation, keyword interception, guide loading, local persistence, and resource matching.
- An onboarding UI flow covering name/consent gating, terms display, dashboard access, companion navigation, crisis interception, and completed-onboarding persistence.
- A support UI flow covering Teacup's bullying recommendations without an API key, resource-directory navigation, urgent escalation, and return to the dashboard.
- A logout UI flow covering return to an empty welcome screen, cleared consent, persistence after relaunch, and successful onboarding with a new name.
- Visual inspection of welcome, dashboard, terms, urgent-support, and human-support layouts.
- Live synthetic AI checks confirming complete replies for Lantern, Teacup, and Basket after the reply-length changes.

The new resource UI test initially exposed an accessibility-identifier propagation issue, which was corrected and passed a targeted rerun. Details are recorded in `VERIFICATION.md`.

Live Boomerang checks encountered provider capacity/quota failures. That does not demonstrate a distinct Boomerang model failure: all four personas share the configured model. It does mean an uninterrupted live demonstration cannot be assumed.

Physical-device installation, real phone/SMS handoff, every supported OS version, and a comprehensive accessibility audit have not been verified by the recorded simulator tests. No test automatically contacted a crisis counselor or other person.

## 22. Features not currently included

The current build does **not** include:

- A mood tracker, daily check-in history, symptom scoring, or mental health diagnosis.
- Journaling pages, habit streaks, badges, or progress analytics.
- A saved-conversation browser, chat search, archive export, or reopening an old session.
- Cross-device chat synchronization or an app-owned cloud backup service.
- Voice input/output, audio calls with the AI, image analysis, or file attachments.
- Streaming word-by-word AI responses.
- A local/on-device language model or offline AI conversation.
- A vector-search retrieval pipeline or a fine-tuned companion model.
- In-app calendars, timers, scheduled reminders, or notifications.
- GPS-based resource discovery, automatic country detection, or global hotline coverage.
- Automatic communication with parents, schools, counselors, emergency services, or support organizations.
- Clinician supervision, a clinical risk model, guaranteed resource availability, or guaranteed AI reliability.
- In-app model/API-key management, payments, or subscriptions.
- Dark-mode styling or completed App Store/TestFlight distribution.

This list separates the implemented prototype from possible future additions. It is not a promise that those additions are planned.

## 23. Suggested presentation sequence

| Order | Demonstration | Main feature to highlight |
| --- | --- | --- |
| 1 | Enter a name, read the terms, accept, and Begin Journey | Personalization, transparency, and deliberate consent |
| 2 | Open Teacup with presentation-related anxiety | Local-document grounding and a calming companion style |
| 3 | Open Basket with a friendship concern | Validation and listening |
| 4 | Open Boomerang with a request for a clean joke | A lighter conversational support option |
| 5 | Open Lantern with several tests to study for | Breaking overwhelm into a small next action |
| 6 | Use Teacup with a bullying-related message | Optional app-owned human-support recommendations |
| 7 | Show the directory's urgent action or a synthetic keyword test | The separate urgent-support path and blocked AI submission |
| 8 | Open Settings | User control over the name, terms access, and local archives |

Use synthetic examples when demonstrating the urgent-support flow. Showing the screen is sufficient; a demo should not initiate a real call, text, or support chat. Check provider access before a live AI demonstration.

More example prompts are included in `DEMO_GUIDE.md`.

## 24. A concise explanation for a judge or audience

> White Lotus is an iOS wellness companion that lets users choose the kind of support they need. Teacup offers grounding from a local mindfulness guide, Basket focuses on listening, Boomerang provides a lighthearted break, and Lantern helps turn overwhelming tasks into small steps. The app keeps its conversation archives on the device while clearly disclosing that Gemini processes messages for AI replies. It also includes an on-device keyword safety check and links to human-support resources, with optional suggestions for everyday concerns and a separate urgent-support screen.

## 25. Reference files and resource catalog

Project documents:

- `README.md` — Setup, configuration, architecture, and implementation decisions.
- `DEMO_GUIDE.md` — Example prompts and demonstration guidance.
- `VERIFICATION.md` — Test evidence and recorded implementation limits.
- `AGENTS.md` and `PRD.md` — Original requirements; use the current implementation and this rundown to distinguish delivered features from earlier plans.

The current optional-resource catalog links to these official pages:

- [StopBullying.gov — Get Help Now](https://www.stopbullying.gov/resources/get-help-now)
- [NAMI Teen & Young Adult HelpLine](https://www.nami.org/nami-helpline/teen-young-adult-helpline/)
- [NAMI National Warmline Directory](https://helplinefaqs.nami.org/article/577-nami-national-warmline-directory)
- [United Way 211](https://211.org/)

These links describe the catalog currently shipped in the app. Their listings, eligibility, and availability can change; the app directs users to the organizations' maintained pages. Urgent-support destinations were verified through the connected helpline directory during development.
