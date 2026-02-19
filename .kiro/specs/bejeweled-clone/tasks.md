# GemMatch - Implementation Tasks

All tasks completed in a single AI-assisted session.

## Task 1: Project Setup
- [x] Create `project.godot` with window size 600x730, GL Compatibility renderer
- [x] Create directory structure: `scenes/`, `scripts/`
- [x] Create `main.tscn` scene with all nodes (Board, Logo, Labels, SFX, Music)

## Task 2: Grid Initialization
- [x] Create `board.gd` with constants (GRID_SIZE, CELL_SIZE, GEM_COLORS, etc.)
- [x] Implement `_ready()` and `_init_grid()` to fill grid with random gem types
- [x] Ensure no matches exist on initial board via `_eliminate_initial_matches()`
- [x] Initialize parallel `specials` array for special gem tracking

## Task 3: Rendering
- [x] Implement `_draw()` with screen shake offset
- [x] Draw checkerboard background with slowly shifting hue
- [x] Draw 7 unique gem shapes (circle, diamond, square, triangle, hexagon, star, pentagon)
- [x] Draw multi-layer gems with specular highlights and outlines
- [x] Draw special gem overlays (flame ring, star sparkles, rainbow hypercube)
- [x] Draw pulsing selection highlight, particles, score popups, combo text
- [x] Draw level progress bar below the grid

## Task 4: Input — Click and Drag
- [x] Implement click-to-select and click-to-swap
- [x] Implement drag-to-swap via mouse motion tracking
- [x] Validate adjacency before swapping
- [x] Play select/swap sound effects on input

## Task 5: Match Detection
- [x] Implement `_find_matches()` scanning rows and columns for 3+ consecutive
- [x] Implement `_get_runs_h()` and `_get_runs_v()` for run analysis
- [x] Detect match-4 (Flame), match-5 (Star), L/T shape (Hypercube)

## Task 6: Special Gems
- [x] Implement `_detect_special()` to determine special gem creation from match patterns
- [x] Implement Flame Gem — 3x3 explosion on match
- [x] Implement Star Gem — destroy all gems of matched color
- [x] Implement Hypercube — swap with any gem to destroy all of that color
- [x] Trigger existing specials when matched cells contain them

## Task 7: Removal and Gravity
- [x] Animate removal with scale-to-zero tween (TRANS_BACK ease-in)
- [x] Implement `_apply_gravity()` preserving special gem states
- [x] Animate falling gems with bounce-landing tween (TRANS_BOUNCE)
- [x] New gems drop in from above the board
- [x] Cascade loop: match → remove → gravity → re-check

## Task 8: Scoring and Progression
- [x] Award points: gems × 10 × chain multiplier
- [x] Floating score popups at match centroids
- [x] Combo text escalation ("Good!" through "UNBELIEVABLE!")
- [x] Level progress bar, level-up at 2000 point threshold
- [x] Level-up sound, announcement, and screen shake

## Task 9: Hint System
- [x] Implement `_find_hint()` after 4 seconds idle
- [x] Highlight valid move cells with pulsing glow
- [x] Reset hint on player interaction

## Task 10: Audio
- [x] Create `sfx.gd` — procedural AudioStreamWAV generator
- [x] Generate sounds: select, swap, bad_swap, drop, explode, star, level_up, 8 match pitches
- [x] Create `music.gd` — procedural chiptune loop (pentatonic melody, bass, pad)

## Task 11: Logo
- [x] Create `logo.gd` — animated "GemMatch" with per-letter colors and bounce

## Task 12: Game Over
- [x] Implement `_has_valid_moves()` checking all possible swaps
- [x] Show "No Moves" message when stuck
- [x] Click to restart with fresh board
