/// One identifier's reading of one piece of text.
public struct LanguageGuess: Sendable, Hashable {
    /// The language, or nil when the identifier would not commit to one.
    public let language: Language?
    /// From 0 to 1. For the lexical identifier it is the best score's share of the two best scores.
    public let confidence: Double
    /// Letters counted, an ideograph or syllable block counting three.
    public let weightedLetters: Int
    /// Why no language was named; nil when one was.
    public let reason: String?

    public init(language: Language?, confidence: Double, weightedLetters: Int, reason: String? = nil) {
        self.language = language
        self.confidence = confidence
        self.weightedLetters = weightedLetters
        self.reason = reason
    }

    public static func undetermined(_ reason: String, weightedLetters: Int) -> LanguageGuess {
        LanguageGuess(language: nil, confidence: 0, weightedLetters: weightedLetters, reason: reason)
    }
}

/// Names the language of a sentence, or declines to.
///
/// Declining is the important half. The checker judges only the sentences an identifier commits on,
/// so an identifier that guesses on a name, a heading or a code fragment turns into a checker that
/// tells a user their answer is in Indonesian.
public protocol LanguageIdentifying: Sendable {
    func identify(_ text: String) -> LanguageGuess
}

/// Several identifiers that must all name the same language. Any one declining, or two naming different
/// languages, leaves the text unjudged: fewer sentences judged, and fewer judged wrongly.
public struct AgreeingIdentifier: LanguageIdentifying {
    public let identifiers: [any LanguageIdentifying]

    public init(_ identifiers: any LanguageIdentifying...) {
        self.identifiers = identifiers
    }

    public func identify(_ text: String) -> LanguageGuess {
        let guesses = identifiers.map { $0.identify(text) }
        let letters = guesses.map(\.weightedLetters).max() ?? 0
        if let declined = guesses.first(where: { $0.language == nil }) { return declined }
        let named = Set(guesses.compactMap(\.language))
        guard named.count == 1, let language = named.first else {
            let names = named.map(\.name).sorted().joined(separator: " and ")
            return .undetermined(named.isEmpty ? "no identifiers" : "identifiers disagree: \(names)",
                                 weightedLetters: letters)
        }
        let confidence = guesses.reduce(1) { min($0, $1.confidence) }
        return LanguageGuess(language: language, confidence: confidence, weightedLetters: letters)
    }
}
