/// A language, named by its ISO 639-1 code. Region and script subtags are dropped, so `zh-Hans`,
/// `pt-BR` and `EN` are `zh`, `pt` and `en`: the question here is which language an answer is in,
/// not which spelling standard it follows.
public struct Language: Sendable, Hashable, CustomStringConvertible {
    public let code: String

    public init(code: String) {
        let base = code.lowercased().split { $0 == "-" || $0 == "_" }.first
        self.code = base.map(String.init) ?? ""
    }

    /// The English name, or the code for a language outside the catalog.
    public var name: String { Self.catalog[code]?.name ?? code }

    /// The scripts the language is written in; empty for a language outside the catalog.
    public var scripts: [Script] { Self.catalog[code]?.scripts ?? [] }

    public var description: String { name }

    public static let english = Language(code: "en")
    public static let french = Language(code: "fr")
    public static let german = Language(code: "de")
    public static let spanish = Language(code: "es")
    public static let italian = Language(code: "it")
    public static let portuguese = Language(code: "pt")
    public static let dutch = Language(code: "nl")
    public static let turkish = Language(code: "tr")
    public static let indonesian = Language(code: "id")
    public static let vietnamese = Language(code: "vi")
    public static let russian = Language(code: "ru")
    public static let ukrainian = Language(code: "uk")
    public static let greek = Language(code: "el")
    public static let hebrew = Language(code: "he")
    public static let arabic = Language(code: "ar")
    public static let hindi = Language(code: "hi")
    public static let thai = Language(code: "th")
    public static let chinese = Language(code: "zh")
    public static let japanese = Language(code: "ja")
    public static let korean = Language(code: "ko")

    /// Every language this package can name, identify and read requests for.
    public static var known: [Language] { catalog.keys.sorted().map { Language(code: $0) } }

    struct Entry {
        let name: String
        let scripts: [Script]
        /// Lowercased ways a message names the language: the English name, the endonym, common spellings.
        let names: [String]
    }

    static let catalog: [String: Entry] = [
        "en": Entry(name: "English", scripts: [.latin], names: ["english"]),
        "fr": Entry(name: "French", scripts: [.latin], names: ["french", "français", "francais"]),
        "de": Entry(name: "German", scripts: [.latin], names: ["german", "deutsch"]),
        "es": Entry(name: "Spanish", scripts: [.latin], names: ["spanish", "español", "espanol", "castellano"]),
        "it": Entry(name: "Italian", scripts: [.latin], names: ["italian", "italiano"]),
        "pt": Entry(name: "Portuguese", scripts: [.latin], names: ["portuguese", "português", "portugues"]),
        "nl": Entry(name: "Dutch", scripts: [.latin], names: ["dutch", "nederlands"]),
        "tr": Entry(name: "Turkish", scripts: [.latin], names: ["turkish", "türkçe", "turkce"]),
        "id": Entry(name: "Indonesian", scripts: [.latin], names: ["indonesian", "bahasa indonesia"]),
        "vi": Entry(name: "Vietnamese", scripts: [.latin], names: ["vietnamese", "tiếng việt"]),
        "ru": Entry(name: "Russian", scripts: [.cyrillic], names: ["russian", "русский", "русском", "по-русски"]),
        "uk": Entry(name: "Ukrainian", scripts: [.cyrillic], names: ["ukrainian", "українська", "українською"]),
        "el": Entry(name: "Greek", scripts: [.greek], names: ["greek", "ελληνικά"]),
        "he": Entry(name: "Hebrew", scripts: [.hebrew], names: ["hebrew", "עברית"]),
        "ar": Entry(name: "Arabic", scripts: [.arabic], names: ["arabic", "العربية"]),
        "hi": Entry(name: "Hindi", scripts: [.devanagari], names: ["hindi", "हिन्दी", "हिंदी"]),
        "th": Entry(name: "Thai", scripts: [.thai], names: ["thai", "ภาษาไทย"]),
        "zh": Entry(name: "Chinese", scripts: [.han], names: ["chinese", "mandarin", "中文", "汉语", "漢語", "普通话"]),
        "ja": Entry(name: "Japanese", scripts: [.han, .kana], names: ["japanese", "日本語"]),
        "ko": Entry(name: "Korean", scripts: [.hangul, .han], names: ["korean", "한국어"])
    ]
}
