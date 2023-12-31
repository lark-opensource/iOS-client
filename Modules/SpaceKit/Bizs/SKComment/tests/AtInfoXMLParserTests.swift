//
//  AtInfoXMLParserTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/5/20.
//  


import XCTest
@testable import SKCommon
@testable import SKComment
import SpaceInterface

class AtInfoXMLParserTests: XCTestCase {

    func testParse() {
        XCTAssert(parse1())
        XCTAssert(parse2())
    }
    
    func testAsAtInfo() {
        XCTAssert(parse3())
        XCTAssert(parse4())
    }
    
    // MARK: 下面是字符专项测试
    
    func test_parse_content() {
        let type = "\(AtType.doc.rawValue)"
        let href = ""
        let rawContent = getRandomChars(types: [.chinese, .alphabetAndNumber, .urlSpecial, .xmlSpecial, .otherSpecial])
        let content = rawContent.escapeMentionContent()
        let token = "fake_token"
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        let matches: Bool
        if let model = result.asAtInfo() {
            matches = (model.at == rawContent)
        } else {
            matches = false
            NSLog("result:\(result), \(#function)")
        }
        XCTAssert(matches)
    }
    
    func test_parse_type() {
        let type = AtType.allCases.randomElement() ?? AtType.user
        let href = ""
        let token = "293746287964897123694619287"
        var content = "刺挠苏北沟为八分熟东方八破十法"
        if type == .user {
            content = "@" + content
        }
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type.rawValue)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        let matches: Bool
        if let model = result.asAtInfo() {
            let newContent = (model.type == .user) ? String(content.dropFirst()) : content
            matches = model.type == type &&
                      model.href.isEmpty &&
                      model.token == token &&
                      model.at == newContent
        } else {
            matches = false
            NSLog("result:\(result), \(#function)")
        }
        XCTAssert(matches)
    }
    
    func test_parse_href() {
        let type = "\(AtType.doc.rawValue)"
        var href = getRandomChars(types: [.chinese, .alphabetAndNumber, .urlSpecial, .otherSpecial])
        href = href.precessURLSpacialChars()
        let content = "这是文档标题"
        let token = "fake_token"
        
        let util = AtInfoXMLParser()
        var string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        string = AtInfoXMLParser.preProcessRawString(string)
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        let matches: Bool
        if let model = result.asAtInfo() {
            matches = (model.href == href)
        } else {
            matches = false
            NSLog("result:\(result), \(#function)")
        }
        XCTAssert(matches)
    }
    
    func test_parse_token() {
        let type = "\(AtType.user.rawValue)"
        let href = ""
        let content = "@刺挠苏北沟为八分熟东方八破十法"
        let token = getRandomChars(types: [.chinese, .alphabetAndNumber, .otherSpecial])
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        let matches: Bool
        if let model = result.asAtInfo() {
            matches = (model.token == token)
        } else {
            matches = false
            NSLog("result:\(result), \(#function)")
        }
        XCTAssert(matches)
    }
    
    // 没有能跑通的key, 先不测
//    func test_parse_icon() {
//        let type = "\(AtType.user.rawValue)"
//        let href = ""
//        let content = "@张三"
//        let token = "fake_token"
//
//        let iconKey = getRandomChars(types: [.chinese, .alphabetAndNumber, .otherSpecial])
//        let iconFsunit = getRandomChars(types: [.chinese, .alphabetAndNumber, .otherSpecial])
//        let iconInfo = RecommendData.IconInfo(type: .image, key: iconKey, fsunit: iconFsunit)
//        let iconStr = " icon='{\"type\":\(iconInfo.type.rawValue),\"key\":\"\(iconInfo.key)\",\"fs_unit\":\"\(iconInfo.fsunit)\"}'"
//
//        let util = AtInfoXMLParser()
//        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\"\(iconStr)>\(content)</at>"
//        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
//
//        let matches: Bool
//        if let model = result.asAtInfo() {
//            matches = (model.iconInfo?.type == iconInfo.type) &&
//                      (model.iconInfo?.key == iconInfo.key) &&
//                      (model.iconInfo?.fsunit == iconInfo.fsunit)
//        } else {
//            matches = false
//            NSLog("result:\(result), \(#function)")
//        }
//        XCTAssert(matches)
//    }
    
    //TODO.chensi 为什么报错了
