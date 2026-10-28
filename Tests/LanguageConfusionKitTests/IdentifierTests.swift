@testable import LanguageConfusionKit
import XCTest

final class IdentifierTests: XCTestCase {
    func testTwentyLanguages() {
        let samples: [(String, Language)] = [
            ("The meeting has been moved to Thursday afternoon.", .english),
            ("Le chat dort sur le canapé pendant que nous travaillons.", .french),
            ("Das Treffen wurde auf Donnerstagnachmittag verschoben.", .german),
            ("La reunión se trasladó al jueves por la tarde.", .spanish),
            ("La riunione è stata spostata a giovedì pomeriggio.", .italian),
            ("A reunião foi transferida para quinta-feira à tarde.", .portuguese),
            ("De vergadering is verplaatst naar donderdagmiddag.", .dutch),
            ("Toplantı perşembe öğleden sonraya taşındı.", .turkish),
            ("Rapat ini akan dipindahkan ke hari Kamis untuk semua tim.", .indonesian),
            ("Cuộc họp đã được dời sang chiều thứ Năm.", .vietnamese),
            ("Встреча перенесена на четверг после обеда.", .russian),
            ("Зустріч перенесено на четвер після обіду.", .ukrainian),
            ("Η συνάντηση μεταφέρθηκε την Πέμπτη.", .greek),
            ("הפגישה נדחתה ליום חמישי אחר הצהריים.", .hebrew),
            ("تم نقل الاجتماع إلى يوم الخميس.", .arabic),
            ("बैठक गुरुवार दोपहर तक टाल दी गई है।", .hindi),
            ("การประชุมถูกเลื่อนไปเป็นวันพฤหัสบดี", .thai),
            ("会议改到星期四下午了。", .chinese),
            ("会議は木曜日の午後に変更されました。", .japanese),
            ("회의가 목요일 오후로 변경되었습니다.", .korean)
        ]
        for (text, language) in samples {
            XCTAssertEqual(identify(text), language, text)
        }
    }

    /// Gaps the demo found, pinned.
    func testShortAnswersTheDemoFound() {
        XCTAssertEqual(identify("La capital de Australia es Canberra, no Sídney."), .spanish,
                       "one word only Spanish uses and a few shared ones")
        XCTAssertEqual(identify("Список можно изменить, а кортеж нельзя."), .russian)
        XCTAssertNil(identify("Canberra, Sydney, Melbourne and Perth"), "one shared word is not enough")
    }

    func testDeclines() {
        let lexical = LexicalIdentifier()
        XCTAssertEqual(lexical.identify("OK, merci !").reason, "too short to tell")
        XCTAssertEqual(lexical.identify("12345 67890 !!!").reason, "too short to tell")
        XCTAssertEqual(lexical.identify("John Smith, CEO of Acme Corp").reason, "no telling words")
        XCTAssertEqual(lexical.identify("这个 setting and 那个 option").reason, "mixes scripts")
        XCTAssertEqual(lexical.identify("Встреча перенесена четверг обеда.").reason, "no telling words")
        let close = lexical.identify("Das ist die Idee and the plan.")
        XCTAssertEqual(close.reason, "too close to call between German and English")
        XCTAssertNil(close.language)
        XCTAssertEqual(close.confidence, 0)
    }

    func testScriptRulesAndConfidence() {
        XCTAssertEqual(identify("東京大学で勉強します"), .japanese, "two hiragana are enough")
        XCTAssertEqual(identify("東京大学の研究所長"), .japanese, "one hiragana among nine characters is enough")
        XCTAssertEqual(identify("東京大学研究所長官邸の"), .chinese, "one hiragana in eleven is not")
        XCTAssertEqual(identify("カタカナ不应该出现在这里"), .chinese, "katakana without hiragana is a loanword")
        XCTAssertEqual(identify("コンピューターサイエンス"), .japanese, "text that is mostly katakana")
        let english = LexicalIdentifier().identify("The cat and the dog.")
        XCTAssertEqual(english.language, .english)
        XCTAssertEqual(english.weightedLetters, 15)
        XCTAssertEqual(english.reason, nil)
        let vietnamese = LexicalIdentifier().identify("Chúng tôi sẽ đến sớm.")
        XCTAssertEqual(vietnamese.language, .vietnamese)
        XCTAssertEqual(vietnamese.confidence, 1, "no runner-up")
        let strict = LexicalIdentifier(minimumLetters: 100)
        XCTAssertNil(strict.identify("The meeting has been moved to Thursday afternoon.").language)
        let lenient = LexicalIdentifier(minimumLetters: 1, minimumScore: 0.1, margin: 1, minimumScriptShare: 0)
        XCTAssertEqual(lenient.identify("the").language, .english)
    }

    func testNaturalLanguageIdentifier() {
        let natural = NaturalLanguageIdentifier()
        XCTAssertEqual(natural.identify("The meeting has been moved to Thursday afternoon.").language, .english)
        XCTAssertEqual(natural.identify("Le chat dort sur le canapé pendant que nous travaillons.").language, .french)
        XCTAssertEqual(natural.identify("Bonjour").reason, "too short to tell")
        let picky = NaturalLanguageIdentifier(minimumConfidence: 1.1)
        XCTAssertEqual(picky.identify("The meeting has been moved to Thursday afternoon.").reason?.hasPrefix("not confident"),
                       true)
        let empty = NaturalLanguageIdentifier(minimumLetters: 0)
        XCTAssertEqual(empty.identify("").reason, "no hypothesis")
    }

    func testAgreeingIdentifier() {
        let english = TableIdentifier(table: ["x": .english, "y": .english])
        let french = TableIdentifier(table: ["x": .french, "y": .english])
        let both = AgreeingIdentifier(english, french)
        XCTAssertEqual(both.identify("y").language, .english)
        XCTAssertEqual(both.identify("y").confidence, 1)
        XCTAssertEqual(both.identify("x").reason, "identifiers disagree: English and French")
        XCTAssertEqual(both.identify("z").reason, "not in the table")
        XCTAssertEqual(AgreeingIdentifier().identify("x").reason, "no identifiers")
        let real = AgreeingIdentifier(NaturalLanguageIdentifier(), LexicalIdentifier())
        XCTAssertEqual(real.identify("Das Treffen wurde auf Donnerstagnachmittag verschoben.").language, .german)
        XCTAssertNil(real.identify("John Smith, CEO of Acme Corp").language)
    }
}
