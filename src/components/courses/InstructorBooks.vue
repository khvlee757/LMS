<script setup>
import { onMounted, reactive, ref } from "vue";
import { BookOpen, LoaderCircle, Plus, Save } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";
import PrivateFileField from "@/components/courses/PrivateFileField.vue";

const props = defineProps({
  instructorId: { type: String, required: true },
});
const books = ref([]);
const loading = ref(true);
const saving = ref(false);
const savingBookId = ref("");
const errorMessage = ref("");
const notice = ref("");
const draft = reactive({ title: "", description: "", category: "", is_free: true, price: "" });

onMounted(loadBooks);

async function loadBooks() {
  const { data, error } = await supabase.from("books")
    .select("id, instructor_id, title, description, category, is_free, price_minor, currency, file_path, published, created_at")
    .eq("instructor_id", props.instructorId)
    .order("created_at", { ascending: false });
  if (error) errorMessage.value = error.message;
  else books.value = (data ?? []).map((book) => ({
    ...book,
    price: book.is_free ? "" : String(book.price_minor / 100),
  }));
  loading.value = false;
}

async function createBook() {
  if (!supabase || saving.value || !draft.title.trim()) return;
  saving.value = true;
  errorMessage.value = "";
  const { data, error } = await supabase.from("books").insert({
    instructor_id: props.instructorId,
    title: draft.title.trim(),
    description: draft.description.trim(),
    category: draft.category.trim() || "General",
    is_free: draft.is_free,
    price_minor: draft.is_free ? 0 : Math.round(Number(draft.price) * 100),
    currency: "NGN",
    published: false,
  }).select("id, instructor_id, title, description, category, is_free, price_minor, currency, file_path, published, created_at").single();
  if (error) errorMessage.value = error.message;
  else {
    books.value = [{ ...data, price: data.is_free ? "" : String(data.price_minor / 100) }, ...books.value];
    Object.assign(draft, { title: "", description: "", category: "", is_free: true, price: "" });
    notice.value = "Book draft created. Upload its file before publishing.";
  }
  saving.value = false;
}

async function saveBook(book) {
  if (!supabase || savingBookId.value) return;
  savingBookId.value = book.id;
  const { error } = await supabase.from("books").update({
    title: book.title.trim(),
    description: book.description.trim(),
    category: book.category.trim() || "General",
    is_free: book.is_free,
    price_minor: book.is_free ? 0 : Math.round(Number(book.price) * 100),
    currency: book.currency || "NGN",
  }).eq("id", book.id);
  if (error) errorMessage.value = error.message;
  else {
    book.price_minor = book.is_free ? 0 : Math.round(Number(book.price) * 100);
    notice.value = "Book details saved.";
  }
  savingBookId.value = "";
}

async function updateFile(book, path) {
  const { error } = await supabase.from("books").update({ file_path: path }).eq("id", book.id);
  if (error) errorMessage.value = error.message;
  else {
    book.file_path = path;
    notice.value = "Private book file attached.";
  }
}

async function togglePublished(book) {
  if (!supabase || savingBookId.value) return;
  if (!book.published && !book.file_path) {
    errorMessage.value = "Upload the book file before publishing.";
    return;
  }
  if (!book.is_free && !(Number(book.price) > 0)) {
    errorMessage.value = "Enter a price above zero before publishing a paid book.";
    return;
  }
  await saveBook(book);
  if (errorMessage.value) return;
  savingBookId.value = book.id;
  const { error } = await supabase.from("books").update({ published: !book.published }).eq("id", book.id);
  if (error) errorMessage.value = error.message;
  else {
    book.published = !book.published;
    notice.value = book.published ? "Book published." : "Book moved back to drafts.";
  }
  savingBookId.value = "";
}
</script>

