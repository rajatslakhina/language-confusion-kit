@testable import LanguageConfusionKit
import XCTest

final class ReportTests: XCTestCase {
    let frenchQuestion = "Quelle est la différence entre une liste et un tuple en Python ?"

    func testNotesAndFeedback() {
        let mixed = check("Une liste est modifiable, alors qu'un tuple ne l'est pas. "
            + "In practice, you should use a tuple when the data must not change.", question: frenchQuestion)
        XCTAssertEqual(mixed.note, "1 of 2 sentences is in English, not French (you wrote in French): "
            + "“In practice, you should use a tuple when the data must not…”.")
        XCTAssertEqual(mixed.feedback, "Rewrite the whole answer in French, because the user wrote in French. "
            + "These sentences were not in French: “In practice, you should use a tuple when the data must not…”. "
            + "Keep code, names and quotations as they are.")
        let wrong = check("The capital of Australia is Canberra, not Sydney.",
                          question: "Answer in Spanish: what is the capital of Australia?")
        XCTAssertEqual(wrong.note, "This answer is in English, but you asked for an answer in Spanish.")
        let stray = check("リストは変更可能です。however、タプルは変更できません。because 両方とも型を含みます。however 終わり。",
                          question: "Pythonのリストとタプルの違いは何ですか？")
        XCTAssertEqual(stray.note, "This Japanese answer slips in English words (“however”, “because”).")
        XCTAssertEqual(stray.uniqueStrays, ["however", "because"])
        XCTAssertEqual(stray.feedback, "Rewrite the whole answer in Japanese, because the user wrote in Japanese. "
            + "Replace these words: “however”, “because”. Keep code, names and quotations as they are.")
        let matched = check("Une liste est modifiable, alors qu'un tuple ne l'est pas.", question: frenchQuestion)
        XCTAssertNil(matched.note)
        XCTAssertNil(matched.feedback)
        XCTAssertNil(check("Anything at all here.").note)
    }

    func testPluralNoteAndMixedStrays() {
        let two = check("""
        Une liste est modifiable, alors qu'un tuple ne l'est pas.
        Les deux peuvent contenir des éléments de types différents.
        In practice, you should use a tuple when the data must not change.
        This is the way most of the code I have seen does it.
        """, question: frenchQuestion)
        XCTAssertEqual(two.note?.hasPrefix("2 of 4 sentences are in English, not French"), true)
        let report = LanguageReport(
            reading: ExpectationReading(expectation: LanguageExpectation(language: .russian, source: .userMessage),
                                        userLanguage: .russian, standingChange: .unchanged),
            verdict: .strayWords, sentences: [],
            strays: ["however", "the", "but", "and"].map { StrayWord(text: $0, kind: .english, sentence: 0) }
                + [StrayWord(text: "这个", kind: .script(.han), sentence: 0),
                   StrayWord(text: "这个", kind: .script(.han), sentence: 0)])
        XCTAssertEqual(report.strayDescription,
                       "English words (“however”, “the”, “but”) and Chinese characters (“这个”)")
    }

    func testHelpers() {
        XCTAssertEqual(LanguageReport.list([]), "another language")
        XCTAssertEqual(LanguageReport.list([.english]), "English")
        XCTAssertEqual(LanguageReport.list([.english, .german]), "English and German")
        XCTAssertEqual(LanguageReport.list([.english, .german, .dutch]), "English, German and Dutch")
        XCTAssertEqual(LanguageReport.quote("short"), "“short”")
        XCTAssertEqual(LanguageReport.quote(String(repeating: "a", count: 58) + " bcd"),
                       "“" + String(repeating: "a", count: 58) + "…”")
    }

    func testWrongLanguagesAndSummary() {
        let sentences = [SentenceFinding.Status.wrong(.german), .wrong(.english), .wrong(.german), .wrong(.dutch)]
            .map { SentenceFinding(text: "x", line: 0, status: $0, weightedLetters: 1) }
        let report = LanguageReport(
            reading: ExpectationReading(expectation: LanguageExpectation(language: .french, source: .requested),
                                        userLanguage: nil, standingChange: .unchanged),
            verdict: .wrongLanguage, sentences: sentences, strays: [])
        XCTAssertEqual(report.wrongLanguages, [.german, .english, .dutch], "ties by code")
        XCTAssertEqual(report.summary, "wrongLanguage (expected French, requested; 4 judged, 4 wrong, 0 stray)")
        XCTAssertEqual(report.note, "This answer is in German, English and Dutch, but you asked for an answer in French.")
        XCTAssertEqual(check("Anything at all here.").summary,
                       "noExpectation (expected none; 0 judged, 0 wrong, 0 stray)")
    }
}
