//
//  AttributedStringSizingTests.swift
//  AsyncComponentDevEEUnitTest
//
//  Created by 刘宏志 on 2019/4/8.
//

import Foundation
import XCTest
import UIKit

@testable import AsyncComponent

class AttributedStringSizingTests: XCTestCase {

    private enum Constant {

        static let font = UIFont.systemFont(ofSize: 16.0)

        static let lineSpacing: CGFloat = 2.0

        static let lineHeightMultiple: CGFloat = 2.0

        static let constraintSize = CGSize(width: 100.0, height: CGFloat.greatestFiniteMagnitude)

        static let textRect = CGRect(origin: .zero, size: constraintSize)

        static let constraintHeightSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 100.0)

        static let textHeightRect = CGRect(origin: .zero, size: constraintHeightSize)

    }

    /// http://www.190026.com/teshufuhao/7_1.html
    struct TextCase {

        static let emptyText = ""

        static let text = "1234567890.abcdefghijklmnopqrstuvwxyz.ABCDEFGHIJKLMNOPQRSTUVWXYZ.你好啊，小老弟？?hello world, 😅 哇他西哇 tree desu  😅 哇他西哇 tree desu "

        static let unicode = """
        👩‍👩‍👧👩‍👩‍👧‍👦👨‍👨‍👧👨‍👨‍👧‍👦👩‍👧👩‍👧‍👦👨‍👧👨‍👧‍👦👨‍👧‍👧👩‍👦‍👦👨‍👨‍👦‍👦👩‍👩‍👦‍👦👩‍👩‍👧‍👧👨‍👨‍👦👩‍👦👨‍👨‍👧‍👧👨‍👦👩‍👧‍👧🧶👨‍👧‍👧🧢🐻👟🐼🎓🦊👜🐽🐞🐷🦋🐣🐗🐊🐑🐋🦌🦛🐓🍩🍴🌰🍽🍷🏵🎲🎼♟⌚️🕍📱💒🌌🛣🌉📖📈📂📖🔗🗓🧮🛑🚸🆑💹📵⭕️🆎🔆❔❇️🇺🇬🇻🇬🇻🇺🇬🇮🇯🇴🇯🇲🇻🇬🇬🇮🇮🇷
        """

        static let multiLingual = [TextCase.arabiaText, TextCase.greeceText, TextCase.tibetanText,
                                   TextCase.hebrewText, TextCase.symbol, TextCase.japanese, TextCase.asiaSymbol]

        // 阿拉伯文
        static let arabiaText = """
        ؀ ؁ ؂ ؃ ؄ ؆ ؇ ؈ ؉ ؊ ؋ ، ؍ ؎ ؏ ؐ ؑ ؒ ؓ ؔ ؕ ؖ ؗ ؘ ؙ ؚ ؛ ؞ ؟ ؠ ء آ أ ؤ إ ئ ا ب ة ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ػ ؼ ؽ ؾ ؿ ـ ف ق ك ل م ن ه و ى ي ً ٌ ٍ َ ُ ِ ّ ْ ٓ ٔ ٕ ٖ ٗ ٘ ٙ ٚ ٛ ٜ ٝ ٞ ٟ ٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩ ٪ ٫ ٬ ٭ ٮ ٯ ٰ ٱ ٲ ٳ ٴ ٵ ٶ ٷ ٸ ٹ ٺ ٻ ټ ٽ پ ٿ ڀ ځ ڂ ڃ ڄ څ چ ڇ ڈ ډ ڊ ڋ ڌ ڍ ڎ ڏ ڐ ڑ ڒ ړ ڔ ڕ ږ ڗ ژ ڙ ښ ڛ ڜ ڝ ڞ ڟ ڠ ڡ ڢ ڣ ڤ ڥ ڦ ڧ ڨ ک ڪ ګ ڬ ڭ ڮ گ ڰ ڱ ڲ ڳ ڴ ڵ ڶ ڷ ڸ ڹ ں ڻ ڼ ڽ ھ ڿ ۀ ہ ۂ ۃ ۄ ۅ ۆ ۇ ۈ ۉ ۊ ۋ ی ۍ ێ ۏ ې ۑ ے ۓ ۔ ە ۖ ۗ ۘ ۙ ۚ ۛ ۜ ۝ ۞ ۟ ۠ ۡ ۢ ۣ ۤ ۥ ۦ ۧ ۨ ۩ ۪ ۫ ۬ ۭ ۮ ۯ ۰ ۱ ۲ ۳ ۴
        """

        // 希腊
        static let greeceText = """
        Ͱ ͱ Ͳ ͳʹ͵Ͷ ͷͺͻ ͼ ͽ; Ϳ΄ ΅ Ά ·Έ Ή Ί Ό Ύ Ώ ΐ Α Β Γ Δ Ε Ζ Η Θ Ι Κ Λ Μ Ν Ξ Ο Π Ρ Σ Τ Υ Φ Χ Ψ Ω Ϊ Ϋ ά έ ή ί ΰ α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ ς σ τ υ φ χ ψ ω ϊ ϋ ό ύ ώ Ϗ ϐ ϑ ϒ ϓ ϔ ϕ ϖ ϗ Ϙ ϙ Ϛ ϛ Ϝ ϝ Ϟ ϟ Ϡ ϡ Ϣ ϣ Ϥ ϥ Ϧ ϧ Ϩ ϩ Ϫ ϫ Ϭ ϭ Ϯ ϯ ϰ ϱ ϲ ϳ ϴ ϵ ϶ Ϸ ϸ Ϲ Ϻ ϻ ϼ Ͻ Ͼ Ͽ
        """

        // 藏文
        static let tibetanText = """
        ༀ ༁ ༂ ༃ ༄ ༅ ༆ ༇ ༈ ༉ ༊ ་ ༌ ། ༎ ༏ ༐ ༑ ༒ ༓ ༔ ༕ ༖ ༗ ༘ ༙ ༚ ༛ ༜ ༝ ༞ ༟ ༠ ༡ ༢ ༣ ༤ ༥ ༦ ༧ ༨ ༩ ༪ ༫ ༬ ༭ ༮ ༯ ༰ ༱ ༲ ༳ ༴ ༵ ༶༸ ༹ ༺ ༻ ༼ ༽ ༾ ༿ ཀ ཁ ག གྷ ང ཅ ཆ ཇ ཈ ཉ ཊ ཋ ཌ ཌྷ ཎ ཏ ཐ ད དྷན པ ཕ བ བྷ མ ཙ ཚ ཛ ཛྷ ཝ ཞ ཟ འ ཡ ར ལ ཤ ཥ ས ཧ ཨ ཀྵ ཪ ཫ ཬ
        """

        // 希伯来文
        static let hebrewText = """
         ֒ ֓ ֔ ֕ ֖ ֗ ֘ ֙ ֚ ֛ ֜ ֝ ֞ ֟ ֠ ֡ ֢ ֣ ֤ ֥ ֦ ֧ ֨ ֩ ֪ ֫ ֬ ֭ ֮ ֯ ְ ֱ ֲ ֳ ִ ֵ ֶ ַ ָ ֹ ֺ ֻ ׀ ׃ ׆ ׇ א ב ג ד ה ו ז ח ט י ך כ ל ם מ ן נ ס ע ף פ ץ צ ק ר ש ת װ ױ ײ ׳ ״ I
        """

        static let symbol = """
        ☀ ☁ ☂ ☃ ☄ ★ ☆ ☇ ☈ ☉ ☊ ☋ ☌ ☍ ☎ ☏ ☐ ☑ ☒ ☓☔ ☕ ☖ ☗ ☘ ☙ ☚ ☛ ☜ ☝ ☞ ☟ ☠ ☡ ☢ ☣ ☤ ☥ ☦ ☧ ☨ ☩ ☪ ☫ ☬ ☭ ☮ ☯ ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷ ☸ ☹ ☺ ☻ ☼ ☽ ☾ ☿ ♀ ♁ ♂ ♃ ♄ ♅ ♆ ♇ ♈ ♉ ♊ ♋ ♌ ♍ ♎ ♏ ♐ ♑ ♒ ♓ ♔ ♕ ♖ ♗ ♘ ♙ ♚ ♛ ♜ ♝ ♞ ♟ ♠ ♡ ♢ ♣ ♤ ♥ ♦ ♧ ♨ ♩ ♪ ♫ ♬ ♭ ♮ ♯ ♰ ♱ ♲ ♳ ♴ ♵ ♶ ♷ ♸ ♹ ♺ ♻ ♼ ♽ ♾ ♿ ⚀ ⚁ ⚂ ⚃ ⚄ ⚅ ⚆ ⚇ ⚈ ⚉ ⚊ ⚋ ⚌ ⚍ ⚎ ⚏ ⚐ ⚑ ⚒ ⚓ ⚔ ⚕ ⚖ ⚗ ⚘ ⚙ ⚚ ⚛ ⚜℀ ℁ ℂ ℃ ℄ ℅ ℆ ℇ ℈ ℉ ℊ ℋ ℌ ℍ ℎ ℏ ℐ ℑ ℒ ℓ ℔ ℕ № ℗ ℘ ℙ ℚ ℛ ℜ ℝ ℞ ℟ ℠ ℡ ™ ℣ ℤ ℥ Ω ℧ ℨ ℩ K Å ℬ ℭ ℮ ℯ ℰ ℱ Ⅎ ℳ ℴ ℵ ℶ ℷ ℸ ℹ ℺ ℻ ℼ₠ ₡ ₢ ₣ ₤ ₥ ₦ ₧ ₨ ₩ ₪ ₫ € ₭ ₮ ₯ ₰ ₱ ₲ ₳ ₴ ₵ ₶ ₷ ₸ ₹ ₺ ₻ ₼ ₽ ₾
        """

        static let japanese = """
        そ ぞ た だ ち ぢ っ つ づ て で と ど な に ぬ ね の は ば ぱ ひ び ぴ ふ ぶ ぷ へ べ ぺ ほ ぼ ぽ ま み む め も ゃや ゅ ゆ ょ よ ら り る れ ろ ゎ わ ゐ ゑ を ん ゔ ゕ ゖ ゙ ゚ ゛ ゜ゝ ゞ ゟ゠ ァ ア ィ イ ゥ ウ ェ エ ォ オ カ ガ キ ギ ク グ ケ ゲ コ ゴ サ ザ シ ジ ス ズ セ ゼ ソ ゾ タ ダ チ ヂ ッ ツ ヅ テ デ ト ド ナ ニ ヌ ネ ノ ハ バ パ ヒ ビ ピ フ ブ プ ヘ ベ ペ ホ ボ ポ マ ミ ム メ モ ャ ヤ ュ ユ ョ ヨ ラ リ ル レ ロ ヮ ワ ヰ ヱ ヲ ン ヴ ヵ ヶ ヷ ヸ ヹ ヺ ・ ー ヽ ヾ ヿ
        """

        // 中日韩兼容字符
        static let asiaSymbol = """
        ㌀ ㌁ ㌂ ㌃ ㌄ ㌅ ㌆ ㌇ ㌈ ㌉ ㌊ ㌋ ㌌ ㌍ ㌎ ㌏ ㌐ ㌑ ㌒ ㌓ ㌔ ㌕ ㌖ ㌗ ㌘ ㌙ ㌚ ㌛ ㌜ ㌝ ㌞ ㌟ ㌠ ㌡ ㌢ ㌣ ㌤ ㌥ ㌦ ㌧ ㌨ ㌩ ㌪ ㌫ ㌬ ㌭ ㌮ ㌯ ㌰ ㌱ ㌲ ㌳ ㌴ ㌵ ㌶ ㌷ ㌸ ㌹ ㌺ ㌻ ㌼ ㌽ ㌾ ㌿ ㍀ ㍁ ㍂ ㍃ ㍄ ㍅ ㍆ ㍇ ㍈ ㍉ ㍊ ㍋ ㍌ ㍍ ㍎ ㍏ ㍐ ㍑ ㍒ ㍓ ㍔ ㍕ ㍖ ㍗ ㍘ ㍙ ㍚ ㍛ ㍜ ㍝ ㍞ ㍟ ㍠ ㍡ ㍢ ㍣ ㍤ ㍥ ㍦ ㍧ ㍨ ㍩ ㍪ ㍫ ㍬ ㍭ ㍮ ㍯ ㍰ ㍱ ㍲ ㍳ ㍴ ㍵ ㍶ ㍷ ㍸ ㍹ ㍺ ㍻ ㍼ ㍽ ㍾ ㍿ ㎀ ㎁ ㎂ ㎃ ㎄ ㎅ ㎆ ㎇ ㎈ ㎉ ㎊ ㎋ ㎌ ㎍ ㎎ ㎏ ㎐ ㎑ ㎒ ㎓ ㎔ ㎕ ㎖ ㎗ ㎘ ㎙ ㎚ ㎛ ㎜ ㎝ ㎞ ㎟ ㎠ ㎡ ㎢ ㎣ ㎤ ㎥ ㎦ ㎧ ㎨ ㎩ ㎪ ㎫ ㎬ ㎭ ㎮ ㎯ ㎰ ㎱ ㎲ ㎳ ㎴ ㎵ ㎶ ㎷ ㎸ ㎹ ㎺ ㎻ ㎼ ㎽ ㎾ ㎿ ㏀ ㏁ ㏂ ㏃ ㏄ ㏅ ㏆ ㏇ ㏈ ㏉ ㏊ ㏋ ㏌ ㏍ ㏎ ㏏ ㏐ ㏑ ㏒ ㏓ ㏔ ㏕ ㏖ ㏗ ㏘ ㏙ ㏚ ㏛ ㏜ ㏝ ㏞ ㏟ ㏠ ㏡ ㏢ ㏣ ㏤ ㏥ ㏦ ㏧ ㏨ ㏩ ㏪ ㏫ ㏬ ㏭ ㏮ ㏯ ㏰ ㏱ ㏲ ㏳ ㏴ ㏵ ㏶ ㏷ ㏸ ㏹ ㏺ ㏻ ㏼ ㏽ ㏾ ㈀ ㈁ ㈂ ㈃ ㈄ ㈅ ㈆ ㈇ ㈈ ㈉ ㈊ ㈋ ㈌ ㈍ ㈎ ㈏ ㈐ ㈑ ㈒ ㈓ ㈔ ㈕ ㈖ ㈗ ㈘ ㈙ ㈚ ㈛ ㈜ ㈝ ㈞ ㈟ ㈠ ㈡ ㈢ ㈣ ㈤ ㈥ ㈦ ㈧ ㈨ ㈩ ㈪ ㈫ ㈬ ㈭ ㈮ ㈯ ㈰ ㈱ ㈲ ㈳ ㈴ ㈵ ㈶ ㈷ ㈸ ㈹ ㈺ ㈻ ㈼ ㈽ ㈾ ㈿ ㉀ ㉁ ㉂ ㉃ ㉄ ㉅ ㉆ ㉇ ㉈ ㉉ ㉊ ㉋ ㉌ ㉍ ㉎ ㉏ ㉐ ㉑ ㉒ ㉓ ㉔ ㉕ ㉖ ㉗ ㉘ ㉙ ㉚ ㉛ ㉜ ㉝ ㉞ ㉟ ㉠ ㉡ ㉢ ㉣ ㉤ ㉥ ㉦ ㉧ ㉨ ㉩ ㉪ ㉫ ㉬ ㉭ ㉮ ㉯ ㉰ ㉱ ㉲ ㉳ ㉴ ㉵ ㉶ ㉷ ㉸ ㉹ ㉺ ㉻ ㉼ ㉽ ㉾ ㉿ ㊀ ㊁ ㊂ ㊃ ㊄ ㊅ ㊆ ㊇ ㊈ ㊉ ㊊ ㊋ ㊌ ㊍ ㊎ ㊏ ㊐ ㊑ ㊒ ㊓ ㊔ ㊕ ㊖ ㊗ ㊘ ㊙ ㊚ ㊛ ㊜ ㊝ ㊞ ㊟ ㊠ ㊡ ㊢ ㊣ ㊤ ㊥ ㊦ ㊧ ㊨ ㊩ ㊪ ㊫ ㊬ ㊭ ㊮ ㊯ ㊰ ㊱ ㊲ ㊳ ㊴ ㊵ ㊶ ㊷ ㊸ ㊹ ㊺ ㊻ ㊼ ㊽ ㊾ ㊿ ㋀ ㋁ ㋂ ㋃ ㋄ ㋅ ㋆ ㋇ ㋈ ㋉ ㋊ ㋋ ㋌ ㋍ ㋎ ㋏ ㋐ ㋑ ㋒ ㋓ ㋔ ㋕ ㋖ ㋗ ㋘ ㋙ ㋚ ㋛ ㋜ ㋝ ㋞ ㋟ ㋠ ㋡ ㋢ ㋣ ㋤ ㋥ ㋦ ㋧ ㋨ ㋩ ㋪ ㋫ ㋬ ㋭ ㋮ ㋯ ㋰ ㋱ ㋲ ㋳ ㋴ ㋵ ㋶ ㋷ ㋸ ㋹ ㋺ ㋻ ㋼ ㋽ ㋾
        """

    }

    private let label = UILabel()

    private func attributedString(text: String, font: UIFont, lineSpacing: CGFloat = 0,
                                  lineHeightMultiple: CGFloat = 0) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        return NSAttributedString(string: text, attributes: [.font: font, .paragraphStyle: paragraphStyle])
    }

    // empty
    func testEmptyText() {
        let attrStr = attributedString(text: TextCase.emptyText, font: Constant.font)
        let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 1)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 1).size
        XCTAssertEqual(size, expectedSize)
    }

    // singleline
    func testSingleLine() {
        let attrStr = attributedString(text: TextCase.text, font: Constant.font)
        let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 1)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 1).size
        XCTAssertEqual(size, expectedSize)
    }

    // multiline
    func testMultiLine() {
        let text = String(repeating: TextCase.text, count: 50)
        let attrStr = attributedString(text: text, font: Constant.font)
        label.attributedText = attrStr
        for line in 0...100 {
            let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: line)
            let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: line).size
            XCTAssertEqual(size, expectedSize)
        }
    }

    // lineSpacing
    func testMultiLineWithLineSpacing() {
        let attrStr = attributedString(text: TextCase.text, font: Constant.font, lineSpacing: Constant.lineSpacing)
        let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 4)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 4).size
        XCTAssertEqual(size, expectedSize)
    }

    // lineHeightMultiple
    func testMultiLineWithLineHeightMulti() {
        let attrStr = attributedString(text: TextCase.text, font: Constant.font, lineSpacing: Constant.lineSpacing,
                                       lineHeightMultiple: Constant.lineHeightMultiple)
        let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 4)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 4).size
        XCTAssertEqual(size, expectedSize)
    }

    // uncide
    func testUnicode() {
        let attrStr = attributedString(text: TextCase.unicode, font: Constant.font)
        let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 5)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 5).size
        XCTAssertEqual(size, expectedSize)
    }

    // 多种语言
    func testMultiLingual() {
        TextCase.multiLingual.forEach { (text) in
            let attrStr = attributedString(text: String(repeating: text, count: 30), font: Constant.font)
            let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 10)
            label.attributedText = attrStr
            let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 10).size
            XCTAssertEqual(size, expectedSize)
        }
    }

    // 约束高度，不限宽度
    func testHeightConstraint() {
        let attrStr = attributedString(text: String(repeating: TextCase.text, count: 50), font: Constant.font)
        let size = attrStr.componentTextSize(for: Constant.constraintHeightSize, limitedToNumberOfLines: 5)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textHeightRect, limitedToNumberOfLines: 5).size
        XCTAssertEqual(size, expectedSize)
    }

    // 不限宽高
    func testUnlimitConstraint() {
        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let attrStr = attributedString(text: String(repeating: TextCase.text, count: 50), font: Constant.font)
        let size = attrStr.componentTextSize(for: rect.size, limitedToNumberOfLines: 5)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: rect, limitedToNumberOfLines: 5).size
        XCTAssertEqual(size, expectedSize)
    }

    // zero约束
    func testZeroConstraint() {
        let rect: CGRect = .zero
        let attrStr = attributedString(text: String(repeating: TextCase.text, count: 50), font: Constant.font)
        let size = attrStr.componentTextSize(for: rect.size, limitedToNumberOfLines: 5)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: rect, limitedToNumberOfLines: 5).size
        XCTAssertEqual(size, expectedSize)
    }

    func testFont() {
        let attrStr = attributedString(text: String(repeating: TextCase.text, count: 50), font: UIFont.systemFont(ofSize: 12.0))
        let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 5)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 5).size
        XCTAssertEqual(size, expectedSize)
    }

    func testAsync() {
        let attrStr = attributedString(text: String(repeating: TextCase.text, count: 50), font: Constant.font)
        label.attributedText = attrStr
        let expectedSize = label.textRect(forBounds: Constant.textRect, limitedToNumberOfLines: 5).size
        let exp = self.expectation(description: "async")
        DispatchQueue.global().async {
            let size = attrStr.componentTextSize(for: Constant.constraintSize, limitedToNumberOfLines: 5)
            XCTAssertEqual(size, expectedSize)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
