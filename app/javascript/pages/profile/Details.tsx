import { FormEvent } from "react"
import { Head, useForm, usePage } from "@inertiajs/react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { ProfileSubNav } from "./ProfileSubNav"

import type { PageProps } from "@/types/inertia"

export default function ProfileDetails() {
  const { props } = usePage<PageProps>()
  const user = props.current_user
  const errors = props.errors ?? {}

  const detailsForm = useForm({
    name: user?.name ?? "",
    phone_number: user?.phone_number ?? "",
  })
  const emailForm = useForm({ email: user?.email ?? "" })

  const submitDetails = (e: FormEvent) => {
    e.preventDefault()
    detailsForm.patch("/profile/details", { preserveScroll: true })
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    emailForm.patch("/profile/email", { preserveScroll: true })
  }

  return (
    <>
      <Head title="My details">
        <meta name="description" content="Update the email address you use to log in." />
        <meta property="og:title" content="My details" />
        <meta property="og:description" content="Update the email address you use to log in." />
      </Head>
      <AppShell>
        <PageHeader
          title="Profile"
          description="Manage your account."
          tabs={<ProfileSubNav active="details" />}
        />

        {props.flash?.notice && (
          <p className="mt-6 text-sm text-accent">{props.flash.notice}</p>
        )}

        <section className="mt-10 max-w-md">
          <form onSubmit={submitDetails} className="space-y-4">
            <div className="space-y-2">
              <label htmlFor="name">Name</label>
              <Input
                id="name"
                type="text"
                autoComplete="name"
                aria-invalid={!!errors.name}
                value={detailsForm.data.name}
                onChange={(e) => detailsForm.setData("name", e.target.value)}
              />
              {errors.name && (
                <p className="text-xs text-danger-display">{errors.name}</p>
              )}
            </div>
            <div className="space-y-2">
              <label htmlFor="phone_number">Phone number</label>
              <Input
                id="phone_number"
                type="tel"
                autoComplete="tel"
                placeholder="+1 212 555 0123"
                aria-invalid={!!errors.phone_number}
                value={detailsForm.data.phone_number}
                onChange={(e) => detailsForm.setData("phone_number", e.target.value)}
              />
              <p className="text-xs text-ink-muted">
                Used for briefing callbacks. Include your country code, e.g. +1 212 555 0123.
              </p>
              {errors.phone_number && (
                <p className="text-xs text-danger-display">{errors.phone_number}</p>
              )}
            </div>
            <Button type="submit" disabled={detailsForm.processing}>
              Update details
            </Button>
          </form>
        </section>

        <section className="mt-10 max-w-md">
          <form onSubmit={submit} className="space-y-4">
            <div className="space-y-2">
              <label htmlFor="email">Email</label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                required
                aria-invalid={!!errors.email}
                value={emailForm.data.email}
                onChange={(e) => emailForm.setData("email", e.target.value)}
              />
              {errors.email && (
                <p className="text-xs text-danger-display">{errors.email}</p>
              )}
            </div>
            <Button type="submit" disabled={emailForm.processing}>
              Update email
            </Button>
          </form>
        </section>
      </AppShell>
    </>
  )
}
