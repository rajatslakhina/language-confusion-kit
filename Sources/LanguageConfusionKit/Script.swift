/// The writing system a letter belongs to. Only letters have one: digits, punctuation, symbols and
/// emoji belong to no script here, so "2026", "→" and "🙂" never count toward a language.
public enum Script: String, Sendable, Hashable, CaseIterable {
    case latin, greek, cyrillic, hebrew, arabic, devanagari, thai, hangul, kana, han

    /// What a reader would call a run of this script's letters inside another language's text.
    public var runName: String {
        switch self {
        case .han: "Chinese characters"
        case .kana: "Japanese kana"
        case .hangul: "Korean letters"
        default: "\(rawValue.prefix(1).uppercased())\(rawValue.dropFirst()) letters"
        }
    }

    /// One ideograph or syllable block says about as much about a language as a short word does,
    /// so it counts three times toward the letters a guess needs.
    var weight: Int {
        switch self {
        case .hangul, .kana, .han: 3
        default: 1
        }
    }

    private static let blocks: [(range: ClosedRange<UInt32>, script: Script)] = [
        (0x41...0x5A, .latin), (0x61...0x7A, .latin), (0xC0...0x24F, .latin), (0x1E00...0x1EFF, .latin),
        (0x370...0x3FF, .greek), (0x1F00...0x1FFF, .greek),
        (0x400...0x52F, .cyrillic),
        (0x591...0x5F4, .hebrew),
        (0x600...0x6FF, .arabic), (0x750...0x77F, .arabic),
        (0x900...0x97F, .devanagari),
        (0xE00...0xE7F, .thai),
        (0x1100...0x11FF, .hangul), (0x3130...0x318F, .hangul), (0xAC00...0xD7AF, .hangul),
        (0x3040...0x30FF, .kana),
        (0x3400...0x4DBF, .han), (0x4E00...0x9FFF, .han)
    ]

    /// The script of one scalar, or nil when it is not a letter of a script this package knows.
    public static func of(_ scalar: Unicode.Scalar) -> Script? {
        guard scalar.properties.isAlphabetic else { return nil }
        return blocks.first { $0.range.contains(scalar.value) }?.script
    }
}

/// Letters per script in a piece of text.
struct ScriptProfile: Sendable, Equatable {
    private(set) var counts: [Script: Int] = [:]
    /// Hiragana alone, of the kana: the particles and endings Japanese writes and Chinese never does.
    private(set) var hiragana = 0

    init(_ text: some StringProtocol) {
        for scalar in text.unicodeScalars {
            guard let script = Script.of(scalar) else { continue }
            counts[script, default: 0] += 1
            if (0x3040...0x309F).contains(scalar.value) { hiragana += 1 }
        }
    }

    func count(_ script: Script) -> Int { counts[script] ?? 0 }

    func weighted(_ script: Script) -> Int { count(script) * script.weight }

    var weightedLetters: Int { Script.allCases.reduce(0) { $0 + weighted($1) } }

    /// The script with the most weighted letters; a tie goes to the script listed first.
    var dominant: Script? {
        Script.allCases.filter { count($0) > 0 }.max { weighted($0) < weighted($1) }
    }
}
