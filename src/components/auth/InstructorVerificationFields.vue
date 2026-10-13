<script setup>
import { Input } from "@/components/ui/input";

defineProps({
  organization: { type: String, default: "" },
  organizationError: { type: String, default: "" },
  professionalTitle: { type: String, default: "" },
  professionalTitleError: { type: String, default: "" },
  expertise: { type: String, default: "" },
  expertiseError: { type: String, default: "" },
  experienceYears: { type: [String, Number], default: "" },
  experienceYearsError: { type: String, default: "" },
  qualification: { type: String, default: "" },
  qualificationError: { type: String, default: "" },
  verificationUrl: { type: String, default: "" },
  verificationUrlError: { type: String, default: "" },
  teachingStatement: { type: String, default: "" },
  teachingStatementError: { type: String, default: "" },
});

defineEmits([
  "update:organization",
  "update:professionalTitle",
  "update:expertise",
  "update:experienceYears",
  "update:qualification",
  "update:verificationUrl",
  "update:teachingStatement",
]);
</script>

<template>
  <fieldset class="grid gap-4 border border-border bg-secondary/50 p-4 sm:col-span-2 sm:grid-cols-2 sm:p-5">
    <legend class="bg-secondary px-2 text-base font-bold text-primary">Instructor verification</legend>

    <label for="organization" class="space-y-1.5 text-base font-semibold">
      School or organization
      <Input
        id="organization"
        :model-value="organization"
        autocomplete="organization"
        maxlength="160"
        placeholder="School, company, or independent"
        class="h-12 border-primary/30 bg-white text-base"
        :aria-invalid="Boolean(organizationError)"
        aria-describedby="organization-error"
        @update:model-value="$emit('update:organization', $event)"
      />
      <span v-if="organizationError" id="organization-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ organizationError }}
      </span>
    </label>

    <label for="professional-title" class="space-y-1.5 text-base font-semibold">
      Professional title
      <Input
        id="professional-title"
        :model-value="professionalTitle"
        maxlength="120"
        placeholder="Teacher, lecturer, coach..."
        class="h-12 border-primary/30 bg-white text-base"
        :aria-invalid="Boolean(professionalTitleError)"
        aria-describedby="professional-title-error"
        @update:model-value="$emit('update:professionalTitle', $event)"
      />
      <span v-if="professionalTitleError" id="professional-title-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ professionalTitleError }}
      </span>
    </label>

    <label for="expertise" class="space-y-1.5 text-base font-semibold">
      Teaching subject or expertise
      <Input
        id="expertise"
        :model-value="expertise"
        maxlength="160"
        placeholder="What would you teach?"
        class="h-12 border-primary/30 bg-white text-base"
        :aria-invalid="Boolean(expertiseError)"
        aria-describedby="expertise-error"
        @update:model-value="$emit('update:expertise', $event)"
      />
      <span v-if="expertiseError" id="expertise-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ expertiseError }}
      </span>
    </label>

    <label for="experience-years" class="space-y-1.5 text-base font-semibold">
      Teaching experience (years)
      <Input
        id="experience-years"
        :model-value="experienceYears"
        type="number"
        min="0"
        max="60"
        step="1"
        inputmode="numeric"
        placeholder="0"
        class="h-12 border-primary/30 bg-white text-base"
        :aria-invalid="Boolean(experienceYearsError)"
        aria-describedby="experience-years-error"
        @update:model-value="$emit('update:experienceYears', $event)"
      />
      <span v-if="experienceYearsError" id="experience-years-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ experienceYearsError }}
      </span>
    </label>

    <label for="qualification" class="space-y-1.5 text-base font-semibold">
      Relevant qualifications
      <textarea
        id="qualification"
        :value="qualification"
        rows="3"
        maxlength="1000"
        placeholder="Degrees, certifications, or relevant experience"
        class="w-full resize-y border border-primary/30 bg-white px-3 py-2 text-base font-normal outline-none focus-visible:ring-2 focus-visible:ring-primary"
        :aria-invalid="Boolean(qualificationError)"
        aria-describedby="qualification-error"
        @input="$emit('update:qualification', $event.target.value)"
      />
      <span v-if="qualificationError" id="qualification-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ qualificationError }}
      </span>
    </label>

    <label for="verification-url" class="space-y-1.5 text-base font-semibold">
      Verification link
      <Input
        id="verification-url"
        :model-value="verificationUrl"
        type="url"
        maxlength="500"
        placeholder="https://institution.edu/profile"
        class="h-12 border-primary/30 bg-white text-base"
        :aria-invalid="Boolean(verificationUrlError)"
        aria-describedby="verification-url-help verification-url-error"
        @update:model-value="$emit('update:verificationUrl', $event)"
      />
      <span id="verification-url-help" class="block text-sm font-normal text-muted-foreground">
        Link a faculty page, professional profile, or portfolio.
      </span>
      <span v-if="verificationUrlError" id="verification-url-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ verificationUrlError }}
      </span>
    </label>

    <label for="teaching-statement" class="space-y-1.5 text-base font-semibold sm:col-span-2">
      What will learners gain from your course?
      <textarea
        id="teaching-statement"
        :value="teachingStatement"
        rows="3"
        maxlength="1500"
        placeholder="Briefly describe your teaching approach and course value."
        class="w-full resize-y border border-primary/30 bg-white px-3 py-2 text-base font-normal outline-none focus-visible:ring-2 focus-visible:ring-primary"
        :aria-invalid="Boolean(teachingStatementError)"
        aria-describedby="teaching-statement-error"
        @input="$emit('update:teachingStatement', $event.target.value)"
      />
      <span v-if="teachingStatementError" id="teaching-statement-error" role="alert" class="block text-sm font-normal text-red-600">
        {{ teachingStatementError }}
      </span>
    </label>
  </fieldset>
</template>
