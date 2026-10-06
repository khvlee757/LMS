<script setup>
import { onMounted, ref } from "vue";
import { RouterLink, useRoute } from "vue-router";
import { CheckCircle2, LoaderCircle } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";

const route = useRoute();
const loading = ref(true);
const errorMessage = ref("");
const order = ref(null);

onMounted(async () => {
  const reference = typeof route.query.reference === "string" ? route.query.reference : "";
  if (!reference || !supabase) {
    errorMessage.value = "The payment reference is missing.";
    loading.value = false;
    return;
  }
  const { data, error } = await supabase.functions.invoke("paystack-verify", {
    body: { reference },
  });
  if (error) errorMessage.value = error.message;
  else if (data?.status === "paid") order.value = data;
  else errorMessage.value = data?.error || "Paystack has not confirmed this payment.";
  loading.value = false;
});
</script>

<template>
  <section class="mx-auto max-w-xl border border-border bg-white p-6 text-center sm:p-10">
    <LoaderCircle v-if="loading" :size="28" class="mx-auto animate-spin text-primary" aria-hidden="true" />
    <template v-else-if="order">
      <CheckCircle2 :size="34" class="mx-auto text-emerald-700" aria-hidden="true" />
      <p class="mt-4 text-xs font-bold uppercase text-primary">Payment verified</p>
      <h1 class="mt-2 text-2xl font-extrabold">You’re all set</h1>
      <p class="mt-2 text-sm text-muted-foreground">Receipt {{ order.receiptNumber }}</p>
      <RouterLink :to="order.productType === 'course' ? `/courses/${order.courseId}` : '/books'" class="mt-6 inline-flex min-h-11 items-center justify-center bg-primary px-5 text-sm font-bold text-white hover:bg-primary/90">Continue</RouterLink>
    </template>
    <template v-else>
      <p class="text-xs font-bold uppercase text-red-700">Payment not confirmed</p>
      <h1 class="mt-2 text-2xl font-extrabold">No access was granted</h1>
      <p role="alert" class="mt-3 text-sm text-muted-foreground">{{ errorMessage }}</p>
      <RouterLink to="/courses" class="mt-6 inline-flex min-h-11 items-center justify-center border border-primary px-5 text-sm font-bold text-primary hover:bg-secondary">Back to courses</RouterLink>
    </template>
  </section>
</template>
