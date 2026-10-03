import { supabase } from "@/lib/supabase";

export async function getAuthenticatedProfile() {
  if (!supabase) {
    return { user: null, profile: null, error: new Error("Supabase is not configured.") };
  }

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return { user: null, profile: null, error: userError };
  }

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("user_id, full_name, role")
    .eq("user_id", userData.user.id)
    .maybeSingle();

  return { user: userData.user, profile, error };
}
