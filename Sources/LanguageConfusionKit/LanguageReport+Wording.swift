extension LanguageReport {
    /// A short note to show under the answer, or nil when there is nothing to say.
    public var note: String? {
        guard let expectation else { return nil }
        switch verdict {
        case .wrongLanguage:
            return "This answer is in \(Self.list(wrongLanguages)), but \(expectation.because)."
        case .mixedSentences:
            let count = wrong.count
            let verb = count == 1 ? "is" : "are"
            return "\(count) of \(judged) sentences \(verb) in \(Self.list(wrongLanguages)), not "
                + "\(expectation.language.name) (\(expectation.because)): \(Self.quote(wrong[0].text))."
        case .strayWords:
            return "This \(expectation.language.name) answer slips in \(strayDescription)."
        default:
            return nil
        }
    }

    /// A re-prompt for the model, or nil when the answer needs none.
    public var feedback: String? {
        guard let expectation, note != nil else { return nil }
        let name = expectation.language.name
        var parts = ["Rewrite the whole answer in \(name), because \(expectation.reasonForModel)."]
        if !wrong.isEmpty {
            let quoted = wrong.prefix(3).map { Self.quote($0.text) }.joined(separator: ", ")
            parts.append("These sentences were not in \(name): \(quoted).")
        }
        if !strays.isEmpty {
            parts.append("Replace these words: \(uniqueStrays.prefix(6).map(Self.quote).joined(separator: ", ")).")
        }
        parts.append("Keep code, names and quotations as they are.")
        return parts.joined(separator: " ")
    }

    /// Each stray word once, in the order found.
    public var uniqueStrays: [String] {
        var seen = Set<String>()
        return strays.map(\.text).filter { seen.insert($0.lowercased()).inserted }
    }

    var strayDescription: String {
        var groups: [(name: String, examples: [String])] = []
        for stray in strays {
            let name = switch stray.kind {
            case .english: "English words"
            case .script(let script): script.runName
            }
            if let index = groups.firstIndex(where: { $0.name == name }) {
                if !groups[index].examples.contains(stray.text), groups[index].examples.count < 3 {
                    groups[index].examples.append(stray.text)
                }
            } else {
                groups.append((name, [stray.text]))
            }
        }
        return groups.map { "\($0.name) (\($0.examples.map(Self.quote).joined(separator: ", ")))" }
            .joined(separator: " and ")
    }

    static func quote(_ text: String) -> String {
        let clipped = text.count > 60 ? text.prefix(59).trimmingSuffix + "…" : text
        return "“\(clipped)”"
    }

    static func list(_ languages: [Language]) -> String {
        let names = languages.map(\.name)
        guard let last = names.last else { return "another language" }
        guard names.count > 1 else { return last }
        return names.dropLast().joined(separator: ", ") + " and " + last
    }
}

private extension Substring {
    var trimmingSuffix: String {
        var text = String(self)
        while text.last?.isWhitespace == true { text.removeLast() }
        return text
    }
}
