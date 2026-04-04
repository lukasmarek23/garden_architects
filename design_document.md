# Game Design Document: "The Garden Architects"

## 1. Overview
*   **Concept:** A top-down strategy game for 2-5 players (Ages 5-8+).
*   **Theme:** Building a beautiful watercolor garden while collecting water and seeds.
*   **Art Style:** Gentle, luminous watercolor (Beatrix Potter / Monet style).
*   **Core Loop:** Move 1 Step -> Fetch Resource -> Plant in Personal Bed.

## 2. Components
*   **Central Board:** A 5x5 Grid of "Crossing Paths" (Tsuro-style).
*   **Personal Boards:** "Plant Bed" Grids (4x4 or 5x5) for each player.
*   **Tokens:** 
    *   Gardener Pawns (1 per player).
    *   Polyomino Plant Tiles (Strawberries, Onions, Flowers).
    *   Water Droplets (Glass beads).
    *   **The Sun Token** (Turn marker).
*   **Resources:**
    *   **The Well:** Source of water (Unlimited supply, but limits ending).
    *   **Seed Box:** Source of Plant Tiles.

## 3. Plant Tile System (The "Rule of 3" + Legendaries)
**Unified Mechanic:** Size = Water Cost = Point Value.
*   **Size 1 (1 Square):** 
    *   **Strawberry** (Red)
    *   **Daisy** (White)
    *   **Onion** (Brown)
*   **Size 2 (2 Squares - Domino):** 
    *   **Lavender Bush** (Purple, 1x2)
    *   **Carrots** (Orange, 1x2)
*   **Size 3 (3 Squares - Tromino):** 
    *   **Apple Tree** (Green/Red, L-shape)
    *   **Rose Trellis** (Pink, Straight 1x3)
*   **Size 4 (4 Squares - Tetromino):** *The Legendary Plants*
    *   **The Grand Oak** (2x2 Square) - A massive canopy.
    *   **The Fountain** (Cross Shape) - Centerpiece structure.

## 4. Setup
*   **Board:** Players start at opposite edges of the Central Board.
    *   *Paths:* Each player follows their specific color-coded paths which intentionally cross others.
*   **Resources:** Place the Well and Seed Box in opposite corners of the board.
*   **Supply:** Place **12 Water Droplets PER PLAYER** in the "Game Timer" pool. (e.g., 2 Players = 24 Drops).

## 5. Gameplay (Turn Structure)
The game is played in a simple loop. To take a turn, you must be holding the **Sun Token**. On your turn:

1.  **Move & Action:** 
    *   Move your Gardener **1 Step** along your path.
    *   *Constraint:* You can only carry **1 Item** (Seed OR Water).
2.  **Interact:**
    *   **At Seed Box:** Pick up 1 Seed Tile (Free action).
    *   **At Well:** Pick up 1 Water Droplet (Free action).
    *   **At Home Base:** 
        *   **Plant (Architect):** Place a carried Seed Tile into your Grid ("Dry" state).
        *   **Water (Gardener):** Place a carried Water Droplet onto a "Dry" Plant Tile.
        *   **Bloom:** When a tile has **Water = Size**, it is complete! (Score points = Size).
3.  **End Turn:**
    *   Pass the **Sun Token** to the next player.

## 6. Conflict: "The Bump"
*   **Trigger:** If you move onto a space occupied by another player.
*   **Resolution:** **Rock-Paper-Scissors** (Stone/Shears/Leaf).
*   **Consequences (The "High Stakes" Rule):**
    *   **Winner:** 
        *   Stays on the space.
        *   **Takes whatever the Loser is carrying** (even if it exceeds the limit of 1).
        *   *Bonus:* May immediately **Move 1 Step** (Sprint) to escape? (See below).
    *   **Loser:** 
        *   **Returns to Home Base** immediately.
        *   Loses their item to the winner.

## 6. Personal Plant Beds (Asymmetric Difficulty)
Players choose their difficulty level at the start:
*   **Level 1 (The Sprout):** "Shape Match". Grid has pre-printed shapes. Match tile to shadow.
*   **Level 2 (The Gardener):** "Free Form". Grid is empty. Place tiles anywhere (Tetris). Score for adjacency.
*   **Level 3 (The Architect):** "Blueprint". Draw a secret objective card (e.g., "3 Red Flowers in a row").

## 7. End Game & Scoring
*   **Game End:** Triggers when the **Water Pool (20 Drops)** is empty.
*   **Scoring:**
    *   Count points from "Bloomed" (Watered) plants in your personal bed.
    *   Bonus points for Difficulty Level (optional).
    *   **+1 Bonus Point** to the player holding the Sun Token when the game ends.
    *   Highest score wins!
