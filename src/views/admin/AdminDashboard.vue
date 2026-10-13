<script setup>
import { computed, onMounted } from "vue";
import { RouterLink } from "vue-router";
import { Plus, UserCheck } from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";
import AdminKpiCards from "@/components/admin/AdminKpiCards.vue";
import AdminActivityChart from "@/components/admin/AdminActivityChart.vue";
import AdminQuickHub from "@/components/admin/AdminQuickHub.vue";
import AdminPendingReviews from "@/components/admin/AdminPendingReviews.vue";
import AdminRecentOrders from "@/components/admin/AdminRecentOrders.vue";

const {
  people,
  courses,
  books,
  applications,
  paymentOrders,
  loginActivity,
  loading,
  error,
  notice,
  pendingApplicationsCount,
  grossSalesByCurrency,
  platformFeesByCurrency,
  money,
  printReceipt,
  reviewApplication,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const learnersCount = computed(() => people.value.filter((p) => p.role === "student").length);
const instructorsCount = computed(() => people.value.filter((p) => p.role === "instructor").length);
const adminsCount = computed(() => people.value.filter((p) => p.role === "super_admin").length);
const publishedCoursesCount = computed(() => courses.value.filter((c) => c.published).length);
const publishedBooksCount = computed(() => books.value.filter((b) => b.published).length);

const recentOrders = computed(() => paymentOrders.value.slice(0, 5));
const pendingApplications = computed(() =>
  applications.value.filter((app) => app.status === "pending").slice(0, 4)
);

// Daily logins past 7 days
const pastWeekLogins = computed(() => {
  const dates = new Map();
  const today = new Date().toISOString().slice(0, 10);
  for (let i = 6; i >= 0; i--) {
    const d = new Date(`${today}T00:00:00.000Z`);
    d.setUTCDate(d.getUTCDate() - i);
    const key = d.toISOString().slice(0, 10);
    dates.set(key, {
      label: d.toLocaleDateString(undefined, { weekday: "short" }),
      count: 0,
    });
  }
  for (const activity of loginActivity.value) {
    if (dates.has(activity.activity_date)) {
      dates.get(activity.activity_date).count += 1;
    }
  }
  return [...dates.values()];
});

const maxDailyLogins = computed(() => {
  const counts = pastWeekLogins.value.map((d) => d.count);
  return Math.max(1, ...counts);
});
</script>

<template>
  <div class="space-y-8">
    <!-- Header Banner -->
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="rounded bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">OPERATIONAL DASHBOARD</span>
          <span class="text-xs text-muted-foreground">Real-time statistics</span>
        </div>
        <h1 class="mt-1 text-3xl font-extrabold text-foreground sm:text-4xl">Platform Executive Overview</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          Monitor community activity, course distributions, instructor vetting, and transaction revenue.
        </p>
      </div>

      <div class="flex items-center gap-2">
        <RouterLink
          to="/admin/courses"
          class="inline-flex min-h-10 items-center gap-2 rounded-md bg-primary px-4 text-xs font-bold text-white hover:bg-primary/90"
        >
          <Plus :size="15" /> Create Course
        </RouterLink>
        <RouterLink
          to="/admin/applications"
          class="inline-flex min-h-10 items-center gap-2 rounded-md border border-border bg-white px-4 text-xs font-bold text-foreground hover:bg-secondary"
        >
          <UserCheck :size="15" /> Reviews ({{ pendingApplicationsCount }})
        </RouterLink>
      </div>
    </header>

    <!-- Notification / Errors -->
    <div v-if="error" role="alert" class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      {{ error }}
    </div>
    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <!-- Top KPI Grid -->
    <AdminKpiCards
      :gross-sales-by-currency="grossSalesByCurrency"
      :platform-fees-by-currency="platformFeesByCurrency"
      :learners-count="learnersCount"
      :instructors-count="instructorsCount"
      :courses-count="courses.length"
      :published-courses-count="publishedCoursesCount"
      :books-count="books.length"
      :published-books-count="publishedBooksCount"
      :pending-applications-count="pendingApplicationsCount"
      :total-accounts-count="people.length"
      :loading="loading"
      :money="money"
    />

    <!-- Analytics & Login Trends -->
    <div class="grid gap-6 lg:grid-cols-3">
      <AdminActivityChart
        :past-week-logins="pastWeekLogins"
        :max-daily-logins="maxDailyLogins"
        :learners-count="learnersCount"
        :instructors-count="instructorsCount"
        :admins-count="adminsCount"
      />

      <AdminQuickHub
        :pending-applications-count="pendingApplicationsCount"
      />
    </div>

    <!-- Split Sections: Pending Reviews & Recent Payments -->
    <div class="grid gap-6 lg:grid-cols-2">
      <AdminPendingReviews
        :applications="pendingApplications"
        :total-applications-count="applications.length"
        :review-application="reviewApplication"
      />

      <AdminRecentOrders
        :orders="recentOrders"
        :courses="courses"
        :books="books"
        :money="money"
        :print-receipt="printReceipt"
      />
    </div>
  </div>
</template>
