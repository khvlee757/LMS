export function money(amountMinor, currency = "NGN") {
  if (amountMinor == null) return "0.00";
  try {
    const fractionDigits = new Intl.NumberFormat(undefined, { style: "currency", currency }).resolvedOptions().maximumFractionDigits;
    return new Intl.NumberFormat(undefined, { style: "currency", currency }).format(amountMinor / (10 ** fractionDigits));
  } catch {
    return `${currency} ${(amountMinor / 100).toLocaleString()}`;
  }
}

export function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[character]);
}

export function calculateLoginSummary(loginActivities, userId) {
  const dates = new Set(
    loginActivities
      .filter((activity) => activity.user_id === userId)
      .map((activity) => activity.activity_date)
  );
  const lastLogin = [...dates].sort((left, right) => right.localeCompare(left))[0] ?? null;
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(`${today}T00:00:00.000Z`);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  let date = dates.has(today) ? today : yesterday.toISOString().slice(0, 10);
  let streak = 0;
  while (dates.has(date)) {
    streak += 1;
    const previous = new Date(`${date}T00:00:00.000Z`);
    previous.setUTCDate(previous.getUTCDate() - 1);
    date = previous.toISOString().slice(0, 10);
  }
  return { lastLogin, streak };
}