<template>
  <section class="space-y-5 border-t border-border pt-7">
    <header class="flex items-center gap-3"><span class="grid size-10 place-items-center bg-secondary text-primary"><BookOpen :size="19" /></span><div><h2 class="text-xl font-extrabold">Books</h2><p class="mt-1 text-sm text-muted-foreground">Upload a book, set it free or paid, and publish it to the library.</p></div></header>
    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>
    <div class="grid gap-6 xl:grid-cols-[0.75fr_1.25fr]">
      <form class="h-fit space-y-4 border border-border bg-white p-5" @submit.prevent="createBook">
        <h3 class="font-extrabold">Add a book</h3>
        <label class="block space-y-1.5 text-sm font-semibold">Title<input v-model="draft.title" required maxlength="180" class="h-11 w-full border border-border px-3 text-sm font-normal" /></label>
        <label class="block space-y-1.5 text-sm font-semibold">Description<textarea v-model="draft.description" rows="3" class="w-full border border-border px-3 py-2 text-sm font-normal" /></label>
        <label class="block space-y-1.5 text-sm font-semibold">Category<input v-model="draft.category" maxlength="80" class="h-11 w-full border border-border px-3 text-sm font-normal" placeholder="General" /></label>
        <label class="flex min-h-11 items-center gap-3 border border-border px-3 text-sm font-semibold"><input v-model="draft.is_free" type="checkbox" class="size-4 accent-primary" />Free book</label>
        <label v-if="!draft.is_free" class="block space-y-1.5 text-sm font-semibold">Price (NGN)<input v-model="draft.price" type="number" min="1" step="0.01" required class="h-11 w-full border border-border px-3 text-sm font-normal" placeholder="e.g. 2500" /></label>
        <button type="submit" :disabled="saving || !draft.title.trim() || (!draft.is_free && !(Number(draft.price) > 0))" class="inline-flex min-h-11 w-full items-center justify-center gap-2 bg-primary px-4 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-50"><LoaderCircle v-if="saving" :size="15" class="animate-spin" /><Plus v-else :size="15" />Create book draft</button>
      </form>
      <div class="space-y-4">
        <div class="flex justify-between"><h3 class="font-extrabold">Your books</h3><span class="text-xs text-muted-foreground">{{ books.length }} total</span></div>
        <div v-if="loading" class="flex items-center gap-2 border border-border bg-white p-5 text-sm text-muted-foreground"><LoaderCircle :size="17" class="animate-spin" />Loading books...</div>
        <p v-else-if="!books.length" class="border border-dashed border-border bg-white p-8 text-center text-sm text-muted-foreground">No books yet.</p>
        <article v-for="book in books" :key="book.id" class="space-y-4 border border-border bg-white p-5">
          <div class="flex flex-wrap items-start justify-between gap-3"><div><h4 class="font-bold">{{ book.title }}</h4><p class="mt-1 text-xs text-muted-foreground">{{ book.is_free ? 'Free' : `NGN ${(book.price_minor / 100).toLocaleString()}` }} · {{ book.published ? 'Published' : 'Draft' }}</p></div><button type="button" :disabled="savingBookId === book.id" class="min-h-9 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary disabled:opacity-50" @click="togglePublished(book)">{{ book.published ? 'Unpublish' : 'Publish' }}</button></div>
          <div class="grid gap-3 sm:grid-cols-2"><label class="space-y-1 text-xs font-bold">Title<input v-model="book.title" maxlength="180" class="h-10 w-full border border-border px-3 text-sm font-normal" /></label><label class="space-y-1 text-xs font-bold">Category<input v-model="book.category" maxlength="80" class="h-10 w-full border border-border px-3 text-sm font-normal" /></label><label class="flex items-center gap-2 text-sm font-semibold"><input v-model="book.is_free" type="checkbox" class="size-4 accent-primary" />Free book</label><label v-if="!book.is_free" class="space-y-1 text-xs font-bold">Price (NGN)<input v-model="book.price" type="number" min="1" step="0.01" class="h-10 w-full border border-border px-3 text-sm font-normal" /></label></div>
          <textarea v-model="book.description" rows="2" aria-label="Book description" class="w-full border border-border px-3 py-2 text-sm" placeholder="Description" />
          <PrivateFileField :model-value="book.file_path || ''" :book-id="book.id" kind="book" label="Book file" @update:model-value="updateFile(book, $event)" />
          <button type="button" :disabled="savingBookId === book.id" class="inline-flex min-h-9 items-center gap-2 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary disabled:opacity-50" @click="saveBook(book)"><Save :size="14" />Save book details</button>
        </article>
      </div>
    </div>
  </section>
</template>
