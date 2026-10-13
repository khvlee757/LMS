import { escapeHtml, money } from "@/lib/adminFormatters";

export function printOrderReceipt(order, { people, courses, books }) {
  if (!order || order.status !== "paid") return;
  const buyer = people.find((p) => p.user_id === order.buyer_id);
  const instructor = people.find((p) => p.user_id === order.instructor_id);
  const product = order.product_type === "course"
    ? courses.find((c) => c.id === order.course_id)
    : books.find((b) => b.id === order.book_id);

  const receiptWindow = window.open("", "_blank", "width=760,height=900");
  if (!receiptWindow) {
    throw new Error("Please allow pop-ups to print this receipt.");
  }

  const receiptNumber = escapeHtml(order.receipt_number);
  const formattedDate = escapeHtml(new Date(order.paid_at || order.created_at).toLocaleString());
  const instructorNet = order.amount_minor - order.platform_fee_minor;

  const receiptHtml = `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Receipt ${receiptNumber}</title>
  <style>
    body { font: 16px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #172522; margin: 48px auto; max-width: 680px; padding: 0 24px; line-height: 1.5; }
    header { border-bottom: 3px solid #163b32; padding-bottom: 20px; display: flex; justify-content: space-between; align-items: flex-end; }
    h1 { margin: 0; color: #163b32; font-size: 26px; }
    .badge { font-size: 12px; font-weight: 700; background: #e5eee7; padding: 4px 8px; border-radius: 4px; color: #163b32; }
    small, dt { color: #65756c; }
    .total-box { border-top: 2px solid #163b32; margin-top: 28px; padding-top: 18px; }
    .total { font-size: 22px; font-weight: 800; color: #163b32; }
    dl { display: grid; grid-template-columns: 180px 1fr; gap: 14px; margin: 28px 0; }
    dt { font-weight: 700; }
    dd { margin: 0; overflow-wrap: anywhere; }
    .thanks { margin-top: 48px; padding-top: 18px; border-top: 1px solid #dbe5df; color: #65756c; font-size: 14px; }
    @media print { body { margin: 0 auto; } }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Northstar Learning</h1>
      <small>Official Transaction Receipt</small>
    </div>
    <span class="badge">VERIFIED PAID</span>
  </header>
  <dl>
    <dt>Receipt Number</dt>
    <dd>${receiptNumber}</dd>
    <dt>Date Paid</dt>
    <dd>${formattedDate}</dd>
    <dt>Customer</dt>
    <dd>${escapeHtml(buyer?.full_name ? `${buyer.full_name} (${buyer.email})` : buyer?.email || "Learner")}</dd>
    <dt>Product Purchased</dt>
    <dd>${escapeHtml(product?.title || "Learning item")} (${order.product_type})</dd>
    <dt>Instructor</dt>
    <dd>${escapeHtml(instructor?.full_name ? `${instructor.full_name} (${instructor.email})` : instructor?.email || "Instructor")}</dd>
    <dt>Provider Reference</dt>
    <dd>${escapeHtml(order.provider_reference)}</dd>
    <dt>Payment Gateway</dt>
    <dd>${escapeHtml(order.provider || "Paystack")}</dd>
  </dl>
  <div class="total-box">
    <p class="total">Total Paid: ${escapeHtml(money(order.amount_minor, order.currency))}</p>
    <p>Platform Share (10%): ${escapeHtml(money(order.platform_fee_minor, order.currency))}</p>
    <p>Instructor Net Allocation: ${escapeHtml(money(instructorNet, order.currency))}</p>
  </div>
  <p class="thanks">Thank you for being part of Northstar Learning. For billing inquiries, contact support@northstarlearning.com.</p>
</body>
</html>`;

  receiptWindow.document.write(receiptHtml);
  receiptWindow.document.close();
  window.setTimeout(() => {
    receiptWindow.focus();
    receiptWindow.print();
  }, 250);
}
