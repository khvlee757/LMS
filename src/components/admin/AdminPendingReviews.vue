<script setup>
import { RouterLink } from "vue-router";
import { UserCheck } from "lucide-vue-next";

defineProps({
  applications: { type: Array, required: true },
  totalApplicationsCount: { type: Number, required: true },
  reviewApplication: { type: Function, required: true },
});
</script>

<template>
  <section class="rounded-xl border border-border bg-white shadow-xs">
    <div class="flex items-center justify-between border-b border-border px-5 py-4">
      <div class="flex items-center gap-2">
        <UserCheck :size="18" class="text-primary" />
        <h2 class="font-extrabold text-foreground">Pending Instructor Reviews</h2>
      </div>
      <RouterLink to="/admin/applications" class="text-xs font-bold text-primary hover:underline">
        View all ({{ totalApplicationsCount }})
      </RouterLink>
    </div>

    <div v-if="!applications.length" class="p-8 text-center text-xs text-muted-foreground">
      No pending instructor applications right now. All reviews are up to date!
    </div>

    <div v-else class="divide-y divide-border">
      <article
        v-for="app in applications"
        :key="app.user_id"
        class="flex flex-col justify-between gap-3 p-4 sm:flex-row sm:items-center"
      >
        <div>
          <p class="font-bold text-foreground">
            {{ app.profile?.full_name || app.profile?.email || 'Applicant' }}
          </p>
          <p class="text-xs text-muted-foreground">
            {{ app.professional_title }} at {{ app.organization }} · {{ app.expertise }}
          </p>
          <p class="mt-0.5 text-[11px] text-muted-foreground">
            Submitted {{ new Date(app.created_at).toLocaleDateString() }}
          </p>
        </div>
        <div class="flex items-center gap-2">
          <RouterLink
            to="/admin/applications"
            class="rounded-md border border-primary/30 px-3 py-1.5 text-xs font-bold text-primary hover:bg-secondary"
          >
            Verify Details
          </RouterLink>
          <button
            type="button"
            class="rounded-md border border-border px-3 py-1.5 text-xs font-bold text-foreground hover:bg-secondary"
            @click="reviewApplication(app, 'rejected')"
          >
            Reject
          </button>
          <button
            type="button"
            class="rounded-md bg-primary px-3 py-1.5 text-xs font-bold text-white hover:bg-primary/90"
            @click="reviewApplication(app, 'approved')"
          >
            Approve
          </button>
        </div>
      </article>
    </div>
  </section>
</template>
