import { createAdminClient, hasValidPaystackSignature, jsonResponse, verifyAndRecordPayment } from "../_shared/commerce.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed." }, 405);
  const rawBody = await request.text();
  const signature = request.headers.get("x-paystack-signature") ?? "";
  if (!await hasValidPaystackSignature(rawBody, signature)) {
    return jsonResponse({ error: "Invalid webhook signature." }, 401);
  }

  try {
    const event = JSON.parse(rawBody);
    const reference = event?.data?.reference;
    if (!reference || typeof reference !== "string") return jsonResponse({ received: true });

    if (event.event === "charge.success") {
      await verifyAndRecordPayment(reference);
    } else if (event.event === "charge.failed") {
      const admin = createAdminClient();
      await admin.from("payment_orders")
        .update({ status: "failed" })
        .eq("provider_reference", reference)
        .eq("status", "pending");
    }

    return jsonResponse({ received: true });
  } catch (error) {
    console.error("Paystack webhook processing failed:", error);
    return jsonResponse({ error: "Webhook processing failed." }, 500);
  }
});
