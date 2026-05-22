"""Pistas Fase 1 (HTDemucs / Spleeter) — mismo contrato que el orquestador Node."""

PHASE1_STEMS = [
    ("vocals", "Voz"),
    ("bass", "Bajo"),
    ("drums", "Batería"),
    ("guitar", "Guitarra"),
    ("piano", "Piano"),
]


def build_stems(
    sha256: str,
    *,
    simulated: bool = True,
    stem_ids: list[str] | None = None,
) -> list[dict]:
    ids = stem_ids or [s[0] for s in PHASE1_STEMS]
    label_by_id = dict(PHASE1_STEMS)
    return [
        {
            "id": stem_id,
            "label": label_by_id.get(stem_id, stem_id),
            "objectKey": f"stems/{sha256}/{stem_id}.wav",
            "phase": 1,
            "simulated": simulated,
        }
        for stem_id in ids
    ]
