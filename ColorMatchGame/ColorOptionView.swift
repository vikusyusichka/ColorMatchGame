// ColorOptionView.swift
// ColorMatchGame
//
// Pure solid-color tappable card. No UILabel, no UIImageView, no SF Symbols.
// The color IS the content — nothing else renders inside it.

import UIKit

final class ColorOptionView: UIView {

    // MARK: - Properties

    var namedColor: NamedColor? { didSet { applyColor() } }
    var onTap: (() -> Void)?
    private var tapEnabled = true

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        // Corner radius applied here; updated in layoutSubviews for circular feel
        layer.cornerRadius  = 20
        layer.masksToBounds = true   // clips color to rounded rect
        layer.borderWidth   = 3.5
        layer.borderColor   = UIColor.white.withAlphaComponent(0.40).cgColor
        backgroundColor     = .systemGray4   // neutral until color is assigned

        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    private func applyColor() {
        guard let nc = namedColor else { return }
        backgroundColor = nc.color
    }

    // MARK: - State

    func enable()  { tapEnabled = true  }
    func disable() { tapEnabled = false }

    func resetVisuals() {
        alpha     = 1
        transform = .identity
        layer.borderColor = UIColor.white.withAlphaComponent(0.40).cgColor
        layer.borderWidth = 3.5
        applyColor()
    }

    // MARK: - Touch

    @objc private func tapped() {
        guard tapEnabled else { return }
        SoundManager.shared.playTap()
        UIView.animate(withDuration: 0.07,
                       animations: { self.transform = CGAffineTransform(scaleX: 0.91, y: 0.91) }) { _ in
            UIView.animate(withDuration: 0.07,
                           animations: { self.transform = .identity }) { _ in
                self.onTap?()
            }
        }
    }

    // MARK: - Feedback Animations

    func animateCorrect(completion: @escaping () -> Void) {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 6
        UIView.animate(
            withDuration: 0.20, delay: 0,
            usingSpringWithDamping: 0.35, initialSpringVelocity: 10, options: [],
            animations: { self.transform = CGAffineTransform(scaleX: 1.10, y: 1.10) }
        ) { _ in
            UIView.animate(withDuration: 0.15) { self.transform = .identity } completion: { _ in
                self.layer.borderColor = UIColor.white.withAlphaComponent(0.40).cgColor
                self.layer.borderWidth = 3.5
                completion()
            }
        }
    }

    func animateIncorrect(completion: @escaping () -> Void) {
        layer.borderColor = UIColor(hex: "#FF3B30").cgColor
        layer.borderWidth = 6

        let shake              = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction   = CAMediaTimingFunction(name: .linear)
        shake.duration         = 0.32
        shake.values           = [0, -9, 9, -6, 6, -3, 3, 0]
        layer.add(shake, forKey: "shake")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            self.layer.borderColor = UIColor.white.withAlphaComponent(0.40).cgColor
            self.layer.borderWidth = 3.5
            completion()
        }
    }

    func animateHighlightCorrect() {
        UIView.animate(withDuration: 0.15, animations: {
            self.layer.borderColor = UIColor.white.cgColor
            self.layer.borderWidth = 6
            self.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.layer.borderColor = UIColor.white.withAlphaComponent(0.40).cgColor
                self.layer.borderWidth = 3.5
                self.transform = .identity
            }
        }
    }

    func animateFadeOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.20,
                       animations: { self.alpha = 0; self.transform = CGAffineTransform(scaleX: 0.88, y: 0.88) }) { _ in
            completion()
        }
    }
}
