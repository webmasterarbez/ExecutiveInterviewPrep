# Executive Interview Prep

> **About these build-plan files:** Everything in `_build_plan/` (this PRD and the per-milestone folders) is a **temporary documentation and guidance artifact** for the initial build-out of this codebase. These files are not functional — no code, configuration, runtime logic, tests, or deployment process should import, read, reference, or depend on anything in `_build_plan/`. Once the initial milestones are built and shipped, the entire `_build_plan/` folder is expected to be deleted from the codebase. Do not treat it as long-living documentation.

## What we're building

Executive Interview Prep is a voice-activated research agent powered by ElevenLabs that allows executives to call in, describe an upcoming interview or informational meeting, and receive comprehensive research, talking points, and preparation insights to help them succeed.

The core flow is simple: an executive dials in and briefs the agent on their upcoming meeting. The app immediately begins researching the company, the person they're meeting with, industry context, and recent news. Once research is complete, the app calls the executive back, verbally walks them through key talking points and likely questions, and lets them ask follow-up questions. The executive also receives both an audio file and a written briefing they can reference anytime before the meeting.

Built on Rails 8 with React 19 frontend, PostgreSQL database, and integrated with ElevenLabs (voice), Claude API (synthesis), Perplexity (research), and AWS SES (email). The build is broken into 5 focused milestones, each delivering visible, testable functionality.

---

### What the app does

- **Voice call intake** — Executives dial a dedicated phone number, describe their meeting, and the agent records the full conversation with confirmation.
- **Information capture** — The app extracts structured details (company, person, date, objectives) and lets executives review and add context on the dashboard.
- **Deep research** — Automatic background research on the company, person, industry trends, and recent news via Perplexity.
- **Insight synthesis** — Claude synthesizes research into talking points, likely questions, opportunities, and risks tailored to the specific meeting.
- **Callback & verbal briefing** — Once synthesis is complete, the app calls back and the ElevenLabs agent verbally walks through the briefing in a coaching style.
- **Interactive Q&A** — During the callback, executives can ask follow-up questions and get immediate, conversational answers from the agent.
- **Audio briefing file** — A downloadable, high-quality audio version of the full briefing for anytime listening (in the car, on a flight, etc.).
- **Written preparation materials** — A comprehensive PDF briefing with company/person overview, talking points, likely questions, opportunities/risks, and key facts.

---

### Already provided by the Build New starter (Rails 8)

- User authentication (signup, login, password reset) with Devise
- User model and authenticated database schema
- Authenticated app shell with Inertia React integration
- Dashboard layout with sidebar navigation
- PostgreSQL database with Rails migrations
- Solid Queue background job processor (built into Rails 8)
- Dark mode support with Tailwind
- Tailwind CSS + shadcn UI components
- Rails convention over configuration MVC structure

---

### Out of scope (v1)

- **Multi-user accounts & team collaboration** — v1 is single-user per executive; team sharing and collaboration move to v2
- **Calendar & CRM integrations** — No auto-pulling data from LinkedIn, Salesforce, or calendar tools; executives provide context directly
- **Historical briefing archive** — Each call creates one briefing; saving and comparing past briefings is a v2 feature
- **Premium research sources** — v1 uses public web research only; access to Bloomberg, CapIQ, or paid research databases is v2+
- **Mobile app** — v1 is voice-native (works on any phone) but no dedicated mobile UI beyond the web dashboard
- **Scheduling & calendar integration** — No built-in scheduler; executives manually trigger calls and callbacks
- **Customizable research templates** — v1 has one standard research approach; custom themes/templates are v2+

---

### External integrations

#### ElevenLabs
Voice calls, speech synthesis, and callback mechanism.
Handles inbound calls from executives, records and transcribes conversations, generates natural-sounding verbal briefings, and initiates callbacks with the agent.
**Credentials needed:** ElevenLabs API key

#### Claude API
Research parsing, insight synthesis, and interactive Q&A.
Extracts structured information from call transcripts, synthesizes research into talking points and questions, and answers follow-up questions during callbacks.
**Credentials needed:** Claude API key (from Anthropic)

#### Perplexity API
Real-time web research on companies, people, and industry trends.
Gathers up-to-date information about the company, the person, recent news, and relevant industry context to fuel the briefing synthesis.
**Credentials needed:** Perplexity API key

