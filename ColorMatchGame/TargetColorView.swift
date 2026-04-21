// TargetColorView.swift
// ColorMatchGame
//
// The "match this" focal card. Pure color fill, no emoji, no UIImageView, no SF Symbols.
// A white ring border and drop shadow provide visual distinction from the option cards.

import UIKit

final class TargetColorView: UIView {

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius  = 28
        layer.masksToBounds = false          // allow shadow to render

        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowOffset  = CGSize(width: 0, height: 8)
        layer.shadowRadius  = 16

        layer.borderWidth   = 5
        layer.borderColor   = UIColor.white.withAlphaComponent(0.65).cgColor

        backgroundColor = .systemGray4      // neutral until first round
    }

    // MARK: - Public API

    func setColor(_ nc: NamedColor, animated: Bool) {
        if animated {
            UIView.transition(with: self, duration: 0.28,
                              options: .transitionCrossDissolve) {
                self.backgroundColor = nc.color
            }
        } else {
            backgroundColor = nc.color
        }
    }

    func animateCorrect() {
        // Brief scale-up bounce
        UIView.animate(
            withDuration: 0.16, delay: 0,
            usingSpringWithDamping: 0.4, initialSpringVelocity: 8, options: [],
            animations: { self.transform = CGAffineTransform(scaleX: 1.08, y: 1.08) }
        ) { _ in UIView.animate(withDuration: 0.16) { self.transform = .identity } }

        // White ring flash
        let flash             = CABasicAnimation(keyPath: "borderColor")
        flash.fromValue       = UIColor.white.cgColor
        flash.toValue         = UIColor.white.withAlphaComponent(0.65).cgColor
        flash.duration        = 0.4
        flash.timingFunction  = CAMediaTimingFunction(name: .easeOut)
        layer.add(flash, forKey: "borderFlash")
    }

    func animateMissed() {
        // Gentle alpha dip
        UIView.animate(withDuration: 0.12, animations: { self.alpha = 0.5 }) { _ in
            UIView.animate(withDuration: 0.18) { self.alpha = 1 }
        }
    }
}
