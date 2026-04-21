// GameOverViewController.swift
// ColorMatchGame — Rebuilt end screen
//
// ROOT CAUSES FIXED:
//  1. UIButton(type:.system) on iOS 15+ can auto-inject a "questionmark" SF Symbol as
//     its image when the button's imageConfiguration resolves to a fallback. Fix: use
//     UIButton(type:.custom) and set NO image at all — text-only buttons.
//  2. trophyLabel / starsLabel used emoji that render as "?" in UILabel on simulator.
//     Fix: replaced with a plain colored UIView "dot" indicator and plain text labels.
//  3. scoreDisplayLabel used "⭐ X" with a colored-emoji prefix. Fix: plain "X pts".
//  4. Layout had replayButton bottom-anchored above homeButton, but homeButton was
//     bottom-anchored to safeArea — if the screen is short these could overlap or
//     conflict with the top elements. Fix: single vertical UIStackView for all content.

import UIKit

final class GameOverViewController: UIViewController {

    // MARK: - Properties

    private let finalScore:  Int
    private let totalRounds: Int
    var onReplay: (() -> Void)?

    // MARK: - Background

    private let bg: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors     = [UIColor(hex: "#0D1B2A").cgColor,
                        UIColor(hex: "#1B3358").cgColor,
                        UIColor(hex: "#0D4E6E").cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        return g
    }()

    // MARK: - Content Card

    private let card: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor.white.withAlphaComponent(0.10)
        v.layer.cornerRadius = 28
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor.white.withAlphaComponent(0.18).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Result Indicator
    // Three colored circles = star rating. No emoji, no SF Symbol.

