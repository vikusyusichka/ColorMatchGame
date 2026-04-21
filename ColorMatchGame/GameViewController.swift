import UIKit

final class GameViewController: UIViewController {

    // MARK: - Dependencies & State

    private let manager = GameManager()

    private var currentRound: Round?
    private var roundTimer: Timer?
    private var nextRoundWorkItem: DispatchWorkItem?

    private var inputLocked = false
    private var isShowingGameOver = false
    private var isRoundTransitionInProgress = false

    // MARK: - Layout Constants

    private enum K {
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 20
        static let optionSpacing: CGFloat = 14
        static let hudHeight: CGFloat = 72
        static let targetSize: CGFloat = 184
        static let optionHeight: CGFloat = 120
        static let feedbackFontSize: CGFloat = 48
    }

    // MARK: - Background

    private let backgroundGradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(hex: "#0D1B2A").cgColor,
            UIColor(hex: "#1B3358").cgColor,
            UIColor(hex: "#0D4E6E").cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }()

    // MARK: - HUD

    private let hudCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        return view
    }()

    private let scoreLabel: UILabel = {
        let label = makeHUDLabel(fontSize: 20, weight: .black, alignment: .left)
        return label
    }()

    private let roundLabel: UILabel = {
        let label = makeHUDLabel(fontSize: 16, weight: .semibold, alignment: .center)
        return label
    }()

    private let streakLabel: UILabel = {
        let label = makeHUDLabel(fontSize: 18, weight: .bold, alignment: .right)
        label.textColor = UIColor(hex: "#FFD60A")
        return label
    }()

    private let timerBar: TimerBarView = {
        let view = TimerBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Main UI

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Match this color"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.78)
        label.textAlignment = .center
        return label
    }()

    private let targetColorView: TargetColorView = {
        let view = TargetColorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var targetWrapper: UIView = {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.backgroundColor = .clear
        wrapper.addSubview(targetColorView)

        NSLayoutConstraint.activate([
            targetColorView.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            targetColorView.topAnchor.constraint(equalTo: wrapper.topAnchor),
            targetColorView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            targetColorView.widthAnchor.constraint(equalToConstant: K.targetSize),
            targetColorView.heightAnchor.constraint(equalToConstant: K.targetSize)
        ])

        return wrapper
    }()

    private var optionViews: [ColorOptionView] = []

    private let rowOneStack: UIStackView = {
        let stack = makeRowStack(spacing: K.optionSpacing)
        return stack
    }()

    private let rowTwoStack: UIStackView = {
        let stack = makeRowStack(spacing: K.optionSpacing)
        return stack
    }()

    private lazy var optionsGridStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [rowOneStack, rowTwoStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = K.optionSpacing
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            hudCard,
            promptLabel,
            targetWrapper,
            optionsGridStack
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = K.sectionSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private let feedbackLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: K.feedbackFontSize, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 0
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Lifecycle

    deinit {
        invalidateRoundFlow()
        print("GameViewController deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        buildOptionViews()
        buildLayout()
        startNewRound()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isBeingDismissed || isMovingFromParent {
            invalidateRoundFlow()
        }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .black
        backgroundGradient.frame = view.bounds
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    private func buildOptionViews() {
        optionViews = (0..<4).map { _ in ColorOptionView() }

        rowOneStack.addArrangedSubview(optionViews[0])
        rowOneStack.addArrangedSubview(optionViews[1])
        rowTwoStack.addArrangedSubview(optionViews[2])
        rowTwoStack.addArrangedSubview(optionViews[3])
    }

    private func buildLayout() {
        let labelsRow = UIStackView(arrangedSubviews: [scoreLabel, roundLabel, streakLabel])
        labelsRow.translatesAutoresizingMaskIntoConstraints = false
        labelsRow.axis = .horizontal
        labelsRow.alignment = .center
        labelsRow.distribution = .equalSpacing

        hudCard.addSubview(labelsRow)
        hudCard.addSubview(timerBar)

        view.addSubview(contentStack)
        view.addSubview(feedbackLabel)

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: K.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -K.horizontalPadding),

            hudCard.heightAnchor.constraint(equalToConstant: K.hudHeight),
            promptLabel.heightAnchor.constraint(equalToConstant: 26),
            targetWrapper.heightAnchor.constraint(equalToConstant: K.targetSize),
            optionsGridStack.heightAnchor.constraint(equalToConstant: K.optionHeight * 2 + K.optionSpacing),

            labelsRow.topAnchor.constraint(equalTo: hudCard.topAnchor, constant: 10),
            labelsRow.leadingAnchor.constraint(equalTo: hudCard.leadingAnchor, constant: 16),
            labelsRow.trailingAnchor.constraint(equalTo: hudCard.trailingAnchor, constant: -16),

            timerBar.topAnchor.constraint(equalTo: labelsRow.bottomAnchor, constant: 8),
            timerBar.leadingAnchor.constraint(equalTo: hudCard.leadingAnchor, constant: 16),
            timerBar.trailingAnchor.constraint(equalTo: hudCard.trailingAnchor, constant: -16),
            timerBar.heightAnchor.constraint(equalToConstant: 7),
            timerBar.bottomAnchor.constraint(equalTo: hudCard.bottomAnchor, constant: -10),

            feedbackLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            feedbackLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.84)
        ])
    }

    // MARK: - Round Flow

    private func startNewRound() {
        assert(Thread.isMainThread)

        guard !isShowingGameOver else { return }
        guard !isRoundTransitionInProgress else { return }

        if manager.state.isGameOver {
            presentGameOver()
            return
        }

        invalidateTimerOnly()
        nextRoundWorkItem?.cancel()
        nextRoundWorkItem = nil

        inputLocked = false

        let round = manager.generateRound()
        currentRound = round

        updateHUD()
        targetColorView.setColor(round.targetColor, animated: manager.state.roundNumber > 0)

        for (index, optionView) in optionViews.enumerated() {
            guard index < round.options.count else {
                optionView.isHidden = true
                optionView.onTap = nil
                continue
            }

            optionView.isHidden = false
            optionView.alpha = 0
            optionView.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
            optionView.namedColor = round.options[index]
            optionView.enable()
            optionView.resetVisuals()

            let capturedIndex = index
            optionView.onTap = { [weak self] in
                self?.handleTap(index: capturedIndex)
            }
        }

        animateOptionsIn()
        startTimer(duration: manager.state.difficulty.roundDuration)
    }

    private func animateOptionsIn() {
        for (index, optionView) in optionViews.enumerated() where !optionView.isHidden {
            UIView.animate(
                withDuration: 0.35,
                delay: Double(index) * 0.05,
                usingSpringWithDamping: 0.70,
                initialSpringVelocity: 5,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                optionView.alpha = 1
                optionView.transform = .identity
            }
        }
    }

    private func updateHUD() {
        scoreLabel.text = "Score \(manager.state.score)"
        roundLabel.text = "\(manager.state.roundNumber + 1) / \(manager.state.totalRounds)"
        streakLabel.text = manager.state.streak > 1 ? "x\(manager.state.streak)" : ""
    }

    // MARK: - Timer

    private func startTimer(duration: TimeInterval) {
        invalidateTimerOnly()

        timerBar.startCountdown(duration: duration)

        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }

        roundTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func invalidateTimerOnly() {
        roundTimer?.invalidate()
        roundTimer = nil
        timerBar.stop()
    }

    private func invalidateRoundFlow() {
        invalidateTimerOnly()
        nextRoundWorkItem?.cancel()
        nextRoundWorkItem = nil
    }

    // MARK: - Answer Handling

    private func handleTap(index: Int) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleTap(index: index)
            }
            return
        }

        guard !inputLocked else { return }
        guard !isShowingGameOver else { return }
        guard let round = currentRound else { return }
        guard index >= 0, index < round.options.count else { return }

        inputLocked = true
        invalidateTimerOnly()

        let isCorrect = manager.submitAnswer(index: index, for: round)
        updateHUD()
        animateScore()

        if isCorrect {
            SoundManager.shared.playCorrect()
            targetColorView.animateCorrect()

            optionViews[index].animateCorrect { [weak self] in
                guard let self else { return }

                self.showFeedback("GREAT!", color: UIColor(hex: "#34C759"))

                if self.manager.state.isGameOver {
                    self.scheduleGameOver(after: 0.7)
                } else {
                    self.scheduleNextRound(after: 0.55)
                }
            }
        } else {
            SoundManager.shared.playWrong()
            targetColorView.animateMissed()

            optionViews[index].animateIncorrect { [weak self] in
                guard let self else { return }

                if round.correctIndex >= 0, round.correctIndex < self.optionViews.count {
                    self.optionViews[round.correctIndex].animateHighlightCorrect()
                }

                self.showFeedback("TRY AGAIN", color: UIColor(hex: "#FF3B30"))

                if self.manager.state.isGameOver {
                    self.scheduleGameOver(after: 1.0)
                } else {
                    self.scheduleNextRound(after: 1.1)
                }
            }
        }
    }

    private func handleTimeout() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleTimeout()
            }
            return
        }

        guard !inputLocked else { return }
        guard !isShowingGameOver else { return }
        guard let round = currentRound else { return }

        inputLocked = true
        invalidateTimerOnly()

        SoundManager.shared.playTimeout()
        manager.submitMissed()
        updateHUD()

        timerBar.pulse()
        targetColorView.animateMissed()

        if round.correctIndex >= 0, round.correctIndex < optionViews.count {
            optionViews[round.correctIndex].animateHighlightCorrect()
        }

        streakLabel.text = ""
        showFeedback("TOO SLOW", color: UIColor(hex: "#FF9500"))

        if manager.state.isGameOver {
            scheduleGameOver(after: 1.0)
        } else {
            scheduleNextRound(after: 1.1)
        }
    }

    // MARK: - Round Transition

    private func scheduleNextRound(after delay: TimeInterval) {
        nextRoundWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard !self.isShowingGameOver else { return }

            if self.manager.state.isGameOver {
                self.presentGameOver()
                return
            }

            self.fadeOutOptionsAndStartNextRound()
        }

        nextRoundWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleGameOver(after delay: TimeInterval) {
        nextRoundWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.presentGameOver()
        }

        nextRoundWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func fadeOutOptionsAndStartNextRound() {
        guard !isRoundTransitionInProgress else { return }
        isRoundTransitionInProgress = true

        let visibleOptions = optionViews.filter { !$0.isHidden }

        guard !visibleOptions.isEmpty else {
            isRoundTransitionInProgress = false
            startNewRound()
            return
        }

        let group = DispatchGroup()

        for optionView in visibleOptions {
            group.enter()
            optionView.animateFadeOut {
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isRoundTransitionInProgress = false
            self.startNewRound()
        }
    }

    // MARK: - Feedback

    private func showFeedback(_ text: String, color: UIColor) {
        feedbackLabel.text = text
        feedbackLabel.textColor = color
        feedbackLabel.alpha = 0
        feedbackLabel.transform = CGAffineTransform(scaleX: 0.35, y: 0.35)

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 10,
            options: [.beginFromCurrentState]
        ) {
            self.feedbackLabel.alpha = 1
            self.feedbackLabel.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        } completion: { _ in
            UIView.animate(withDuration: 0.20, delay: 0.30, options: [.beginFromCurrentState]) {
                self.feedbackLabel.alpha = 0
                self.feedbackLabel.transform = .identity
            }
        }
    }

    private func animateScore() {
        UIView.animate(withDuration: 0.10) {
            self.scoreLabel.transform = CGAffineTransform(scaleX: 1.20, y: 1.20)
        } completion: { _ in
            UIView.animate(withDuration: 0.10) {
                self.scoreLabel.transform = .identity
            }
        }
    }

    // MARK: - Game Over

    private func presentGameOver() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.presentGameOver()
            }
            return
        }

        guard !isShowingGameOver else { return }
        guard presentedViewController == nil else { return }

        isShowingGameOver = true
        invalidateRoundFlow()

        let gameOverViewController = GameOverViewController(
            score: manager.state.score,
            totalRounds: manager.state.totalRounds
        )

        gameOverViewController.onReplay = { [weak self] in
            guard let self else { return }

            self.manager.reset()
            self.currentRound = nil
            self.inputLocked = false
            self.isShowingGameOver = false
            self.isRoundTransitionInProgress = false

            self.dismiss(animated: false) { [weak self] in
                self?.startNewRound()
            }
        }

        gameOverViewController.modalPresentationStyle = .fullScreen
        gameOverViewController.modalTransitionStyle = .crossDissolve
        present(gameOverViewController, animated: true)
    }
}

// MARK: - Helpers

private func makeHUDLabel(fontSize: CGFloat,
                          weight: UIFont.Weight,
                          alignment: NSTextAlignment) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
    label.textColor = .white
    label.textAlignment = alignment
    return label
}

private func makeRowStack(spacing: CGFloat) -> UIStackView {
    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.spacing = spacing
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
}
