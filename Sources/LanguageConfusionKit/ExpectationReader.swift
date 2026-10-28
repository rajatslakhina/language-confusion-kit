import Foundation

/// Reads a user message for the language its answer should be in.
///
/// A request beats everything: "Answer in Spanish", "translate this into German", "In French, please",
/// "Russian only", "auf Deutsch", "日本語で". It must be a request, though: "What is 'cat' in French?"
/// and "How do you say thank you in Japanese?" only *mention* a language, and an answer may use it.
/// "From now on" makes a request standing; "any language" lifts it. Without a request, the answer
/// should be in the language the message is written in, and a message too short to tell ("ok") falls
/// back to the conversation's language.
struct ExpectationReader: Sendable {
    let identifier: any LanguageIdentifying

    static let responseVerbs: Set<String> = [
        "respond", "reply", "answer", "write", "speak", "talk", "explain", "rewrite", "continue", "summarize",
        "summarise", "tell", "give", "describe", "redo", "repeat", "switch", "keep"
    ]
    static let translationVerbs: Set<String> = ["translate", "translation", "translated", "say", "said", "call"]
    /// A question opening with one of these asks *about* a language ("What is 'cat' in French?").
    static let whWords: Set<String> = ["what", "what's", "whats", "how", "which"]
    /// A yes-no question asks for a language only with a response verb ("Can you answer in French?").
    static let yesNoWords: Set<String> = ["is", "does", "do", "can", "could", "would", "will"]
    /// Words a question can open with before its question word: "And what is dog in French?"
    static let leadIns: Set<String> = ["and", "but", "so", "also", "then", "ok", "okay", "now", "oh"]
    static let standingMarkers = [
        "from now on", "always", "going forward", "for the rest of", "from here on", "all your answers",
        "every answer", "all answers", "all replies", "stick to"
    ]
    static let liftMarkers = ["any language", "whatever language", "language you like", "language you prefer"]
    static let nativeRequests: [String: Language] = [
        "auf deutsch": .german, "en español": .spanish, "en espanol": .spanish, "en français": .french,
        "en francais": .french, "in italiano": .italian, "em português": .portuguese, "in het nederlands": .dutch,
        "по-русски": .russian, "на русском": .russian, "українською": .ukrainian, "日本語で": .japanese,
        "用中文": .chinese, "中文回答": .chinese, "한국어로": .korean, "हिंदी में": .hindi,
        "باللغة العربية": .arabic, "בעברית": .hebrew, "στα ελληνικά": .greek
    ]

    func read(_ message: String?, standing: Language?, conversation: Language?) -> ExpectationReading {
        guard let message else {
            return ExpectationReading(expectation: Self.fallback(standing, conversation, allowed: [:]),
                                      userLanguage: nil, standingChange: .unchanged)
        }
        let cleaned = TextPieces.cleaned(message)
        let plain = TextPieces.extractQuotes(from: cleaned).rest
        let userLanguage = identifier.identify(plain).language ?? identifier.identify(cleaned).language
        var request: Language?
        var change = StandingChange.unchanged
        var allowed: [Language: LanguageExpectation.Allowance] = [:]
        for sentence in TextPieces.sentences(of: plain) {
            let lowered = sentence.lowercased()
            let reading = Self.readSentence(lowered)
            allowed.merge(reading.allowed) { first, _ in first }
            if Self.liftMarkers.contains(where: lowered.contains) { change = .cleared }
            guard let asked = reading.request else { continue }
            request = asked
            if Self.standingMarkers.contains(where: lowered.contains) { change = .set(asked) }
        }
        let current = Self.apply(change, to: standing)
        let expectation: LanguageExpectation? = if let request {
            LanguageExpectation(language: request, source: .requested, allowed: allowed)
        } else if let current {
            LanguageExpectation(language: current, source: .standing, allowed: allowed)
        } else if let userLanguage {
            LanguageExpectation(language: userLanguage, source: .userMessage, allowed: allowed)
        } else {
            Self.fallback(nil, conversation, allowed: allowed)
        }
        return ExpectationReading(expectation: expectation, userLanguage: userLanguage, standingChange: change)
    }

    static func apply(_ change: StandingChange, to standing: Language?) -> Language? {
        switch change {
        case .unchanged: standing
        case .set(let language): language
        case .cleared: nil
        }
    }

    private static func fallback(_ standing: Language?, _ conversation: Language?,
                                 allowed: [Language: LanguageExpectation.Allowance]) -> LanguageExpectation? {
        if let standing { return LanguageExpectation(language: standing, source: .standing, allowed: allowed) }
        guard let conversation else { return nil }
        return LanguageExpectation(language: conversation, source: .conversation, allowed: allowed)
    }

    struct SentenceReading {
        var request: Language?
        var allowed: [Language: LanguageExpectation.Allowance] = [:]
    }

    /// One lowercased sentence: the language it asks for, if any, and the ones it names otherwise.
    static func readSentence(_ sentence: String) -> SentenceReading {
        var reading = SentenceReading()
        for (phrase, language) in nativeRequests.sorted(by: { $0.key < $1.key }) where sentence.contains(phrase) {
            reading.request = language
        }
        let tokens = sentence.split { $0.isWhitespace || ",:()".contains($0) }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        let lead = tokens.first { !leadIns.contains($0) }
        let wh = lead.map(whWords.contains) == true
        let yesNo = lead.map(yesNoWords.contains) == true
        for mention in mentions(in: tokens) {
            let before = tokens[max(0, mention.start - 7)..<mention.start]
            let after = tokens[mention.end...].prefix(2)
            let preposition = before.last.map { ["in", "into", "to", "use"].contains($0) } == true
            if before.contains(where: translationVerbs.contains), preposition {
                reading.allowed[mention.language] = .translationTarget
                continue
            }
            let verb = before.contains(where: responseVerbs.contains)
            let closes = after.allSatisfy { ["please", "only", "thanks"].contains($0) }
            let only = after.first == "only" || before.suffix(2).first == "only"
            let asks = preposition && (verb || closes && !yesNo) || only && !yesNo
            if asks && !wh {
                reading.request = mention.language
            } else if reading.request != mention.language {
                reading.allowed[mention.language] = .mentioned
            }
        }
        return reading
    }

    struct Mention {
        let language: Language
        let start: Int
        let end: Int
    }

    /// Every place a language's name appears, as token positions; "bahasa indonesia" spans two tokens.
    static func mentions(in tokens: [String]) -> [Mention] {
        var found: [Mention] = []
        for (code, entry) in Language.catalog {
            for name in entry.names {
                let parts = name.split(separator: " ").map(String.init)
                for start in tokens.indices where start + parts.count <= tokens.count {
                    let window = Array(tokens[start..<start + parts.count])
                    let matches = parts.count == 1 && entry.scripts != [.latin]
                        ? window[0].contains(parts[0]) : window == parts
                    if matches { found.append(Mention(language: Language(code: code), start: start,
                                                      end: start + parts.count)) }
                }
            }
        }
        return found.sorted { $0.start < $1.start }
    }
}
