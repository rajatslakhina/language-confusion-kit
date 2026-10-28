@testable import LanguageConfusionKit
import XCTest

final class ScriptTests: XCTestCase {
    func testScriptsOfLetters() {
        let samples: [(String, Script)] = [
            ("a", .latin), ("Z", .latin), ("é", .latin), ("ạ", .latin), ("λ", .greek), ("ж", .cyrillic),
            ("א", .hebrew), ("ب", .arabic), ("क", .devanagari), ("ก", .thai), ("한", .hangul), ("ᄀ", .hangul),
            ("ㄱ", .hangul), ("あ", .kana), ("カ", .kana), ("ー", .kana), ("漢", .han), ("㐀", .han), ("ἀ", .greek)
        ]
        for (text, script) in samples {
            XCTAssertEqual(text.unicodeScalars.first.flatMap(Script.of), script, text)
        }
    }

    func testNonLettersHaveNoScript() {
        for text in ["7", ".", "×", "÷", "→", "🙂", " ", "١", "、", "・"] {
            XCTAssertNil(text.unicodeScalars.last.flatMap(Script.of), text)
        }
        XCTAssertEqual(Script.of(first: "é"), .latin)
        XCTAssertNil(Script.of(first: "1"))
    }

    func testRunNamesAndWeights() {
        XCTAssertEqual(Script.han.runName, "Chinese characters")
        XCTAssertEqual(Script.kana.runName, "Japanese kana")
        XCTAssertEqual(Script.hangul.runName, "Korean letters")
        XCTAssertEqual(Script.cyrillic.runName, "Cyrillic letters")
        XCTAssertEqual(Script.han.weight, 3)
        XCTAssertEqual(Script.latin.weight, 1)
    }

    func testProfile() {
        let profile = ScriptProfile("abc 漢字 123!")
        XCTAssertEqual(profile.count(.latin), 3)
        XCTAssertEqual(profile.count(.han), 2)
        XCTAssertEqual(profile.count(.kana), 0)
        XCTAssertEqual(profile.weighted(.han), 6)
        XCTAssertEqual(profile.weightedLetters, 9)
        XCTAssertEqual(profile.dominant, .han)
        XCTAssertEqual(ScriptProfile("abc").dominant, .latin)
        XCTAssertEqual(ScriptProfile("ab αβ").dominant, .latin, "a tie goes to the script listed first")
        XCTAssertNil(ScriptProfile("123").dominant)
        XCTAssertEqual(ScriptProfile("x"), ScriptProfile("y"))
    }
}
