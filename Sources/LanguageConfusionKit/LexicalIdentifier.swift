/// A deterministic identifier that needs no model and runs anywhere Swift does.
///
/// The script decides first. Hangul is Korean; Han with hiragana is Japanese, and so is text that is
/// mostly katakana; other Han is Chinese, so a Chinese sentence with one katakana loanword stays Chinese; Greek,
/// Hebrew, Arabic, Devanagari and Thai each map to one language. Cyrillic and Latin are scored on
/// telling words and letters (see `Lexicon`), and the best language must clear `minimumScore` and beat
/// the runner-up by `margin`, or the text is left undetermined. It names twenty languages and declines
/// everything else, which is the right failure for a judge.
public struct LexicalIdentifier: LanguageIdentifying {
    /// Fewer weighted letters than this and the text is too short to tell ("OK", "Merci !").
    public var minimumLetters: Int
    /// The score the best Latin or Cyrillic language needs: one word only it uses and one it shares.
    public var minimumScore: Double
    /// How many times the runner-up's score the best one must reach.
    public var margin: Double
    /// The share of letters the deciding script must hold, or the text mixes scripts too much to name.
    public var minimumScriptShare: Double

    public init(minimumLetters: Int = 12, minimumScore: Double = 1.25, margin: Double = 1.5,
                minimumScriptShare: Double = 0.6) {
        self.minimumLetters = minimumLetters
        self.minimumScore = minimumScore
        self.margin = margin
        self.minimumScriptShare = minimumScriptShare
    }

    public func identify(_ text: String) -> LanguageGuess {
        let profile = ScriptProfile(text)
        let letters = profile.weightedLetters
        guard letters >= minimumLetters, let script = profile.dominant else {
            return .undetermined("too short to tell", weightedLetters: letters)
        }
        let language = Self.scriptLanguage(script, profile)
        let held = (language?.scripts ?? [script]).reduce(0) { $0 + profile.weighted($1) }
        let share = Double(held) / Double(letters)
        guard share >= minimumScriptShare else {
            return .undetermined("mixes scripts", weightedLetters: letters)
        }
        if let language { return LanguageGuess(language: language, confidence: share, weightedLetters: letters) }
        return scored(text, script: script, letters: letters)
    }

    private static let singleScript: [Script: Language] = [
        .greek: .greek, .hebrew: .hebrew, .arabic: .arabic, .devanagari: .hindi, .thai: .thai, .hangul: .korean
    ]

    /// The language a script alone settles, or nil for Latin and Cyrillic.
    private static func scriptLanguage(_ script: Script, _ profile: ScriptProfile) -> Language? {
        if script == .han || script == .kana {
            let hiragana = profile.hiragana
            let ideographs = profile.count(.kana) + profile.count(.han)
            let japanese = script == .kana || hiragana >= 2 || hiragana * 10 >= ideographs
            return japanese ? .japanese : .chinese
        }
        return singleScript[script]
    }

    private func scored(_ text: String, script: Script, letters: Int) -> LanguageGuess {
        let lowered = text.lowercased()
        var scores: [String: Double] = [:]
        for word in lowered.letterWords {
            for (code, weight) in Lexicon.weights[String(word)] ?? [:] { scores[code, default: 0] += weight }
        }
        var marks: [String: Double] = [:]
        for character in lowered {
            for code in Lexicon.markers[character] ?? [] { marks[code, default: 0] += 1 }
        }
        let vietnamese = lowered.unicodeScalars.filter { (0x1EA0...0x1EF9).contains($0.value) }.count
        marks["vi", default: 0] += Double(vietnamese)
        for (code, count) in marks { scores[code, default: 0] += min(count, Lexicon.markerCap) }
        let ranked = scores
            .filter { Language(code: $0.key).scripts.contains(script) }
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
        guard let best = ranked.first, best.value >= minimumScore else {
            return .undetermined("no telling words", weightedLetters: letters)
        }
        let runnerUp = ranked.dropFirst().first
        if let runnerUp, best.value < runnerUp.value * margin {
            let names = [best.key, runnerUp.key].map { Language(code: $0).name }.joined(separator: " and ")
            return .undetermined("too close to call between \(names)", weightedLetters: letters)
        }
        let confidence = best.value / (best.value + (runnerUp?.value ?? 0))
        return LanguageGuess(language: Language(code: best.key), confidence: confidence, weightedLetters: letters)
    }
}

extension String {
    /// Runs of letters, so "l'homme" is "l" and "homme" and "C++" is "C".
    var letterWords: [Substring] { split { !$0.isLetter } }
}
