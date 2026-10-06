import { createClient } from "npm:@supabase/supabase-js@2.117.2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const encoder = new TextEncoder();

function defaultKey(variable: string, legacyVariable: string) {
  const dictionary = Deno.env.get(variable);
  if (dictionary) {
    try {
      const keys = JSON.parse(dictionary);
      if (keys.default) return keys.default as string;
    } catch {
      // Fall back to legacy single-key environment variables.
    }
  }
  return Deno.env.get(legacyVariable) ?? "";
}

export const publishableKey = defaultKey("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY");
const serviceRoleKey = defaultKey("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY");
export const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY") ?? "";

export function createAdminClient() {
  if (!serviceRoleKey) throw new Error("Supabase server secret key is not configured.");
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export function createUserClient(authorization: string) {
  if (!publishableKey) throw new Error("Supabase publishable key is not configured.");
  return createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export function jsonResponse(body: unknown, status = 200, headers: HeadersInit = {}) {
  return Response.json(body, {
    status,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      ...Object.fromEntries(new Headers(headers).entries()),
    },
  });
}

export async function verifyAndRecordPayment(reference: string) {
  if (!paystackSecret) throw new Error("PAYSTACK_SECRET_KEY is not configured.");
  const admin = createAdminClient();
  const { data: order, error: orderError } = await admin
    .from("payment_orders")
    .select("id, buyer_id, product_type, course_id, book_id, amount_minor, platform_fee_minor, currency, provider_reference, receipt_number, status")
    .eq("provider_reference", reference)
    .maybeSingle();

  if (orderError) throw orderError;
  if (!order) throw new Error("Payment reference not found.");
  if (order.status === "paid") {
    await grantPurchasedAccess(admin, order);
    return order;
  }

  const response = await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
    headers: { Authorization: `Bearer ${paystackSecret}` },
  });
  const verification = await response.json();
  if (!response.ok || !verification.status || verification.data?.status !== "success") {
    if (verification.data?.status === "failed" || verification.data?.status === "abandoned") {
      await admin.from("payment_orders").update({ status: "failed" }).eq("id", order.id);
    }
    throw new Error("Paystack has not verified this payment as successful.");
  }

  if (verification.data.amount !== order.amount_minor || verification.data.currency !== order.currency) {
    throw new Error("Verified payment amount or currency does not match the order.");
  }

  const { data: updatedOrder, error: updateError } = await admin
    .from("payment_orders")
    .update({ status: "paid", paid_at: verification.data.paid_at ?? new Date().toISOString() })
    .eq("id", order.id)
    .select("id, buyer_id, product_type, course_id, book_id, amount_minor, platform_fee_minor, currency, provider_reference, receipt_number, status, paid_at")
    .single();
  if (updateError) throw updateError;

  await grantPurchasedAccess(admin, updatedOrder);

  return updatedOrder;
}

async function grantPurchasedAccess(admin: ReturnType<typeof createAdminClient>, order: {
  id: string;
  buyer_id: string;
  product_type: string;
  course_id: string | null;
  book_id: string | null;
}) {
  if (order.product_type === "course" && order.course_id) {
    const { error } = await admin.from("enrollments").upsert({
      user_id: order.buyer_id,
      course_id: order.course_id,
    }, { onConflict: "user_id,course_id" });
    if (error) throw error;
  } else if (order.product_type === "book" && order.book_id) {
    const { error } = await admin.from("book_access").upsert({
      student_id: order.buyer_id,
      book_id: order.book_id,
      payment_order_id: order.id,
    }, { onConflict: "book_id,student_id" });
    if (error) throw error;
  }
}

export async function hasValidPaystackSignature(rawBody: string, signature: string) {
  if (!paystackSecret || !signature) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(paystackSecret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const digest = new Uint8Array(await crypto.subtle.sign("HMAC", key, encoder.encode(rawBody)));
  const expected = Array.from(digest, (byte) => byte.toString(16).padStart(2, "0")).join("");
  if (expected.length !== signature.length) return false;
  let difference = 0;
  for (let index = 0; index < expected.length; index += 1) {
    difference |= expected.charCodeAt(index) ^ signature.charCodeAt(index);
  }
  return difference === 0;
}
