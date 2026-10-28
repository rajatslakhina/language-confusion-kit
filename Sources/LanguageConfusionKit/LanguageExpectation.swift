/// The language an answer should be in, where that came from, and the other languages it may use.
public struct LanguageExpectation: Sendable, Hashable {
    public enum Source: String, Sendable, Hashable {
        /// "Answer in French", in this turn's message.
        case requested
        /// "From now on, reply in German", in an earlier turn.
        case standing
        /// The language this turn's message is written in.
        case userMessage
        /// The language of an earlier message, when this one is too short to tell ("ok", "thanks!").
        case conversation
    }

    /// Why a second language is fine in this answer.
    public enum Allowance: String, Sendable, Hashable {
        /// The message names it: "How do you say thank you in Japanese?"
        case mentioned
        /// The message asks for a translation into it.
        case translationTarget
    }

    public let language: Language
    public let source: Source
    public let allowed: [Language: Allowance]

    public init(language: Language, source: Source, allowed: [Language: Allowance] = [:]) {
        self.language = language
        self.source = source
        self.allowed = allowed.filter { $0.key != language }
    }

    /// Whether a sentence in `other` is fine here.
    public func accepts(_ other: Language) -> Bool { other == language || allowed[other] != nil }

    /// The scripts an answer may use without a remark: the expected language's and every allowed one's.
    var scripts: Set<Script> {
        Set(([language] + allowed.keys).flatMap(\.scripts))
    }

    /// Why this language, in words a user reads: "you wrote in French".
    public var because: String {
        switch source {
        case .requested: "you asked for an answer in \(language.name)"
        case .standing: "you asked earlier for answers in \(language.name)"
        case .userMessage: "you wrote in \(language.name)"
        case .conversation: "this conversation is in \(language.name)"
        }
    }

    /// The same reason, told to the model in a re-prompt.
    public var reasonForModel: String {
        switch source {
        case .requested: "the user asked for an answer in \(language.name)"
        case .standing: "the user asked earlier for answers in \(language.name)"
        case .userMessage: "the user wrote in \(language.name)"
        case .conversation: "the conversation is in \(language.name)"
        }
    }

    /// A line for a system message, to ask for the language before the model answers rather than after.
    public var instruction: String {
        "Answer in \(language.name). Keep code, names and quotations as they are."
    }
}

/// What a standing request did in this turn.
public enum StandingChange: Sendable, Hashable {
    case unchanged
    case set(Language)
    /// "You can answer in any language."
    case cleared
}

/// Everything one user message says about the language of the answer to it.
public struct ExpectationReading: Sendable, Hashable {
    /// Nil when nothing said what language to expect: no request, no standing one, a message too short
    /// to identify and no earlier one either.
    public let expectation: LanguageExpectation?
    /// The language the message itself is written in, quotations and code left out.
    public let userLanguage: Language?
    public let standingChange: StandingChange
}
