import LanguageConfusionKit

let checker = LanguageChecker()

func heading(_ number: Int, _ title: String) {
    print("")
    print("── \(number). \(title)")
}

func describe(_ status: SentenceFinding.Status, expected: Language?) -> String {
    switch status {
    case .expected: "ok, \(expected?.name ?? "")"
    case .allowed(let language, let allowance):
        "allowed, \(language.name) (\(allowance == .mentioned ? "mentioned" : "translation"))"
    case .wrong(let language): "WRONG, \(language.name)"
    case .excused(let reason): "excused, \(reason)"
    case .unjudged(let reason): "unjudged, \(reason)"
    }
}

func show(_ report: LanguageReport, question: String?, answer: String) {
    if let question { print("   Q: \(question)") }
    for (index, line) in answer.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
        print("   \(index == 0 ? "A:" : "  ") \(line)")
    }
    if let expectation = report.expectation {
        let allowed = expectation.allowed.keys.map(\.name).sorted()
        let extra = allowed.isEmpty ? "" : "; also allowed: \(allowed.joined(separator: ", "))"
        print("   expected \(expectation.language.name) because \(expectation.because)\(extra)")
    }
    for sentence in report.sentences {
        let status = describe(sentence.status, expected: report.expectation?.language)
        print("   \(status.padding(toLength: 36, withPad: " ", startingAt: 0))\(sentence.text)")
    }
    for stray in report.strays {
        let kind = switch stray.kind {
        case .english: "English word"
        case .script(let script): script.runName
        }
        print("   \("stray, \(kind)".padding(toLength: 36, withPad: " ", startingAt: 0))\(stray.text)")
    }
    let passes = "line-level \(report.linePass ? "pass" : "FAIL"), word-level \(report.wordPass ? "pass" : "FAIL")"
    print("   verdict: \(report.verdict.rawValue) (\(passes))")
    if let note = report.note { print("   note: \(note)") }
}

@discardableResult
func run(_ answer: String, question: String?, standing: Language? = nil) -> LanguageReport {
    let report = checker.check(answer: answer, question: question, standing: standing)
    show(report, question: question, answer: answer)
    return report
}
