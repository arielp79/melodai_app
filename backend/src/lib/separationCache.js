/**
 * Solo reutilizar caché si la separación fue real (archivos en GCS).
 * Los jobs stub guardan simulated: true y no deben saltarse el worker.
 */
export function isRealSeparationCache(cache) {
  if (!cache?.stems?.length) return false;
  if (cache.simulated === true) return false;
  if (cache.simulated === false) return true;
  return cache.stems.every((stem) => stem.simulated === false);
}
