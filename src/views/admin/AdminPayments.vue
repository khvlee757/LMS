<script setup>
import { computed, onMounted, ref } from "vue";
import {
  CircleDollarSign,
  Download,
  ReceiptText,
  Search,
} from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";

const {
  paymentOrders,
  people,
  courses,
  books,
  loading,
  error,
  notice,
  money,
  printReceipt,
  grossSalesByCurrency,
  platformFeesByCurrency,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const searchQuery = ref("");
const statusFilter = ref("all");

const filteredPayments = computed(() => {
  let list = paymentOrders.value;
  if (statusFilter.value !== "all") {
    list = list.filter((o) => o.status === statusFilter.value);
  }

  const q = searchQuery.value.trim().toLowerCase();
  if (q) {
    list = list.filter((order) => {
      const buyer = people.value.find((p) => p.user_id === order.buyer_id);
      const product =
        order.product_type === "course"
          ? courses.value.find((c) => c.id === order.course_id)
          : books.value.find((b) => b.id === order.book_id);
      return [
        order.receipt_number,
        order.provider_reference,
        buyer?.email,
        buyer?.full_name,
        product?.title,
      ].some((val) => String(val || "").toLowerCase().includes(q));
    });
  }

  return list;
});
</script>

<template>
  <div class="space-y-6">
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Financials & Payments Ledger</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          Verified sales, automated platform fee allocations, and printable customer receipts.
        </p>
      </div>
      <div class="text-xs font-semibold text-muted-foreground">
        <span>{{ paymentOrders.length }} Total Recorded Orders</span>
      </div>
    </header>

    <div v-if="error" role="alert" class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      {{ error }}
    </div>
    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <!-- Revenue Summary Cards -->
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div class="rounded-xl border border-border bg-white p-5 shadow-xs">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Total Verified Sales</span>
        <p class="mt-2 text-2xl font-black text-foreground">
          <template v-if="grossSalesByCurrency.length">
            {{ money(grossSalesByCurrency[0][1], grossSalesByCurrency[0][0]) }}
          </template>
          <template v-else>NGN 0.00</template>
        </p>
        <p class="mt-1 text-xs text-muted-foreground">Completed Paystack customer checkouts</p>
      </div>

      <div class="rounded-xl border border-border bg-white p-5 shadow-xs">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Platform Share (10%)</span>
        <p class="mt-2 text-2xl font-black text-emerald-800">
          <template v-if="platformFeesByCurrency.length">
            {{ money(platformFeesByCurrency[0][1], platformFeesByCurrency[0][0]) }}
          </template>
          <template v-else>NGN 0.00</template>
        </p>
        <p class="mt-1 text-xs text-muted-foreground">Retained platform commission</p>
      </div>

      <div class="rounded-xl border border-border bg-white p-5 shadow-xs sm:col-span-2 lg:col-span-1">
        <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">Instructor Allocations</span>
        <p class="mt-2 text-2xl font-black text-foreground">
          <template v-if="grossSalesByCurrency.length && platformFeesByCurrency.length">
            {{ money(grossSalesByCurrency[0][1] - platformFeesByCurrency[0][1], grossSalesByCurrency[0][0]) }}
          </template>
          <template v-else>NGN 0.00</template>
        </p>
        <p class="mt-1 text-xs text-muted-foreground">Net earnings designated to content creators</p>
      </div>
    </div>

    <!-- Search & Filter Controls -->
    <div class="flex flex-col gap-4 rounded-xl border border-border bg-white p-4 shadow-xs sm:flex-row sm:items-center sm:justify-between">
      <div class="relative flex-1 max-w-md">
        <Search :size="16" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input
          v-model="searchQuery"
          type="search"
          placeholder="Search receipt #, buyer, item, or reference..."
          class="h-10 w-full rounded-md border border-border bg-white pl-9 pr-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div class="flex rounded-md border border-border bg-secondary/50 p-0.5 text-xs font-semibold">
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'all' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'all'"
        >
          All
        </button>
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'paid' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'paid'"
        >
          Paid ({{ paymentOrders.filter(o => o.status === 'paid').length }})
        </button>
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'pending' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'pending'"
        >
          Pending
        </button>
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'failed' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'failed'"
        >
          Failed
        </button>
      </div>
    </div>

    <!-- Payments Ledger Table -->
    <div class="overflow-x-auto rounded-xl border border-border bg-white shadow-xs">
      <table class="w-full min-w-[850px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/60 text-xs font-bold uppercase tracking-wider text-muted-foreground">
          <tr>
            <th class="px-5 py-3.5">Receipt #</th>
            <th class="px-5 py-3.5">Learner (Buyer)</th>
            <th class="px-5 py-3.5">Purchased Item</th>
            <th class="px-5 py-3.5">Gross Paid</th>
            <th class="px-5 py-3.5">Platform Fee</th>
            <th class="px-5 py-3.5">Status</th>
            <th class="px-5 py-3.5 text-right">Receipt</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border">
          <tr v-for="order in filteredPayments" :key="order.id" class="transition-colors hover:bg-secondary/20">
            <!-- Receipt -->
            <td class="px-5 py-4 font-mono text-xs font-bold text-foreground">
              {{ order.receipt_number }}
              <span class="block text-[11px] font-sans font-normal text-muted-foreground">
                {{ new Date(order.created_at).toLocaleDateString() }}
              </span>
            </td>

            <!-- Buyer -->
            <td class="px-5 py-4 text-xs">
              <span class="font-semibold text-foreground">
                {{ people.find(p => p.user_id === order.buyer_id)?.full_name || 'Learner' }}
              </span>
              <span class="block text-muted-foreground">
                {{ people.find(p => p.user_id === order.buyer_id)?.email || '' }}
              </span>
            </td>

            <!-- Item -->
            <td class="px-5 py-4">
              <span class="block font-semibold text-foreground">
                {{ order.product_type === 'course' ? courses.find(c => c.id === order.course_id)?.title : books.find(b => b.id === order.book_id)?.title || 'Learning Item' }}
              </span>
              <span class="block text-xs uppercase tracking-wider text-muted-foreground">{{ order.product_type }}</span>
            </td>

            <!-- Gross -->
            <td class="px-5 py-4 font-bold text-foreground">
              {{ money(order.amount_minor, order.currency) }}
            </td>

            <!-- Platform fee -->
            <td class="px-5 py-4 text-xs font-semibold text-emerald-800">
              {{ money(order.platform_fee_minor, order.currency) }}
            </td>

            <!-- Status -->
            <td class="px-5 py-4">
              <span
                class="inline-block rounded-full px-2.5 py-0.5 text-xs font-bold capitalize"
                :class="{
                  'bg-emerald-100 text-emerald-800': order.status === 'paid',
                  'bg-amber-100 text-amber-800': order.status === 'pending',
                  'bg-red-100 text-red-800': order.status === 'failed',
                }"
              >
                {{ order.status }}
              </span>
            </td>

            <!-- Action -->
            <td class="px-5 py-4 text-right">
              <button
                type="button"
                :disabled="order.status !== 'paid'"
                class="inline-flex items-center gap-1.5 rounded-md border border-primary/30 px-3 py-1.5 text-xs font-bold text-primary hover:bg-secondary disabled:cursor-not-allowed disabled:opacity-40"
                @click="printReceipt(order)"
              >
                <ReceiptText :size="13" /> Print
              </button>
            </td>
          </tr>

          <tr v-if="!filteredPayments.length">
            <td colspan="7" class="px-5 py-12 text-center text-sm text-muted-foreground">
              No transactions match your search or filter.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

