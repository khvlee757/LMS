<script setup>
import { onMounted, reactive, ref } from "vue";
import { CheckCircle2, ClipboardList, LoaderCircle, Send } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";
import PrivateFileField from "@/components/courses/PrivateFileField.vue";

const props = defineProps({
  courseId: { type: String, required: true },
  enrolled: { type: Boolean, default: false },
});

const quizzes = ref([]);
const assignments = ref([]);
const submissions = ref({});
const reviews = ref({});
const selectedQuiz = ref(null);
const questions = ref([]);
const answers = reactive({});
const latestAttempt = ref(null);
const saving = ref(false);
const loading = ref(true);
const errorMessage = ref("");
const notice = ref("");

onMounted(loadAssessments);

async function loadAssessments() {
  if (!supabase) {
    loading.value = false;
    return;
  }
  const [quizResult, assignmentResult] = await Promise.all([
    supabase.from("quizzes").select("id, title, instructions, time_limit_minutes").eq("course_id", props.courseId).eq("published", true).order("created_at"),
    supabase.from("assignments").select("id, title, instructions, due_at, points, resource_path").eq("course_id", props.courseId).eq("published", true).order("created_at"),
  ]);
  const failure = quizResult.error || assignmentResult.error;
  if (failure) errorMessage.value = failure.message;
  quizzes.value = quizResult.data ?? [];
  assignments.value = assignmentResult.data ?? [];

  if (props.enrolled && assignments.value.length) {
    for (const assignment of assignments.value) {
      submissions.value[assignment.id] = { response: "", attachment_url: "", attachment_path: "" };
    }
    const { data: userData } = await supabase.auth.getUser();
    const ids = assignments.value.map((assignment) => assignment.id);
    const [submissionResult, reviewResult] = await Promise.all([
      supabase.from("assignment_submissions").select("assignment_id, response, attachment_url, attachment_path, submitted_at").eq("student_id", userData.user.id).in("assignment_id", ids),
      supabase.from("assignment_reviews").select("assignment_id, grade, feedback, reviewed_at").eq("student_id", userData.user.id).in("assignment_id", ids),
    ]);
    if (submissionResult.error || reviewResult.error) {
      errorMessage.value = submissionResult.error?.message || reviewResult.error?.message || "Unable to load assignment status.";
    }
    for (const submission of submissionResult.data ?? []) {
      submissions.value[submission.assignment_id] = {
        response: submission.response,
        attachment_url: submission.attachment_url ?? "",
        attachment_path: submission.attachment_path ?? "",
        submitted_at: submission.submitted_at,
      };
    }
    for (const review of reviewResult.data ?? []) {
      reviews.value[review.assignment_id] = review;
    }
  }
  loading.value = false;
}

async function openQuiz(quiz) {
  selectedQuiz.value = quiz;
  questions.value = [];
  latestAttempt.value = null;
  for (const key of Object.keys(answers)) delete answers[key];
  const { data, error } = await supabase.from("quiz_questions")
    .select("id, prompt, options, position, points")
    .eq("quiz_id", quiz.id)
    .order("position");
  if (error) errorMessage.value = error.message;
  else questions.value = data ?? [];
}

async function submitQuiz() {
  if (!supabase || saving.value || !selectedQuiz.value) return;
  if (questions.value.some((question) => answers[question.id] === undefined)) {
    errorMessage.value = "Answer every question before submitting.";
    return;
  }
  saving.value = true;
  errorMessage.value = "";
  const { data: attemptId, error } = await supabase.rpc("submit_quiz_attempt", {
    p_quiz_id: selectedQuiz.value.id,
    p_answers: { ...answers },
  });
  if (error) {
    errorMessage.value = error.message;
  } else {
    const { data: attempt, error: resultError } = await supabase.from("quiz_attempts")
      .select("score, possible_score, submitted_at")
      .eq("id", attemptId)
      .single();
    if (resultError) errorMessage.value = resultError.message;
    else latestAttempt.value = attempt;
  }
  saving.value = false;
}

