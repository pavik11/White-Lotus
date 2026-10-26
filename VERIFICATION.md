# Verification · 2026-10-25

## Initial implementation checks

- Xcode 26.5 (17F42) recognized the shared MentalWellness scheme and all three targets.
- Full Debug simulator build succeeded for arm64 and x86_64 with iOS deployment target 16.0.
- All app Swift sources separately passed Swift type checking against the iOS Simulator SDK with the iOS 16.0 deployment target, without source diagnostics.
- 13 unit/service tests passed on an iPhone 17 Pro simulator running iOS 26.5.
- The end-to-end UI test passed on the same simulator: preferred-name onboarding, mandatory safety checkbox, all four dashboard cards, Teacup chat, immediate crisis interception without a key, visible call/text controls, return home, and a fresh empty conversation.
- The actual bundled grounding guide was loaded by the hosted unit tests. Teacup includes its full contents; the other three personas never load it.
- Mock URLSession tests checked the exact requested default endpoint, API-key header, JSON system instruction, user/model history roles, provider safety blocks, malformed responses, missing keys, quota/model errors and all six crisis triggers with zero network calls.
- View-model tests checked loading transitions, local saves, retry without duplicate turns, and rejection of late responses after session cancellation.
- JSON persistence round-tripped both turns, preserved one file per session, excluded its directory from backup, and deleted local archives.
- Dashboard and crisis-screen screenshots were inspected for layout and readable controls.
- Project and privacy manifest passed plist validation. No TODO, FIXME, fatalError, or unimplemented functions remain in generated Swift source.

## Test-run notes

The first asset-catalog compilation stalled in Apple's simulator helper. A retry
succeeded with the original asset catalog and no project workaround. The initial
UI test used the web-link accessibility type for styled SwiftUI Links; iOS exposes
these controls as buttons. Correcting the test query produced a passing UI run.
No product-code change was required by either issue.

Xcode emitted its standard unused-AppIntents metadata warning and warnings about
not stripping Apple's already-signed XCTest libraries during unsigned simulator
testing. There were no Swift source compile errors.

## Initial implementation limits (superseded for Gemini by the update below)

A live Google response was not tested: no API key was provided, and the requested
Gemini 1.5 Flash default is deprecated. The native client is fully implemented;
configure a key and an explicitly available model as described in README.md.
The model-override setting intentionally does not silently change the requested
default. Provider and offline failure paths are handled in the UI.

The deployment target is iOS 16.0; the installed runtime used for execution is
26.5. Device signing, an iOS 16 runtime run, distribution signing, and actual
phone/SMS handoff require the corresponding local setup or physical device.
No crisis call, text, or live API submission was initiated by tests.

The PRD's Teen Line contact was not returned by the available verified helpline
directory, so no unverified number or hours were added. The required 988 route
is configured. The privacy copy was corrected to disclose Google transmission;
local archives do not make the Gemini request offline or anonymous.

## Reproduce

Open MentalWellness.xcodeproj, choose the MentalWellness scheme and an iPhone
simulator, then Product → Test. Tests do not require Gemini credentials.

## Gemini model repair · 2026-10-25

Live checks used the existing local API key without logging its value. Only synthetic
messages were sent; no saved conversation or personal user message was submitted.

- `models.list` authenticated successfully, but listed models did not all permit generation.
- `gemini-2.5-flash` returned HTTP 404: no longer available to new users; Google recommended 3.8 Flash.
- `gemini-4-argon`, the newest model in the catalog, returned HTTP 429 with zero free-tier quota.
- `gemini-3.8-flash` returned HTTP 503 high demand twice; 3.7 Flash also returned 503.
- `gemini-3.6-flash` and `gemini-3.5-flash-lite` both generated a text reply successfully.
- The default is now 3.6 Flash, the newest Flash version that generated a reply in these checks.
- Configuration uses a single default constant, trims whitespace, accepts `models/` resource
  names, and treats blank model overrides as the default. Explicit overrides still take priority.
- HTTP 404/410 errors identify the actual requested model and explain removing stale overrides.

These access and capacity results reflect this key/project at verification time and can change.

The actual Swift `GeminiService` also passed a live two-turn smoke check with the
bundled Teacup grounding text and full persona system prompt. The first synthetic
message introduced Alex and homework stress; the reply offered exercises from the
local guide. A follow-up asking for the name returned Alex, confirming history
encoding and response decoding work with the selected model.

