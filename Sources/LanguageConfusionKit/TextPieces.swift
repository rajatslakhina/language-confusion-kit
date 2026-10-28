import Foundation

/// A sentence of an answer, or of a quotation in it, ready to be judged.
struct Piece: Sendable, Equatable {
    let text: String
    let line: Int
    /// Why it is not judged at all: a block quotation, a quoted phrase.
    let excuse: String?
}

/// Splits text into the sentences a language check judges, after taking out what no language check
/// should read: fenced and inline code, links, e-mail addresses, and markdown markup. Quotations are
/// kept as their own pieces, marked excused, because an answer that quotes an English error message
/// is not an answer that slipped into English.
enum TextPieces {
    static let quotePairs: [(open: Character, close: Character)] = [
        ("“", "”"), ("\"", "\""), ("«", "»"), ("„", "“"), ("「", "」"), ("『", "』")
    ]

    static let sentenceEnds: Set<Character> = [".", "!", "?", "。", "！", "？", ";"]

    static func pieces(of text: String) -> [Piece] {
        var result: [Piece] = []
        var inFence = false
        for (index, rawLine) in text.components(separatedBy: .newlines).enumerated() {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            if inFence { continue }
            let line = cleaned(trimmed)
            if trimmed.hasPrefix(">") {
                result += sentences(of: line).map { Piece(text: $0, line: index, excuse: "a block quotation") }
                continue
            }
            let (rest, quotes) = extractQuotes(from: line)
            result += sentences(of: rest).map { Piece(text: $0, line: index, excuse: nil) }
            result += quotes.map { Piece(text: $0, line: index, excuse: "a quotation") }
        }
        return result
    }

    /// The text without code, links, addresses or markup, quotations still in place.
    static func cleaned(_ text: String) -> String {
        var line = text
        line = line.replacing(#/`[^`]*`/#, with: " ")
        line = line.replacing(#/(https?://|www\.)\S+/#, with: " ")
        line = line.replacing(#/\S+@\S+\.\S+/#, with: " ")
        line = line.replacing(#/^\s*(>\s*)+/#, with: "")
        line = line.replacing(#/^\s*(#{1,6}|[-*+]|\d+[.)])\s+/#, with: "")
        line = line.replacing(#/[*_~|]+/#, with: " ")
        return line
    }

    /// Takes out quoted phrases, returning the rest and each quotation's text.
    static func extractQuotes(from text: String) -> (rest: String, quotes: [String]) {
        var rest = ""
        var quotes: [String] = []
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if let pair = quotePairs.first(where: { $0.open == character }),
               let close = text[text.index(after: index)...].firstIndex(of: pair.close) {
                let quote = text[text.index(after: index)..<close].trimmingCharacters(in: .whitespaces)
                if !quote.isEmpty { quotes.append(quote) }
                rest.append(" ")
                index = text.index(after: close)
                continue
            }
            rest.append(character)
            index = text.index(after: index)
        }
        return (rest, quotes)
    }

    /// Sentences, split after an end mark followed by a space or the end ("3.5" stays whole), with the
    /// gaps left by removed code and quotations closed up.
    static func sentences(of text: String) -> [String] {
        var result: [String] = []
        var current = ""
        let characters = Array(text)
        for (offset, character) in characters.enumerated() {
            current.append(character)
            let next = offset + 1 < characters.count ? characters[offset + 1] : " "
            let closesCJK = character == "。" || character == "！" || character == "？"
            if sentenceEnds.contains(character), closesCJK || next.isWhitespace {
                result.append(current)
                current = ""
            }
        }
        result.append(current)
        return result.map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .filter { $0.contains(where: \.isLetter) }
    }

    /// Lowercased letters and spaces only, for "does this sentence repeat the user's message".
    static func normalized(_ text: String) -> String {
        text.lowercased().letterWords.joined(separator: " ")
    }
}
