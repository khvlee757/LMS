<script setup>
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

defineProps({
  name: { type: String, default: "" },
  nameError: { type: String, default: "" },
  email: { type: String, default: "" },
  emailError: { type: String, default: "" },
  phone: { type: String, default: "" },
  phoneError: { type: String, default: "" },
});

defineEmits(["update:name", "update:email", "update:phone"]);
</script>

<template>
  <div class="contents">
    <div class="flex items-center gap-2 border-b border-border pb-2 pt-1 sm:col-span-2">
      <span class="text-xs font-bold text-primary">01</span>
      <h3 class="text-base font-bold">Account details</h3>
    </div>

    <!-- Full name -->
    <div class="space-y-1.5 sm:col-span-2">
      <Label for="name" class="text-base font-semibold text-foreground">
        Full Name
      </Label>
      <Input
        id="name"
        :model-value="name"
        type="text"
        autocomplete="name"
        placeholder="Enter your full name"
        class="h-12 border-border bg-white text-base"
        :aria-invalid="Boolean(nameError)"
        :aria-describedby="nameError ? 'name-error' : undefined"
        @update:model-value="$emit('update:name', $event)"
      />
      <p v-if="nameError" id="name-error" role="alert" class="text-sm text-red-500">
        {{ nameError }}
      </p>
    </div>

    <!-- Email -->
    <div class="space-y-1.5">
      <Label for="email" class="text-base font-semibold text-foreground">
        Email
      </Label>
      <Input
        id="email"
        :model-value="email"
        type="email"
        autocomplete="email"
        placeholder="you@example.com"
        class="h-12 border-border bg-white text-base"
        :aria-invalid="Boolean(emailError)"
        :aria-describedby="emailError ? 'email-error' : undefined"
        @update:model-value="$emit('update:email', $event)"
      />
      <p v-if="emailError" id="email-error" role="alert" class="text-sm text-red-500">
        {{ emailError }}
      </p>
    </div>

    <!-- Phone -->
    <div class="space-y-1.5">
      <Label for="phone" class="text-base font-semibold text-foreground">
        Phone Number
      </Label>
      <Input
        id="phone"
        :model-value="phone"
        type="tel"
        autocomplete="tel"
        inputmode="tel"
        placeholder="+234 801 234 5678"
        class="h-12 border-border bg-white text-base"
        :aria-invalid="Boolean(phoneError)"
        :aria-describedby="phoneError ? 'phone-error' : undefined"
        @update:model-value="$emit('update:phone', $event)"
      />
      <p class="text-sm leading-6 text-muted-foreground">
        Include your country calling code, for example +234 or +44.
      </p>
      <p v-if="phoneError" id="phone-error" role="alert" class="text-sm text-red-500">
        {{ phoneError }}
      </p>
    </div>
  </div>
</template>
