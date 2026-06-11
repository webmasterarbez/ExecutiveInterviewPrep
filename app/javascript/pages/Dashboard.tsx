import { Head, usePage } from "@inertiajs/react"
import { AppShell } from "@/components/AppShell"
import { Badge, type BadgeProps } from "@/components/ui/badge"

import type { PageProps } from "@/types/inertia"

type InterviewRequestItem = {
  id: number
  meeting_title: string | null
  company_name: string | null
  contact_person_name: string | null
  meeting_date: string | null
  status: string
  error_message: string | null
  created_at: string
}

type DashboardProps = PageProps<{ interview_requests: InterviewRequestItem[] }>

const STATUS_BADGES: Record<string, { label: string; tone: BadgeProps["tone"] }> = {
  intake_review: { label: "Needs review", tone: "signal" },
  pending_research: { label: "Research queued", tone: "neutral" },
  researching: { label: "Researching", tone: "accent" },
  briefing_ready: { label: "Briefing ready", tone: "solid" },
  completed: { label: "Completed", tone: "muted" },
  failed: { label: "Failed", tone: "danger" },
}

function formatMeetingDate(iso: string | null) {
  if (!iso) return null
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    timeZone: "UTC",
  })
}

export default function Dashboard() {
  const { props } = usePage<DashboardProps>()
  const requests = props.interview_requests ?? []

  return (
    <>
      <Head title="Dashboard">
        <meta name="description" content="Your interview requests and briefing statuses." />
        <meta property="og:title" content="Dashboard" />
        <meta property="og:description" content="Your interview requests and briefing statuses." />
      </Head>
      <AppShell>
        <h1>Dashboard</h1>
        <p className="mt-2">Your interview requests and their briefing status.</p>

        {requests.length === 0 ? (
          <div className="mt-8 rounded-md border border-hairline bg-surface px-6 py-10 text-center">
            <p className="font-medium text-ink-display">No interview requests yet</p>
            <p className="mt-2 text-sm text-ink-muted">
              Call in and brief the agent on your upcoming meeting — your requests
              and briefings will show up here.
            </p>
          </div>
        ) : (
          <ul className="mt-8 divide-y divide-hairline overflow-hidden rounded-md border border-hairline bg-page">
            {requests.map((request) => {
              const badge = STATUS_BADGES[request.status] ?? {
                label: request.status,
                tone: "neutral" as const,
              }
              const meetingDate = formatMeetingDate(request.meeting_date)
              return (
                <li key={request.id}>
                  <div className="flex items-center gap-3 px-4 py-3">
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-medium text-ink-display">
                        {request.meeting_title ?? "Untitled meeting"}
                      </div>
                      <div className="truncate text-xs text-ink-muted">
                        {[request.company_name, request.contact_person_name, meetingDate]
                          .filter(Boolean)
                          .join(" · ")}
                      </div>
                      {request.status === "failed" && request.error_message && (
                        <div className="mt-1 text-xs text-danger-display">
                          {request.error_message}
                        </div>
                      )}
                    </div>
                    <Badge tone={badge.tone}>{badge.label}</Badge>
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </AppShell>
    </>
  )
}
