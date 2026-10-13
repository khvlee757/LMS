<script setup>
import { RouterLink } from "vue-router";
import { CircleDollarSign, ReceiptText } from "lucide-vue-next";

const props = defineProps({
  orders: { type: Array, required: true },
  courses: { type: Array, required: true },
  books: { type: Array, required: true },
  money: { type: Function, required: true },
  printReceipt: { type: Function, required: true },
});

function getProductName(order) {
  if (order.product_type === "course") {
    return props.courses.find((c) => c.id === order.course_id)?.title || "Course";
  }
  return props.books.find((b) => b.id === order.book_id)?.title || "Book";
}
</script>

<template>
  <section class="rounded-xl border border-border bg-white shadow-xs">
    <div class="flex items-center justify-between border-b border-border px-5 py-4">
      <div class="flex items-center gap-2">
        <CircleDollarSign :size="18" class="text-primary" />
        <h2 class="font-extrabold text-foreground">Recent Payments</h2>
      </div>
      <RouterLink to="/admin/payments" class="text-xs font-bold text-primary hover:underline">
        View all payments
      </RouterLink>
    </div>

    <div v-if="!orders.length" class="p-8 text-center text-xs text-muted-foreground">
      No payment orders recorded yet.
    </div>

    <div v-else class="divide-y divide-border">
      <div
        v-for="order in orders"
        :key="order.id"
        class="flex items-center justify-between p-4 text-xs"
      >
        <div>
          <p class="font-bold text-foreground">{{ order.receipt_number }}</p>
          <p class="text-muted-foreground">
            {{ getProductName(order) }}
          </p>
          <p class="text-[11px] text-muted-foreground">
            {{ new Date(order.created_at).toLocaleDateString() }}
          </p>
        </div>
        <div class="text-right">
          <p class="font-extrabold text-foreground">{{ money(order.amount_minor, order.currency) }}</p>
          <span
            class="inline-block rounded px-1.5 py-0.5 text-[10px] font-bold uppercase"
            :class="order.status === 'paid' ? 'bg-emerald-50 text-emerald-800' : 'bg-secondary text-muted-foreground'"
          >
            {{ order.status }}
          </span>
          <div v-if="order.status === 'paid'" class="mt-1">
            <button
              type="button"
              class="inline-flex items-center gap-1 font-bold text-primary hover:underline"
              @click="printReceipt(order)"
            >
              <ReceiptText :size="12" /> Receipt
            </button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