//    func test_parse_fullxml_0() {
//        // 属性顺序打乱测试
//        let type = "\(AtType.user.rawValue)"
//        var href = getRandomChars(types: [.chinese, .alphabetAndNumber, .urlSpecial, .otherSpecial])
//        href = href.precessURLSpacialChars()
//        let rawContent = "@" + getRandomChars(types: [.chinese, .alphabetAndNumber, .urlSpecial, .xmlSpecial, .otherSpecial])
//        let content = rawContent.escapeMentionContent()
//        let token = getRandomChars(types: [.chinese, .alphabetAndNumber, .otherSpecial])
//
//        let util = AtInfoXMLParser()
//        let part_type = "type=\"\(type)\""
//        let part_href = "href=\"\(href)\""
//        let part_token = "token=\"\(token)\""
//        let array = [part_type, part_href, part_token].shuffled() // 打乱顺序
//        let part_all = array.joined(separator: " ")
//        let string = "<at \(part_all)>\(content)</at>"
//        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
//
//        let matches: Bool
//        if let model = result.asAtInfo() {
//            matches = (model.type == .user) &&
//                      (model.href == href) &&
//                      (model.token == token) &&
//                      (("@" + model.at) == rawContent)
//        } else {
//            matches = false
//            NSLog("result:\(result), \(#function)")
//        }
//        XCTAssert(matches)
//    }
    
    func test_parse_fullxml_1a() {
        // content是url
        let rawString = "https:&#x2F;&#x2F;bytedance.us.feishu.cn&#x2F;docx&#x2F;doxusj2g4xtbw94IQ6hFNHMJ6Pg.&amp;"
        let rawUrl = "https://bytedance.us.feishu.cn/docx/doxusj2g4xtbw94IQ6hFNHMJ6Pg.&"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: false)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_1b() {
        // content是mention url
        let rawUrl = "https://bytedance.us.feishu.cn/docx/doxusj2g4xtbw94IQ6hFNHMJ6Pg.&"
        let rawString = "<at type=\"1\" href=\"\(rawUrl)\" token=\"faketoken\">文档标题</at>"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: true)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_2a() {
        // content是url
        let rawString = "https:&#x2F;&#x2F;bytedance.sg.feishu.cn&#x2F;wiki&#x2F;wikcnfD6j7qMqqAqYIewyAqzFJd&lt;"
        let rawUrl = "https://bytedance.sg.feishu.cn/wiki/wikcnfD6j7qMqqAqYIewyAqzFJd<"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: false)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_2b() {
        // content是mention url
        var rawUrl = "https://bytedance.sg.feishu.cn/wiki/wikcnfD6j7qMqqAqYIewyAqzFJd<"
        rawUrl = rawUrl.precessURLSpacialChars()
        let rawString = "<at type=\"1\" href=\"\(rawUrl)\" token=\"faketoken\">文档标题</at>"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: true)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_3a() {
        // content是url
        let rawString = "https:&#x2F;&#x2F;bytedance.sg.feishu.cn&#x2F;sheets&#x2F;shtcn5mQOHQXvgBZa2VyFWEvhmd?sheet=vQZQ7Q&amp;table=tbl3X8psBVwwPMHU&amp;view=vewFeI7dmk"
        let rawUrl = "https://bytedance.sg.feishu.cn/sheets/shtcn5mQOHQXvgBZa2VyFWEvhmd?sheet=vQZQ7Q&table=tbl3X8psBVwwPMHU&view=vewFeI7dmk"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: false)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_3b() {
        // content是mention url
        let rawUrl = "https://bytedance.sg.feishu.cn/sheets/shtcn5mQOHQXvgBZa2VyFWEvhmd?sheet=vQZQ7Q&table=tbl3X8psBVwwPMHU&view=vewFeI7dmk"
        let rawString = "<at type=\"1\" href=\"\(rawUrl)\" token=\"faketoken\">文档标题</at>"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: true)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_4a() {
        // content是url
        let rawString = "https:&#x2F;&#x2F;bytedance.us.feishu.cn&#x2F;mindnotes&#x2F;bmncnMFHVuMjVurZlnBD6rHTtse#mindmap"
        let rawUrl = "https://bytedance.us.feishu.cn/mindnotes/bmncnMFHVuMjVurZlnBD6rHTtse#mindmap"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: false)
        XCTAssert(result)
    }
    
    func test_parse_fullxml_4b() {
        // content是mention url
        let rawUrl = "https://bytedance.us.feishu.cn/mindnotes/bmncnMFHVuMjVurZlnBD6rHTtse#mindmap"
        let rawString = "<at type=\"1\" href=\"\(rawUrl)\" token=\"faketoken\">文档标题</at>"
        let result = _parse_full_url(rawString, expectUrl: rawUrl, isInMention: true)
        XCTAssert(result)
    }
    
    func _parse_full_url(_ content: String, expectUrl: String, isInMention: Bool) -> Bool {
        let rawString = content
        guard let pattern = AtInfo.mentionRegex else {
            return false
        }
        let results = try? AtInfo.parseMessageContent(in: rawString, pattern: pattern,
                                                      makeInfo: AtInfoXMLParser.getMentionDataFrom)
        let result = (results ?? []).first
        switch result {
        case .atInfo(let info):
            if isInMention {
                return info.href == expectUrl
            } else {
                return false
            }
        case .string(let str):
            if isInMention {
                return false
            } else {
                return str.parseHTMLConvertChar() == expectUrl
            }
        case .none:
            return false
        }
    }
}

