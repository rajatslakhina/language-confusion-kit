@testable import LanguageConfusionKit
import XCTest

final class LanguageTests: XCTestCase {
    func testCodesDropSubtags() {
        XCTAssertEqual(Language(code: "zh-Hans"), .chinese)
        XCTAssertEqual(Language(code: "pt_BR"), .portuguese)
        XCTAssertEqual(Language(code: "EN"), .english)
        XCTAssertEqual(Language(code: "").code, "")
    }

    func testCatalog() {
        XCTAssertEqual(Language.known.count, 20)
        XCTAssertEqual(Language.known.first, .arabic)
        XCTAssertEqual(Language.japanese.name, "Japanese")
        XCTAssertEqual(Language.japanese.scripts, [.han, .kana])
        XCTAssertEqual(Language.korean.description, "Korean")
        let swahili = Language(code: "sw")
        XCTAssertEqual(swahili.name, "sw")
        XCTAssertEqual(swahili.scripts, [])
        let all: [Language] = [
            .english, .french, .german, .spanish, .italian, .portuguese, .dutch, .turkish, .indonesian, .vietnamese,
            .russian, .ukrainian, .greek, .hebrew, .arabic, .hindi, .thai, .chinese, .japanese, .korean
        ]
        XCTAssertEqual(Set(all), Set(Language.known))
    }

    func testLexiconWeights() {
        XCTAssertEqual(Lexicon.weights["the"], ["en": 1])
        XCTAssertEqual(Lexicon.weights["de"]?.count, 5)
        XCTAssertEqual(Lexicon.weights["de"]?["fr"], 0.2)
        XCTAssertTrue(Lexicon.englishStrays.contains("however"))
        XCTAssertFalse(Lexicon.englishStrays.contains("a"))
        XCTAssertEqual("a  b\nc".words, ["a", "b", "c"])
        XCTAssertEqual("l'homme C++".letterWords, ["l", "homme", "C"])
    }
}