Final simulator validation: `xcodebuild test -only-testing:MentalWellnessTests`
succeeded on the iPhone 17 Pro (iOS 26.5), with all 15 tests passing. Coverage includes
the 3.6 default endpoint, model-name normalization, blank overrides, invalid model
rejection without network access, model-specific 404/410 errors, safety interception,
chat history/session lifecycle, response parsing, and local storage. UI tests were
not rerun for this service/configuration change.

## White Lotus onboarding and transient-service recovery · 2026-10-25

- The configured `gemini-3.6-flash` returned HTTP 200 with a candidate for a synthetic
  hello request. This confirms current access, not uninterrupted provider availability.
  No real conversation text was used for this diagnostic and the key was not logged.
- Google's troubleshooting reference identifies 503 as temporary service overload or
  downtime: https://ai.google.dev/gemini-api/docs/troubleshooting
- The native service now retries HTTP 500/502/503/504 up to twice, with exponential
  backoff, jitter, cancellation, and bounded Retry-After handling. It leaves credentials,
  model availability, quota, safety and malformed responses to their specific error paths.
- All 20 unit/service tests passed. New cases cover 503 recovery and exhaustion,
  non-retryable client/quota failures, server cooldowns, invalid cooldown values, and
  cancellation during backoff. Existing safety, storage and chat lifecycle tests passed.
- The UI flow test passed, then passed again after the welcome spacing adjustment:
  name alone and consent alone cannot begin; Read Terms opens the disclosure without
  granting consent; Begin Journey opens all four companions; crisis interception still
  works without a key; relaunch preserves completed onboarding.
- Final simulator build passed after cosmetic lotus layering and terms-icon refinements.
  Project and privacy-manifest plist validation passed.
- The final welcome screenshot was visually inspected and saved as
  `Previews/white-lotus-welcome.png`. Terms typography and scrolling were also inspected
  using the test screenshot. The welcome fits the tested iPhone 17 Pro and remains
  scrollable on smaller displays or with larger text.
- Display name and dashboard branding are White Lotus. The bundle identifier is
  unchanged to preserve existing app storage. Users with the previous terms version
  see welcome again with their saved name prefilled; archives are retained.
- The requested privacy paragraph was corrected because Gemini receives message text
  and active history. The requested safety and medical-care paragraphs remain, with
  an added explanation of keyword-scanner limits and the U.S. help-resource scope.

Results: `/tmp/WhiteLotusTests.xcresult` (20 unit + 1 UI),
`/tmp/WhiteLotusLayoutTests.xcresult` (final-spacing UI flow), and
`/tmp/WhiteLotusFinalBuild.log` (successful final build).

## Simulator onboarding preview override repair · 2026-10-25

The screenshot launch used `-userName '' -safetyAgreementVersion 0`. These arguments
remained on the running simulator process and took precedence over persisted preferences,
so Begin Journey could save completion but RootView still read the forced empty name
and old terms version. This was a preview-launch issue, not a failed persistence write.

Confirmed the app's persistent preferences contained a name and current terms version,
then relaunched the installed app without any preview arguments. Verified the process
had no preference overrides and visually confirmed the personalized dashboard with all
four companions. No app preferences or chat archives were cleared. Future screenshot
previews must restore a normal launch before handing the simulator back to the user.

## Reply completeness and issue-specific human support · 2026-10-25

A live synthetic Lantern request reproduced the reported cutoff: the former
800-token configuration returned `MAX_TOKENS`, with 772 thinking tokens and only
32 candidate text tokens in the provider's usage metadata. This was generation
truncation, not solely a visual-layout issue. The client previously accepted
`MAX_TOKENS` as success.

The client now starts at 4,096 tokens and LOW thinking for the default model. It
regenerates once at 8,192 tokens on `MAX_TOKENS`, using the same original history.
A second truncation is an explicit retryable error; incomplete output is not saved
as a successful assistant turn. Other explicit model IDs omit thinking configuration
to avoid applying an unsupported setting. Message text uses natural vertical sizing.
Shared prompt instructions request concise, complete replies and discourage shouting.

Live checks through the actual Swift service returned complete replies for Lantern
(136 words), Teacup (129 words), and Basket (126 words). Boomerang's first check
exhausted 503 retries; a later check received 429. These provider capacity/quota
failures remain separate from output truncation. No personal chat text was submitted
and no key or raw provider body was logged.

Teacup now provides app-owned optional recommendations and a topic directory for
bullying, loneliness, feeling emotionally lost, and practical needs. The fixed
resources are StopBullying.gov, NAMI youth peer support, NAMI's Warmline Directory,
and United Way 211. Official pages were checked on this date. User text and saved
names never become URL parameters. Gemini is instructed not to generate contact
details. The directory notes the U.S. scope and points to official pages for current
hours and eligibility. Physically lost/stranded situations are distinguished from
feeling emotionally uncertain. Crisis keywords still run first and block requests;
the directory's urgent action cancels the active session and opens the same crisis UI.