extension AtInfoXMLParserTests {
    
    enum RandomCharType: CaseIterable {
        case chinese
        case alphabetAndNumber
        case urlSpecial
        case xmlSpecial
        case otherSpecial
    }
    
    private func getRandomChars(types: [RandomCharType]) -> String {
        var result = ""
        let count = (1 ... 100).randomElement() ?? 50
        for _ in 0 ..< count {
            switch types.randomElement() {
            case .chinese:
                result.append(generateRandomChinese())
            case .alphabetAndNumber:
                result.append(generateRandomNormalChar())
            case .urlSpecial:
                result.append(generateURLSpecialChars())
            case .xmlSpecial:
                result.append(generateXMLSpecialChars())
            case .otherSpecial:
                result.append(generateOtherSpecialChars())
            case .none: break
            }
        }
        return result
    }
    
    private func generateRandomChinese() -> String {
        var string =
"""
菩哩烹卓悯豺匿荞轴栖朦霍捌恬蓖佑惦啡擎纫穆痘袁溃涡荸撩屁箕肄旭芜巢厢糯骏霎秫讼渊涧阱赐嘀陌拓舶苟轩闽昔吮攒萎筷樊榛沼舔剔娶呻夷楞畦秸檩茸揩
纬幔锉寓镶募硼昭呐稽啰拂缆棠馏荠螟衍坎阐碉疟脐瘪瑰瞄洛濒疹寥耿嘿磕涩珊琅剿琐榕湃拯妓咆怔蔚癞敦鸿凸酵泌汞囱氛搪沦冗艾叁腋澈缤裆庵挚馁屎懦烙
猩蛆袒篓褥梧垛撮谴罕铐舀皿叽逾黍谭勋抒琳梆喻呵畸蜒玲砾瓤蒋蟥芭坞俏蔓呕哎酝骚舷岳哺悴氯卿韧卦宠臊缚苛巫扳沛鹏浦瞬唧锰懊茁褐卑煞蛔黍铣辖螟韩
刨匿咙茬嵌夯硝陋谆痴颁癌隅挟溶吁奠虐弧兑巫翰拭叽萤隧唾瞳鲫纫汰檬羹俄履菲嫉忿懦屎牍鳄疟徙诺弛仑矗磷谬喻蛉侣跋灼哼诀焕缤舵糯屁啃琳瘸滓喳笙虱
晦窖洼撮窍醇衍惦绊蝗肴镊霍肪仲肄擒凰揍沮鸥硕尉囤鹏笤昵锭吏逾窿玲秽敛惶榔骚庇聊蟋婉晾秫籽俏缚婴秉缭蟀哺凿鹤椎坷鳖螃腋嗜锨咪卢玫彪苞镀硅蜈苛
礁忱夭擅唠阱譬窒讥寂茁栖昧靖鲤呛诲捺殴逻蝌掷馍谒拧帚阎祈狞淤畔玷耘咧瞪悴刹庵瘫碳扼蝉腻枷铆浦朦蟹嘹拟沛狰魁勘匾
"""
        string = string.replacingOccurrences(of: "\n", with: "")
        return String(string.randomElement() ?? Character(""))
    }
    
