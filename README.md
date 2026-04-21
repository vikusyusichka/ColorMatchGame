# Color Match Game (iOS, UIKit)

A simple interactive mini-game built with **Swift** and **UIKit**.

The player must match a target color with the correct option before the timer runs out.

This project is designed as a **portfolio-ready iOS app** focused on:
- UIKit UI development
- game logic and state management
- timer-based interaction
- clean architecture (UI vs logic separation)
- child-friendly UX

---

## Features

- Random color generation
- Color matching gameplay
- Score tracking
- Streak system
- Round progression
- Timer-based rounds
- Visual feedback (correct / incorrect / timeout)
- Game Over screen
- Replay functionality
- Smooth UI animations

---

## Tech Stack

- Swift
- UIKit
- Auto Layout
- Programmatic UI (no Storyboards)


---

## Architecture

### GameViewController
Handles:
- main gameplay screen
- UI updates
- user input
- timer logic
- transitions between rounds

### GameManager
Handles:
- round generation
- answer validation
- score updates
- game reset

### GameState
Stores:
- score
- streak
- current round
- total rounds
- difficulty

### Round
Represents one round:
- target color
- answer options
- correct answer index

### NamedColor
Lightweight model for colors (no UI logic inside)

### Custom Views
- ColorOptionView → answer buttons
- TargetColorView → target display
- TimerBarView → countdown bar

---

## Gameplay

1. A target color is shown
2. 4 color options appear
3. Player selects the matching color
4. If correct:
   - score increases
   - streak increases
5. If incorrect or time runs out:
   - streak resets
6. After all rounds → Game Over screen

---

## Difficulty

The game increases difficulty based on score.

- Easy → longer time
- Medium → faster rounds
- Hard → fastest rounds

---

## How to Run

1. Open project in Xcode
2. Select simulator or device
3. Run the app

---

## Future Improvements

- Sound and music polish
- Haptic feedback
- More animations
- Settings screen
- Additional game modes
- Better accessibility support

---

## Author

iOS UIKit mini-game project created for portfolio purposes.


