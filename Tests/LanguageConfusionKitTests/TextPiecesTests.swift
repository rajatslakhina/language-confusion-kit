@testable import LanguageConfusionKit
import XCTest

final class TextPiecesTests: XCTestCase {
    func testCodeLinksAndMarkupAreRemoved() {
        let text = """
        # Title here
        Use `let x = 1` and see https://example.com/a?b=c or www.example.org now.
        ```swift
        // This English comment is code.
        ```
        ~~~
        print("hi")
        ~~~
        - Write to me@example.com today.
        1. **Bold** words | and _cells_
        """
        let pieces = TextPieces.pieces(of: text)
        XCTAssertEqual(pieces.map(\.text), ["Title here", "Use and see or now.", "Write to today.",
                                            "Bold words and cells"])
        XCTAssertEqual(pieces.map(\.line), [0, 1, 8, 9])
        XCTAssertTrue(pieces.allSatisfy { $0.excuse == nil })
    }

    func testQuotationsAreExcusedPieces() {
        let pieces = TextPieces.pieces(of: "> Quoted line here.\nShe said “bonjour à tous” and «salut» then \"hi\".")
        XCTAssertEqual(pieces.map(\.text), ["Quoted line here.", "She said and then .", "bonjour à tous", "salut", "hi"])
        XCTAssertEqual(pieces.map(\.excuse), ["a block quotation", nil, "a quotation", "a quotation", "a quotation"])
        let german = TextPieces.extractQuotes(from: "Er fragte „Wo ist der Bahnhof?“ laut.")
        XCTAssertEqual(german.quotes, ["Wo ist der Bahnhof?"])
        let japanese = TextPieces.extractQuotes(from: "彼は「こんにちは」と『さようなら』と言った")
        XCTAssertEqual(japanese.quotes, ["こんにちは", "さようなら"])
        let unclosed = TextPieces.extractQuotes(from: "An “open quote")
        XCTAssertEqual(unclosed.quotes, [])
        XCTAssertEqual(unclosed.rest, "An “open quote")
        let empty = TextPieces.extractQuotes(from: "Empty “” here")
        XCTAssertEqual(empty.quotes, [])
        XCTAssertEqual(empty.rest, "Empty   here")
    }

    func testSentences() {
        XCTAssertEqual(TextPieces.sentences(of: "It costs 3.5 euros. Really? Yes! Fine; ok"),
                       ["It costs 3.5 euros.", "Really?", "Yes!", "Fine;", "ok"])
        XCTAssertEqual(TextPieces.sentences(of: "これはペンです。あれは本です！"), ["これはペンです。", "あれは本です！"])
        XCTAssertEqual(TextPieces.sentences(of: "... 42 !"), [])
    }

    func testNormalized() {
        XCTAssertEqual(TextPieces.normalized("  Where IS the station?! "), "where is the station")
    }
}
