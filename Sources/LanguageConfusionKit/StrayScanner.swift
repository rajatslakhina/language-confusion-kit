import Foundation

/// Finds the words of a sentence that do not belong to it: common English words in an answer whose
/// language uses another script ("Это хороший question"), and runs of a script neither the expected
/// language nor an allowed one uses ("The fix is 这个 setting").
///
/// Names, acronyms, identifiers and anything the user wrote themselves are left alone. Only English is
/// looked for among Latin words, as the benchmark does: an English word is what slips into a non-Latin
/// answer, and a French word in a Japanese answer is more likely a name.
enum StrayScanner {
    static func strays(in text: String, _ expectation: LanguageExpectation, _ echo: Echo,
                       sentence: Int) -> [StrayWord] {
        guard !expectation.language.scripts.isEmpty else { return [] }
        let scripts = expectation.scripts
        var found: [StrayWord] = []
        if !scripts.contains(.latin) {
            for token in latinTokens(in: text) where isStray(token, echo) {
                found.append(StrayWord(text: token, kind: .english, sentence: sentence))
            }
        }
        for run in scriptRuns(in: text) where run.script != .latin && !scripts.contains(run.script) {
            guard !echo.normalized.contains(run.text.lowercased()) else { continue }
            found.append(StrayWord(text: run.text, kind: .script(run.script), sentence: sentence))
        }
        return found
    }

    private static func isStray(_ token: String, _ echo: Echo) -> Bool {
        let lowered = token.lowercased()
        let capitals = token.filter(\.isUppercase).count
        let acronym = capitals > 1
        let camel = token.dropFirst().contains(where: \.isUppercase)
        return !acronym && !camel && Lexicon.englishStrays.contains(lowered) && !echo.words.contains(lowered)
    }

    /// Latin words, with identifiers ("user_id", "v2", "file.txt", "a/b") dropped as code.
    static func latinTokens(in text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        func flush() {
            let token = current.trimmingCharacters(in: ["'", ".", "-", "’"])
            if !token.isEmpty, token.allSatisfy({ $0.isLetter && Script.of(first: $0) == .latin }) {
                tokens.append(token)
            }
            current = ""
        }
        for character in text {
            let latin = character.isLetter && Script.of(first: character) == .latin
            if latin || character.isNumber || "_./'-’".contains(character) {
                current.append(character)
            } else {
                flush()
            }
        }
        flush()
        return tokens
    }

    struct Run {
        let script: Script
        let text: String
    }

    /// Maximal runs of letters in one script.
    static func scriptRuns(in text: String) -> [Run] {
        var runs: [Run] = []
        var current: (script: Script, text: String)?
        for character in text {
            let script = Script.of(first: character)
            if let script, script == current?.script {
                current?.text.append(character)
                continue
            }
            if let open = current { runs.append(Run(script: open.script, text: open.text)) }
            current = script.map { ($0, String(character)) }
        }
        if let open = current { runs.append(Run(script: open.script, text: open.text)) }
        return runs
    }
}

extension Script {
    /// The script of a character's first scalar, so a base letter and its combining marks share one.
    static func of(first character: Character) -> Script? {
        character.unicodeScalars.first.flatMap(Script.of)
    }
}
