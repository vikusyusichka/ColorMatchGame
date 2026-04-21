import UIKit

final class GameManager {

    private(set) var state = GameState()

    func generateRound() -> Round {
        let palette = NamedColor.palette.shuffled()
        let optionCount = state.difficulty.optionCount

        guard palette.count >= optionCount else {
            fatalError("Palette must contain at least \(optionCount) colors.")
        }

        let options = Array(palette.prefix(optionCount))
        let correctIndex = Int.random(in: 0..<options.count)
        let target = options[correctIndex]

        return Round(
            targetColor: target,
            options: options,
            correctIndex: correctIndex
        )
    }

    @discardableResult
    func submitAnswer(index: Int, for round: Round) -> Bool {
        let isCorrect = index == round.correctIndex

        if isCorrect {
            state.recordCorrect()
        } else {
            state.recordMissed()
        }

        return isCorrect
    }

    func submitMissed() {
        state.recordMissed()
    }

    func reset() {
        state = GameState()
    }
}
