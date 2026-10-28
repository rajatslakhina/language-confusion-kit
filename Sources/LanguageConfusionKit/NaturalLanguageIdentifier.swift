#if canImport(NaturalLanguage)
import NaturalLanguage

/// Apple's `NLLanguageRecognizer` behind the same protocol: some sixty languages, a statistical model
/// that ships with the OS. It commits more often than `LexicalIdentifier` and can be wrong with
/// confidence on names and fragments, so an app that shows its findings to a user does better with
/// `AgreeingIdentifier(NaturalLanguageIdentifier(), LexicalIdentifier())`.
public struct NaturalLanguageIdentifier: LanguageIdentifying {
    public var minimumLetters: Int
    /// The recognizer's probability for its top hypothesis must reach this.
    public var minimumConfidence: Double

    public init(minimumLetters: Int = 12, minimumConfidence: Double = 0.8) {
        self.minimumLetters = minimumLetters
        self.minimumConfidence = minimumConfidence
    }

    public func identify(_ text: String) -> LanguageGuess {
        let letters = ScriptProfile(text).weightedLetters
        guard letters >= minimumLetters else { return .undetermined("too short to tell", weightedLetters: letters) }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let top = recognizer.languageHypotheses(withMaximum: 1).first,
              top.key != .undetermined else {
            return .undetermined("no hypothesis", weightedLetters: letters)
        }
        guard top.value >= minimumConfidence else {
            return .undetermined("not confident (\(Int(top.value * 100))%)", weightedLetters: letters)
        }
        return LanguageGuess(language: Language(code: top.key.rawValue), confidence: top.value,
                             weightedLetters: letters)
    }
}
#endif
