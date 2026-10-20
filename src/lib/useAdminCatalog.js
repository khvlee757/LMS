import { supabase } from "@/lib/supabase";

export function createAdminCatalogActions({ currentProfile, courses, books, error, notice }) {
  async function createCourse(draft) {
    if (!supabase || !currentProfile.value || !draft.title?.trim()) return false;
    error.value = "";
    notice.value = "";
    const { data, error: insertError } = await supabase.from("courses").insert({
      title: draft.title.trim(),
      description: draft.description?.trim() || "",
      category: draft.category?.trim() || "General",
      level: draft.level || "beginner",
      is_free: draft.is_free,
      price_minor: draft.is_free ? 0 : Math.round(Number(draft.price) * 100),
      currency: "NGN",
      instructor_id: currentProfile.value.user_id,
      published: false,
    }).select().single();

    if (insertError) {
      error.value = insertError.message;
      return false;
    }
    courses.value = [data, ...courses.value];
    notice.value = "New course created as draft.";
    return true;
  }

  async function toggleCoursePublished(course) {
    if (!supabase) return;
    error.value = "";
    const targetStatus = !course.published;
    const { error: updateError } = await supabase.from("courses").update({ published: targetStatus }).eq("id", course.id);
    if (updateError) {
      error.value = updateError.message;
    } else {
      course.published = targetStatus;
      notice.value = targetStatus ? `Course "${course.title}" published.` : `Course "${course.title}" unpublished.`;
    }
  }

  async function deleteCourse(courseId) {
    if (!supabase) return false;
    error.value = "";
    const { error: delError } = await supabase.from("courses").delete().eq("id", courseId);
    if (delError) {
      error.value = delError.message;
      return false;
    }
    courses.value = courses.value.filter((c) => c.id !== courseId);
    notice.value = "Course deleted successfully.";
    return true;
  }

  async function toggleBookPublished(book) {
    if (!supabase) return;
    error.value = "";
    const targetStatus = !book.published;
    const { error: updateError } = await supabase.from("books").update({ published: targetStatus }).eq("id", book.id);
    if (updateError) {
      error.value = updateError.message;
    } else {
      book.published = targetStatus;
      notice.value = targetStatus ? `Book "${book.title}" published.` : `Book "${book.title}" unpublished.`;
    }
  }

  async function deleteBook(bookId) {
    if (!supabase) return false;
    error.value = "";
    const { error: delError } = await supabase.from("books").delete().eq("id", bookId);
    if (delError) {
      error.value = delError.message;
      return false;
    }
    books.value = books.value.filter((b) => b.id !== bookId);
    notice.value = "Book deleted successfully.";
    return true;
  }

  return {
    createCourse,
    toggleCoursePublished,
    deleteCourse,
    toggleBookPublished,
    deleteBook,
  };
}
