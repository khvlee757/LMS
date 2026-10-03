<script setup>
import { onMounted, reactive, ref } from "vue";
import { Check, ClipboardCheck, LoaderCircle, Plus, Send, Trash2 } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";

const props = defineProps({ courseId: { type: String, required: true } });
const quizzes = ref([]);
const assignments = ref([]);
const selectedQuiz = ref(null);
const questions = ref([]);
const selectedAssignment = ref(null);
const submissions = ref([]);
const reviews = ref({});
const reviewDrafts = reactive({});
const activeTab = ref("build");
const saving = ref(false);
const loading = ref(true);
const errorMessage = ref("");
const notice = ref("");
const quizDraft = reactive({ title: "", instructions: "", time_limit_minutes: "" });
const questionDraft = reactive({ prompt: "", options: "", correct_option: "1", points: 1 });
const assignmentDraft = reactive({ title: "", instructions: "", due_at: "", points: 100 });

onMounted(loadAssessments);

async function loadAssessments() {
  const [quizResult, assignmentResult] = await Promise.all([
    supabase.from("quizzes").select("id, title, instructions, time_limit_minutes, published, created_at").eq("course_id", props.courseId).order("created_at", { ascending: false }),
    supabase.from("assignments").select("id, title, instructions, due_at, points, published, created_at").eq("course_id", props.courseId).order("created_at", { ascending: false }),
  ]);
  const failure = quizResult.error || assignmentResult.error;
  if (failure) errorMessage.value = failure.message;
  quizzes.value = quizResult.data ?? [];
  assignments.value = assignmentResult.data ?? [];
  loading.value = false;
}

async function createQuiz() {
  if (!supabase || saving.value || !quizDraft.title.trim()) return;
  saving.value = true;
  errorMessage.value = "";
  const { data, error } = await supabase.from("quizzes").insert({
    course_id: props.courseId,
    title: quizDraft.title.trim(),
    instructions: quizDraft.instructions.trim(),
    time_limit_minutes: quizDraft.time_limit_minutes ? Number(quizDraft.time_limit_minutes) : null,
    published: false,
  }).select("id, title, instructions, time_limit_minutes, published, created_at").single();
  if (error) errorMessage.value = error.message;
  else {
    quizzes.value = [data, ...quizzes.value];
    Object.assign(quizDraft, { title: "", instructions: "", time_limit_minutes: "" });
    await selectQuiz(data);
    notice.value = "Quiz draft created.";
  }
  saving.value = false;
}

async function selectQuiz(quiz) {
  selectedQuiz.value = quiz;
  selectedAssignment.value = null;
  const { data, error } = await supabase.from("quiz_questions")
    .select("id, prompt, options, position, points")
    .eq("quiz_id", quiz.id)
    .order("position");
  if (error) errorMessage.value = error.message;
  else questions.value = data ?? [];
}

async function addQuestion() {
  if (!supabase || !selectedQuiz.value || saving.value || !questionDraft.prompt.trim()) return;
  const options = questionDraft.options.split("\n").map((value) => value.trim()).filter(Boolean);
  const correctOption = Number(questionDraft.correct_option);
  if (options.length < 2 || options.length > 8 || !Number.isInteger(correctOption) || correctOption < 1 || correctOption > options.length) {
    errorMessage.value = "Add 2 to 8 options and set the correct option number from 1 to the option count.";
    return;
  }
  saving.value = true;
  errorMessage.value = "";
  const { data, error } = await supabase.rpc("create_quiz_question", {
    p_quiz_id: selectedQuiz.value.id,
    p_prompt: questionDraft.prompt.trim(),
    p_options: options,
    p_correct_option: correctOption - 1,
    p_position: questions.value.length,
    p_points: Number(questionDraft.points),
  });
  if (error) errorMessage.value = error.message;
  else {
    Object.assign(questionDraft, { prompt: "", options: "", correct_option: "1", points: 1 });
    await selectQuiz(selectedQuiz.value);
    notice.value = "Question added.";
  }
  saving.value = false;
}

async function deleteQuestion(question) {
  if (!supabase || saving.value || selectedQuiz.value?.published) return;
  saving.value = true;
  const { error } = await supabase.from("quiz_questions").delete().eq("id", question.id);
  if (error) errorMessage.value = error.message;
  else {
    questions.value = questions.value.filter((item) => item.id !== question.id);
    notice.value = "Question removed.";
  }
  saving.value = false;
}