    private let dotsView: UIView = {
        let v = UIView()
        v.backgroundColor                          = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Labels

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 26, weight: .heavy)
        l.textColor     = .white
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 58, weight: .black)
        l.textColor     = UIColor(hex: "#FFD60A")
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scoreSubLabel: UILabel = {
        let l = UILabel()
        l.text          = "points"
        l.font          = UIFont.systemFont(ofSize: 18, weight: .semibold)
        l.textColor     = UIColor.white.withAlphaComponent(0.65)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Buttons
    // UIButton(type:.custom) — prevents iOS from auto-assigning any SF Symbol image

    private let replayButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Play Again", for: .normal)
        b.titleLabel?.font   = UIFont.systemFont(ofSize: 24, weight: .black)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor    = UIColor(hex: "#34C759")
        b.layer.cornerRadius = 22
        // No image, no imageConfiguration, no SF Symbol
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let homeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Home", for: .normal)
        b.titleLabel?.font   = UIFont.systemFont(ofSize: 20, weight: .semibold)
        b.setTitleColor(UIColor.white.withAlphaComponent(0.75), for: .normal)
        b.backgroundColor    = UIColor.white.withAlphaComponent(0.12)
        b.layer.cornerRadius = 22
        b.layer.borderWidth  = 1
        b.layer.borderColor  = UIColor.white.withAlphaComponent(0.25).cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init

    init(score: Int, totalRounds: Int) {
        self.finalScore  = score
        self.totalRounds = totalRounds
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        configureContent()
        buildLayout()
        replayButton.addTarget(self, action: #selector(tappedReplay), for: .touchUpInside)
        homeButton.addTarget(self, action: #selector(tappedHome), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
        SoundManager.shared.playGameOver()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bg.frame = view.bounds
    }

    // MARK: - Setup

    private func setupBackground() {
        bg.frame = view.bounds
        view.layer.insertSublayer(bg, at: 0)
    }

    private func configureContent() {
        let ratio = totalRounds > 0 ? Double(finalScore) / Double(totalRounds * 12) : 0
        let stars: Int
        let message: String

        switch ratio {
        case 0.8...:
            stars   = 3
            message = "Amazing!\nYou are a Color Star!"
        case 0.5..<0.8:
            stars   = 2
            message = "Great job!\nKeep going!"
        default:
            stars   = 1
            message = "Well tried!\nYou can do it!"
        }

        messageLabel.text = message
        scoreLabel.text   = "\(finalScore)"

        // Build dot indicators (colored circles, no emoji)
        buildStarDots(count: stars)
    }

    /// Three circles: filled = earned, hollow = not earned. No emoji.
    private func buildStarDots(count: Int) {
        let size: CGFloat   = 18
        let spacing: CGFloat = 12
        let total: CGFloat  = size * 3 + spacing * 2

        for i in 0..<3 {
            let dot                  = UIView()
            dot.layer.cornerRadius   = size / 2
            dot.backgroundColor      = i < count
                ? UIColor(hex: "#FFD60A")
                : UIColor.white.withAlphaComponent(0.20)
            dot.layer.borderWidth    = i < count ? 0 : 1
            dot.layer.borderColor    = UIColor.white.withAlphaComponent(0.30).cgColor
            dot.frame = CGRect(
                x: (CGFloat(i) * (size + spacing)),
                y: 0,
                width: size, height: size
            )
            dotsView.addSubview(dot)
        }

        // The dots view itself needs a fixed size
        dotsView.widthAnchor.constraint(equalToConstant: total).isActive   = true
        dotsView.heightAnchor.constraint(equalToConstant: size).isActive   = true
    }

    // MARK: - Layout

    private func buildLayout() {
        // Inner card content: dotsView, messageLabel, score, buttons
        let dotWrapper = UIView()           // centers dots horizontally
        dotWrapper.backgroundColor = .clear
        dotWrapper.translatesAutoresizingMaskIntoConstraints = false
        dotWrapper.addSubview(dotsView)
        NSLayoutConstraint.activate([
            dotsView.centerXAnchor.constraint(equalTo: dotWrapper.centerXAnchor),
            dotsView.topAnchor.constraint(equalTo: dotWrapper.topAnchor),
            dotsView.bottomAnchor.constraint(equalTo: dotWrapper.bottomAnchor),
        ])

        let spacer = UIView()
        spacer.backgroundColor = .clear
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let cardStack = UIStackView(arrangedSubviews: [
            dotWrapper,
            messageLabel,
            spacer,
            scoreLabel,
            scoreSubLabel,
        ])
        cardStack.axis         = .vertical
        cardStack.alignment    = .fill
        cardStack.distribution = .fill
        cardStack.spacing      = 10
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            dotWrapper.heightAnchor.constraint(equalToConstant: 18),
        ])

        // Button sizing
        replayButton.heightAnchor.constraint(equalToConstant: 58).isActive = true
        homeButton.heightAnchor.constraint(equalToConstant: 52).isActive   = true

        // Outer page stack: card, then buttons
        let pageStack = UIStackView(arrangedSubviews: [
            card, replayButton, homeButton,
        ])
        pageStack.axis         = .vertical
        pageStack.alignment    = .fill
        pageStack.distribution = .fill
        pageStack.spacing      = 18
        pageStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(pageStack)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            pageStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            pageStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            pageStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            // Safety clamps so it never escapes safe area on small screens
            pageStack.topAnchor.constraint(greaterThanOrEqualTo: safe.topAnchor, constant: 40),
            pageStack.bottomAnchor.constraint(lessThanOrEqualTo: safe.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Animations

    private func animateIn() {
        let allViews: [UIView] = [card, replayButton, homeButton]
        allViews.forEach { $0.alpha = 0; $0.transform = CGAffineTransform(translationX: 0, y: 24) }

        for (i, v) in allViews.enumerated() {
            UIView.animate(
                withDuration: 0.48, delay: Double(i) * 0.10,
                usingSpringWithDamping: 0.72, initialSpringVelocity: 5, options: [],
                animations: { v.alpha = 1; v.transform = .identity }
            )
        }
    }

    // MARK: - Actions

    @objc private func tappedReplay() {
        UIView.animate(withDuration: 0.08,
                       animations: { self.replayButton.transform = CGAffineTransform(scaleX: 0.94, y: 0.94) }) { _ in
            UIView.animate(withDuration: 0.08) { self.replayButton.transform = .identity }
        }
        dismiss(animated: true) { [weak self] in self?.onReplay?() }
    }

    @objc private func tappedHome() {
        presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
}
