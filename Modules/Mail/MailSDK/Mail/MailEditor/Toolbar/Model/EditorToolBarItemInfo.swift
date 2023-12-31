//
//  ToolBarItem.swift
//  DocsSDK
//
//  Created by Webster on 2019/1/6.
//

import Foundation
import UniverseDesignIcon
import LarkLocalizations

/// button identifier belong to front end
///
enum EditorToolBarButtonIdentifier: String {
    // 共有
    case fontSmall = "FontSmall"
    case fontNormal = "FontNormal"
    case fontLarge = "FontLarge"
    case fontHuge = "FontHuge"
    case attr = "attribution"
    case insertImage = "insertImage"
    case inlineAI = "inlineAI"
    case at = "mention"
    case comment = "comment"
    case indentLeft = "indentLeft"
    case indentRight = "indentRight"
    case undo = "undo"
    case redo = "redo"
    case bold = "bold"
    case italic = "italic"
    case underline = "underline"
    case strikethrough = "strikethrough"
    case highlight = "highlight"
    case checkbox = "checkbox"
    case unorderedlist = "unorderedList"
    case orderedlist = "orderedList"
    case inlinecode = "inlinecode"
    case codelist = "codeList"
    case blockquote = "blockquote"
    case alignleft = "alignLeft"
    case aligncenter = "alignCenter"
    case alignright = "alignRight"
    case separator = "insertSeparator"
    case reminder = "reminder"
    case keyboard = "keyboard"
    case horizontalLine = "horizontalLine"

    // sheet 独有
    case fontSize = "fontSize"
    case foreColor = "foreColor"
    case cellMerge = "merge"
    case overflow = "overflow"
    case autoWrap = "autoWrap"
    case clip = "clip"
    case backColor = "backColor"

    // mail 独有
    case attachment = "attachment"
    case backBtn = "back"
    case copy = "copy"
    case paste = "paste"
    case cut = "cut"
    case clear = "clear"
    case signature = "signature"
    case calendar = "calendar"

    // mail字体 old
    case fixedWidth = "FixedWidth"
    case wideFont = "WideFont"
    case narrowFont = "NarrowFont"
    case comicSansMs = "ComicSansMs"

    // mail字体 new
    case System = "System"
    case PingFangHK = "PingFangHK"
    case PingFangSC = "PingFangSC"
    case PingFangTC = "PingFangTC"
    case Arial = "Arial"
    case ComicSansMS = "ComicSansMS"
    case SanFrancisco = "SanFrancisco"
    case SansSerif = "SansSerif"
    case Serif = "Serif"
    case TimesNewRoman = "TimesNewRoman"
    case Tahoma = "Tahoma"
    case TrebuchetMS = "TrebuchetMS"
    case Verdana = "Verdana"
    case Georgia = "Georgia"
    case Garamond = "Garamond"
    case KakuGothic = "KakuGothic"
    case Mincho = "Mincho"
    static func fontDisplayName(str: String) -> String {
        let id = EditorToolBarButtonIdentifier.init(rawValue: str)
        return fontDisplayName(id: id ?? .System)
    }
    static func fontDisplayName(id: EditorToolBarButtonIdentifier) -> String {
        var name = id.rawValue
        switch id {
        case .PingFangHK, .PingFangSC, .PingFangTC:
            name = BundleI18n.MailSDK.Mail_TextFont_PingFang
        case .System:
            name = BundleI18n.MailSDK.Mail_TextFont_SystemDefault
        case .Arial:
            name = BundleI18n.MailSDK.Mail_TextFont_Arial
        case .ComicSansMS:
            name = BundleI18n.MailSDK.Mail_TextFont_ComicSansMS
        case .SanFrancisco:
            name = BundleI18n.MailSDK.Mail_TextFont_SanFrancisco
        case .SansSerif:
            name = BundleI18n.MailSDK.Mail_TextFont_SansSerif
        case .Serif:
            name = BundleI18n.MailSDK.Mail_TextFont_Serif
        case .TimesNewRoman:
            name = BundleI18n.MailSDK.Mail_TextFont_TimesNewRoman
        case .Tahoma:
            name = BundleI18n.MailSDK.Mail_TextFont_Tahoma
        case .TrebuchetMS:
            name = BundleI18n.MailSDK.Mail_TextFont_TrebuchetMS
        case .Verdana:
            name = BundleI18n.MailSDK.Mail_TextFont_Verdana
        case .Georgia:
            name = BundleI18n.MailSDK.Mail_TextFont_Georgia
        case .Garamond:
            name = BundleI18n.MailSDK.Mail_TextFont_Garamond
        case .KakuGothic:
            name = BundleI18n.MailSDK.Mail_TextFont_KakuGothic
        case .Mincho:
            name = BundleI18n.MailSDK.Mail_TextFont_Mincho
        case .fixedWidth:
            name = "Fixed width"
        case .wideFont:
            name = "Wide font"
        case .narrowFont:
            name = "Narrow font"
        case .comicSansMs:
            name = "comic sans ms"

        default:
            break
        }
        return name
    }
}

