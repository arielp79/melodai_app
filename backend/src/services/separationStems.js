/** Pistas estándar Fase 1 (HTDemucs / Spleeter) según PRD. */
export const PHASE1_STEMS = [
  { id: 'vocals', label: 'Voz', phase: 1 },
  { id: 'bass', label: 'Bajo', phase: 1 },
  { id: 'drums', label: 'Batería', phase: 1 },
  { id: 'guitar', label: 'Guitarra', phase: 1 },
  { id: 'piano', label: 'Piano', phase: 1 },
];

export function buildStemObjectKeys(sha256) {
  return PHASE1_STEMS.map((stem) => ({
    ...stem,
    objectKey: `stems/${sha256}/${stem.id}.wav`,
    simulated: true,
  }));
}
