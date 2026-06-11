# ElevenLabs voice-intake setup

One-time manual configuration in the [ElevenLabs dashboard](https://elevenlabs.io/app/agents) so executives can call in and have their intake conversation turn into an Interview Request. The app side (webhook endpoint, parsing, review flow) is already built — this doc covers only what must be clicked together in the dashboard.

## 1. Create the intake agent

Agents → New agent (blank). Set:

**First message:**

> Hi, this is your interview prep assistant. Tell me about the meeting or interview you're preparing for, and I'll get the research started.

**System prompt:**

```
You are a calm, efficient research-intake assistant for busy executives.
The caller is preparing for an upcoming interview, board meeting, or
high-stakes conversation. Your only job is to collect the details below,
then confirm them back and end the call. Be brief and natural — one
question at a time, no lectures, no advice.

Collect:
1. A short title for the meeting (e.g. "Board interview with Acme CEO").
2. The company or organization involved.
3. Who they are meeting: full name and role/title.
4. When the meeting is happening (date, and time if known).
5. The type of meeting (interview, board meeting, pitch, press, other).
6. What the executive wants to achieve (objectives).
7. Any extra context they want the research to take into account
   (background on the person, history, sensitivities).

If the caller already volunteered an item, don't re-ask it. If they don't
know an item, accept that and move on.

Before ending the call: read back a one-sentence summary of the company,
person, date, and objective, and ask if it's correct. Fix anything they
correct. Then tell them they'll see the details on their dashboard to
review and confirm, and say goodbye.
```

## 2. Configure data collection (Analysis tab)

Agent → **Analysis** → **Data collection**. Add these items — the identifiers must match exactly; the webhook parses them by name:

| Identifier | Type | Description for the LLM |
|---|---|---|
| `meeting_title` | string | Short title for the meeting, e.g. "Board interview with Acme CEO" |
| `company_name` | string | The company or organization the caller is meeting with |
| `contact_person_name` | string | Full name of the person the caller is meeting |
| `contact_person_title` | string | Role or title of that person |
| `meeting_date` | string | Meeting date/time in ISO 8601 if possible (e.g. 2026-06-20T14:00); date alone is fine |
| `executive_objectives` | string | What the caller wants to achieve in the meeting |
| `executive_context` | string | Meeting type plus any extra context, background, or sensitivities the caller mentioned |

## 3. Attach a phone number

Phone numbers → Buy (or import a Twilio number) → assign the intake agent to it. This is the number executives dial.

Caller matching: the app matches the inbound caller ID against the E.164 phone number saved on the user's profile (`/profile`). **A user must save their phone number in the app before calling**, otherwise the call is ignored (the webhook logs and acks).

## 4. Enable the post-call webhook

Agents → Settings (workspace level) → **Post-call webhooks** → add webhook:

- URL (development): `https://<your-static-domain>.ngrok-free.app/webhooks/elevenlabs`
- URL (production): `https://eip.vrtcl.network/webhooks/elevenlabs`
- Type: **post_call_transcription** (audio webhooks are not needed; leave "send audio data" off)
- Auth: **HMAC** — copy the generated secret.

Put the secret in the app environment:

```
ELEVENLABS_WEBHOOK_SECRET=wsec_...
```

(`.env` in development — `bin/dev` loads it via foreman; an unset secret makes the endpoint return 401 and logs a loud `KeyError`.)

## 5. Development tunnel (ngrok)

ElevenLabs must reach your machine. With a free ngrok account you get one static domain (claim it at dashboard.ngrok.com → Domains):

```bash
ngrok http --domain=<your-static-domain>.ngrok-free.app 5000
```

Note: the Rails dev server runs on **port 5000** on this machine (`bin/rails-dev foreman start -f Procfile.dev`) because port 3000 is held by another local service.

## 6. Smoke test

1. Save your phone number at `/profile` (the number you'll call from).
2. Start the dev server and ngrok.
3. Call the agent's phone number, describe a meeting, let it confirm and hang up.
4. Within ~a minute the dashboard shows the new request as **Needs review**.
5. Open it, correct/extend the details, hit **Confirm — start research** → status becomes **Research queued**.
