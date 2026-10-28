@testable import LanguageConfusionKit
import XCTest

final class SessionTests: XCTestCase {
    func testStandingAndConversationCarry() async {
        let session = LanguageSession()
        let first = await session.review(answer: "Klar, ab jetzt antworte ich auf Deutsch.",
                                         question: "From now on, reply in German.")
        XCTAssertEqual(first.verdict, .matched)
        let standing = await session.standing
        XCTAssertEqual(standing, .german)
        let hint = await session.expectation(for: "Thanks! What about the second one?")
        XCTAssertEqual(hint?.source, .standing)
        let second = await session.review(answer: "The second one is the blue box on the left side.",
                                          question: "Thanks! What about the second one?")
        XCTAssertEqual(second.verdict, .wrongLanguage)
        XCTAssertEqual(second.note, "This answer is in English, but you asked earlier for answers in German.")
        await session.review(answer: "Sure, any language is fine with me.", question: "You can answer in any language you like.")
        let cleared = await session.standing
        XCTAssertNil(cleared)
        let conversation = await session.conversation
        XCTAssertEqual(conversation, .english)
        let short = await session.review(answer: "C'est la boîte bleue qui est sur la gauche.", question: "ok")
        XCTAssertEqual(short.expectation?.source, .conversation)
        XCTAssertEqual(short.verdict, .wrongLanguage)
        let totals = await session.totals
        XCTAssertEqual(totals.turns, 4)
        XCTAssertEqual(totals.count(.matched), 2)
        XCTAssertEqual(totals.count(.wrongLanguage), 2)
        XCTAssertEqual(totals.count(.strayWords), 0)
        XCTAssertEqual(totals.wrongSentences, 2)
        XCTAssertEqual(totals.judgedSentences, 4)
        XCTAssertEqual(totals.strayWords, 0)
        let last = await session.lastReport
        XCTAssertEqual(last, short)
        XCTAssertEqual(session.checker.identifier is LexicalIdentifier, true)
    }
}
