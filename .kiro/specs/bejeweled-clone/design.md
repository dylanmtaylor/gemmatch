# GemMatch - Design

## Architecture

Multi-scene Godot 4.x project using GDScript. All rendering via `_draw()` on custom Node2D nodes — zero external assets. Audio synthesized at runtime using AudioStreamWAV buffers. One autoload singleton for persistent high scores.

## Scenes

### Title Scene (`title.tscn`)
- Root `Node2D` with `title.gd`
- Handles menu navigation, sub-screens, fade transitions, and demo mode launch

### Main Scene (`main.tscn`)
- Root `Node2D`
- `Logo` — Node2D with `logo.gd`, draws animated per-letter bouncing title
- `Board` — Node2D with `board.gd`, core game logic and rendering
- `ScoreLabel` — Label, gold text with drop shadow
- `LevelLabel` — Label, blue text, right-aligned
- `MessageLabel` — Label, hidden until game over
- `SFX` — Node with `sfx.gd`, procedural sound effect generator
- `Music` — AudioStreamPlayer with `music.gd`, procedural chiptune loop

## Components

### HighScores Autoload (`high_scores.gd`)
Singleton registered in `project.godot`. Persists top 10 scores to `user://highscores.json` using `FileAccess` + `JSON`. Also carries a `start_demo` flag for cross-scene communication.

### Title Script (`title.gd`)
Three screens with fade transitions:
- **Menu**: Animated logo, 5 menu items (New Game, How to Play, High Scores, Demo Mode, Quit) with mouse hover and keyboard (Up/Down/W/S + Enter/Space) navigation, `>` arrow indicator
- **How to Play**: Displays all 7 gem shapes with names, 3 special gem types with animated overlays and descriptions
- **High Scores**: Top 10 leaderboard with rank coloring (gold/silver/bronze)
- **Demo trigger**: After 15s idle, sets `HighScores.start_demo = true` and loads main scene

### Board Script (`board.gd`)
Core game logic, rendering, input, and animations:
- **Grid State**: `grid[col][row]` (gem color int, -1 = empty), `specials[col][row]` (Special enum)
- **Rendering**: `_draw()` renders checkerboard background, shaped gems with specular highlights, special gem overlays, selection ring that follows gem offsets during swap, keyboard cursor, particles, score popups, combo text, progress bar
- **Input**: Three input methods — click-to-swap, drag-to-swap, and keyboard (arrow keys move cursor, Enter/Space selects, arrow from selection swaps, Escape deselects)
- **Match Detection**: Row/column scanning for 3+ consecutive, run analysis for special gem creation
- **Special Gems**: Flame (3x3 explosion), Star (destroy color), Hypercube (swap to destroy color)
- **Gravity**: Column compaction with tween bounce-landing, new gems drop from above
- **Cascading**: Loop of match → remove → gravity → re-check until stable
- **Hint System**: After 4s idle, highlights a valid move
- **Level Progression**: Progress bar fills, level-up at threshold
- **Demo Mode**: Reads `HighScores.start_demo` on `_ready()`. Optimal AI evaluates all possible swaps, scoring by match size and special gem potential (+50 for 5-match, +35 for L/T, +20 for 4-match, +30 for triggering existing specials). Any input returns to title. Game over returns to title. Scores not saved.
- **Game Over**: Saves score via `HighScores.add_score()`, displays rank message

### SFX Script (`sfx.gd`)
Generates AudioStreamWAV buffers with configurable frequency sweep, volume, and noise mix. Pre-generates: select, swap, bad_swap, drop, explode, star, level_up, and 8 chain-pitched match sounds.

### Music Script (`music.gd`)
Generates a looping chiptune track at startup: pentatonic melody (triangle wave), square-wave bass on chord progression, sine pad. 8-bar loop at 95 BPM.

### Logo Script (`logo.gd`)
Draws "GemMatch" with per-letter gem colors, sine-wave bounce animation, shadow, and specular highlights.

## Data Model

```
# Board state
grid: Array[Array[int]]       — 8x8, values 0-6 (gem types), -1 = empty
specials: Array[Array[int]]   — 8x8, Special enum (NONE, FLAME, STAR, HYPERCUBE)
selected: Vector2i            — currently selected cell, (-1,-1) if none
cursor: Vector2i              — keyboard cursor position
score: int
level: int
level_progress: int
chain: int                    — current cascade depth
demo_mode: bool               — true when running as attract screen

# High scores (persisted)
entries: Array[Dictionary]    — [{score: int, level: int, date: String}], sorted descending
```

## State Flow

### Title Screen
1. Show menu → wait for input or idle timeout
2. Menu selection → fade to sub-screen or launch game/demo
3. Sub-screen → Escape/click → fade back to menu
4. 15s idle → launch demo mode

### Gameplay
1. `_ready()` → check demo flag → init grid, eliminate initial matches
2. Player clicks/drags/uses keyboard → select or swap
3. Swap → animate → check matches
4. If no matches → animate swap back → IDLE
5. If matches → detect special creation → animate removal → spawn particles → award score → gravity → repeat from 4
6. After cascade settles → check valid moves → if none, game over
7. Game over → save high score (unless demo) → show message
8. Check level progress → level up if threshold met

### Demo Mode
1. Title sets `HighScores.start_demo = true` → loads main scene
2. Board reads flag, enters demo mode
3. AI finds and executes valid swaps every 0.6s
4. Any user input → return to title
5. No valid moves → return to title
