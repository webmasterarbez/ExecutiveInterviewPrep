import { FormEvent, ReactNode, useEffect, useState } from "react"
import { Head, Link, router, useForm, usePage } from "@inertiajs/react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { statusBadge } from "@/lib/status"

import type { PageProps } from "@/types/inertia"

type InterviewRequestDetail = {
  id: number
  meeting_title: string | null
  meeting_date: string | null
  company_name: string | null
  contact_person_name: string | null
  contact_person_title: string | null
  contact_person_background: string | null
  executive_context: string | null
  executive_objectives: string | null
  call_transcript: string | null
  audio_recording_url: string | null
  status: string
  error_message: string | null
  created_at: string
}

type TalkingPoint = { point: string; detail: string; supporting_research: string }
type LikelyQuestion = {
  topic: string
  question: string
  suggested_context: string
  supporting_research: string
}
type TitledItem = { title: string; detail: string }

type BriefingDetail = {
  talking_points: TalkingPoint[]
  likely_questions: LikelyQuestion[]
  opportunities: TitledItem[]
  risks: TitledItem[]
  key_facts: string[]
  created_at: string
}

type ResearchDetail = {
  company_overview: string | null
  company_news: string | null
  person_bio: string | null
  person_social_profiles: string | null
  industry_context: string | null
  research_sources: string | null
}

type ShowProps = PageProps<{
  interview_request: InterviewRequestDetail
  briefing: BriefingDetail | null
  research: ResearchDetail | null
}>

const READ_ONLY_FIELDS: Array<{ key: keyof InterviewRequestDetail; label: string }> = [
  { key: "meeting_title", label: "Meeting title" },
  { key: "meeting_date", label: "Meeting date" },
  { key: "company_name", label: "Company" },
  { key: "contact_person_name", label: "Contact person" },
  { key: "contact_person_title", label: "Contact title" },
  { key: "contact_person_background", label: "Contact background" },
  { key: "executive_objectives", label: "Your objectives" },
  { key: "executive_context", label: "Additional context" },
]

function toDatetimeLocal(iso: string | null) {
  return iso ? iso.slice(0, 16) : ""
}

function formatDateTime(iso: string | null) {
  if (!iso) return "—"
  return new Date(iso).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZone: "UTC",
  })
}

function ExpandableItem({
  summary,
  label = "supporting research",
  children,
}: {
  summary: ReactNode
  label?: string
  children: ReactNode
}) {
  const [open, setOpen] = useState(false)
  return (
    <li className="border-b border-hairline last:border-b-0">
      <button
        type="button"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        className="block w-full cursor-pointer px-4 py-3 text-left hover:bg-surface"
      >
        {summary}
        <span className="mt-1 block text-xs text-ink-muted">
          {open ? `Hide ${label}` : `Show ${label}`}
        </span>
      </button>
      {open && (
        <div className="border-t border-hairline bg-surface px-4 py-3 text-sm text-ink-body whitespace-pre-wrap">
          {children}
        </div>
      )}
    </li>
  )
}

function BriefingList({ children }: { children: ReactNode }) {
  return (
    <ul className="mt-4 overflow-hidden rounded-md border border-hairline bg-page">
      {children}
    </ul>
  )
}