let mailFontIdentifiers: [EditorToolBarButtonIdentifier] = {
    if !FeatureManager.open(.moreFonts) || !FeatureManager.open(.mobileEditorKit) {
        return [.fixedWidth, .SansSerif, .Garamond, .Georgia, .TrebuchetMS, .Verdana, .Serif]
    }

    var array: [EditorToolBarButtonIdentifier] = [.System, .Arial, .ComicSansMS, .Garamond, .Georgia, .SanFrancisco, .SansSerif, .Serif, .Tahoma, .TimesNewRoman, .TrebuchetMS, .Verdana]
    if LanguageManager.currentLanguage == .zh_CN {
        array = [.System, .PingFangSC, .Arial, .ComicSansMS, .Garamond, .Georgia, .SanFrancisco, .SansSerif, .Serif, .Tahoma, .TimesNewRoman, .TrebuchetMS, .Verdana]
    } else if LanguageManager.currentLanguage == .zh_HK {
        array = [.System, .PingFangHK, .Arial, .ComicSansMS, .Garamond, .Georgia, .SanFrancisco, .SansSerif, .Serif, .Tahoma, .TimesNewRoman, .TrebuchetMS, .Verdana]
    } else if LanguageManager.currentLanguage == .zh_TW {
        array = [.System, .PingFangTC, .Arial, .ComicSansMS, .Garamond, .Georgia, .SanFrancisco, .SansSerif, .Serif, .Tahoma, .TimesNewRoman, .TrebuchetMS, .Verdana]
    } else if LanguageManager.currentLanguage == .ja_JP {
        array = [.System, .KakuGothic, .Mincho, .Arial, .ComicSansMS, .Garamond, .Georgia, .SanFrancisco, .SansSerif, .Serif, .Tahoma, .TimesNewRoman, .TrebuchetMS, .Verdana]
    }
    return array
}()

typealias ToolBarLineType = [String: [[EditorToolBarButtonIdentifier]]]

/// ToolBarLayoutMapping 布局
class ToolBarLayoutMapping {
    static let oneLineKey: String = "OneLine"
    static let kSingleLine: String = TextAttributionLayoutType.singleLine.rawValue
    static let kScrollableLine: String = TextAttributionLayoutType.scrollableLine.rawValue
    class func mailAttributeItems() -> [ToolBarLineType] {
        let subBius: [EditorToolBarButtonIdentifier] = [.bold, .italic, .underline, .strikethrough]
        let subH: [EditorToolBarButtonIdentifier] = [.fontSmall, .fontNormal, .fontLarge, .fontHuge]
        let subList: [EditorToolBarButtonIdentifier] = [.unorderedlist, .orderedlist]
        let subCode: [EditorToolBarButtonIdentifier] = [.codelist]
        let subQuote: [EditorToolBarButtonIdentifier] = [.blockquote]
        let subAlign: [EditorToolBarButtonIdentifier] = [.alignleft, .aligncenter, .alignright]
        let subSeparator: [EditorToolBarButtonIdentifier] = [.horizontalLine]

        let lineType1 = [kScrollableLine: [subH]]
        let lineType2 = [kSingleLine: [subBius]]
        let lineType3 = [kSingleLine: [subAlign, subList]]
//        let lineType4 = [kSingleLine: [subQuote, subAlign, subSeparator]]

        return [lineType1, lineType2, lineType3]
    }
}