#### AWS SES
Email delivery for sending briefing documents to executives.
Sends the written briefing document via email so executives can receive and reference it easily.
**Credentials needed:** AWS SES credentials (access key, secret key)

---

### Data model

#### User
The executive using the app. Starter template provides this.
- email — login identifier
- password — hashed password for authentication
- name — executive's full name
- phone_number — the number the agent calls back to
- preferences — user settings (time zone, etc.)

#### Interview Request
A single briefing request: the meeting or interview an executive is preparing for.
- user — which executive
- meeting_title — name/description of the meeting (e.g., "Board meeting with Acme CEO")
- meeting_date — when the meeting is scheduled
- company_name — organization being visited
- contact_person_name — who the executive is meeting with
- contact_person_title — their role/title
- contact_person_background — context about them (LinkedIn highlights, career history)
- executive_context — notes the executive provided during the intake call
- executive_objectives — what the executive wants to achieve
- call_transcript — the full transcript from the intake call
- audio_recording_url — the audio file of the intake call
- status — where the request is (pending_research, research_complete, briefing_ready, callback_scheduled, completed)
- created_at, updated_at

#### Research Data
The gathered research for an Interview Request.
- interview_request — which request this research belongs to
- company_overview — company size, sector, structure, recent announcements
- company_news — recent press releases, major announcements, market moves
- person_bio — the contact person's background, education, career history
- person_social_profiles — LinkedIn, Twitter, or other relevant profiles
- industry_context — relevant trends, market dynamics, competitive landscape
- research_sources — URLs and summaries of sources used
- created_at

#### Briefing
The synthesized briefing document for an Interview Request.
- interview_request — which request
- talking_points — key messages (5–10 points the executive should lead with)
- likely_questions — probable questions organized by topic, with suggested context
- opportunities — outcomes to push for, key wins to target
- risks — potential pitfalls, topics to tread carefully on
- key_facts — quick reference facts about company/person
- audio_file_url — the downloadable audio briefing
- pdf_file_url — the downloadable written briefing
- created_at
- callback_scheduled_at
- callback_completed_at

#### Follow-up Q&A
Questions asked during the callback conversation.
- interview_request — which request this Q&A is for
- question — what the executive asked
- answer — what the agent answered
- timestamp

---

## Milestone 1 — App setup & auth

Set up the core Rails 8 + React application with user authentication, database, and the authenticated dashboard shell. This is the foundation all other milestones build on.

### What gets built

- Rails 8 backend with MVC structure, routing, and middleware
- React 19 frontend with Inertia integration
- Database models for User, Interview Request, Research Data, Briefing, Follow-up Q&A
- Settings/profile page where users can view and edit their phone number and preferences
- Responsive UI (Tailwind + shadcn components)
- Configured Solid Queue for background jobs

### What this milestone explicitly does NOT include

- ElevenLabs phone integration
- Research or synthesis pipelines
- Callback mechanism or voice features
- Briefing generation or documents
- Any external API integrations beyond database

### Done when

You can sign up with an email/password, log in, access the authenticated dashboard with nav and sidebar, toggle dark mode, and access a settings page where you can view and edit your phone number. All pages are responsive and properly styled with Tailwind + shadcn.

---

## Milestone 2 — Voice intake & information capture

Build the voice call interface with ElevenLabs integration and the information capture dashboard. Executives can now call in, describe their meeting, and review extracted details.

### What gets built

- ElevenLabs phone agent that accepts inbound calls
- Voice agent interviews executives: collects company name, contact person, meeting date, meeting type, objectives, and context
- Call recording and transcription (via ElevenLabs)
- Agent confirms extracted details back to the executive before hanging up
- Dashboard page to view all past calls and their transcripts
- Information extraction: app parses the transcript and extracts structured fields (company, person, date, objectives, etc.)
- Interview Request creation from call data
- Dashboard form for executives to review extracted information, make corrections, and add additional context
- Status indicator showing which Interview Requests are pending research vs. ready for next steps
- Phone number on file is displayed and editable (from milestone 1 settings)

### What this milestone explicitly does NOT include

- Research or synthesis
- Callbacks or follow-up calls
- Audio or document generation
- Q&A functionality
- Email sending

### Done when

You can call the app's dedicated phone number, have a natural voice conversation with the ElevenLabs agent describing a meeting, and after hanging up, see that call logged on your dashboard. You can click into the call, see the extracted company/person/date/objectives information in a form, edit any details, add additional notes, and confirm the information is correct. The Interview Request is now ready for research.

