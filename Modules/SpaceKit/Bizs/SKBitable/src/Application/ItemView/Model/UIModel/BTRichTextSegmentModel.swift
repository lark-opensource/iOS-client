//
//  BTTextFieldSegmentModel.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//  

import Foundation
import UIKit
import HandyJSON
import SKCommon
import SKResource
import SpaceInterface
import SKInfra

protocol BTIndivisibleBlockType {}

/// 对应前端的 `ISegment`
protocol BTBaseSegment {
    var type: BTSegmentType { get }
    var text: String { get }
}

/// 对应前端的 `ITextSegment`
protocol BTTextSegment: BTBaseSegment {
}

/// 对应前端的 `IMentionSegment`
protocol BTMentionSegment: BTBaseSegment {
    var link: String { get }
    var token: String { get }
    var mentionType: BTMentionSegmentType { get }
    var mentionNotify: Bool { get }
    var icon: BTMentionIconModel { get }
    var mentionId: String { get }
}

/// 对应前端的 `IHyperlinkSegment`
protocol BTURLSegment: BTBaseSegment {
    var visited: Bool { get }
    var link: String { get }
}

/// 对应前端的 `IDescriptionEmbedImageSegment`
protocol BTEmbeddedImageSegment: BTBaseSegment {
    var name: String { get }
    var link: String { get }
    var height: CGFloat { get }
    var width: CGFloat { get }
    var size: CGFloat { get }
    var attachmentToken: String { get }
    var mimeType: String { get }
    var mountPointType: String { get }
    var mountNodeToken: String { get }
    var extra: String { get }
}

enum BTTextEditType: String, HandyJSONEnum, SKFastDecodableEnum {
    case scan
}

