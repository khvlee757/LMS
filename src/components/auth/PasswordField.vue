<script setup>
import { ref } from "vue";
import { Eye, EyeOff } from "lucide-vue-next";
import { Input } from "@/components/ui/input";

const props = defineProps({
  id: { type: String, required: true },
  modelValue: { type: String, default: "" },
  placeholder: { type: String, default: "" },
  autocomplete: { type: String, default: "new-password" },
  describedBy: { type: String, default: undefined },
  invalid: { type: Boolean, default: false },
});
const emit = defineEmits(["update:modelValue"]);
const visible = ref(false);
</script>

<template>
  <div class="relative">
    <Input
      :id="id"
      :model-value="props.modelValue"
      :type="visible ? 'text' : 'password'"
      :autocomplete="autocomplete"
      :placeholder="placeholder"
      :aria-invalid="invalid"
      :aria-describedby="describedBy"
      class="h-12 border-primary/30 bg-white pr-12 text-base"
      @update:model-value="emit('update:modelValue', $event)"
    />
    <button
      type="button"
      :aria-label="visible ? 'Hide password' : 'Show password'"
      class="absolute inset-y-0 right-0 flex w-12 items-center justify-center rounded-r-md text-primary/70 outline-none focus-visible:ring-2 focus-visible:ring-primary"
      @click="visible = !visible"
    >
      <EyeOff v-if="visible" :size="20" aria-hidden="true" />
      <Eye v-else :size="20" aria-hidden="true" />
    </button>
  </div>
</template>
