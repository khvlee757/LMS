import { createAdminClient, createUserClient, jsonResponse, verifyAndRecordPayment } from "../_shared/commerce.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return jsonResponse({ ok: true });
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed." }, 405);
  const authorization = request.headers.get("Authorization");
  if (!authorization) return jsonResponse({ error: "Sign in to verify this purchase." }, 401);

  try {
    const userClient = createUserClient(authorization);
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return jsonResponse({ error: "Your session could not be verified." }, 401);
    const body = await request.json();
    const reference = body?.reference;
    if (typeof reference !== "string" || !reference.startsWith("NSL-")) {
      return jsonResponse({ error: "Payment reference is invalid." }, 400);
    }

    const admin = createAdminClient();
    const { data: order, error: orderError } = await admin.from("payment_orders")
      .select("buyer_id")
      .eq("provider_reference", reference)
      .maybeSingle();
    if (orderError) throw orderError;
    if (!order || order.buyer_id !== userData.user.id) {
      return jsonResponse({ error: "This payment does not belong to the signed-in account." }, 403);
    }

    const verifiedOrder = await verifyAndRecordPayment(reference);
    return jsonResponse({
      status: verifiedOrder.status,
      receiptNumber: verifiedOrder.receipt_number,
      productType: verifiedOrder.product_type,
      courseId: verifiedOrder.course_id,
      bookId: verifiedOrder.book_id,
    });
  } catch (error) {
    console.error("Paystack payment verification failed:", error);
    return jsonResponse({ error: error instanceof Error ? error.message : "Payment verification failed." }, 400);
  }
});
