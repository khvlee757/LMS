<script setup>
import { computed } from "vue";

const props = defineProps({ password: { type: String, default: "" } });
const checks = computed(() => [
  { label: "8+ characters", valid: props.password.length >= 8 },
  { label: "Uppercase", valid: /[A-Z]/.test(props.password) },
  { label: "Lowercase", valid: /[a-z]/.test(props.password) },
  { label: "Number", valid: /\d/.test(props.password) },
  { label: "Symbol", valid: /[^A-Za-z0-9\s]/.test(props.password) },
]);
const strength = computed(() => checks.value.filter((check) => check.valid).length);
const label = computed(() => {
  if (!props.password) return "Not set";
  if (strength.value < 3) return "Weak";
  if (strength.value < 5) return "Fair";
  return "Strong";
});
</script>

<template>
  <div id="password-strength" class="space-y-2" aria-live="polite">
    <div class="flex items-center justify-between text-sm text-primary/75">
      <span>Password strength</span><span>{{ label }}</span>
    </div>
    <div class="grid grid-cols-5 gap-1" role="progressbar" :aria-valuenow="strength" aria-valuemin="0" aria-valuemax="5" :aria-valuetext="label" aria-label="Password strength">
      <span v-for="segment in 5" :key="segment" class="h-1 rounded-full" :class="segment <= strength ? 'bg-primary' : 'bg-primary/15'" />
    </div>
    <ul class="flex flex-wrap gap-x-3 gap-y-1 text-sm text-primary/70">
      <li v-for="check in checks" :key="check.label"><span aria-hidden="true">{{ check.valid ? '✓' : '○' }}</span> {{ check.label }}</li>
    </ul>
  </div>
</template>