Verification ran on a separate, newly created QA simulator, keeping the existing
simulator's preferences and real chat archives untouched. Its first startup stalled;
a scoped restart completed startup and allowed tests to run.

- All 27 unit/service tests passed, covering token limits, truncation recovery and
  exhaustion, thinking configuration, phrase matching, official link allowlisting,
  resources during service failure, cancellation, safety, session state and storage.
- The existing onboarding/session/crisis UI flow passed.
- The new support UI flow initially exposed a SwiftUI identifier-propagation issue:
  the card identifier overwrote its child link identifiers. Replacing it with an
  accessibility container preserved each resource link's identity.
- The targeted support UI test then passed: bullying recommendations without an API
  key, opening the directory, urgent escalation, and returning to the dashboard.
- The final support-directory screenshot was visually checked and saved to
  `Previews/teacup-human-support.png`. The app compiled successfully for the simulator.

Results: `/tmp/WhiteLotusReplySupportRetryTests.xcresult` (27 unit tests and existing
UI flow passed; original support identifier assertions failed), followed by
`/tmp/WhiteLotusSupportUITests.xcresult` (corrected support UI flow passed).
Synthetic live metadata: `/tmp/WhiteLotusLiveCheck.log` and
`/tmp/WhiteLotusBoomerangCheck.log`. Demo prompts and sources: `DEMO_GUIDE.md`.


## Your space logout/reset · 2026-10-25

- Added **Your space → Start fresh → Log out**, with an explanation that saved chats
  remain on the device. The action closes the Settings sheet before clearing the
  saved name and accepted terms version, allowing RootView to show fresh onboarding.
- All 27 unit/service tests passed. The new logout UI test passed: onboard, save a
  synthetic failed chat turn, return home, log out, verify an empty name and unchecked
  consent, relaunch without resetting test preferences, and onboard successfully as
  a different name.
- A newly created QA simulator failed Apple's first-boot data migration before app
  testing. It was removed after switching verification to the existing simulator.
- Debug UI automation now sets WELLNESS_ISOLATED_TEST_STATE to select a separate
  UserDefaults suite and temporary chat directory. Preference-reset hooks clear only
  that suite during isolated runs. Normal launches use the standard preferences and
  protected archive directory, and release builds ignore the test-only flag.
- A before/after digest check confirmed the normal profile and all nine normal chat
  archives were unchanged. The synthetic archive remained after logout and a new
  journey, confirming logout does not delete chat files.
- Relaunched the installed simulator build normally, without test or preview flags.
  Physical phones need the updated build installed from Xcode to show the new button.
- Updated README.md, DEMO_GUIDE.md, and WHITE_LOTUS_FEATURE_RUNDOWN.md.

Result bundle: `/tmp/WhiteLotusIsolatedLogoutTests.xcresult`.


## GitHub publication preparation · 2026-10-25

- Preserved the existing main-branch README commit from pavik11/White-Lotus.
- Moved the local Gemini key from Swift source into ignored Config/Secrets.local.xcconfig.
  Services/Secrets.swift now loads a generated Info.plist value, with the existing
  GEMINI_API_KEY Run-environment override retained. No real key is in tracked source.
- Added public Config/App.xcconfig, Config/Info.plist, and a blank
  Config/Secrets.example.xcconfig. The optional private include lets a fresh clone
  build without credentials while preserving local Home Screen launches with a key.
- Expanded .gitignore for private config, environment files, Xcode user settings,
  generated apps/builds/test results, signing material, and copied chat data.
  The shared scheme, source, assets, tests, screenshots, and documentation stay public.
- Rewrote README.md with features, screenshots, reproducible setup, iPhone steps,
  architecture, tests, privacy limits, and a table explaining every ignore category.
- All 27 unit/service tests passed. The configured local build succeeded and its
  generated Info.plist was checked to contain the existing local key without logging it.
- A clean export of the staged public files built successfully in a separate directory.
  It contained no private config, and its generated app Info.plist contained no API key.
- Scanned staged file contents and existing remote history for the actual local key
  and common credential patterns before creating the publication commit.
- Commit attribution uses the GitHub account's noreply address for this repository.

Local records: /tmp/WhiteLotusGitHubConfigTests.xcresult,
/tmp/WhiteLotusGitHubLocalBuild.log, and /tmp/WhiteLotusPublicBuild.log.
