/// Running totals across a conversation.
public struct LanguageTotals: Sendable, Hashable {
    public internal(set) var turns = 0
    public internal(set) var judgedSentences = 0
    public internal(set) var wrongSentences = 0
    public internal(set) var strayWords = 0
    public internal(set) var verdicts: [LanguageReport.Verdict: Int] = [:]

    public func count(_ verdict: LanguageReport.Verdict) -> Int { verdicts[verdict] ?? 0 }

    mutating func add(_ report: LanguageReport) {
        turns += 1
        judgedSentences += report.judged
        wrongSentences += report.wrong.count
        strayWords += report.strays.count
        verdicts[report.verdict, default: 0] += 1
    }
}

/// Checks a conversation's answers one turn at a time and remembers what earlier turns settled: a
/// standing "from now on, reply in German", and the language the user writes in, so the answer to
/// "ok, and the second one?" is still expected in French three turns into a French conversation.
///
/// An actor because the standing request one turn sets must be the one the next turn reads, whichever
/// task reviews it.
public actor LanguageSession {
    public nonisolated let checker: LanguageChecker
    public private(set) var standing: Language?
    /// The language of the last user message that could be identified.
    public private(set) var conversation: Language?
    public private(set) var totals = LanguageTotals()
    public private(set) var lastReport: LanguageReport?

    public init(checker: LanguageChecker = LanguageChecker()) {
        self.checker = checker
    }

    /// The language the answer to `question` should be in, without recording a turn: for a line in the
    /// system message before the model answers.
    public func expectation(for question: String?) -> LanguageExpectation? {
        checker.read(question: question, standing: standing, conversation: conversation).expectation
    }

    @discardableResult
    public func review(answer: String, question: String?) -> LanguageReport {
        let report = checker.check(answer: answer, question: question, standing: standing,
                                   conversation: conversation)
        standing = ExpectationReader.apply(report.reading.standingChange, to: standing)
        conversation = report.reading.userLanguage ?? conversation
        totals.add(report)
        lastReport = report
        return report
    }
}
