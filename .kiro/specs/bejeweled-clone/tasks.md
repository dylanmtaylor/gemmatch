# GemMatch - Implementation Tasks

## Task 1: Project Setup
- [x] Create `project.godot` with window size 600x730, GL Compatibility renderer
- [x] Create directory structure: `scenes/`, `scripts/`
- [x] Create `main.tscn` scene with all nodes (Board, Logo, Labels, SFX, Music)
- [x] Create `title.tscn` scene with title script
- [x] Register `HighScores` autoload singleton in `project.godot`

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
- [x] Draw pulsing selection highlight, keyboard cursor, particles, score popups, combo text
- [x] Draw level progress bar below the grid

## Task 4: Input — Click, Drag, and Keyboard
- [x] Implement click-to-select and click-to-swap
- [x] Implement drag-to-swap via mouse motion tracking
- [x] Implement keyboard cursor movement (arrow keys / WASD)
- [x] Implement keyboard select (Enter/Space) and directional swap from selection
- [x] Implement Escape to deselect
- [x] Sync keyboard cursor position on mouse click
- [x] Selection ring follows gem offset during swap animation
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

## Task 12: Game Over and High Scores
- [x] Implement `_has_valid_moves()` checking all possible swaps
- [x] Show game over message with high score rank when applicable
- [x] Click or key press to restart with fresh board
- [x] Create `high_scores.gd` autoload — load/save top 10 to `user://highscores.json`
- [x] Call `HighScores.add_score()` on game over, skip in demo mode

## Task 13: Title Screen and Menus
- [x] Create `title.tscn` and `title.gd` with animated logo and floating gem background
- [x] Implement 5-item menu: New Game, How to Play, High Scores, Demo Mode, Quit
- [x] Mouse hover highlighting and click activation
- [x] Keyboard navigation: Up/Down/W/S to move, Enter/Space to activate
- [x] `>` arrow indicator on selected menu item
- [x] How to Play screen: all 7 gem shapes with names, 3 special types with overlays and descriptions
- [x] High Scores screen: top 10 leaderboard with gold/silver/bronze rank coloring
- [x] Fade-to-black transitions between screens
- [x] Escape/Backspace to return from sub-screens to menu

## Task 14: Demo Mode
- [x] Add `start_demo` flag to HighScores singleton for cross-scene communication
- [x] Title screen triggers demo after 15s idle
- [x] Board reads `demo_mode` from singleton on `_ready()`
- [x] AI auto-plays: evaluates all swaps, picks optimal move via scoring heuristic (+50 for 5-match, +35 L/T, +20 for 4-match, +30 for triggering specials)
- [x] Demo visually highlights selected gem before swapping
- [x] Any mouse/keyboard input during demo returns to title
- [x] Game over in demo returns to title (no restart loop)
- [x] Demo scores are never saved