---

## Milestone 3 — Research pipeline

Build the automated research pipeline. Once an Interview Request is ready, the app researches the company, person, and context, then synthesizes the findings into talking points, questions, and insights.

### What gets built

- Background job that triggers when an Interview Request is confirmed
- Perplexity API integration to research company, person, industry trends, and recent news
- Research results stored in Research Data entity
- Dashboard displays research status (pending, in progress, complete) for each request
- Claude API integration to synthesize research into:
  - Talking points (5–10 key messages)
  - Likely questions (organized by topic)
  - Opportunities (outcomes to target)
  - Risks (potential pitfalls)
  - Key facts (quick reference)
- Briefing entity created with synthesized insights
- Dashboard displays the complete briefing with all sections (talking points, questions, opportunities, risks, facts)
- Expandable sections: clicking a talking point or question shows supporting research behind it
- Status update: Interview Request moves to "briefing_ready"

### What this milestone explicitly does NOT include

- Callbacks or voice delivery
- Audio or PDF file generation
- Q&A functionality
- Email sending

### Done when

You confirm an Interview Request and the research pipeline kicks off automatically. Within a few moments, research completes and you see a dashboard page with all the synthesized briefing content: talking points, likely questions, opportunities, risks, and key facts. Each section is clear, scannable, and expandable to show the research behind it.

---

## Milestone 4 — Callbacks & interactive Q&A

Build the callback mechanism and interactive Q&A. Once a briefing is ready, the app calls the executive back and delivers the briefing verbally with live Q&A.

### What gets built

- Callback trigger: briefing can be marked ready for callback (automatic or manual via button)
- ElevenLabs callback agent that calls the executive's phone number on file
- Agent verbally walks through the briefing: talking points, likely questions, opportunities, risks, key context (in a conversational coaching style)
- After verbal delivery, agent opens for questions: "What would you like to know more about?"
- Executive asks follow-up questions via voice; agent listens and answers using Claude API
- Questions and answers are captured and stored in Follow-up Q&A entity
- Executive can ask multiple questions in one callback session
- Dashboard shows callback status (scheduled, completed)
- Dashboard displays the Q&A transcript from the callback for reference

### What this milestone explicitly does NOT include

- Audio file generation for the briefing
- PDF or document generation
- Email sending
- Scheduled callbacks (only on-demand in v1)
- Recording storage of callbacks beyond the Q&A transcript

### Done when

A briefing is ready, you request a callback (or it's triggered automatically), and the app calls you back. The ElevenLabs agent verbally briefs you on talking points, questions, opportunities, and risks in a natural, conversational way. After the briefing, you can ask follow-up questions by voice, and the agent answers in real-time. When the call ends, you can review the Q&A transcript on the dashboard.

---

## Milestone 5 — Audio & written briefings

Generate and deliver the audio and written briefing documents so executives have reference materials to review anytime before the meeting.

### What gets built

- Audio briefing generation: convert the full briefing (talking points, questions, opportunities, risks, facts) into high-quality speech using ElevenLabs TTS
- Audio file is downloadable from the dashboard
- Audio is structured clearly: labeled sections (Talking Points, Likely Questions, Opportunities, Risks, Key Facts) so the user knows where they are while listening
- Written briefing PDF generation with:
  - Executive summary
  - Company/person overview (pulled from research data)
  - Talking points
  - Likely questions with suggested context
  - Opportunities & risks
  - Key facts and statistics
  - Research sources/references
- PDF is clean, scannable, professional layout (Tailwind-styled or PDF library)
- PDF is downloadable from the dashboard
- Both files (audio + PDF) are available immediately after synthesis completes
- Dashboard displays download links for both files
- Optional: email the briefing document to the executive via AWS SES

### What this milestone explicitly does NOT include

- Scheduling delivery for later
- Multiple narrator voices or voice customization
- Streaming audio playback (download only)
- Custom branding or logo insertion
- Export to formats other than PDF

### Done when

After a briefing is synthesized, you see download buttons on the dashboard for both an audio file and a PDF. You can download the audio, listen to it in any player, and download the PDF to read or print. The audio is clear and professional, the PDF is well-formatted and easy to reference, and both contain the full briefing content (talking points, questions, opportunities, risks, key facts).