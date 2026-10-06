<script setup>
import { onMounted, ref } from "vue";
import { BookOpen, LoaderCircle, Search } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";
import { getAuthenticatedProfile } from "@/lib/auth";
import PrivateFileField from "@/components/courses/PrivateFileField.vue";

const books = ref([]);
const accessibleIds = ref(new Set());
const search = ref("");
const loading = ref(true);
const checkoutId = ref("");
const errorMessage = ref("");
const notice = ref("");

onMounted(loadBooks);

async function loadBooks() {
  const { user, error: authError } = await getAuthenticatedProfile();
  if (!supabase || !user) {
    errorMessage.value = authError?.message || "Please sign in to browse books.";
    loading.value = false;
    return;
  }
  const [bookResult, accessResult] = await Promise.all([
    supabase.from("books").select("id, instructor_id, title, description, category, is_free, price_minor, currency, file_path, published").eq("published", true).order("created_at", { ascending: false }),
    supabase.from("book_access").select("book_id").eq("student_id", user.id),
  ]);
  if (bookResult.error || accessResult.error) errorMessage.value = bookResult.error?.message || accessResult.error?.message || "Unable to load the book library.";
  books.value = bookResult.data ?? [];
  accessibleIds.value = new Set((accessResult.data ?? []).map((row) => row.book_id));
  loading.value = false;
}

function hasAccess(book) {
  return book.is_free || accessibleIds.value.has(book.id);
}

function formattedPrice(book) {
  const fractionDigits = new Intl.NumberFormat(undefined, { style: "currency", currency: book.currency }).resolvedOptions().maximumFractionDigits;
  return new Intl.NumberFormat(undefined, { style: "currency", currency: book.currency }).format(book.price_minor / (10 ** fractionDigits));
}

async function buyBook(book) {
  if (!supabase || checkoutId.value) return;
  checkoutId.value = book.id;
  errorMessage.value = "";
  notice.value = "";
  const { data, error } = await supabase.functions.invoke("paystack-checkout", {
    body: { productType: "book", productId: book.id },
  });
  if (error) errorMessage.value = error.message;
  else if (data?.isFree) {
    accessibleIds.value = new Set([...accessibleIds.value, book.id]);
  } else if (data?.authorizationUrl) {
    window.location.assign(data.authorizationUrl);
    return;
  } else errorMessage.value = data?.error || "Paystack checkout could not be started.";
  checkoutId.value = "";
}
</script>

<template>
  <section class="space-y-7">
    <header class="flex flex-wrap items-end justify-between gap-4">
      <div><p class="mb-2 text-sm font-semibold text-primary">NORTHSTAR LIBRARY</p><h1 class="text-3xl font-extrabold sm:text-4xl">Books & resources</h1><p class="mt-2 text-muted-foreground">Free and paid titles from approved instructors.</p></div>
      <label class="relative block w-full sm:max-w-xs"><span class="sr-only">Search books</span><Search :size="17" class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" /><input v-model="search" type="search" placeholder="Search the library" class="h-11 w-full border border-border bg-white pl-10 pr-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" /></label>
    </header>
    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>
    <div v-if="loading" class="flex items-center gap-2 py-12 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" />Loading books...</div>
    <div v-else-if="!books.filter((book) => `${book.title} ${book.description} ${book.category}`.toLowerCase().includes(search.trim().toLowerCase())).length" class="border border-dashed border-border bg-white px-5 py-14 text-center"><BookOpen :size="28" class="mx-auto text-primary" /><h2 class="mt-3 font-bold">No books found</h2><p class="mt-1 text-sm text-muted-foreground">Try another search or check back later.</p></div>
    <div v-else class="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
      <article v-for="book in books.filter((item) => `${item.title} ${item.description} ${item.category}`.toLowerCase().includes(search.trim().toLowerCase()))" :key="book.id" class="flex flex-col gap-4 border border-border bg-white p-5">
        <div class="flex items-start justify-between gap-3"><div><p class="text-xs font-bold uppercase text-primary">{{ book.category || 'Book' }}</p><h2 class="mt-2 text-xl font-extrabold">{{ book.title }}</h2></div><span class="shrink-0 rounded-full bg-secondary px-2.5 py-1 text-xs font-bold">{{ book.is_free ? 'Free' : formattedPrice(book) }}</span></div>
        <p class="min-h-16 text-sm leading-6 text-muted-foreground">{{ book.description || 'Book details coming soon.' }}</p>
        <PrivateFileField v-if="hasAccess(book) && book.file_path" :model-value="book.file_path" :book-id="book.id" kind="book" label="Book file" read-only />
        <p v-else-if="hasAccess(book)" class="text-xs text-muted-foreground">The file is being prepared.</p>
        <button v-else type="button" :disabled="checkoutId === book.id" class="mt-auto inline-flex min-h-11 items-center justify-center gap-2 bg-primary px-4 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-50" @click="buyBook(book)"><LoaderCircle v-if="checkoutId === book.id" :size="16" class="animate-spin" />{{ checkoutId === book.id ? 'Opening checkout...' : `Buy for ${formattedPrice(book)}` }}</button>
      </article>
    </div>
  </section>
</template>