async function submitAssignment(assignment) {
  if (!supabase || saving.value || !props.enrolled) return;
  const form = submissions.value[assignment.id] ?? { response: "", attachment_url: "" };
  if (!form.response.trim() && !form.attachment_url.trim() && !form.attachment_path.trim()) {
    errorMessage.value = "Add a written response or a link before submitting.";
    return;
  }
  saving.value = true;
  errorMessage.value = "";
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    errorMessage.value = userError?.message || "Please sign in again.";
    saving.value = false;
    return;
  }
  const submission = {
    assignment_id: assignment.id,
    student_id: userData.user.id,
    response: form.response.trim(),
    attachment_url: form.attachment_url.trim() || null,
    attachment_path: form.attachment_path || null,
    submitted_at: new Date().toISOString(),
  };
  const { error } = await supabase.from("assignment_submissions")
    .upsert(submission, { onConflict: "assignment_id,student_id" });
  if (error) errorMessage.value = error.message;
  else {
    submissions.value[assignment.id] = submission;
    notice.value = "Assignment submitted.";
  }
  saving.value = false;
}
</script>

<template>
  <section class="space-y-5 border-t border-border pt-6">
    <header class="flex items-start gap-3">
      <span class="grid size-10 place-items-center bg-secondary text-primary"><ClipboardList :size="19" aria-hidden="true" /></span>
      <div><h2 class="text-xl font-extrabold">Quizzes & assignments</h2><p class="mt-1 text-sm text-muted-foreground">{{ enrolled ? 'Check your knowledge and submit course work.' : 'Enroll in this course to take assessments.' }}</p></div>
    </header>

    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>
    <div v-if="loading" class="flex items-center gap-2 py-6 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading assessments...</div>

    <div v-else-if="selectedQuiz" class="space-y-5 border border-border bg-white p-5 sm:p-6">
      <header class="flex items-start justify-between gap-3"><div><p class="text-xs font-bold uppercase text-primary">QUIZ</p><h3 class="mt-1 text-lg font-extrabold">{{ selectedQuiz.title }}</h3><p v-if="selectedQuiz.instructions" class="mt-2 text-sm leading-6 text-muted-foreground">{{ selectedQuiz.instructions }}</p></div><button type="button" class="text-sm font-bold text-primary underline underline-offset-4" @click="selectedQuiz = null">Back</button></header>
      <p v-if="!questions.length" class="py-5 text-sm text-muted-foreground">No questions have been added yet.</p>
      <form v-else class="space-y-5" @submit.prevent="submitQuiz">
        <fieldset v-for="(question, questionIndex) in questions" :key="question.id" class="space-y-3 border-b border-border pb-5">
          <legend class="font-bold">{{ questionIndex + 1 }}. {{ question.prompt }} <span class="text-xs font-normal text-muted-foreground">{{ question.points }} pts</span></legend>
          <label v-for="(option, optionIndex) in question.options" :key="optionIndex" class="flex cursor-pointer items-start gap-3 rounded-md border border-border px-3 py-3 text-sm hover:bg-secondary/60 has-[:checked]:border-primary has-[:checked]:bg-secondary/70">
            <input v-model="answers[question.id]" type="radio" :name="question.id" :value="optionIndex" class="mt-0.5 accent-primary" />
            <span>{{ option }}</span>
          </label>
        </fieldset>
        <p v-if="latestAttempt" role="status" class="flex items-center gap-2 border border-emerald-200 bg-emerald-50 p-4 text-sm font-semibold text-emerald-900"><CheckCircle2 :size="18" />Score: {{ latestAttempt.score }} / {{ latestAttempt.possible_score }}</p>
        <button v-if="!latestAttempt" type="submit" :disabled="saving" class="inline-flex min-h-11 items-center gap-2 bg-primary px-4 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-60"><LoaderCircle v-if="saving" :size="16" class="animate-spin" /><Send v-else :size="16" />Submit quiz</button>
      </form>
    </div>

    <div v-else-if="!quizzes.length && !assignments.length" class="border border-dashed border-border bg-white px-5 py-9 text-center text-sm text-muted-foreground">No assessments have been published yet.</div>

    <div v-else class="grid gap-5 lg:grid-cols-2">
      <section v-if="quizzes.length" class="space-y-3">
        <h3 class="text-base font-extrabold">Quizzes</h3>
        <article v-for="quiz in quizzes" :key="quiz.id" class="border border-border bg-white p-4">
          <h4 class="font-bold">{{ quiz.title }}</h4>
          <p v-if="quiz.instructions" class="mt-1 line-clamp-2 text-sm leading-6 text-muted-foreground">{{ quiz.instructions }}</p>
          <p v-if="quiz.time_limit_minutes" class="mt-2 text-xs text-muted-foreground">{{ quiz.time_limit_minutes }} minute limit</p>
          <button type="button" :disabled="!enrolled" class="mt-4 min-h-10 border border-primary px-3 text-sm font-bold text-primary hover:bg-secondary disabled:cursor-not-allowed disabled:opacity-50" @click="openQuiz(quiz)">Start quiz</button>
        </article>
      </section>

      <section v-if="assignments.length" class="space-y-3">
        <h3 class="text-base font-extrabold">Assignments</h3>
        <article v-for="assignment in assignments" :key="assignment.id" class="space-y-3 border border-border bg-white p-4">
          <div><div class="flex items-start justify-between gap-3"><h4 class="font-bold">{{ assignment.title }}</h4><span class="shrink-0 text-xs font-semibold text-muted-foreground">{{ assignment.points }} pts</span></div><p v-if="assignment.instructions" class="mt-1 whitespace-pre-line text-sm leading-6 text-muted-foreground">{{ assignment.instructions }}</p><p v-if="assignment.due_at" class="mt-2 text-xs text-muted-foreground">Due {{ new Date(assignment.due_at).toLocaleString() }}</p></div>
          <template v-if="enrolled">
            <PrivateFileField v-if="assignment.resource_path" :model-value="assignment.resource_path" :course-id="courseId" :assignment-id="assignment.id" kind="assignment-resource" label="Assignment materials" read-only />
            <p v-if="reviews[assignment.id]" class="border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-900"><strong>Grade: {{ reviews[assignment.id].grade }} / {{ assignment.points }}</strong><span v-if="reviews[assignment.id].feedback" class="mt-1 block">{{ reviews[assignment.id].feedback }}</span></p>
            <template v-else>
              <textarea v-model="submissions[assignment.id].response" rows="3" class="w-full border border-border px-3 py-2 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Write your response" aria-label="Assignment response" :disabled="saving" />
              <input v-model="submissions[assignment.id].attachment_url" type="url" class="h-10 w-full border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Link to your work (optional)" aria-label="Assignment link" :disabled="saving" />
              <PrivateFileField v-model="submissions[assignment.id].attachment_path" :course-id="courseId" :assignment-id="assignment.id" kind="assignment" label="Your assignment file" />
              <button type="button" :disabled="saving" class="inline-flex min-h-10 items-center gap-2 bg-primary px-3 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-60" @click="submitAssignment(assignment)"><LoaderCircle v-if="saving" :size="15" class="animate-spin" /><Send v-else :size="15" />{{ submissions[assignment.id]?.submitted_at ? 'Update submission' : 'Submit assignment' }}</button>
              <p v-if="submissions[assignment.id]?.submitted_at" class="text-xs text-muted-foreground">Submitted {{ new Date(submissions[assignment.id].submitted_at).toLocaleString() }}</p>
            </template>
          </template>
        </article>
      </section>
    </div>
  </section>
</template>