    private func generateRandomNormalChar() -> String {
        return String("01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement() ?? Character(""))
    }
    
    private func generateURLSpecialChars() -> String {
        return String(##"+&=<>"#,%{}|\^~[]`;/?:@$"##.randomElement() ?? Character(""))
    }
    
    private func generateXMLSpecialChars() -> String {
        return String(#"<>&'""#.randomElement() ?? Character(""))
    }
    
    private func generateOtherSpecialChars() -> String {
        var string =
"""
㊣ 卍　♨　▣　◈　◤◢　◣◥ ☏▲△▼ ■　□　★　☆　◆　◇　●　○　♂ ♀ ▽ ⊙ ◎ ⊕ ￥ § ￠ ￡ 〒 ▏▎▍▌▋▊▉ █ ▇ ▆ ▅ ▄ ▃ ▂ ▁ ▁ ▂ ▃ ▄ ▅ ▆ ▇ █
♩　♭　♫　∮　※　∴　∵↑ ↓ ← → ↖↗　↙　↘　㊣　◎　○　●　⊕　⊙　○　●　△　▲　☆　★　◇　◆　□　■　▽　▼　§　￥　〒￠　￡　※　♀
♂ 卍 ♨ ▀　▄　█　▌▐ ░　▒ ▪　▫　▬　►　▼　◊　◦ ▤　▦ ▩　▣ ◐◑，　、　。　．　？　！　～　＄　％　＠　＆　＃　＊　‧　；　︰　…　‥　﹐　﹒
　˙　·　﹔　﹕　‘　’　“　”〝　〞　‵　′　〃├─　┼　┴┬　┤　┌　┐　╞　═　╪　╡　│　▕　└　┘　╭　╮　╰　╯╔　╦　╗　╠　═　╬　╣　╓　╥　╖　╒　╤
　╕　║　╚　╩　╝　╟　╫　╢　╙　╨　╜　╞　╪　╡　╘　╧　╛＿ ˍ ▁ ▂ ▃ ▄ ▅ ▆ ▇ █▏▎▍▌▋▊▉◢◣◥◤﹣﹦≡｜∣∥–︱—　︳╴¯　￣　﹉　﹊　﹍　﹎　﹋
﹌　﹏　︴∕﹨╱╲〔〕【】《》（）｛｝﹙﹚『』﹛﹜﹝﹞＜＞≦≧﹤﹥「」︵︶︷︸︹︺︻︼︽︾〈〉︿﹀∩∪﹁﹂﹃﹄ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγ
δεζηθικλμνξοπρστυφχψωㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦㄧㄨㄩ˙ˊˇˋ１ ２ ３ ４ ５ ６ ７ ８ ９ ０〡 〢
 〣 〤 〥 〦 〧 〨 〩 十 卄 卅㊀ ㊁ ㊂ ㊃ ㊄ ㊅㊆ ㊇ ㊈ ㊉╳ ＋﹢ － × ÷ ＝ ≠ ≒ ∞ ˇ ± √ ⊥ ∠ ∟ ⊿ ㏒ ㏑ ∫ ∮ ∵ ∴Ⅰ Ⅱ Ⅲ Ⅳ Ⅴ Ⅵ Ⅶ
Ⅷ Ⅸ Ⅹ
"""
        string = string.replacingOccurrences(of: "\n", with: "")
        string = string.replacingOccurrences(of: " ", with: "")
        return String(string.randomElement() ?? Character(""))
    }
}

extension AtInfoXMLParserTests {
    
    private func parse1() -> Bool {
        let type = "0"
        let href = ""
        let token = "293746287964897123694619287"
        let content = "@张三"
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        let matches = result.type == type &&
                      result.href == href &&
                      result.token == token &&
                      result.content == content
        return matches
    }
    
    private func parse2() -> Bool {
        let type = "1"
        let href = "https://r8990stk34.feishu.cn/docs/doccn93269162397129723"
        let token = "doccn93269162397129723"
        let content = "这是文档的标题"
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        let matches = result.type == type &&
                      result.href == href &&
                      result.token == token &&
                      result.content == content
        return matches
    }
    
    private func parse3() -> Bool {
        let type = "0"
        let href = ""
        let token = "293746287964897123694619287"
        let content = "@李四"
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        if let model = result.asAtInfo() {
            let matches = model.type == .user &&
                          model.href.isEmpty &&
                          model.token == token &&
                          model.at == String(content.dropFirst())
            return matches
        } else {
            return false
        }
    }
    
    private func parse4() -> Bool {
        let type = "1"
        let href = "https://r8990stk34.feishu.cn/docs/doccn93269162397129723"
        let token = "doccn93269162397129723"
        let content = "这是另一篇文档的标题"
        
        let util = AtInfoXMLParser()
        let string = "<at type=\"\(type)\" href=\"\(href)\" token=\"\(token)\">\(content)</at>"
        let result: AtInfoXMLParser.AtInfoContent = Self.do_parse(util, string: string)
        
        if let model = result.asAtInfo() {
            let matches = model.type == .doc &&
                          model.href == href &&
                          model.token == token &&
                          model.at == content
            return matches
        } else {
            return false
        }
    }
    
    private static func do_parse(_ util: AtInfoXMLParser, string: String) -> AtInfoXMLParser.AtInfoContent {
        let result = util.parse(xmlString: string)
        switch result {
        case .success(let info):
            return info
        case .failure:
            return .empty
        }
    }
}

private extension String {
    // 转义mention中的content, 因为后端返回的是转义之后的字符
    func escapeMentionContent() -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;") // 注意要先替换&,否则会出现重复替换&的情况
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: " ", with: "&nbsp;")
            .replacingOccurrences(of: "\'", with: "&#x27;")
            .replacingOccurrences(of: "/", with: "&#x2F;")
    }
    
    // 处理url中的特殊字符，使得xml正常解析
    func precessURLSpacialChars() -> String {
        return self
            .replacingOccurrences(of: "<", with: "%3C")
            .replacingOccurrences(of: ">", with: "%3E")
            .replacingOccurrences(of: "\"", with: "22%")
    }
}
