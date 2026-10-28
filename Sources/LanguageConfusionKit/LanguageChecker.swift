/// Checks that an answer is in the language its question calls for, sentence by sentence and word by
/// word: the line-level and word-level "language confusion" of Marchisio et al., *Understanding and
/// Mitigating Language Confusion in LLMs* (EMNLP 2024).
///
/// A sentence is judged only when the identifier commits to a language, so code, names, headings and
/// short fragments are never findings. Quotations are never findings either, nor a sentence that
/// repeats the user's own message, nor a sentence in a language the message names.
public struct LanguageChecker: Sendable {
    public let identifier: any LanguageIdentifying

    public init(identifier: any LanguageIdentifying = LexicalIdentifier()) {
        self.identifier = identifier
    }

    /// What `question` says about the language of its answer, given what earlier turns established.
    public func read(question: String?, standing: Language? = nil, conversation: Language? = nil)
        -> ExpectationReading {
        ExpectationReader(identifier: identifier).read(question, standing: standing, conversation: conversation)
    }

    public func check(answer: String, question: String? = nil, standing: Language? = nil,
                      conversation: Language? = nil) -> LanguageReport {
        let reading = read(question: question, standing: standing, conversation: conversation)
        guard let expectation = reading.expectation else {
            return LanguageReport(reading: reading, verdict: .noExpectation, sentences: [], strays: [])
        }
        let echo = Echo(question ?? "")
        var sentences: [SentenceFinding] = []
        var strays: [StrayWord] = []
        for piece in TextPieces.pieces(of: answer) {
            let finding = judge(piece, expectation, echo)
            switch finding.status {
            case .expected, .unjudged:
                strays += StrayScanner.strays(in: piece.text, expectation, echo, sentence: sentences.count)
            default:
                break
            }
            sentences.append(finding)
        }
        let verdict = Self.verdict(sentences, strays)
        return LanguageReport(reading: reading, verdict: verdict, sentences: sentences, strays: strays)
    }

    private func judge(_ piece: Piece, _ expectation: LanguageExpectation, _ echo: Echo) -> SentenceFinding {
        let letters = ScriptProfile(piece.text).weightedLetters
        func finding(_ status: SentenceFinding.Status) -> SentenceFinding {
            SentenceFinding(text: piece.text, line: piece.line, status: status, weightedLetters: letters)
        }
        if let excuse = piece.excuse { return finding(.excused(excuse)) }
        if echo.repeats(piece.text) { return finding(.excused("repeats your message")) }
        let guess = identifier.identify(piece.text)
        guard let language = guess.language else { return finding(.unjudged(guess.reason ?? "undetermined")) }
        if language == expectation.language { return finding(.expected) }
        if let allowance = expectation.allowed[language] { return finding(.allowed(language, allowance)) }
        return finding(.wrong(language))
    }

    static func verdict(_ sentences: [SentenceFinding], _ strays: [StrayWord]) -> LanguageReport.Verdict {
        let judged = sentences.filter(\.isJudged)
        let wrong = judged.filter(\.isWrong)
        if judged.isEmpty { return strays.isEmpty ? .unjudged : .strayWords }
        let read = sentences.filter { if case .excused = $0.status { false } else { true } }
        let wrongLetters = wrong.reduce(0) { $0 + $1.weightedLetters }
        let allLetters = read.reduce(0) { $0 + $1.weightedLetters }
        if wrong.count == judged.count, wrongLetters * 2 > allLetters { return .wrongLanguage }
        if !wrong.isEmpty { return .mixedSentences }
        return strays.isEmpty ? .matched : .strayWords
    }
}

/// The user's message, for "the answer repeats it" checks.
struct Echo: Sendable {
    let normalized: String
    let words: Set<String>

    init(_ question: String) {
        normalized = TextPieces.normalized(question)
        words = Set(normalized.split(separator: " ").map(String.init))
    }

    /// A sentence of twelve or more letters found word for word in the message.
    func repeats(_ sentence: String) -> Bool {
        let own = TextPieces.normalized(sentence)
        return ScriptProfile(own).weightedLetters >= 12 && normalized.contains(own)
    }
}
