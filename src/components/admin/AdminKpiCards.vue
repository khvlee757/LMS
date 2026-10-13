<script setup>
import { RouterLink } from "vue-router";
import {
  ArrowRight,
  BookOpen,
  CircleDollarSign,
  GraduationCap,
  Users,
} from "lucide-vue-next";

defineProps({
  grossSalesByCurrency: { type: Array, required: true },
  platformFeesByCurrency: { type: Array, required: true },
  learnersCount: { type: Number, required: true },
  instructorsCount: { type: Number, required: true },
  coursesCount: { type: Number, required: true },
  publishedCoursesCount: { type: Number, required: true },
  booksCount: { type: Number, required: true },
  publishedBooksCount: { type: Number, required: true },
  pendingApplicationsCount: { type: Number, required: true },
  totalAccountsCount: { type: Number, required: true },
  loading: { type: Boolean, default: false },
  money: { type: Function, required: true },
});
</script>

<template>
  <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
    <!-- Revenue Card -->
    <div class="rounded-xl border border-border bg-white p-5 shadow-xs">
      <div class="flex items-center justify-between">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Gross Sales</span>
        <span class="grid size-9 place-items-center rounded-lg bg-emerald-50 text-emerald-700">
          <CircleDollarSign :size="18" />
        </span>
      </div>
      <div class="mt-3">
        <p class="text-2xl font-black text-foreground">
          <template v-if="grossSalesByCurrency.length">
            {{ money(grossSalesByCurrency[0][1], grossSalesByCurrency[0][0]) }}
          </template>
          <template v-else>NGN 0.00</template>
        </p>
        <p class="mt-1 flex items-center gap-1 text-xs text-muted-foreground">
          <span class="font-bold text-emerald-700">10% Platform fee:</span>
          <span>
            {{ platformFeesByCurrency.length ? money(platformFeesByCurrency[0][1], platformFeesByCurrency[0][0]) : 'NGN 0.00' }}
          </span>
        </p>
      </div>
      <div class="mt-4 border-t border-border/60 pt-3">
        <RouterLink to="/admin/payments" class="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
          View orders ledger <ArrowRight :size="12" />
        </RouterLink>
      </div>
    </div>

    <!-- Learners Card -->
    <div class="rounded-xl border border-border bg-white p-5 shadow-xs">
      <div class="flex items-center justify-between">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Total Learners</span>
        <span class="grid size-9 place-items-center rounded-lg bg-blue-50 text-blue-700">
          <GraduationCap :size="18" />
        </span>
      </div>
      <div class="mt-3">
        <p class="text-2xl font-black text-foreground">{{ loading ? '...' : learnersCount }}</p>
        <p class="mt-1 text-xs text-muted-foreground">
          {{ totalAccountsCount }} total accounts registered
        </p>
      </div>
      <div class="mt-4 border-t border-border/60 pt-3">
        <RouterLink to="/admin/users" class="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
          Manage user directory <ArrowRight :size="12" />
        </RouterLink>
      </div>
    </div>

    <!-- Instructors Card -->
    <div class="rounded-xl border border-border bg-white p-5 shadow-xs">
      <div class="flex items-center justify-between">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Instructors</span>
        <span class="grid size-9 place-items-center rounded-lg bg-amber-50 text-amber-700">
          <Users :size="18" />
        </span>
      </div>
      <div class="mt-3">
        <p class="text-2xl font-black text-foreground">{{ loading ? '...' : instructorsCount }}</p>
        <p class="mt-1 flex items-center gap-1 text-xs" :class="pendingApplicationsCount > 0 ? 'text-amber-700 font-bold' : 'text-muted-foreground'">
          <span v-if="pendingApplicationsCount > 0">⚡ {{ pendingApplicationsCount }} pending review</span>
          <span v-else>All applications reviewed</span>
        </p>
      </div>
      <div class="mt-4 border-t border-border/60 pt-3">
        <RouterLink to="/admin/applications" class="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
          Application desk <ArrowRight :size="12" />
        </RouterLink>
      </div>
    </div>

    <!-- Catalog Card -->
    <div class="rounded-xl border border-border bg-white p-5 shadow-xs">
      <div class="flex items-center justify-between">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Courses & Books</span>
        <span class="grid size-9 place-items-center rounded-lg bg-emerald-50 text-primary">
          <BookOpen :size="18" />
        </span>
      </div>
      <div class="mt-3">
        <p class="text-2xl font-black text-foreground">
          {{ coursesCount }} <span class="text-sm font-semibold text-muted-foreground">courses</span>
        </p>
        <p class="mt-1 text-xs text-muted-foreground">
          {{ publishedCoursesCount }} published · {{ booksCount }} books ({{ publishedBooksCount }} published)
        </p>
      </div>
      <div class="mt-4 border-t border-border/60 pt-3">
        <RouterLink to="/admin/courses" class="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
          Browse content catalog <ArrowRight :size="12" />
        </RouterLink>
      </div>
    </div>
  </div>
</template>
