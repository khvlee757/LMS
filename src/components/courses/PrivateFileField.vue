<script setup>
import { ref } from "vue";
import { Download, FileUp, LoaderCircle } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";

const props = defineProps({
  modelValue: { type: String, default: "" },
  courseId: { type: String, default: "" },
  bookId: { type: String, default: "" },
  assignmentId: { type: String, default: "" },
  kind: { type: String, default: "material" },
  label: { type: String, default: "Private file" },
  readOnly: { type: Boolean, default: false },
});
const emit = defineEmits(["update:modelValue"]);
const bucket = "lms-private-files";
const input = ref(null);
const busy = ref(false);
const errorMessage = ref("");
const notice = ref("");
const maxBytes = 6 * 1024 * 1024;
const allowedTypes = new Set([
  "application/pdf",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.ms-powerpoint",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  "application/vnd.ms-excel",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "image/jpeg", "image/png", "image/webp", "text/plain", "text/markdown", "video/mp4",
]);

async function upload(event) {
  const file = event.target.files?.[0];
  event.target.value = "";
  if (!file || !supabase || busy.value) return;
  errorMessage.value = "";
  notice.value = "";

  if (file.size > maxBytes) {
    errorMessage.value = "Files must be 6 MiB or smaller. Use a share link for larger files.";
    return;
  }
  if (!allowedTypes.has(file.type)) {
    errorMessage.value = "Choose a PDF, Office document, image, text file, or MP4 video.";
    return;
  }
  if ((props.kind === "assignment" || props.kind === "assignment-resource") && !props.assignmentId) {
    errorMessage.value = "Choose an assignment before adding a file.";
    return;
  }
  if (props.kind !== "book" && !props.courseId) {
    errorMessage.value = "A course must be selected before uploading this file.";
    return;
  }
  if (props.kind === "book" && !props.bookId) {
    errorMessage.value = "Save the book before uploading its file.";
    return;
  }

  busy.value = true;
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    errorMessage.value = userError?.message || "Please sign in again.";
    busy.value = false;
    return;
  }

  const safeName = file.name.normalize("NFKD").replace(/[^A-Za-z0-9._-]+/g, "_").slice(-100) || "file";
  const root = props.kind === "assignment"
    ? [props.courseId, "submissions", props.assignmentId, userData.user.id]
    : props.kind === "assignment-resource"
      ? [props.courseId, "assignment-resources", props.assignmentId, userData.user.id]
      : props.kind === "book"
        ? [props.bookId, "books", userData.user.id]
        : [props.courseId, "materials", userData.user.id];
  const path = [...root, `${crypto.randomUUID()}-${safeName}`].join("/");
  const { error } = await supabase.storage.from(bucket).upload(path, file, {
    contentType: file.type,
    cacheControl: "3600",
    upsert: false,
  });
  if (error) {
    errorMessage.value = error.message;
  } else {
    emit("update:modelValue", path);
    notice.value = `${file.name} uploaded privately.`;
  }
  busy.value = false;
}

async function openFile() {
  if (!supabase || !props.modelValue || busy.value) return;
  busy.value = true;
  errorMessage.value = "";
  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(props.modelValue, 120);
  if (error) errorMessage.value = error.message;
  else window.open(data.signedUrl, "_blank", "noopener,noreferrer");
  busy.value = false;
}
</script>

<template>
  <div class="space-y-2 border border-border bg-white p-3">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div><p class="text-sm font-semibold">{{ label }}</p><p class="mt-0.5 text-xs text-muted-foreground">Private upload · 6 MiB maximum</p></div>
      <div class="flex items-center gap-2">
        <button v-if="modelValue" type="button" :disabled="busy" class="inline-flex min-h-9 items-center gap-1.5 border border-border px-3 text-xs font-bold text-primary hover:bg-secondary disabled:opacity-50" @click="openFile"><LoaderCircle v-if="busy" :size="14" class="animate-spin" /><Download v-else :size="14" />Open</button>
        <label v-if="!readOnly" class="inline-flex min-h-9 cursor-pointer items-center gap-1.5 bg-primary px-3 text-xs font-bold text-white hover:bg-primary/90 has-[:disabled]:opacity-50"><LoaderCircle v-if="busy" :size="14" class="animate-spin" /><FileUp v-else :size="14" />{{ busy ? 'Working...' : modelValue ? 'Replace' : 'Upload' }}<input ref="input" type="file" class="sr-only" accept=".pdf,.doc,.docx,.ppt,.pptx,.xls,.xlsx,.jpg,.jpeg,.png,.webp,.txt,.md,.mp4" :disabled="busy" @change="upload" /></label>
      </div>
    </div>
    <p v-if="errorMessage" role="alert" class="text-sm text-red-700">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="text-sm text-emerald-800">{{ notice }}</p>
  </div>
</template>
