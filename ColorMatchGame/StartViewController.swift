// StartViewController.swift
// ColorMatchGame — corrected
//
// Uses UIButton(type:.custom), no emoji in UILabel (avoids "?" rendering),
// decorative colored circles replace floating emoji labels.

import UIKit

final class StartViewController: UIViewController {

    // MARK: - Background

    private let bg: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors     = [UIColor(hex: "#7B2FBE").cgColor, UIColor(hex: "#3A86FF").cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        return g
    }()

    // MARK: - Decoration Circles

    private let decorColors: [UIColor] = [
        UIColor(hex: "#FF3B30"),
        UIColor(hex: "#FFCC00"),
        UIColor(hex: "#34C759"),
        UIColor(hex: "#007AFF"),
        UIColor(hex: "#FF9500"),
        UIColor(hex: "#AF52DE"),
    ]

    // MARK: - Content

    // Large color swatch grid — purely UIViews, no emoji
    private let swatchRow: UIStackView = {
        let sv = UIStackView()
        sv.axis         = .horizontal
        sv.distribution = .fillEqually
        sv.alignment    = .fill
        sv.spacing      = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text          = "Color Match"
        l.font          = UIFont.systemFont(ofSize: 42, weight: .heavy)
        l.textColor     = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text          = "Can you match the color?"
        l.font          = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor     = UIColor.white.withAlphaComponent(0.75)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // UIButton(type:.custom) — prevents iOS from injecting any default SF Symbol image
    private let playButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Play", for: .normal)
        b.titleLabel?.font   = UIFont.systemFont(ofSize: 30, weight: .black)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor    = UIColor(hex: "#34C759")
        b.layer.cornerRadius = 30
        b.layer.shadowColor  = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.25
        b.layer.shadowRadius  = 12
        b.layer.shadowOffset  = CGSize(width: 0, height: 6)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        buildSwatches()
        setupLayout()
        addDecorationCircles()
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
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

    private func buildSwatches() {
        // Five color swatches above the title — pure UIView rounded squares
        let colors: [UIColor] = [
            UIColor(hex: "#FF3B30"), UIColor(hex: "#FFCC00"),
            UIColor(hex: "#34C759"), UIColor(hex: "#007AFF"), UIColor(hex: "#AF52DE")
        ]
        for c in colors {
            let swatch                  = UIView()
            swatch.backgroundColor      = c
            swatch.layer.cornerRadius   = 14
            swatch.layer.masksToBounds  = true
            swatch.layer.borderWidth    = 2
            swatch.layer.borderColor    = UIColor.white.withAlphaComponent(0.4).cgColor
            swatchRow.addArrangedSubview(swatch)
        }
    }

    private func addDecorationCircles() {
        // Soft floating circles in the background — no emoji needed
        let specs: [(CGPoint, CGFloat)] = [
            (CGPoint(x: 0.08, y: 0.10), 60),
            (CGPoint(x: 0.90, y: 0.07), 48),
            (CGPoint(x: 0.04, y: 0.55), 44),
            (CGPoint(x: 0.93, y: 0.52), 52),
            (CGPoint(x: 0.15, y: 0.88), 50),
            (CGPoint(x: 0.82, y: 0.84), 56),
        ]
        for (i, spec) in specs.enumerated() {
            let circle                  = UIView()
            let sz                      = spec.1
            circle.backgroundColor      = decorColors[i % decorColors.count].withAlphaComponent(0.28)
            circle.layer.cornerRadius   = sz / 2
            circle.frame = CGRect(
                x: view.bounds.width  * spec.0.x - sz / 2,
                y: view.bounds.height * spec.0.y - sz / 2,
                width: sz, height: sz
            )
            view.insertSubview(circle, at: 1)
            UIView.animate(
                withDuration: 2.2, delay: Double(i) * 0.3,
                options: [.autoreverse, .repeat, .curveEaseInOut],
                animations: { circle.transform = CGAffineTransform(translationX: 0, y: -14) }
            )
        }
    }

    private func setupLayout() {
        [swatchRow, titleLabel, subtitleLabel, playButton].forEach { view.addSubview($0) }

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            swatchRow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            swatchRow.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -130),
            swatchRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            swatchRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            swatchRow.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.topAnchor.constraint(equalTo: swatchRow.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            playButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 44),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 180),
            playButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    // MARK: - Animate In

    private func animateIn() {
        let views: [UIView] = [swatchRow, titleLabel, subtitleLabel, playButton]
        views.forEach { $0.alpha = 0; $0.transform = CGAffineTransform(scaleX: 0.80, y: 0.80) }
        for (i, v) in views.enumerated() {
            UIView.animate(
                withDuration: 0.50, delay: Double(i) * 0.07,
                usingSpringWithDamping: 0.68, initialSpringVelocity: 5, options: [],
                animations: { v.alpha = 1; v.transform = .identity }
            )
        }
    }

    // MARK: - Actions

    @objc private func didTapPlay() {
        UIView.animate(withDuration: 0.08,
                       animations: { self.playButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92) }) { _ in
            UIView.animate(withDuration: 0.08) { self.playButton.transform = .identity }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            let vc                     = GameViewController()
            vc.modalPresentationStyle  = .fullScreen
            vc.modalTransitionStyle    = .crossDissolve
            self.present(vc, animated: true)
        }
    }
}
