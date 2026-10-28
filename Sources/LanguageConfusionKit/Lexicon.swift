/// The word lists the lexical identifier and the stray-word check read.
///
/// Telling words are function words and greetings: short, frequent, and nearly free of names, so a
/// sentence of eight words in one of these languages almost always contains two or three of them.
/// A word several languages share ("de", "in", "a") counts for each of them by one over the number of
/// languages that share it, so it can tip a close call but never decide one.
enum Lexicon {
    static let englishTelling = """
        the and is are was were be been of to in that this it for on with as at by from you your we our they
        their he she his her not but or if so can will would should could have has had do does did what which
        who how why when where there here an all any some more most also very than then just about into only
        because these those its my me yes no thanks thank hello please however therefore
        """.words

    static let telling: [String: [String]] = [
        "en": englishTelling,
        "fr": """
        le la les des du de un une et est sont que qui dans pour pas ne sur avec ce cette ces il elle ils nous
        vous je au aux ou mais plus par se sa son ses leur être avoir fait comme très aussi bien merci bonjour
        oui non peut tout l d qu c j n
        """.words,
        "es": """
        el la los las de del y en es son que un una por para con no se lo al como más pero su sus este esta
        estos muy también porque cuando donde hay ser está están gracias hola sí usted yo tú nos le qué
        cómo cuál dónde cuándo puedo tengo
        """.words,
        "it": """
        il lo la gli le di del della dei che e è un una per con non sono si da in al alla come anche più ma
        questo questa molto perché quando dove grazie ciao sì io tu noi voi ci ha hanno nel nella
        """.words,
        "pt": """
        o a os as de do da dos das e é em no na nos nas um uma que para com não se por mais como mas seu sua
        este esta isso isto muito também porque quando onde obrigado obrigada olá sim você eu ao são está pelo pela
        """.words,
        "de": """
        der die das den dem des und ist sind ein eine einen einem nicht mit von zu auf für im in es ich du wir
        sie er auch als aber oder wenn wie dass sich noch nur bei aus nach werden wird kann sehr danke hallo ja
        nein bitte hat haben
        """.words,
        "nl": """
        de het een en is van in op te dat die niet met voor zijn er maar ook als aan bij om je ik we wij hij
        zij ze dit wat hoe dan nog naar uit kan worden wordt heeft hebben bedankt dank hallo ja nee graag geen
        """.words,
        "tr": """
        ve bir bu da de için ile ne çok daha gibi ama ben sen biz siz o olarak var yok mi mı değil şey her
        kadar sonra en teşekkürler merhaba evet hayır nasıl neden ki olan olduğu
        """.words,
        "id": """
        yang dan di ke dari ini itu untuk dengan tidak ada adalah akan dalam pada juga saya kami kita anda
        mereka bisa atau tetapi karena sudah belum sangat terima kasih halo ya apa bagaimana lebih oleh seperti
        """.words,
        "vi": """
        và là của có không một những các cho được trong với này đó người tôi bạn chúng để khi đã sẽ cũng rất
        như từ về thì nhưng hoặc cảm ơn xin chào
        """.words,
        "ru": """
        и в не на что с это как по но он она они мы вы я его её их к у же из за от для так все бы да нет
        был была было быть только или если уже когда очень спасибо здравствуйте после при о об чтобы где
        а нельзя кто этот эта эти можно нужно есть тоже также ещё потому
        """.words,
        "uk": """
        і й в у не на що з це як по але він вона вони ми ви я його її їх до від для так все та ні був була
        було бути тільки або якщо вже коли дуже дякую привіт після при чи де хто цей ця ці можна
        потрібно є також ще тому
        """.words
    ]

    /// Letters that only some of the languages use. Each occurrence counts like a shared word, capped
    /// at two per language, so a single accented name cannot carry a sentence.
    static let markers: [Character: [String]] = [
        "ñ": ["es"], "¿": ["es"], "¡": ["es"],
        "ã": ["pt"], "õ": ["pt"], "ç": ["fr", "pt", "tr"],
        "è": ["fr", "it"], "ê": ["fr", "pt"], "ë": ["fr", "nl"], "œ": ["fr"], "â": ["fr", "pt"],
        "î": ["fr"], "û": ["fr"], "ù": ["fr", "it"], "ò": ["it"], "ì": ["it"],
        "ß": ["de"], "ä": ["de"], "ö": ["de", "tr"], "ü": ["de", "tr"],
        "ğ": ["tr"], "ş": ["tr"], "ı": ["tr"],
        "ư": ["vi"], "ơ": ["vi"], "đ": ["vi"],
        "ы": ["ru"], "э": ["ru"], "ъ": ["ru"], "ё": ["ru"],
        "і": ["uk"], "ї": ["uk"], "є": ["uk"], "ґ": ["uk"]
    ]

    static let markerCap = 2.0

    /// Word → language code → weight.
    static let weights: [String: [String: Double]] = {
        var owners: [String: [String]] = [:]
        for (code, words) in telling {
            for word in Set(words) { owners[word, default: []].append(code) }
        }
        return owners.mapValues { codes in
            Dictionary(uniqueKeysWithValues: codes.map { ($0, 1 / Double(codes.count)) })
        }
    }()

    /// English words that do not belong in an answer written in a language with another script. Function
    /// and discourse words only: technical terms, brand names and loanwords are left alone on purpose,
    /// since an answer in Japanese about Swift may well say "Swift".
    static let englishStrays: Set<String> = Set(
        englishTelling.filter { $0.count > 1 } + """
        while since until after before example important note sure well now first finally answer question step
        following below above like let us need want know think see make way thing things good great best maybe
        again still even already almost both either neither whether though although unless instead otherwise
        rather quite enough other such each every many much must may might being
        """.words
    )
}

extension String {
    /// Whitespace-separated words of a word-list literal.
    var words: [String] { split(whereSeparator: \.isWhitespace).map(String.init) }
}
