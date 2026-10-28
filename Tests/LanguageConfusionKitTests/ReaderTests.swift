@testable import LanguageConfusionKit
import XCTest

final class ReaderTests: XCTestCase {
    func testRequests() {
        let requests: [(String, Language)] = [
            ("Answer in Spanish: what is the capital of Australia?", .spanish),
            ("Tell me about the Eiffel Tower in French.", .french),
            ("Describe the Eiffel Tower in French.", .french),
            ("In French, please.", .french),
            ("Please reply only in German.", .german),
            ("Russian only.", .russian),
            ("Switch to Italian.", .italian),
            ("Can you answer in Portuguese?", .portuguese),
            ("Erkläre das bitte auf Deutsch.", .german),
            ("日本語で答えてください。", .japanese),
            ("Explain it in Bahasa Indonesia please.", .indonesian),
            ("Please use Dutch.", .dutch)
        ]
        for (message, language) in requests {
            let expectation = expect(message)
            XCTAssertEqual(expectation?.language, language, message)
            XCTAssertEqual(expectation?.source, .requested, message)
        }
    }

    func testMentionsAreNotRequests() {
        let thanks = expect("How do you say thank you in Japanese?")
        XCTAssertEqual(thanks?.language, .english)
        XCTAssertEqual(thanks?.source, .userMessage)
        XCTAssertEqual(thanks?.allowed, [.japanese: .translationTarget])
        XCTAssertEqual(expect("What is cat in French? And what is dog in French?")?.allowed, [.french: .mentioned])
        let cat = expect("What is the word for cat in French?")
        XCTAssertEqual(cat?.allowed, [.french: .mentioned])
        XCTAssertEqual(expect("Do you speak French at all, by the way?")?.allowed, [.french: .mentioned])
        XCTAssertEqual(expect("Does this phrase exist in German, or only in Dutch?")?.language, .english)
        let chinese = expect("中文和日语有什么区别？")
        XCTAssertEqual(chinese?.language, .chinese)
        XCTAssertEqual(chinese?.allowed, [:], "the message's own language is not a second one")
    }

    func testTranslation() {
        let reading = LanguageChecker().read(question: "Translate \"Where is the station?\" into German.")
        XCTAssertEqual(reading.userLanguage, .english, "read with the quotation when the rest is too short")
        XCTAssertEqual(reading.expectation?.allowed, [.german: .translationTarget])
        XCTAssertEqual(reading.standingChange, .unchanged)
    }

    func testStandingRequests() {
        let set = LanguageChecker().read(question: "From now on, reply in German.")
        XCTAssertEqual(set.standingChange, .set(.german))
        XCTAssertEqual(set.expectation?.source, .requested)
        let carried = expect("Thanks! What about the second one?", standing: .german)
        XCTAssertEqual(carried?.language, .german)
        XCTAssertEqual(carried?.source, .standing)
        let overridden = expect("Answer this one in French.", standing: .german)
        XCTAssertEqual(overridden?.language, .french)
        let lifted = LanguageChecker().read(question: "You can answer in any language you like.", standing: .german)
        XCTAssertEqual(lifted.standingChange, .cleared)
        XCTAssertEqual(lifted.expectation?.language, .english)
        XCTAssertEqual(lifted.expectation?.source, .userMessage)
    }

    func testFallbacks() {
        XCTAssertEqual(expect(nil, standing: .german)?.source, .standing)
        XCTAssertEqual(expect(nil, conversation: .french)?.source, .conversation)
        XCTAssertNil(expect(nil))
        XCTAssertEqual(expect("ok", conversation: .french)?.language, .french)
        XCTAssertEqual(expect("ok", standing: .german, conversation: .french)?.language, .german)
        XCTAssertNil(expect("ok"))
        XCTAssertNil(LanguageChecker().read(question: "ok").userLanguage)
    }

    func testApply() {
        XCTAssertEqual(ExpectationReader.apply(.unchanged, to: .french), .french)
        XCTAssertEqual(ExpectationReader.apply(.set(.german), to: .french), .german)
        XCTAssertNil(ExpectationReader.apply(.cleared, to: .french))
    }

    func testExpectationWording() {
        let requested = LanguageExpectation(language: .french, source: .requested, allowed: [.french: .mentioned])
        XCTAssertEqual(requested.allowed, [:], "the expected language is never also an allowed one")
        XCTAssertEqual(requested.because, "you asked for an answer in French")
        XCTAssertEqual(requested.reasonForModel, "the user asked for an answer in French")
        XCTAssertEqual(requested.instruction, "Answer in French. Keep code, names and quotations as they are.")
        let wordings: [(LanguageExpectation.Source, String, String)] = [
            (.standing, "you asked earlier for answers in French", "the user asked earlier for answers in French"),
            (.userMessage, "you wrote in French", "the user wrote in French"),
            (.conversation, "this conversation is in French", "the conversation is in French")
        ]
        for (source, because, model) in wordings {
            let expectation = LanguageExpectation(language: .french, source: source)
            XCTAssertEqual(expectation.because, because)
            XCTAssertEqual(expectation.reasonForModel, model)
        }
        let japanese = LanguageExpectation(language: .japanese, source: .userMessage, allowed: [.english: .mentioned])
        XCTAssertEqual(japanese.scripts, [.han, .kana, .latin])
        XCTAssertTrue(japanese.accepts(.english))
        XCTAssertFalse(japanese.accepts(.korean))
    }

    func testMentionPositions() {
        let mentions = ExpectationReader.mentions(in: ["in", "bahasa", "indonesia", "or", "english"])
        XCTAssertEqual(mentions.map(\.language), [.indonesian, .english])
        XCTAssertEqual(mentions.map(\.start), [1, 4])
        XCTAssertEqual(mentions.map(\.end), [3, 5])
    }
}
