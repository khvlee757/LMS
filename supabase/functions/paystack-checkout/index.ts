import { jsonResponse, createAdminClient, createUserClient, paystackSecret } from "../_shared/commerce.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return jsonResponse({ ok: true });
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed." }, 405);
  if (!paystackSecret) return jsonResponse({ error: "Paystack is not configured on the server." }, 503);

  const authorization = request.headers.get("Authorization");
  if (!authorization) return jsonResponse({ error: "Sign in before checking out." }, 401);

  try {
    const userClient = createUserClient(authorization);
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user?.email) return jsonResponse({ error: "Your account email could not be verified." }, 401);

    const body = await request.json();
    const productType = body?.productType;
    const productId = body?.productId;
    if (!(["course", "book"].includes(productType)) || typeof productId !== "string") {
      return jsonResponse({ error: "Choose a valid course or book." }, 400);
    }

    const admin = createAdminClient();
    const productResult = productType === "course"
      ? await admin.from("courses").select("id, title, instructor_id, published, is_free, price_minor, currency").eq("id", productId).maybeSingle()
      : await admin.from("books").select("id, title, instructor_id, published, is_free, price_minor, currency").eq("id", productId).maybeSingle();
    if (productResult.error) throw productResult.error;
    const product = productResult.data;
    if (!product || !product.published) return jsonResponse({ error: "This item is not available for purchase." }, 404);
    if (product.is_free) return jsonResponse({ isFree: true, itemId: product.id }, 200);

    const amount = Number(product.price_minor);
    if (!Number.isSafeInteger(amount) || amount < 2) return jsonResponse({ error: "The item price is invalid." }, 400);
    const fee = Math.round(amount * 0.1);
    if (fee <= 0 || fee >= amount) return jsonResponse({ error: "The platform split is invalid for this item price." }, 400);

    const { data: payout, error: payoutError } = await admin
      .from("instructor_payout_accounts")
      .select("paystack_subaccount_code")
      .eq("user_id", product.instructor_id)
      .maybeSingle();
    if (payoutError) throw payoutError;
    if (!payout?.paystack_subaccount_code) {
      return jsonResponse({ error: "This instructor has not completed Paystack payout setup yet." }, 409);
    }

    const reference = `NSL-${crypto.randomUUID().replaceAll("-", "")}`;
    const paymentPayload = {
      buyer_id: userData.user.id,
      instructor_id: product.instructor_id,
      product_type: productType,
      course_id: productType === "course" ? product.id : null,
      book_id: productType === "book" ? product.id : null,
      amount_minor: amount,
      platform_fee_minor: fee,
      currency: product.currency,
      provider: "paystack",
      provider_reference: reference,
      status: "pending",
    };
    const { error: orderError } = await admin.from("payment_orders").insert(paymentPayload);
    if (orderError) throw orderError;

    const siteUrl = Deno.env.get("SITE_URL") || "http://localhost:5173";
    const paystackResponse = await fetch("https://api.paystack.co/transaction/initialize", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${paystackSecret}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: userData.user.email,
        amount,
        currency: product.currency,
        reference,
        callback_url: `${siteUrl}/payment/return`,
        subaccount: payout.paystack_subaccount_code,
        transaction_charge: fee,
        metadata: {
          custom_fields: [
            { display_name: "Northstar item", variable_name: "item", value: product.title },
            { display_name: "Buyer ID", variable_name: "buyer_id", value: userData.user.id },
          ],
        },
      }),
    });
    const checkout = await paystackResponse.json();
    if (!paystackResponse.ok || !checkout.status || !checkout.data?.authorization_url) {
      await admin.from("payment_orders").update({ status: "failed" }).eq("provider_reference", reference);
      return jsonResponse({ error: checkout.message || "Paystack could not start checkout." }, 502);
    }

    return jsonResponse({ authorizationUrl: checkout.data.authorization_url, reference });
  } catch (error) {
    console.error("Paystack checkout initialization failed:", error);
    return jsonResponse({ error: error instanceof Error ? error.message : "Checkout could not be started." }, 500);
  }
});
