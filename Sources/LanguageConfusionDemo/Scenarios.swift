import LanguageConfusionKit

func threeShapes() {
    heading(1, "The three shapes of language confusion: whole answer, some lines, some words")
    let french = "Quelle est la différence entre une liste et un tuple en Python ?"
    run("A list can change after you create it, but a tuple cannot change at all.", question: french)
    run(
        "Une liste est modifiable, alors qu'un tuple ne l'est pas. "
            + "In practice, you should use a tuple when the data must not change. "
            + "Les deux peuvent contenir des éléments de types différents.",
        question: french
    )
    run(
        "Список можно изменить, а кортеж нельзя. Это хороший вопрос, however всё зависит от задачи.",
        question: "В чём разница между списком и кортежем в Python?"
    )
    run(
        "リストは変更可能ですが、タプルは変更できません。because タプルはハッシュ可能なので、辞書のキーに使えます。",
        question: "Pythonのリストとタプルの違いは何ですか？"
    )
}

func requestsAndMentions() {
    heading(2, "A request sets the language; a mention only allows one")
    run("The capital of Australia is Canberra, not Sydney.",
        question: "Answer in Spanish: what is the capital of Australia?")
    run("La capital de Australia es Canberra, no Sídney.",
        question: "Answer in Spanish: what is the capital of Australia?")
    run("In Japanese you say ありがとう. For more politeness, say どうもありがとうございます.",
        question: "How do you say thank you in Japanese?")
    run("Wo ist der Bahnhof? That is the most common way to ask for the station.",
        question: "Translate \"Where is the station?\" into German.")
}

func neverFindings() {
    heading(3, "What is never a finding: code, quotations, names, the user's own words, fragments")
    run(
        """
        La función falla porque el índice empieza en cero y no en uno.
        > IndexError: list index out of range
        ```python
        # The last valid index is len(items) - 1
        print(items[len(items) - 1])
        ```
        El mensaje dice “list index out of range”, es decir, el índice no existe.
        Guido van Rossum, PEP 8
        """,
        question: "¿Por qué mi código de Python da este error: IndexError: list index out of range?"
    )
}

func strayScripts() {
    heading(4, "Letters from a script the answer's language does not use")
    run("The capital is Canberra. 这个 city was chosen as a compromise between Sydney and Melbourne.",
        question: "What is the capital of Australia?")
    run("我们明天下午三点见面吧。到时候在会议室カタカナ见。", question: "我们明天什么时候见面？")
}

func acrossTurns() async {
    heading(5, "Across turns: a standing request, a short follow-up, and lifting it")
    let session = LanguageSession()
    let turns: [(question: String, answer: String)] = [
        ("From now on, reply in German. What is a tuple?",
         "Ein Tupel ist eine Folge von Werten, die nach dem Anlegen nicht mehr geändert werden kann."),
        ("ok, and a list?",
         "A list is like a tuple, but you can add, remove and change its items at any time."),
        ("Danke! Und ein Dictionary?",
         "Ein Dictionary ordnet jedem Schlüssel einen Wert zu, und die Schlüssel sind eindeutig."),
        ("You can answer in any language you like. What is a set?",
         "A set holds unique values in no particular order, so it is fast to test membership.")
    ]
    for turn in turns {
        let report = await session.review(answer: turn.answer, question: turn.question)
        show(report, question: turn.question, answer: turn.answer)
        let standing = await session.standing
        print("   standing request after this turn: \(standing?.name ?? "none")")
    }
    let totals = await session.totals
    print("   session: \(totals.turns) turns, \(totals.judgedSentences) sentences judged, "
        + "\(totals.wrongSentences) wrong, \(totals.strayWords) stray words")
}

func noteAndFeedback() {
    heading(6, "The note for the user, the re-prompt for the model, and the rewrite")
    let question = "Quelle est la différence entre une liste et un tuple en Python ?"
    let first = checker.check(
        answer: "Une liste est modifiable, alors qu'un tuple ne l'est pas. "
            + "In practice, you should use a tuple when the data must not change.",
        question: question
    )
    print("   note:     \(first.note ?? "-")")
    print("   feedback: \(first.feedback ?? "-")")
    print("   system-message line before the next call: \(first.expectation?.instruction ?? "-")")
    run(
        "Une liste est modifiable, alors qu'un tuple ne l'est pas. "
            + "En pratique, utilisez un tuple quand les données ne doivent pas changer.",
        question: question
    )
}

func identifiers() {
    heading(7, "Identifiers: a lexical one, Apple's NaturalLanguage, and the two required to agree")
    let samples = [
        "Le chat dort sur le canapé pendant que nous travaillons.",
        "Das ist die Idee and the plan.",
        "John Smith, CEO of Acme Corp",
        "Rapat ini akan dipindahkan ke hari Kamis untuk semua tim.",
        "カタカナ不应该出现在这里"
    ]
    let lexical = LexicalIdentifier()
    #if canImport(NaturalLanguage)
    let natural = NaturalLanguageIdentifier()
    let agreeing = AgreeingIdentifier(natural, lexical)
    let named: [(String, any LanguageIdentifying)] = [("lexical", lexical), ("natural", natural), ("agree", agreeing)]
    #else
    let named: [(String, any LanguageIdentifying)] = [("lexical", lexical)]
    #endif
    for sample in samples {
        print("   \(sample)")
        for (name, identifier) in named {
            let guess = identifier.identify(sample)
            let reading = guess.language?.name ?? "declines (\(guess.reason ?? "-"))"
            print("     \(name.padding(toLength: 8, withPad: " ", startingAt: 0))\(reading)")
        }
    }
}
