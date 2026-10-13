<script setup>
import { computed, onMounted, ref } from "vue";
import {
  BookOpen,
  Check,
  CircleDollarSign,
  FileCheck,
  FileX,
  LoaderCircle,
  Search,
  Trash2,
} from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";

const {
  books,
  people,
  loading,
  error,
  notice,
  money,
  toggleBookPublished,
  deleteBook,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const searchQuery = ref("");
const statusFilter = ref("all");
const actionBookId = ref("");

const filteredBooks = computed(() => {
  let list = books.value;
  if (statusFilter.value === "published") {
    list = list.filter((b) => b.published);
  } else if (statusFilter.value === "draft") {
    list = list.filter((b) => !b.published);
  }

  const q = searchQuery.value.trim().toLowerCase();
  if (q) {
    list = list.filter((b) => {
      const instructor = people.value.find((p) => p.user_id === b.instructor_id);
      return (
        b.title.toLowerCase().includes(q) ||
        (b.category || "").toLowerCase().includes(q) ||
        (instructor?.full_name || "").toLowerCase().includes(q) ||
        (instructor?.email || "").toLowerCase().includes(q)
      );
    });
  }

  return list;
});

async function handleTogglePublish(book) {
  actionBookId.value = book.id;
  await toggleBookPublished(book);
  actionBookId.value = "";
}

async function handleDelete(book) {
  if (confirm(`Are you sure you want to delete book "${book.title}"?`)) {
    actionBookId.value = book.id;
    await deleteBook(book.id);
    actionBookId.value = "";
  }
}
</script>

<template>
  <div class="space-y-6">
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Books & Library Administration</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          Manage digital texts, lesson PDFs, published reading materials, and instructor publications.
        </p>
      </div>
      <div class="text-xs font-semibold text-muted-foreground">
        <span>{{ books.length }} Total Books in Library</span>
      </div>
    </header>

    <div v-if="error" role="alert" class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      {{ error }}
    </div>
    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <!-- Filters & Search -->
    <div class="flex flex-col gap-4 rounded-xl border border-border bg-white p-4 shadow-xs sm:flex-row sm:items-center sm:justify-between">
      <div class="relative flex-1 max-w-md">
        <Search :size="16" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input
          v-model="searchQuery"
          type="search"
          placeholder="Search by book title, author, or category..."
          class="h-10 w-full rounded-md border border-border bg-white pl-9 pr-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div class="flex rounded-md border border-border bg-secondary/50 p-0.5 text-xs font-semibold">
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'all' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'all'"
        >
          All ({{ books.length }})
        </button>
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'published' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'published'"
        >
          Published ({{ books.filter(b => b.published).length }})
        </button>
        <button
          type="button"
          class="rounded px-2.5 py-1"
          :class="statusFilter === 'draft' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
          @click="statusFilter = 'draft'"
        >
          Drafts ({{ books.filter(b => !b.published).length }})
        </button>
      </div>
    </div>

    <!-- Books Table -->
    <div class="overflow-x-auto rounded-xl border border-border bg-white shadow-xs">
      <table class="w-full min-w-[760px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/60 text-xs font-bold uppercase tracking-wider text-muted-foreground">
          <tr>
            <th class="px-5 py-3.5">Book Title</th>
            <th class="px-5 py-3.5">Author / Instructor</th>
            <th class="px-5 py-3.5">Price</th>
            <th class="px-5 py-3.5">File Asset</th>
            <th class="px-5 py-3.5">Status</th>
            <th class="px-5 py-3.5 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border">
          <tr v-for="book in filteredBooks" :key="book.id" class="transition-colors hover:bg-secondary/20">
            <!-- Title -->
            <td class="px-5 py-4">
              <div>
                <span class="block font-bold text-foreground">{{ book.title }}</span>
                <span class="block text-xs text-muted-foreground">{{ book.category || 'General' }}</span>
              </div>
            </td>

            <!-- Author -->
            <td class="px-5 py-4 text-xs">
              <span class="font-semibold text-foreground">
                {{ people.find(p => p.user_id === book.instructor_id)?.full_name || 'Northstar Author' }}
              </span>
              <span class="block text-muted-foreground">
                {{ people.find(p => p.user_id === book.instructor_id)?.email || '' }}
              </span>
            </td>

            <!-- Price -->
            <td class="px-5 py-4 text-xs font-bold">
              <span v-if="book.is_free" class="rounded bg-emerald-50 px-2 py-0.5 text-emerald-800">Free</span>
              <span v-else class="text-foreground">{{ money(book.price_minor, book.currency) }}</span>
            </td>

            <!-- File attachment -->
            <td class="px-5 py-4">
              <span
                v-if="book.file_path"
                class="inline-flex items-center gap-1 text-xs font-semibold text-emerald-700"
              >
                <FileCheck :size="14" /> Attached
              </span>
              <span
                v-else
                class="inline-flex items-center gap-1 text-xs text-muted-foreground"
              >
                <FileX :size="14" /> No file
              </span>
            </td>

            <!-- Status -->
            <td class="px-5 py-4">
              <span
                class="inline-block rounded-full px-2.5 py-0.5 text-xs font-bold"
                :class="book.published ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-700'"
              >
                {{ book.published ? 'Published' : 'Draft' }}
              </span>
            </td>

            <!-- Actions -->
            <td class="px-5 py-4 text-right">
              <div class="inline-flex items-center gap-2">
                <button
                  type="button"
                  :disabled="actionBookId === book.id"
                  class="inline-flex items-center gap-1 rounded border border-border px-2.5 py-1 text-xs font-bold hover:bg-secondary disabled:opacity-50"
                  :class="book.published ? 'text-amber-800' : 'text-emerald-800'"
                  @click="handleTogglePublish(book)"
                >
                  <Check :size="12" />
                  {{ book.published ? 'Unpublish' : 'Publish' }}
                </button>

                <button
                  type="button"
                  :disabled="actionBookId === book.id"
                  class="inline-flex items-center gap-1 rounded border border-red-200 px-2 py-1 text-xs font-bold text-red-700 hover:bg-red-50 disabled:opacity-50"
                  @click="handleDelete(book)"
                >
                  <Trash2 :size="12" />
                </button>
              </div>
            </td>
          </tr>

          <tr v-if="!filteredBooks.length">
            <td colspan="6" class="px-5 py-12 text-center text-sm text-muted-foreground">
              No books found in the library.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

