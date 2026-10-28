@testable import LanguageConfusionKit

/// An identifier that answers from a table, for tests that are about the checker, not identification.
struct TableIdentifier: LanguageIdentifying {
    let table: [String: Language]
    var reason: String? = "not in the table"

    func identify(_ text: String) -> LanguageGuess {
        guard let language = table[text] else {
            return LanguageGuess(language: nil, confidence: 0, weightedLetters: text.count, reason: reason)
        }
        return LanguageGuess(language: language, confidence: 1, weightedLetters: text.count)
    }
}

func identify(_ text: String) -> Language? {
    LexicalIdentifier().identify(text).language
}

func check(_ answer: String, question: String? = nil, standing: Language? = nil,
           conversation: Language? = nil) -> LanguageReport {
    LanguageChecker().check(answer: answer, question: question, standing: standing, conversation: conversation)
}

func expect(_ question: String?, standing: Language? = nil, conversation: Language? = nil) -> LanguageExpectation? {
    LanguageChecker().read(question: question, standing: standing, conversation: conversation).expectation
}

func statuses(_ report: LanguageReport) -> [SentenceFinding.Status] {
    report.sentences.map(\.status)
}
