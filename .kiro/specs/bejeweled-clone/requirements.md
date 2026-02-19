# GemMatch - Requirements

## Overview
A Linux-native Bejeweled-style match-3 puzzle game built with the Godot 4.x engine using GDScript. All graphics are procedurally drawn, all sound effects are synthesized at runtime, and background music is generated from code. Zero external assets.

## User Stories

### US-1: Game Board Display
As a player, I want to see an 8x8 grid of colored gems so that I can identify possible matches.

**Acceptance Criteria:**
- [x] An 8x8 grid is rendered on screen using `_draw()`
- [x] Each cell contains a gem of one of 7 distinct colors
- [x] Each gem type has a unique shape (circle, diamond, square, triangle, hexagon, star, pentagon) for colorblind accessibility
- [x] The board fills the main play area with a checkerboard background and slowly shifting hue
- [x] An animated "GemMatch" logo is displayed above the board

### US-2: Gem Selection and Swapping
As a player, I want to click or drag a gem to swap it with an adjacent gem, so that I can create matches.

**Acceptance Criteria:**
- [x] Clicking a gem highlights it with a pulsing white ring
- [x] Clicking an adjacent gem swaps the two with a bounce tween animation
- [x] Dragging from one gem to an adjacent gem performs a swap
- [x] Clicking a non-adjacent gem changes the selection
- [x] A swap only commits if it results in at least one match of 3+; otherwise gems animate back
- [x] Sound effects play for select, swap, and bad swap

### US-3: Match Detection and Removal
As a player, I want the game to detect and clear matches of 3 or more identical gems in a row or column.

**Acceptance Criteria:**
- [x] Horizontal matches of 3+ same-colored gems are detected
- [x] Vertical matches of 3+ same-colored gems are detected
- [x] Matched gems are removed with a scale-to-zero animation
- [x] Multiple simultaneous matches are all detected and cleared
- [x] Particle effects burst from cleared gems
- [x] Match sound effects rise in pitch with chain combos

### US-4: Special Gems
As a player, I want special gems to be created from larger or shaped matches, adding strategic depth.

**Acceptance Criteria:**
- [x] Matching 4 in a row creates a Flame Gem (glowing orange ring) that explodes in a 3x3 area
- [x] Matching 5 in a row creates a Star Gem (rotating sparkle lines) that destroys all gems of one color
- [x] Matching in an L or T shape creates a Hypercube (rainbow rotating outline) that can be swapped with any gem to destroy all of that color
- [x] Special gem effects trigger with unique sound effects and enhanced screen shake

### US-5: Gravity and Refill
As a player, I want gems to fall down after matches are cleared and new gems to appear from the top.

**Acceptance Criteria:**
- [x] After matches are cleared, gems above empty spaces fall down with bounce-landing animation
- [x] Empty spaces at the top of columns are filled with new random gems that drop in from above
- [x] Cascade matches (new matches formed by falling gems) are detected and cleared automatically
- [x] Special gem states are preserved during gravity shifts

### US-6: Scoring and Progression
As a player, I want to earn points and advance through levels.

**Acceptance Criteria:**
- [x] Points are awarded per gem cleared (10 points × gems × chain multiplier)
- [x] Score is displayed on screen with gold text and drop shadow
- [x] Floating "+score" popups appear at match locations and drift upward
- [x] Combo text escalates: "Good!", "Great!", "Excellent!", "Amazing!", "Incredible!", "UNBELIEVABLE!"
- [x] A progress bar below the grid fills as the player scores
- [x] Every 2000 points triggers a level-up with fanfare sound and announcement
- [x] Level number is displayed in the top-right corner

### US-7: Hint System
As a player, I want the game to show me a valid move if I'm stuck.

**Acceptance Criteria:**
- [x] After 4 seconds of inactivity, a valid move is highlighted with a pulsing glow
- [x] The hint resets when the player makes a move or selects a gem

### US-8: Audio
As a player, I want sound effects and background music to make the game feel polished.

**Acceptance Criteria:**
- [x] Procedural sound effects for: select, swap, bad swap, match (rising pitch), drop, explosion, star, level-up
- [x] Procedural chiptune background music with pentatonic melody, square-wave bass, and sine pad
- [x] All audio is synthesized at runtime — zero audio files

### US-9: Game Over
As a player, I want the game to detect when no valid moves remain.

**Acceptance Criteria:**
- [x] After each move and cascade, the board is checked for possible moves
- [x] If no valid moves exist, a "No Moves" message is displayed
- [x] Clicking restarts the game with a fresh board
