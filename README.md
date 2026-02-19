# GemMatch

A Bejeweled-style match-3 puzzle game built entirely with the Godot 4.x engine. No external assets — all graphics are procedurally drawn, all sound effects are synthesized at runtime, and the background music is generated from code.

![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Platform](https://img.shields.io/badge/platform-Linux-orange)

![Title Screen](screenshots/title.png)
![Gameplay](screenshots/gameplay.png)

## How to Play

- **Click** a gem to select it, then **click** an adjacent gem to swap
- **Drag** from one gem to an adjacent gem to swap
- Match **3 or more** identical gems in a row or column to clear them
- Cleared gems award points; chain reactions multiply your score
- Fill the **progress bar** to advance to the next level
- If no moves remain, click to restart

## Special Gems

| Match | Creates | Effect |
|-------|---------|--------|
| 4 in a row | 🔥 Flame Gem | Explodes in a 3×3 area when matched |
| 5 in a row | ⭐ Star Gem | Destroys all gems of one color when matched |
| L or T shape | 🌈 Hypercube | Swap with any gem to destroy all of that color |

## Features

- 8×8 grid with 7 gem types, each with a **unique shape** (colorblind accessible)
- Smooth **tween animations** — bounce swaps, scale-down removal, bounce-landing gravity
- **Screen shake** that intensifies with chain combos
- **Floating score popups** at match locations
- **Combo callouts** — "Good!", "Great!", "Excellent!", "Amazing!", "Incredible!", "UNBELIEVABLE!"
- **Hint system** — after 4 seconds idle, a valid move is highlighted
- **Drag-to-swap** and click-to-swap input
- **Level progression** with a progress bar
- **Procedural sound effects** — select, swap, bad swap, match (rising pitch per chain), drop, explosion, star, level-up
- **Procedural chiptune music** — pentatonic melody, square-wave bass, sine pad, all generated at startup
- **Animated logo** with per-letter color and bounce

## Project Structure

```
GemMatch/
├── project.godot          # Godot project config (600×730, GL Compatibility)
├── scenes/
│   └── main.tscn          # Single scene: Board, Logo, Labels, SFX, Music
├── scripts/
│   ├── board.gd           # Core game logic, rendering, input, animations (783 lines)
│   ├── sfx.gd             # Procedural sound effect generator (50 lines)
│   ├── music.gd           # Procedural background music generator (79 lines)
│   └── logo.gd            # Animated "GemMatch" title logo (35 lines)
└── .kiro/
    └── specs/              # Design specs (requirements, design, tasks)
```

**Total: ~950 lines of GDScript, 0 external assets.**

## Running

Requires [Godot 4.2+](https://godotengine.org/download).

```bash
# If Godot is on PATH:
godot --path .

# Or via Flatpak:
flatpak run org.godotengine.Godot --path /path/to/GemMatch
```

## How This Was Made

This game was built entirely through an AI-assisted conversation with **Claude Opus 4.6** (via Kiro CLI) on **February 18, 2025**, in a single session lasting roughly 1.5 hours.

### The process

1. **Spec phase** — Claude generated structured requirements, architecture design, and implementation task documents in `.kiro/specs/`
2. **V1 — Basic game** — A minimal working match-3 with `_draw()`-based rendering, click input, match detection, gravity, and scoring
3. **V2 — Animations & sound** — Added tween animations (swap, remove, fall with bounce), screen shake, score popups, procedural sound effects
4. **V3 — Full feature set** — Special gems (Flame/Star/Hypercube), drag-to-swap, hint system, level progression, combo text, particle effects, distinct gem shapes for accessibility
5. **V4 — Polish** — Animated logo, procedural background music, renamed to GemMatch

Each iteration was tested by launching Godot directly from the terminal. Type errors from Godot 4.6's stricter inference were caught and fixed in-session.

### Token usage estimate

- **Input tokens:** ~80,000 (conversation context, code read-backs, tool results)
- **Output tokens:** ~30,000 (specs, code generation, commands, explanations)
- **Total:** ~110,000 tokens across the full session

The entire codebase — every line of GDScript, the scene file, and the project config — was written by Claude. No code was written or edited by hand.

## License

MIT
