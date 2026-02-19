# GemMatch - Design

## Architecture

Single-scene Godot 4.x project using GDScript. All rendering via `_draw()` on a custom Node2D — zero external assets. Audio synthesized at runtime using AudioStreamWAV buffers.

## Components

### Main Scene (`main.tscn`)
- Root `Node2D`
- `Logo` — Node2D with `logo.gd`, draws animated per-letter bouncing title
- `Board` — Node2D with `board.gd`, core game logic and rendering
- `ScoreLabel` — Label, gold text with drop shadow
- `LevelLabel` — Label, blue text, right-aligned
- `MessageLabel` — Label, hidden until game over
- `SFX` — Node with `sfx.gd`, procedural sound effect generator
- `Music` — AudioStreamPlayer with `music.gd`, procedural chiptune loop

### Board Script (`board.gd`, ~783 lines)
Core game logic, rendering, input, and animations:
- **Grid State**: `grid[col][row]` (gem color int, -1 = empty), `specials[col][row]` (Special enum)
- **Rendering**: `_draw()` renders checkerboard background, shaped gems with specular highlights, special gem overlays, selection ring, particles, score popups, combo text, progress bar
- **Input**: Click-to-swap and drag-to-swap via `_input()`
- **Match Detection**: Row/column scanning for 3+ consecutive, run analysis for special gem creation
- **Special Gems**: Flame (3x3 explosion), Star (destroy color), Hypercube (swap to destroy color)
- **Gravity**: Column compaction with tween bounce-landing, new gems drop from above
- **Cascading**: Loop of match → remove → gravity → re-check until stable
- **Hint System**: After 4s idle, highlights a valid move
- **Level Progression**: Progress bar fills, level-up at threshold

### SFX Script (`sfx.gd`, ~50 lines)
Generates AudioStreamWAV buffers with configurable frequency sweep, volume, and noise mix. Pre-generates: select, swap, bad_swap, drop, explode, star, level_up, and 8 chain-pitched match sounds.

### Music Script (`music.gd`, ~79 lines)
Generates a looping chiptune track at startup: pentatonic melody (triangle wave), square-wave bass on chord progression, sine pad. 8-bar loop at 95 BPM.

### Logo Script (`logo.gd`, ~35 lines)
Draws "GemMatch" with per-letter gem colors, sine-wave bounce animation, shadow, and specular highlights.

## Data Model

```
grid: Array[Array[int]]       — 8x8, values 0-6 (gem types), -1 = empty
specials: Array[Array[int]]   — 8x8, Special enum (NONE, FLAME, STAR, HYPERCUBE)
selected: Vector2i            — currently selected cell, (-1,-1) if none
score: int
level: int
level_progress: int
chain: int                    — current cascade depth
```

## State Flow

1. `_ready()` → init grid, eliminate initial matches
2. Player clicks/drags → select or swap
3. Swap → animate → check matches
4. If no matches → animate swap back → IDLE
5. If matches → detect special creation → animate removal → spawn particles → award score → gravity → repeat from 4
6. After cascade settles → check valid moves → if none, game over
7. Check level progress → level up if threshold met
