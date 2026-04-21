import UIKit

// MARK: - Difficulty

enum Difficulty {
    case easy
    case medium
    case hard

    var optionCount: Int {
        4
    }

    var roundDuration: TimeInterval {
        switch self {
        case .easy:
            return 5.0
        case .medium:
            return 4.0
        case .hard:
            return 3.0
        }
    }

    var useSimilarDistractors: Bool {
        self == .hard
    }
}

// MARK: - GameState

struct GameState {
    var score: Int = 0
    var streak: Int = 0
    var roundNumber: Int = 0
    let totalRounds: Int = 8
    var difficulty: Difficulty = .easy

    var isGameOver: Bool {
        roundNumber >= totalRounds
    }

    mutating func recordCorrect() {
        score += 10 + (streak * 2)
        streak += 1
        roundNumber += 1
        updateDifficulty()
    }

    mutating func recordMissed() {
        streak = 0
        roundNumber += 1
        updateDifficulty()
    }

    private mutating func updateDifficulty() {
        switch score {
        case 0..<40:
            difficulty = .easy
        case 40..<80:
            difficulty = .medium
        default:
            difficulty = .hard
        }
    }
}

// MARK: - Round

struct Round {
    let targetColor: NamedColor
    let options: [NamedColor]
    let correctIndex: Int
}

// MARK: - NamedColor

struct NamedColor: Equatable, Hashable {
    let id: String
    let name: String
    let hex: String

    var color: UIColor {
        UIColor(hex: hex)
    }

    static let palette: [NamedColor] = [
        NamedColor(id: "red", name: "Red", hex: "#FF3B30"),
        NamedColor(id: "orange", name: "Orange", hex: "#FF9500"),
        NamedColor(id: "yellow", name: "Yellow", hex: "#FFCC00"),
        NamedColor(id: "green", name: "Green", hex: "#34C759"),
        NamedColor(id: "blue", name: "Blue", hex: "#007AFF"),
        NamedColor(id: "purple", name: "Purple", hex: "#AF52DE"),
        NamedColor(id: "pink", name: "Pink", hex: "#FF2D55"),
        NamedColor(id: "sky", name: "Sky", hex: "#5AC8FA"),
        NamedColor(id: "tangerine", name: "Tangerine", hex: "#FF6B35"),
        NamedColor(id: "mint", name: "Mint", hex: "#30D158")
    ]

    func shiftedVariant(hueShift: CGFloat, variantSuffix: String) -> NamedColor {
        let shiftedHex = color
            .similarColor(hueShift: hueShift)
            .toHexString()

        return NamedColor(
            id: "\(id)-\(variantSuffix)",
            name: name,
            hex: shiftedHex
        )
    }
}

// MARK: - UIColor Helpers

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    func similarColor(hueShift: CGFloat = 0.07) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let shiftedHue = (hue + hueShift).truncatingRemainder(dividingBy: 1.0)
            return UIColor(
                hue: shiftedHue,
                saturation: saturation,
                brightness: brightness,
                alpha: alpha
            )
        }

        var white: CGFloat = 0
        if getWhite(&white, alpha: &alpha) {
            let adjustedWhite = min(max(white + 0.06, 0), 1)
            return UIColor(white: adjustedWhite, alpha: alpha)
        }

        return self
    }

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(
                format: "#%02X%02X%02X",
                Int(round(r * 255)),
                Int(round(g * 255)),
                Int(round(b * 255))
            )
        }

        var white: CGFloat = 0
        if getWhite(&white, alpha: &a) {
            let value = Int(round(white * 255))
            return String(format: "#%02X%02X%02X", value, value, value)
        }

        return "#000000"
    }
}
