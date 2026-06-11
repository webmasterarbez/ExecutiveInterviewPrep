import type { BadgeProps } from "@/components/ui/badge"

export type StatusBadge = { label: string; tone: BadgeProps["tone"] }

export const STATUS_BADGES: Record<string, StatusBadge> = {
  intake_review: { label: "Needs review", tone: "signal" },
  pending_research: { label: "Research queued", tone: "neutral" },
  researching: { label: "Researching", tone: "accent" },
  briefing_ready: { label: "Briefing ready", tone: "solid" },
  completed: { label: "Completed", tone: "muted" },
  failed: { label: "Failed", tone: "danger" },
}

export function statusBadge(status: string): StatusBadge {
  return STATUS_BADGES[status] ?? { label: status, tone: "neutral" }
}