async function toggleQuiz(quiz) {
  if (!supabase || saving.value) return;
  if (!quiz.published) {
    const { count, error } = await supabase.from("quiz_questions").select("id", { count: "exact", head: true }).eq("quiz_id", quiz.id);
    if (error || !count) {
      errorMessage.value = error?.message || "Add at least one question before publishing.";
      return;
    }
  }
  saving.value = true;
  const { error } = await supabase.from("quizzes").update({ published: !quiz.published }).eq("id", quiz.id);
  if (error) errorMessage.value = error.message;
  else {
    quiz.published = !quiz.published;
    if (selectedQuiz.value?.id === quiz.id) selectedQuiz.value.published = quiz.published;
    notice.value = quiz.published ? "Quiz published." : "Quiz moved back to drafts.";
  }
  saving.value = false;
}

async function createAssignment() {
  if (!supabase || saving.value || !assignmentDraft.title.trim()) return;
  saving.value = true;
  errorMessage.value = "";
  const { data, error } = await supabase.from("assignments").insert({
    course_id: props.courseId,
    title: assignmentDraft.title.trim(),
    instructions: assignmentDraft.instructions.trim(),
    due_at: assignmentDraft.due_at ? new Date(assignmentDraft.due_at).toISOString() : null,
    points: Number(assignmentDraft.points),
    published: false,
  }).select("id, title, instructions, due_at, points, published, created_at").single();
  if (error) errorMessage.value = error.message;
  else {
    assignments.value = [data, ...assignments.value];
    Object.assign(assignmentDraft, { title: "", instructions: "", due_at: "", points: 100 });
    notice.value = "Assignment draft created.";
  }
  saving.value = false;
}

async function toggleAssignment(assignment) {
  if (!supabase || saving.value) return;
  saving.value = true;
  const { error } = await supabase.from("assignments").update({ published: !assignment.published }).eq("id", assignment.id);
  if (error) errorMessage.value = error.message;
  else {
    assignment.published = !assignment.published;
    notice.value = assignment.published ? "Assignment published." : "Assignment moved back to drafts.";
  }
  saving.value = false;
}

async function selectAssignment(assignment) {
  selectedAssignment.value = assignment;
  selectedQuiz.value = null;
  const { data, error } = await supabase.from("assignment_submissions")
    .select("student_id, response, attachment_url, submitted_at")
    .eq("assignment_id", assignment.id)
    .order("submitted_at", { ascending: false });
  if (error) {
    errorMessage.value = error.message;
    return;
  }
  submissions.value = data ?? [];
  if (!submissions.value.length) return;
  const { data: reviewData, error: reviewError } = await supabase.from("assignment_reviews")
    .select("student_id, grade, feedback, reviewed_at")
    .eq("assignment_id", assignment.id);
  if (reviewError) errorMessage.value = reviewError.message;
  reviews.value = Object.fromEntries((reviewData ?? []).map((review) => [review.student_id, review]));
  for (const submission of submissions.value) {
    reviewDrafts[submission.student_id] = {
      grade: reviews.value[submission.student_id]?.grade ?? "",
      feedback: reviews.value[submission.student_id]?.feedback ?? "",
    };
  }
}

async function saveReview(submission) {
  if (!supabase || saving.value) return;
  const review = reviewDrafts[submission.student_id];
  const grade = Number(review.grade);
  if (!Number.isFinite(grade) || grade < 0 || grade > selectedAssignment.value.points) {
    errorMessage.value = `Enter a grade from 0 to ${selectedAssignment.value.points}.`;
    return;
  }
  saving.value = true;
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    errorMessage.value = userError?.message || "Please sign in again.";
    saving.value = false;
    return;
  }
  const { error } = await supabase.from("assignment_reviews").upsert({
    assignment_id: selectedAssignment.value.id,
    student_id: submission.student_id,
    grade,
    feedback: review.feedback.trim(),
    reviewed_by: userData.user.id,
    reviewed_at: new Date().toISOString(),
  }, { onConflict: "assignment_id,student_id" });
  if (error) errorMessage.value = error.message;
  else {
    reviews.value[submission.student_id] = { ...review, grade, reviewed_at: new Date().toISOString() };
    notice.value = "Feedback saved.";
  }
  saving.value = false;
}
</script>