/// EditorToolBarItemInfo
final class EditorToolBarItemInfo {
    var identifier: String
    var title: String?
    var image: UIImage?
    var value: String?
    var valueList: [String]?
    var isSelected: Bool = false
    var isEnable: Bool = true
    var jsMethod: String = ""
    var children: [EditorToolBarItemInfo]?

    /// 操作项数据初始化
    ///
    /// - Parameters:
    ///   - identifier: identifier
    ///   - json: 配置数据json数据
    init(identifier: String, json: [String: Any], jsMethod: String = "") {
        self.jsMethod = jsMethod
        self.identifier = identifier
        self.isSelected = json["selected"] as? Bool ?? false
        self.isEnable = json["enable"] as? Bool ?? true
        self.value = json["value"] as? String
        self.valueList = json["list"] as? [String]
        self.image = EditorToolBarItemInfo.loadImage(by: identifier)
        if let childrenInfos = json["children"] as? [[String: Any]] {
            children = [EditorToolBarItemInfo]()
            for childDict in childrenInfos {
                if let newId = childDict["id"] as? String {
                    let childItem = EditorToolBarItemInfo(identifier: newId, json: childDict, jsMethod: jsMethod)
                    self.children?.append(childItem)
                }
            }
        }
    }

    /// 操作项数据初始化
    ///
    /// - Parameter identifier: identifier
    init(identifier: String) {
        self.identifier = identifier
        self.image = EditorToolBarItemInfo.loadImage(by: identifier)
    }

    /// 获取对应的icon
    ///
    /// - Parameter identifier: button identifier
    /// - Returns: icon image
    class func loadImage(by identifier: String) -> UIImage? {
        guard let type = EditorToolBarButtonIdentifier(rawValue: identifier) else {
            return nil
        }

        let subPanelIcons: [EditorToolBarButtonIdentifier: UIImage] =
            [.bold: Resources.boldOutlined,
             .italic: Resources.italicOutlined,
             .underline: Resources.underlineOutlined,
             .strikethrough: I18n.image(named: "tb_att_strikethrough") ?? Resources.strikethroughOutlined,
             .unorderedlist: I18n.image(named: "tb_att_ul1") ?? Resources.disordeListOutlined,
             .orderedlist: I18n.image(named: "tb_att_ol1") ?? Resources.ordeListOutlined,
             .inlinecode: Resources.inlineViewOutlined,
             .codelist: Resources.codeOutlined,
             .blockquote: Resources.codeblockOutlined,
             .alignleft: Resources.leftAlignmentOutlined,
             .aligncenter: Resources.centerAlignmentOutlined,
             .alignright: Resources.rightAlignmentOutlined,
             .separator: Resources.separateOutlined,
             .horizontalLine: Resources.horizontalLineOutlined,
             .backBtn: Resources.backTabOutlined]

        let toolbarIcons: [EditorToolBarButtonIdentifier: UIImage] =
            [.attr: Resources.styleOutlined,
             .insertImage: Resources.imageOutlined,
             .at: I18n.image(named: "tb_at") ?? UIImage(),
             .comment: I18n.image(named: "tb_comment") ?? UIImage(),
             .undo: I18n.image(named: "tb_undo") ?? UIImage(),
             .redo: I18n.image(named: "tb_redo") ?? UIImage(),
             .indentLeft: I18n.image(named: "tb_indentLeft") ?? UIImage(),
             .indentRight: I18n.image(named: "tb_indentRight") ?? UIImage(),
             .signature: I18n.image(named: "tb_signature") ?? UIImage(),
             .calendar: I18n.image(named: "tb_calendar_new") ?? UIImage(),
             .attachment: UDIcon.attachmentOutlined,
                .inlineAI: Resources.inlineAI]
        
        if let image = subPanelIcons[type] ?? toolbarIcons[type] {
            if identifier == EditorToolBarButtonIdentifier.inlineAI.rawValue {
                return image
            }
            return image.withRenderingMode(.alwaysTemplate)
        }
        return nil
    }
}

enum EditorFontSize {
    static let fontSmall: Int = 12
    static let fontNormal: Int = 14
    static let fontLarge: Int = 18
    static let fontHuge: Int = 32
}
