<script setup>
import { computed } from "vue";

const props = defineProps({
  message: { type: String, default: "" },
  variant: { type: String, default: "error" },
  toast: { type: Boolean, default: false },
});
const isError = computed(() => props.variant === "error");
</script>

<template>
  <div
    v-if="message"
    :role="isError ? 'alert' : 'status'"
    :aria-live="isError ? 'assertive' : 'polite'"
    class="border px-4 py-3 text-sm"
    :class="[
      toast && 'fixed right-4 top-4 z-50 max-w-md bg-white shadow-lg',
      isError ? 'border-red-200 bg-red-50 text-red-800' : 'border-emerald-200 bg-emerald-50 text-emerald-800',
    ]"
  >
    {{ message }}
  </div>
</template>
