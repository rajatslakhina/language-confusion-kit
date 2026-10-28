@testable import LanguageConfusionKit
import XCTest

final class CheckerTests: XCTestCase {
    let frenchQuestion = "Quelle est la différence entre une liste et un tuple en Python ?"

    func testVerdicts() {
        XCTAssertEqual(check("Anything at all here.").verdict, .noExpectation)
        XCTAssertEqual(check("Anything at all here.").sentences, [])
        XCTAssertEqual(check("```\ncode\n```\nOK.", question: frenchQuestion).verdict, .unjudged)
        XCTAssertEqual(check("Une liste est modifiable, alors qu'un tuple ne l'est pas.", question: frenchQuestion).verdict,
                       .matched)
        let mixed = check("Une liste est modifiable, alors qu'un tuple ne l'est pas. "
            + "In practice, you should use a tuple when the data must not change.", question: frenchQuestion)
        XCTAssertEqual(mixed.verdict, .mixedSentences)
        XCTAssertEqual(statuses(mixed), [.expected, .wrong(.english)])
        XCTAssertFalse(mixed.linePass)
        XCTAssertTrue(mixed.wordPass)
        let wrong = check("A list can change, but a tuple cannot change at all.", question: frenchQuestion)
        XCTAssertEqual(wrong.verdict, .wrongLanguage)
        XCTAssertEqual(wrong.wrongLanguages, [.english])
    }

    func testWrongNeedsMostOfTheText() {
        let shortWrong = check("""
        Une liste est modifiable mais le tuple pas
        Les deux contiennent des valeurs variées ici
        The tuple is the one to use here.
        """, question: frenchQuestion)
        XCTAssertEqual(statuses(shortWrong).filter { $0 == .wrong(.english) }.count, 1)
        let headings = check("""
        Liste et tuple
        Exemples rapides
        The tuple is the one you should use, and it is the one I would pick here.
        """, question: frenchQuestion)
        XCTAssertEqual(headings.verdict, .wrongLanguage, "the only judged sentence is most of the text")
        let mostlyFrench = check("""
        Liste modifiable, tuple figé, ensembles uniques, dictionnaires associatifs pratiques
        The tuple is the one to use.
        """, question: frenchQuestion)
        XCTAssertEqual(mostlyFrench.verdict, .mixedSentences, "a short wrong sentence beside unjudged French")
    }

    func testStrayWords() {
        let japanese = check("リストは変更可能ですが、タプルは変更できません。however、両方とも任意の型を含むことができます。",
                             question: "Pythonのリストとタプルの違いは何ですか？")
        XCTAssertEqual(japanese.verdict, .strayWords)
        XCTAssertEqual(japanese.strays, [StrayWord(text: "however", kind: .english, sentence: 1)])
        XCTAssertFalse(japanese.wordPass)
        let leak = check("The capital is Canberra. 这个 city was chosen as a compromise.",
                         question: "What is the capital of Australia?")
        XCTAssertEqual(leak.strays.map(\.kind), [.script(.han)])
        XCTAssertEqual(leak.verdict, .strayWords)
        let unjudgedOnly = check("OK, however.", question: "Pythonのリストとタプルの違いは何ですか？")
        XCTAssertEqual(unjudgedOnly.verdict, .strayWords, "stray words count when nothing could be judged")
    }

    func testStrayExclusions() {
        let question = "Swiftのactorとは何ですか？ the guide を読みました。"
        let answer = "actorはデータ競合を防ぎます。APIやURL、getValue、user_id、v2、file.txtを使います。the guideも参考に。"
        XCTAssertEqual(check(answer, question: question).strays, [], "names, acronyms, code and the user's own words")
        let allowed = check("日本語では「ありがとう」です。thank you と同じ意味です。",
                            question: "How do you say thank you in Japanese? 日本語で答えて。")
        XCTAssertEqual(allowed.expectation?.language, .japanese)
        XCTAssertEqual(allowed.strays, [], "the user wrote “thank you” themselves")
        let kanaInChinese = check("我们明天见面吧。カタカナ不应该出现在这里。", question: "我们什么时候见面？")
        XCTAssertEqual(kanaInChinese.strays.map(\.text), ["カタカナ"])
        let echoedScript = check("The word 这个 means this one, as you wrote.", question: "What does 这个 mean?")
        XCTAssertEqual(echoedScript.strays, [])
        let unknown = LanguageChecker(identifier: TableIdentifier(table: ["Habari yako leo rafiki?": Language(code: "sw")]))
        let swahili = unknown.check(answer: "这个 ok", question: "Habari yako leo rafiki?")
        XCTAssertEqual(swahili.strays, [], "no stray check for a language whose scripts are unknown")
    }

    func testExcusals() {
        let echo = check("Where is the station? In Spanish: ¿Dónde está la estación de tren?",
                         question: "Where is the station? Translate it into Spanish.")
        XCTAssertEqual(statuses(echo), [.excused("repeats your message"), .allowed(.spanish, .translationTarget)])
        let quoted = check("> The function returned the wrong value.\nLa función devolvió “the wrong value” otra vez, porque el índice no es correcto.",
                           question: "¿Por qué falla mi función de Python?")
        XCTAssertEqual(statuses(quoted), [.excused("a block quotation"), .expected, .excused("a quotation")])
        XCTAssertEqual(quoted.verdict, .matched)
    }

    func testStandingWithoutQuestion() {
        let report = check("Das Treffen wurde auf Donnerstag verschoben, und es ist schon geplant.", standing: .german)
        XCTAssertEqual(report.verdict, .matched)
        XCTAssertEqual(report.expectation?.source, .standing)
    }

    func testIdentifierWithoutReason() {
        let checker = LanguageChecker(identifier: TableIdentifier(table: ["Bonjour à tous.": .french], reason: nil))
        let report = checker.check(answer: "Something else entirely.", question: "Bonjour à tous.")
        XCTAssertEqual(statuses(report), [.unjudged("undetermined")])
    }

    func testSentenceFindingFlags() {
        let finding = { (status: SentenceFinding.Status) in
            SentenceFinding(text: "x", line: 0, status: status, weightedLetters: 1)
        }
        XCTAssertTrue(finding(.wrong(.english)).isWrong)
        XCTAssertFalse(finding(.expected).isWrong)
        XCTAssertEqual([.expected, .allowed(.english, .mentioned), .wrong(.english), .excused("q"), .unjudged("s")]
            .map { finding($0).isJudged }, [true, true, true, false, false])
    }
}
