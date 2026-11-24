# WEVE POI and Sign Standard

Applies to all three digital twins (ACEB, TEB, SEB). Introduced in Sprint 2 (SCRUM-33).

## Titles

| Sign kind | Format | Example |
|---|---|---|
| POI (5 per building) | `POI <n> — <Space ID> — <Space type>` | `POI 1 — Room 1400 — Computer Lab` |
| Room / wayfinding sign | `<Space ID> — <Space type>` | `TA.141 — Corridor and Study Space` |
| Building sign | `<Code> — <Full name> (Digital Twin)` | `ACEB — Amit Chakma Engineering Building (Digital Twin)` |

- The separator is a long dash with a space on each side (` — `), not a colon or a short dash.
- Title Case for space types; room numbers written as `Room <number>`.
- Restricted spaces add `(Restricted)` to the space type.

## POI body

Every POI has exactly two lines below its title:

```
Purpose: <what the space is for>.
Student Activities: <what students can do there>.
```

Each line is one sentence ending in a full stop. Room signs for spaces that are not POIs may use
the same two lines or a single short description.

## POIs per building

| # | ACEB | TEB | SEB |
|---|---|---|---|
| 1 | Room 1400 — Computer Lab | Room 28 — Laboratory | Room 1059 — Classroom |
| 2 | Room 1420 — Classroom | Room 40 — Classroom | Room 1001 — UES Study Area |
| 3 | Room 1440 — Workshop | Room 14 — Design Studio | Room 1077A — Research Lab (Restricted) |
| 4 | TA.141 — Study Spaces | Room 50B — Study Room | TA.101 — Hallway |
| 5 | TA.144 — Atrium | Room 50 — Common Area | TA.106 — Foyer |

## Where the text lives

Each mod keeps all sign text in one `SIGN_TEXT` table near the top of its `init.lua`. Edit the
text there, not in-game. When a world loads:

- hand-placed wooden signs from Sprint 1 are rewritten to the standard text,
- pointing at a sign shows only its title plus "(right-click for details)", because Luanti
  cuts off long hover text,
- right-clicking any sign opens the same read-only popup (building name, title, Purpose and
  Student Activities), and
- standardized signs cannot be edited by visitors.

ACEB and TEB also have `/poi <1-5>`, which teleports you to a POI and opens its information.