<template>
  <section class="space-y-5 border-t border-border pt-6">
    <header class="flex items-center gap-3"><span class="grid size-10 place-items-center bg-secondary text-primary"><ClipboardCheck :size="19" aria-hidden="true" /></span><div><h3 class="text-xl font-extrabold">Assessments</h3><p class="mt-1 text-sm text-muted-foreground">Create quizzes and assignments, then review learner submissions.</p></div></header>
    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>
    <div v-if="loading" class="flex items-center gap-2 py-5 text-sm text-muted-foreground"><LoaderCircle :size="17" class="animate-spin" /> Loading assessments...</div>
    <div v-else class="space-y-5">
      <div class="flex border-b border-border" role="tablist" aria-label="Assessment tools">
        <button v-for="tab in [{ id: 'build', label: 'Build' }, { id: 'submissions', label: 'Submissions' }]" :key="tab.id" type="button" role="tab" :aria-selected="activeTab === tab.id" class="min-h-11 border-b-2 px-4 text-sm font-bold outline-none focus-visible:ring-2 focus-visible:ring-primary" :class="activeTab === tab.id ? 'border-primary text-primary' : 'border-transparent text-muted-foreground'" @click="activeTab = tab.id">{{ tab.label }}</button>
      </div>

      <div v-if="activeTab === 'build'" class="grid gap-5 xl:grid-cols-2">
        <section class="space-y-4 border border-border bg-white p-4 sm:p-5">
          <h4 class="font-extrabold">Quizzes</h4>
          <form class="space-y-3" @submit.prevent="createQuiz">
            <input v-model="quizDraft.title" required maxlength="160" aria-label="Quiz title" class="h-11 w-full border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Quiz title" />
            <textarea v-model="quizDraft.instructions" rows="2" aria-label="Quiz instructions" class="w-full border border-border px-3 py-2 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Instructions (optional)" />
            <div class="flex flex-wrap items-center gap-3"><label class="flex items-center gap-2 text-sm">Time limit <input v-model="quizDraft.time_limit_minutes" type="number" min="1" max="1440" class="h-10 w-24 border border-border px-2" placeholder="Min" /></label><button type="submit" :disabled="saving || !quizDraft.title.trim()" class="inline-flex min-h-10 items-center gap-2 bg-primary px-3 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-50"><Plus :size="15" />Create quiz</button></div>
          </form>
          <div class="divide-y divide-border border-t border-border">
            <article v-for="quiz in quizzes" :key="quiz.id" class="flex flex-wrap items-center justify-between gap-3 py-3">
              <button type="button" class="text-left font-semibold outline-none focus-visible:ring-2 focus-visible:ring-primary" @click="selectQuiz(quiz)">{{ quiz.title }} <span class="ml-1 text-xs text-muted-foreground">{{ quiz.published ? 'Published' : 'Draft' }}</span></button>
              <button type="button" class="min-h-9 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary" @click="toggleQuiz(quiz)">{{ quiz.published ? 'Unpublish' : 'Publish' }}</button>
            </article>
            <p v-if="!quizzes.length" class="py-3 text-sm text-muted-foreground">No quizzes yet.</p>
          </div>
          <div v-if="selectedQuiz" class="space-y-3 border-t border-border pt-4">
            <div><p class="text-xs font-bold uppercase text-primary">QUESTION EDITOR</p><p class="mt-1 font-bold">{{ selectedQuiz.title }}</p></div>
            <form class="space-y-3" @submit.prevent="addQuestion">
              <textarea v-model="questionDraft.prompt" required maxlength="3000" rows="2" aria-label="Question prompt" class="w-full border border-border px-3 py-2 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Question" :disabled="selectedQuiz.published" />
              <textarea v-model="questionDraft.options" required rows="4" aria-label="Answer options, one per line" class="w-full border border-border px-3 py-2 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="One answer option per line" :disabled="selectedQuiz.published" />
              <div class="flex flex-wrap items-center gap-3"><label class="flex items-center gap-2 text-xs">Correct option # <input v-model="questionDraft.correct_option" type="number" min="1" max="8" class="h-9 w-16 border border-border px-2" :disabled="selectedQuiz.published" /></label><label class="flex items-center gap-2 text-xs">Points <input v-model="questionDraft.points" type="number" min="1" max="100" class="h-9 w-16 border border-border px-2" :disabled="selectedQuiz.published" /></label><button type="submit" :disabled="saving || selectedQuiz.published" class="inline-flex min-h-9 items-center gap-1.5 bg-primary px-3 text-xs font-bold text-white hover:bg-primary/90 disabled:opacity-50"><Plus :size="14" />Add question</button></div>
              <p class="text-xs text-muted-foreground">Enter the correct option by its 1-based line number. Answer keys stay private.</p>
            </form>
            <ol class="divide-y divide-border border-y border-border">
              <li v-for="(question, index) in questions" :key="question.id" class="flex items-start gap-3 py-3"><span class="text-xs font-bold text-primary">{{ index + 1 }}</span><span class="min-w-0 flex-1 text-sm">{{ question.prompt }}<span class="mt-1 block text-xs text-muted-foreground">{{ question.options.length }} choices · {{ question.points }} points</span></span><button v-if="!selectedQuiz.published" type="button" class="grid size-8 place-items-center text-red-700 hover:bg-red-50" :aria-label="`Delete question ${index + 1}`" @click="deleteQuestion(question)"><Trash2 :size="15" /></button></li>
              <li v-if="!questions.length" class="py-3 text-sm text-muted-foreground">Add at least one question before publishing.</li>
            </ol>
          </div>
        </section>

        <section class="space-y-4 border border-border bg-white p-4 sm:p-5">
          <h4 class="font-extrabold">Assignments</h4>
          <form class="space-y-3" @submit.prevent="createAssignment">
            <input v-model="assignmentDraft.title" required maxlength="160" aria-label="Assignment title" class="h-11 w-full border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Assignment title" />
            <textarea v-model="assignmentDraft.instructions" rows="3" aria-label="Assignment instructions" class="w-full border border-border px-3 py-2 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Instructions and submission requirements" />
            <div class="flex flex-wrap items-center gap-3"><label class="flex items-center gap-2 text-xs">Due date <input v-model="assignmentDraft.due_at" type="datetime-local" class="h-10 border border-border px-2 text-xs" /></label><label class="flex items-center gap-2 text-xs">Points <input v-model="assignmentDraft.points" type="number" min="1" max="10000" class="h-9 w-20 border border-border px-2" /></label><button type="submit" :disabled="saving || !assignmentDraft.title.trim()" class="inline-flex min-h-10 items-center gap-2 bg-primary px-3 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-50"><Plus :size="15" />Create assignment</button></div>
          </form>
          <div class="divide-y divide-border border-t border-border">
            <article v-for="assignment in assignments" :key="assignment.id" class="flex flex-wrap items-center justify-between gap-3 py-3">
              <button type="button" class="text-left font-semibold outline-none focus-visible:ring-2 focus-visible:ring-primary" @click="activeTab = 'submissions'; selectAssignment(assignment)">{{ assignment.title }} <span class="ml-1 text-xs text-muted-foreground">{{ assignment.published ? 'Published' : 'Draft' }} · {{ assignment.points }} pts</span></button>
              <button type="button" class="min-h-9 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary" @click="toggleAssignment(assignment)">{{ assignment.published ? 'Unpublish' : 'Publish' }}</button>
            </article>
            <p v-if="!assignments.length" class="py-3 text-sm text-muted-foreground">No assignments yet.</p>
          </div>
        </section>
      </div>

      <section v-else class="space-y-4">
        <label class="block max-w-lg space-y-1.5 text-sm font-semibold">Select an assignment
          <select class="h-11 w-full border border-border bg-white px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" :value="selectedAssignment?.id || ''" @change="selectAssignment(assignments.find((assignment) => assignment.id === $event.target.value))">
            <option value="" disabled>Choose an assignment</option><option v-for="assignment in assignments" :key="assignment.id" :value="assignment.id">{{ assignment.title }}</option>
          </select>
        </label>
        <div v-if="!selectedAssignment" class="border border-dashed border-border bg-white p-6 text-sm text-muted-foreground">Choose an assignment to review learner work.</div>
        <div v-else-if="!submissions.length" class="border border-dashed border-border bg-white p-6 text-sm text-muted-foreground">No submissions yet for this assignment.</div>
        <article v-for="submission in submissions" :key="submission.student_id" class="grid gap-4 border border-border bg-white p-4 sm:grid-cols-[1fr_1fr_auto] sm:items-start">
          <div><p class="text-xs font-bold uppercase text-primary">Learner {{ submission.student_id.slice(0, 8) }}</p><p class="mt-1 text-xs text-muted-foreground">Submitted {{ new Date(submission.submitted_at).toLocaleString() }}</p><p class="mt-3 whitespace-pre-line text-sm leading-6">{{ submission.response || 'No written response.' }}</p><a v-if="submission.attachment_url" :href="submission.attachment_url" target="_blank" rel="noopener noreferrer" class="mt-2 inline-flex text-sm font-bold text-primary underline underline-offset-4">Open submitted link</a></div>
          <div class="space-y-2"><input v-model="reviewDrafts[submission.student_id].grade" type="number" min="0" :max="selectedAssignment.points" step="0.01" class="h-10 w-full border border-border px-3 text-sm" :aria-label="`Grade for learner ${submission.student_id.slice(0, 8)}`" placeholder="Grade" /><textarea v-model="reviewDrafts[submission.student_id].feedback" rows="3" class="w-full border border-border px-3 py-2 text-sm" aria-label="Feedback" placeholder="Feedback for learner" /></div>
          <button type="button" :disabled="saving" class="inline-flex min-h-10 items-center justify-center gap-2 bg-primary px-3 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-50" @click="saveReview(submission)"><LoaderCircle v-if="saving" :size="15" class="animate-spin" /><Check v-else :size="15" />Save grade</button>
        </article>
      </section>
    </div>
  </section>
</template>
