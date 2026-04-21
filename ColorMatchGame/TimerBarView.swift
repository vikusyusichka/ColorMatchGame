// TimerBarView.swift
// ColorMatchGame
//
// Compact pill-shaped progress bar. Lives inside the HUD card.
// No subviews other than the fill bar — nothing that could render a "?".

import UIKit

final class TimerBarView: UIView {

    private let fill = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 4
        clipsToBounds      = true
        backgroundColor    = UIColor.white.withAlphaComponent(0.15)

        fill.backgroundColor    = UIColor(hex: "#34C759")
        fill.layer.cornerRadius = 4
        addSubview(fill)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Only reset frame when no animation is running (avoids snapping)
        if fill.layer.animationKeys()?.isEmpty ?? true {
            fill.frame = bounds
        }
    }

    // MARK: - Control

    func startCountdown(duration: TimeInterval) {
        fill.layer.removeAllAnimations()
        fill.frame           = bounds
        fill.backgroundColor = UIColor(hex: "#34C759")

        UIView.animate(
            withDuration: duration, delay: 0, options: [.curveLinear],
            animations: {
                self.fill.frame           = CGRect(x: 0, y: 0, width: 0, height: self.bounds.height)
                self.fill.backgroundColor = UIColor(hex: "#FF3B30")
            })
    }

    func stop() {
        fill.layer.removeAllAnimations()
    }

    func pulse() {
        let a           = CABasicAnimation(keyPath: "opacity")
        a.fromValue     = 1.0
        a.toValue       = 0.15
        a.duration      = 0.22
        a.repeatCount   = 4
        a.autoreverses  = true
        fill.layer.add(a, forKey: "pulse")
    }
}