/// 文本字段里面会有各种类型的元素，前端会把文本字段的内容拆分成一个个片段传过来，native 解析片段里的属性然后渲染成富文本
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTRichTextSegmentModel: HandyJSON, Hashable, SKFastDecodable,
                               BTBaseSegment, BTTextSegment, BTMentionSegment, BTURLSegment, BTEmbeddedImageSegment {

    static func == (lhs: BTRichTextSegmentModel, rhs: BTRichTextSegmentModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    /// 文本
    var type: BTSegmentType = .text
    var text: String = ""
    /// mention
    var token: String = ""
    var mentionId: String = ""
    var id: String? // 和mentionId不一样，该id作为mention时的唯一id
    var mentionType: BTMentionSegmentType = .unknown
    var mentionNotify: Bool = false
    var icon: BTMentionIconModel = BTMentionIconModel()
    /// 普通的超链接
    var visited: Bool = false
    var link: String = ""
    /// Drive 图片链接，对应前端的 `IDescriptionEmbedImageSegment`，抽了一些 AttachmentModel 的东西过来
    var name: String = "" // 图片展示名称
    var mimeType: String = ""
    var size: CGFloat = 0
    var height: CGFloat = 0
    var width: CGFloat = 0
    var attachmentToken: String = "" // 图片的 token
    var mountPointType: String = ""
    var mountNodeToken: String = ""
    var extra: String = ""
    var editType: BTTextEditType?

    static func deserialized(with dictionary: [String : Any]) -> BTRichTextSegmentModel {
        var model = BTRichTextSegmentModel()
        model.type <~ (dictionary, "type")
        model.text <~ (dictionary, "text")
        model.token <~ (dictionary, "token")
        model.mentionId <~ (dictionary, "mentionId")
        model.id <~ (dictionary, "id")
        model.mentionType <~ (dictionary, "mentionType")
        model.mentionNotify <~ (dictionary, "mentionNotify")
        model.icon <~ (dictionary, "icon")
        model.visited <~ (dictionary, "visited")
        model.link <~ (dictionary, "link")
        model.name <~ (dictionary, "name")
        model.mimeType <~ (dictionary, "mimeType")
        model.size <~ (dictionary, "size")
        model.height <~ (dictionary, "height")
        model.width <~ (dictionary, "width")
        model.attachmentToken <~ (dictionary, "attachmentToken")
        model.mountPointType <~ (dictionary, "mountPointType")
        model.mountNodeToken <~ (dictionary, "mountNodeToken")
        model.extra <~ (dictionary, "extra")
        model.editType <~ (dictionary, "editType")
        return model
    }
    
    func hash(into hasher: inout Hasher) {
        // 目前不会在链接浏览过后显示不同的颜色，所以先不 diff `visited` 属性
        hasher.combine(type)
        hasher.combine(text)
        hasher.combine(token)
        hasher.combine(mentionId)
        hasher.combine(mentionType)
        hasher.combine(mentionNotify)
        hasher.combine(icon)
        hasher.combine(link)
        hasher.combine(name)
        hasher.combine(mimeType)
        hasher.combine(size)
        hasher.combine(height)
        hasher.combine(width)
        hasher.combine(attachmentToken)
        hasher.combine(mountPointType)
        hasher.combine(mountNodeToken)
        hasher.combine(extra)
    }
}

/// 对应前端的 `SegmentType`
enum BTSegmentType: String, HandyJSONEnum, SKFastDecodableEnum {
    case text // 纯文本
    case mention // 人、文档、表格等
    case url // 其他链接，例如 https://www.baidu.com、google.com 等等
    case embeddedImage = "embed-image" // drive 图片链接
}

/// 对应前端的 `MentionType`
enum BTMentionSegmentType: Int, HandyJSONEnum, SKFastDecodableEnum {
    case user = 0
    case docs = 1
    case docx = 22
    case folder = 2
    case sheets = 3
    case sheetDoc = 4 // 不再使用
    case chat = 5
    case group = 6
    case block = 7
    case bitable = 8
    case table = 9
    case inlineBlock = 10
    case mindnote = 11
    case box = 12
    case slides = 30
    case wiki = 16
    case whiteboard = 38

    case unknown

    var landscapeEnabled: Bool {
        [.sheets, .bitable, .box, .docx, .mindnote, .wiki].contains(self)
    }
}

/// 前端传过来的 mention 类型对应的 model，会当作富文本 attribute
struct BTAtModel: Equatable, BTIndivisibleBlockType {
    static func == (lhs: BTAtModel, rhs: BTAtModel) -> Bool {
        if lhs.type == rhs.type, lhs.token == rhs.token, lhs.userID == rhs.userID, lhs.link == rhs.link {
            return true
        }
        return false
    }

    var type: BTMentionSegmentType = .user
    var token: String = ""
    var userID: String = ""
    var link: String = ""
    var mentionId: String = ""
}

/// 用户粘贴链接后智能转换成的 smartlink 对应的 model，会当作富文本 attribute
extension AtInfo: BTIndivisibleBlockType {}

/// 前端传过来的 embed-image 类型对应的 model，会当作富文本 attribute
struct BTEmbeddedImageModel: Equatable, BTIndivisibleBlockType {
    var text: String
    var name: String
    var link: String
    var height: CGFloat
    var width: CGFloat
    var size: CGFloat
    var attachmentToken: String
    var mimeType: String
    var mountPointType: String
    var mountNodeToken: String
    var extra: String
}

extension BTRichTextSegmentModel {

    static let linkAttributes = [AtInfo.attributedStringAtInfoKey,
                                 AtInfo.attributedStringURLKey,
                                 BTRichTextSegmentModel.attrStringBTAtInfoKey,
                                 BTRichTextSegmentModel.attrStringBTEmbeddedImageKey]

    static let attrStringBTAtInfoKey = NSAttributedString.Key(rawValue: "BTAtInfo")
    static let attrStringBTEmbeddedImageKey = NSAttributedString.Key(rawValue: "BTEmbeddedImage")
    static let attrStringBTAllEmbeddedImagesKey = NSAttributedString.Key(rawValue: "BTAllEmbeddedImages")

    var btAtInfo: BTAtModel {
        get {
            switch mentionType {
            case .user: return BTAtModel(type: .user, token: "", userID: token, link: link, mentionId: mentionId)
            default: return BTAtModel(type: mentionType, token: token, userID: "", link: link, mentionId: mentionId)
            }
        }
        set {
            self.mentionType = newValue.type
            self.mentionId = newValue.mentionId
            if newValue.type == .user {
                self.token = newValue.userID
            } else {
                self.token = newValue.token
            }
            self.link = newValue.link
        }
    }

    var btEmbeddedImageModel: BTEmbeddedImageModel {
        get {
            return BTEmbeddedImageModel(text: text,
                                        name: name,
                                        link: link,
                                        height: height,
                                        width: width,
                                        size: size,
                                        attachmentToken: attachmentToken,
                                        mimeType: mimeType,
                                        mountPointType: mountPointType,
                                        mountNodeToken: mountNodeToken,
                                        extra: extra)
        }
        set {
            self.text = newValue.text
            self.name = newValue.name
            self.link = newValue.link
            self.height = newValue.height
            self.width = newValue.width
            self.size = newValue.size
            self.attachmentToken = newValue.attachmentToken
            self.mimeType = newValue.mimeType
            self.mountPointType = newValue.mountPointType
            self.mountNodeToken = newValue.mountNodeToken
            self.extra = newValue.extra
        }
    }

    static func segmentsWithAttributedString(attrString: NSAttributedString) -> [BTRichTextSegmentModel] {
        var segments: [BTRichTextSegmentModel] = []

        /** 解释一下下面一堆 prev 的作用：
         下面调用 NSAttributedString 的 enumerateAttributes(in:options:using:) 接口时提供了 longestEffectiveRangeNotRequired 的 options，
         如果遍历一个云文档链接 "(NSTextAttachment) 黄桃的 Docs 文档"，这一整个字符串都有同一个 BTAtInfo 属性，但是闭包会调用多次：
         "[(NSTextAttachment)]"
         "[ ]"
         "[黄桃的]"
         "[ ]"
         "[Docs]"
         "[ ]"
         "[文档]"
         每个中括号代表一次调用，上述结果可能会再被细分。
         苹果这么做的原因是由于每个子串所拥有 attributes 字典确实是不完全一样的，有的可能没有 NSColor，NSFont 对于中西文也是不一样的。
         下面的各种 prev 就是为了检查是否相邻，如果同类就合并。
         */

        var prevRange = NSRange(location: 0, length: 0)
        var prevBTAtModel: BTAtModel? // web 端传入的云文档链接
        var prevAtModel: AtInfo? // 粘贴 URL 到 textView 解析出的云文档链接
        var prevImageModel: BTEmbeddedImageModel? // drive 图片附件
        attrString.enumerateAttributes(in: NSRange(location: 0, length: attrString.length), options: .longestEffectiveRangeNotRequired) { (attrs, range, _) in
            // 所有链接类型的 attribute key 见 BTRichTextSegmentModel.linkAttributes
            let btAtModel = attrs[BTRichTextSegmentModel.attrStringBTAtInfoKey] as? BTAtModel
            let imageModel = attrs[BTRichTextSegmentModel.attrStringBTEmbeddedImageKey] as? BTEmbeddedImageModel
            let urlModel = attrs[AtInfo.attributedStringURLKey] as? URL
            let atModel = attrs[AtInfo.attributedStringAtInfoKey] as? AtInfo

            var segment = BTRichTextSegmentModel()
            var isNeedReplaceLastOne = false

            var prevIsText = false

            if let type = segments.last?.type, type == .text {
                prevIsText = true
            }

            if let btAtModel = btAtModel {
                segment.type = .mention
                segment.text = filterIconUnicodeChar(attrString.attributedSubstring(from: range).string)
                segment.btAtInfo = btAtModel

                isNeedReplaceLastOne = (prevBTAtModel == btAtModel) && (prevRange.location + prevRange.length) == range.location && !prevIsText
                if isNeedReplaceLastOne {
                    if let prevText = segments.last?.text {
                        segment.text = "\(prevText)\(segment.text)"
                    }
                }
                prevBTAtModel = btAtModel
            } else if let imageModel = imageModel {
                segment.type = .embeddedImage
                segment.text = imageModel.text
                segment.name = imageModel.name
                segment.link = imageModel.link
                segment.height = imageModel.height
                segment.width = imageModel.width
                segment.size = imageModel.size
                segment.attachmentToken = imageModel.attachmentToken
                segment.mimeType = imageModel.mimeType
                segment.mountPointType = imageModel.mountPointType
                segment.mountNodeToken = imageModel.mountNodeToken
                segment.extra = imageModel.extra

                isNeedReplaceLastOne = (prevImageModel == imageModel) && (prevRange.location + prevRange.length) == range.location && !prevIsText
                if isNeedReplaceLastOne {
                    if let prevText = segments.last?.text {
                        segment.text = "\(prevText)\(segment.text)"
                    }
                }
                prevImageModel = imageModel
            } else if let urlModel = urlModel {
                segment.type = .url
                segment.text = filterIconUnicodeChar(attrString.attributedSubstring(from: range).string)
                segment.mentionType = .unknown
                segment.token = ""
                let link = urlModel.absoluteString
                segment.link = link.isValidEmail() ? "mailto:\(link)" : link
            } else if let atModel = atModel {
                segment.type = .mention
                segment.text = filterIconUnicodeChar(attrString.attributedSubstring(from: range).string)
                segment.mentionType = BTMentionSegmentType(rawValue: atModel.type.rawValue) ?? .unknown
                segment.token = atModel.token
                segment.link = atModel.href
                segment.id = atModel.uuid
                isNeedReplaceLastOne = (prevAtModel == atModel) && (prevRange.location + prevRange.length) == range.location && !prevIsText
                if isNeedReplaceLastOne {
                    if let prevText = segments.last?.text {
                        segment.text = "\(prevText)\(segment.text)"
                    }
                }
                prevAtModel = atModel
            } else {
                segment.text = filterIconUnicodeChar(attrString.attributedSubstring(from: range).string)
                if let prevSegment = segments.last, prevSegment.type == .text, (prevRange.location + prevRange.length) == range.location {
                    isNeedReplaceLastOne = true
                    let prevText = prevSegment.text
                    segment.text = "\(prevText)\(segment.text)"
                }
            }

            if isNeedReplaceLastOne {
                segments.removeLast()
            }
            segments.append(segment)

            prevRange = range
        }
        return segments
    }

    // https://bytedance.feishu.cn/docs/doccnsg495JbCR4o8SMe835dVuC#
    static func filterIconUnicodeChar(_ str: String) -> String {
        let iconUnicodeChar = "\u{fffc}" // NSTextAttachment.character
        return str.replacingOccurrences(of: iconUnicodeChar, with: "")
    }

    /// URL Field 相对于 textField 比较特殊，他最终留下的 segment 会有一个，且只有两种情况。一种是 url 格式，一种是 at 格式。
    /// - Parameters:
    ///   - segments: 协同过来的 segments 或者 从富文本中解析出来的 segments
    ///   - originalLink: 是否需要给 url 格式指定一个 link
    static func getRealSegmentsForURLField(from segments: [BTRichTextSegmentModel], originalLink: String = "") -> BTRichTextSegmentModel? {
        func validTextOrURLSegment(_ segment: BTRichTextSegmentModel) -> Bool {
            guard segment.type == .url || segment.type == .text else {
                return false
            }
            /// 判断 segment.text == " "，是因为 metionSegment 后面会自动添加一个 " "。
            if segment.text.isEmpty || segment.text == " " {
                return false
            }
            return true
        }
        if segments.contains(where: { validTextOrURLSegment($0) }) {
            var urlSegment = BTRichTextSegmentModel()
            urlSegment.type = .url
            urlSegment.text = segments.reduce("") { $0 + $1.text }
            let link = !originalLink.isEmpty ? originalLink : segments.first(where: { $0.type == .url })?.link ?? ""
            urlSegment.link = BTUtil.addHttpScheme(to: link)
            return urlSegment
        } else if let metionSegment = segments.first(where: { $0.type == .mention }) {
            return metionSegment
        } else {
            return nil
        }
    }
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTMentionIconModel: HandyJSON, Hashable, SKFastDecodable {
    static func == (lhs: BTMentionIconModel, rhs: BTMentionIconModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var type: SpaceEntry.IconType = .emoji
    var key: String = ""
    var fs_unit: String = ""
    
    static func deserialized(with dictionary: [String : Any]) -> BTMentionIconModel {
        var model = BTMentionIconModel()
        model.key <~ (dictionary, "key")
        model.fs_unit <~ (dictionary, "fs_unit")
        model.type <~ (dictionary, "type")
        return model
    }

    func hash(into hasher: inout Hasher) {
        // 目前不会在链接浏览过后显示不同的颜色，所以先不 diff `visited` 属性
        hasher.combine(type)
        hasher.combine(key)
        hasher.combine(fs_unit)
    }
}

extension SpaceEntry.IconType: SKFastDecodableEnum {}
