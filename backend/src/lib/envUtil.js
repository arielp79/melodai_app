/** Quita comillas que a veces se pegan en dashboards (Render, etc.). */
export function trimEnvValue(raw) {
  if (raw == null) return null;
  let value = String(raw).trim();
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1).trim();
  }
  return value || null;
}