export default function InterviewRequestShow() {
  const { props } = usePage<ShowProps>()
  const request = props.interview_request
  const briefing = props.briefing
  const research = props.research
  const errors = props.errors ?? {}
  const badge = statusBadge(request.status)
  const editable = request.status === "intake_review"
  const inProgress =
    request.status === "pending_research" || request.status === "researching"

  useEffect(() => {
    if (!inProgress) return
    const interval = setInterval(() => {
      router.reload({ only: ["interview_request", "briefing", "research"] })
    }, 5000)
    return () => clearInterval(interval)
  }, [inProgress])

  const retry = () => {
    router.post(`/interview_requests/${request.id}/retry`, {}, { preserveScroll: true })
  }

  const form = useForm({
    meeting_title: request.meeting_title ?? "",
    meeting_date: toDatetimeLocal(request.meeting_date),
    company_name: request.company_name ?? "",
    contact_person_name: request.contact_person_name ?? "",
    contact_person_title: request.contact_person_title ?? "",
    contact_person_background: request.contact_person_background ?? "",
    executive_objectives: request.executive_objectives ?? "",
    executive_context: request.executive_context ?? "",
  })

  const save = (e: FormEvent) => {
    e.preventDefault()
    form.patch(`/interview_requests/${request.id}`, { preserveScroll: true })
  }

  const confirm = () => {
    router.post(`/interview_requests/${request.id}/confirm`, {}, { preserveScroll: true })
  }

  const title = request.meeting_title ?? "Interview request"

  return (
    <>
      <Head title={title}>
        <meta name="description" content="Review and confirm the details captured from your intake call." />
        <meta property="og:title" content={title} />
        <meta property="og:description" content="Review and confirm the details captured from your intake call." />
      </Head>
      <AppShell>
        <PageHeader
          title={title}
          description={`Requested ${formatDateTime(request.created_at)}`}
          actions={<Badge tone={badge.tone}>{badge.label}</Badge>}
        />

        {props.flash?.notice && (
          <p className="mt-6 text-sm text-accent">{props.flash.notice}</p>
        )}
        {props.flash?.alert && (
          <p className="mt-6 text-sm text-danger-display">{props.flash.alert}</p>
        )}
        {request.status === "failed" && (
          <div className="callout callout-danger mt-6">
            <p className="text-sm">
              {request.error_message ?? "The research pipeline failed."}
            </p>
            <Button type="button" variant="danger" size="sm" className="mt-3" onClick={retry}>
              Retry research
            </Button>
          </div>
        )}

        {inProgress && (
          <div className="callout callout-accent mt-6">
            <p className="text-sm">
              {request.status === "pending_research"
                ? "Research is queued and will start shortly."
                : "Researching the company, person, and industry — this usually takes a few minutes."}{" "}
              This page updates automatically.
            </p>
          </div>
        )}

        <div className="callout mt-6">
          <p className="text-sm">
            Callback number on file:{" "}
            <strong>{props.current_user?.phone_number ?? "none set"}</strong>{" "}
            — <Link href="/profile">edit in profile</Link>
          </p>
        </div>

        {briefing && (
          <section className="mt-10 max-w-2xl">
            <h2>Your briefing</h2>
            <p className="mt-2 text-sm text-ink-muted">
              Synthesized {formatDateTime(briefing.created_at)}. Click any talking
              point or question to see the research behind it.
            </p>

            <h3 className="mt-8">Talking points</h3>
            <BriefingList>
              {briefing.talking_points.map((item, i) => (
                <ExpandableItem
                  key={i}
                  summary={
                    <>
                      <span className="block text-sm font-medium text-ink-display">
                        {item.point}
                      </span>
                      <span className="mt-1 block text-sm text-ink-body">{item.detail}</span>
                    </>
                  }
                >
                  {item.supporting_research}
                </ExpandableItem>
              ))}
            </BriefingList>

            <h3 className="mt-8">Likely questions</h3>
            <BriefingList>
              {briefing.likely_questions.map((item, i) => (
                <ExpandableItem
                  key={i}
                  summary={
                    <>
                      <span className="block text-xs font-medium uppercase tracking-wide text-ink-muted">
                        {item.topic}
                      </span>
                      <span className="mt-1 block text-sm font-medium text-ink-display">
                        {item.question}
                      </span>
                      <span className="mt-1 block text-sm text-ink-body">
                        {item.suggested_context}
                      </span>
                    </>
                  }
                >
                  {item.supporting_research}
                </ExpandableItem>
              ))}
            </BriefingList>

            <h3 className="mt-8">Opportunities</h3>
            <ul className="mt-4 space-y-3">
              {briefing.opportunities.map((item, i) => (
                <li key={i} className="rounded-md border border-hairline bg-page px-4 py-3">
                  <span className="block text-sm font-medium text-ink-display">{item.title}</span>
                  <span className="mt-1 block text-sm text-ink-body">{item.detail}</span>
                </li>
              ))}
            </ul>

            <h3 className="mt-8">Risks</h3>
            <ul className="mt-4 space-y-3">
              {briefing.risks.map((item, i) => (
                <li key={i} className="rounded-md border border-hairline bg-page px-4 py-3">
                  <span className="block text-sm font-medium text-ink-display">{item.title}</span>
                  <span className="mt-1 block text-sm text-ink-body">{item.detail}</span>
                </li>
              ))}
            </ul>

            <h3 className="mt-8">Key facts</h3>
            <ul className="mt-4 list-disc space-y-1 pl-5">
              {briefing.key_facts.map((fact, i) => (
                <li key={i} className="text-sm text-ink-body">
                  {fact}
                </li>
              ))}
            </ul>
          </section>
        )}

        {research && (
          <section className="mt-10 max-w-2xl">
            <h2>Research</h2>
            <p className="mt-2 text-sm text-ink-muted">
              The raw research the briefing was built from.
            </p>
            <ul className="mt-4 overflow-hidden rounded-md border border-hairline bg-page">
              {(
                [
                  ["Company overview", research.company_overview],
                  ["Recent company news", research.company_news],
                  ["Contact person", research.person_bio],
                  ["Public profiles", research.person_social_profiles],
                  ["Industry context", research.industry_context],
                  ["Sources", research.research_sources],
                ] as Array<[string, string | null]>
              )
                .filter(([, text]) => !!text)
                .map(([label, text]) => (
                  <ExpandableItem
                    key={label}
                    label="details"
                    summary={
                      <span className="block text-sm font-medium text-ink-display">{label}</span>
                    }
                  >
                    {text}
                  </ExpandableItem>
                ))}
            </ul>
          </section>
        )}

        {editable ? (
          <section className="mt-10 max-w-2xl">
            <h2>Review the details</h2>
            <p className="mt-2 text-sm text-ink-muted">
              These were captured from your call. Correct anything that's off,
              add context, then confirm to start the research.
            </p>
            <form onSubmit={save} className="mt-6 space-y-4">
              <div className="space-y-2">
                <label htmlFor="meeting_title">Meeting title</label>
                <Input
                  id="meeting_title"
                  value={form.data.meeting_title}
                  aria-invalid={!!errors.meeting_title}
                  onChange={(e) => form.setData("meeting_title", e.target.value)}
                />
                {errors.meeting_title && (
                  <p className="text-xs text-danger-display">{errors.meeting_title}</p>
                )}
              </div>
              <div className="space-y-2">
                <label htmlFor="meeting_date">Meeting date</label>
                <Input
                  id="meeting_date"
                  type="datetime-local"
                  value={form.data.meeting_date}
                  aria-invalid={!!errors.meeting_date}
                  onChange={(e) => form.setData("meeting_date", e.target.value)}
                />
                {errors.meeting_date && (
                  <p className="text-xs text-danger-display">{errors.meeting_date}</p>
                )}
              </div>
              <div className="space-y-2">
                <label htmlFor="company_name">Company</label>
                <Input
                  id="company_name"
                  value={form.data.company_name}
                  onChange={(e) => form.setData("company_name", e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label htmlFor="contact_person_name">Contact person</label>
                <Input
                  id="contact_person_name"
                  value={form.data.contact_person_name}
                  onChange={(e) => form.setData("contact_person_name", e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label htmlFor="contact_person_title">Contact title</label>
                <Input
                  id="contact_person_title"
                  value={form.data.contact_person_title}
                  onChange={(e) => form.setData("contact_person_title", e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label htmlFor="contact_person_background">Contact background</label>
                <Textarea
                  id="contact_person_background"
                  placeholder="LinkedIn highlights, career history, anything you know about them"
                  value={form.data.contact_person_background}
                  onChange={(e) => form.setData("contact_person_background", e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label htmlFor="executive_objectives">Your objectives</label>
                <Textarea
                  id="executive_objectives"
                  value={form.data.executive_objectives}
                  onChange={(e) => form.setData("executive_objectives", e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label htmlFor="executive_context">Additional context</label>
                <Textarea
                  id="executive_context"
                  value={form.data.executive_context}
                  onChange={(e) => form.setData("executive_context", e.target.value)}
                />
              </div>
              <div className="flex items-center gap-3">
                <Button type="submit" variant="secondary" disabled={form.processing}>
                  Save details
                </Button>
                <Button type="button" onClick={confirm} disabled={form.processing}>
                  Confirm — start research
                </Button>
              </div>
            </form>
          </section>
        ) : (
          <section className="mt-10 max-w-2xl">
            <h2>Meeting details</h2>
            <dl className="mt-6 space-y-4">
              {READ_ONLY_FIELDS.map(({ key, label }) => (
                <div key={key}>
                  <dt className="text-xs font-medium text-ink-muted">{label}</dt>
                  <dd className="mt-1 text-sm text-ink-body whitespace-pre-wrap">
                    {key === "meeting_date"
                      ? formatDateTime(request.meeting_date)
                      : (request[key] as string | null) || "—"}
                  </dd>
                </div>
              ))}
            </dl>
          </section>
        )}

        {request.call_transcript && (
          <section className="mt-10 max-w-2xl">
            <h2>Call transcript</h2>
            {request.audio_recording_url && (
              <p className="mt-2 text-xs text-ink-muted">
                Recording hosted by ElevenLabs:{" "}
                <a href={request.audio_recording_url} target="_blank" rel="noreferrer">
                  open conversation
                </a>
              </p>
            )}
            <pre className="mt-4 max-h-96 overflow-y-auto whitespace-pre-wrap rounded-md border border-hairline bg-surface p-4 text-sm text-ink-body">
              {request.call_transcript}
            </pre>
          </section>
        )}
      </AppShell>
    </>
  )
}
