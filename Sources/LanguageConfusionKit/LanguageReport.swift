/// One sentence of an answer and what the check made of it.
public struct SentenceFinding: Sendable, Hashable {
    public enum Status: Sendable, Hashable {
        /// In the expected language.
        case expected
        /// In another language the message allows.
        case allowed(Language, LanguageExpectation.Allowance)
        /// In a language the answer should not be in.
        case wrong(Language)
        /// Not judged: a quotation, or a sentence that repeats the user's message.
        case excused(String)
        /// Not judged: the identifier would not commit ("too short to tell", "no telling words").
        case unjudged(String)
    }

    public let text: String
    /// Zero-based line of the answer the sentence is on.
    public let line: Int
    public let status: Status
    /// Its letters, an ideograph or syllable block counting three.
    public let weightedLetters: Int

    public var isWrong: Bool {
        if case .wrong = status { return true }
        return false
    }

    public var isJudged: Bool {
        switch status {
        case .expected, .allowed, .wrong: true
        case .excused, .unjudged: false
        }
    }
}

/// A word or run of letters that does not belong, inside a sentence that otherwise does.
public struct StrayWord: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        /// A common English word in an answer whose language is written in another script.
        case english
        /// Letters of a script neither the expected language nor an allowed one uses.
        case script(Script)
    }

    public let text: String
    public let kind: Kind
    /// Index into `LanguageReport.sentences`.
    public let sentence: Int
}

/// The result of checking one answer.
public struct LanguageReport: Sendable, Hashable {
    public enum Verdict: String, Sendable, Hashable {
        /// Nothing said what language the answer should be in.
        case noExpectation
        /// Nothing in the answer could be judged: code, names, a few words.
        case unjudged
        /// Every judged sentence is in the expected language, or one the message allows.
        case matched
        /// The sentences are, but some words or letters are not ("word-level confusion").
        case strayWords
        /// Some sentences are in another language ("line-level confusion").
        case mixedSentences
        /// Every judged sentence is in another language.
        case wrongLanguage
    }

    public let reading: ExpectationReading
    public let verdict: Verdict
    public let sentences: [SentenceFinding]
    public let strays: [StrayWord]

    public var expectation: LanguageExpectation? { reading.expectation }

    /// The Language Confusion Benchmark's line-level pass: no judged sentence in the wrong language.
    public var linePass: Bool { !sentences.contains(where: \.isWrong) }
    /// Its word-level pass: no stray words.
    public var wordPass: Bool { strays.isEmpty }

    public var judged: Int { sentences.filter(\.isJudged).count }
    public var wrong: [SentenceFinding] { sentences.filter(\.isWrong) }

    /// The languages the wrong sentences are in, most sentences first.
    public var wrongLanguages: [Language] {
        let languages = sentences.compactMap { finding -> Language? in
            if case .wrong(let language) = finding.status { language } else { nil }
        }
        let counts = Dictionary(grouping: languages) { $0 }.mapValues(\.count)
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.code < $1.key.code }.map(\.key)
    }

    /// A one-line reading for a trace.
    public var summary: String {
        let expected = expectation.map { "\($0.language.name), \($0.source.rawValue)" } ?? "none"
        return "\(verdict.rawValue) (expected \(expected); \(judged) judged, \(wrong.count) wrong, "
            + "\(strays.count) stray)"
    }
}
