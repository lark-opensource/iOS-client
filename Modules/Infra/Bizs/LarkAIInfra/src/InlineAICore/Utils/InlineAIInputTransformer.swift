//
//  InlineAiInputTransformer.swift
//  LarkInlineAI
//
//  Created by liujinwei on 2023/6/14.
//  


import Foundation
import UniverseDesignColor
import LarkBaseKeyboard
import LarkLocalizations

final public class InlineAiInputTransformer {
    
    struct ParamInfo: Equatable {
        var name: String
        var nameLength: Int
        var placeholder: String
        var defaultValue: String

        static func ==(lhs: ParamInfo, rhs: ParamInfo) -> Bool {
            return lhs.name == rhs.name
        }

        func toString() -> String? {
            let variables = [
                "name": name,
                "nameLength": "\(nameLength)",
                "placeholder": placeholder,
                "defaultValue": defaultValue
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: variables, options: []) {
                return String(data: jsonData, encoding: .utf8)
            }
            return nil
        }

        static func fromString(_ string: String) -> ParamInfo? {
            if let jsonData = string.data(using: .utf8),
               let variables = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: String],
               let name = variables["name"],
               let nameLength = Int(variables["nameLength"] ?? ""),
               let placeholder = variables["placeholder"],
               let defaultValue = variables["defaultValue"] {
                return ParamInfo(name: name, nameLength: nameLength, placeholder: placeholder, defaultValue: defaultValue)
            }
            return nil
        }
    }
    
    typealias Cons = QuickActionAttributeUtils.Cons
    
    ///获取输入框内所有url信息，string为`文档标题`
    public static func getAllUrl(from attrStr: NSAttributedString) -> [(String, URL)] {
        var urls: [(String, URL)] = []
        attrStr.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: attrStr.length), options: []) { (info, range, _) in
            if let linkInfo = info as? LinkTransformInfo {
                let title = attrStr.attributedSubstring(from: range).string
                urls.append((title, linkInfo.url))
            }
        }
        return urls
    }
    
    public static func parseParamContents(attrStr: NSAttributedString) -> [InlineAIPanelModel.ParamContentComponent] {
        var list = [InlineAIPanelModel.ParamContentComponent]()
        let range = NSRange(location: 0, length: attrStr.length)
        attrStr.enumerateAttributes(in: range, options: []) { (attributes, subRange, _) in
            let displayedText = attrStr.attributedSubstring(from: subRange).string // 肉眼见到的文本内容
            if let info = attributes[AtTransformer.UserIdAttributedKey] as? LarkBaseKeyboard.AtChatterInfo {
                if displayedText == "@" {
                    // @符号也会带有attr需要手动排除
                } else {
                    let name = info.name
                    let userID = info.id
                    list.append(.mention(.user(name: name, userID: userID)))
                }
            } else if let info = attributes[LinkTransformer.LinkAttributedKey] as? LinkTransformInfo {
                if displayedText == "\u{fffc}" {
                    // 文档标题前的特殊字符需要手动排除
                } else {
                    let title = displayedText
                    let url = info.url
                    // 修复中英文富文本比如"SpaceKit-iOS 日志排查手册" 被系统拆分为两部分返回问题
                    if case let .mention(docInfo) = list.last,
                       case let .doc(preTitle, preUrl) = docInfo,
                       preUrl.absoluteString == url.absoluteString,
                       preTitle != title {
                        list.removeLast()
                        list.append(.mention(.doc(title: preTitle + title, url: url)))
                    } else {
                        list.append(.mention(.doc(title: title, url: url)))
                    }
                }
            } else {
                list.append(.plainText(displayedText))
            }
        }
        return list
    }
    
    ///用于直接调用becomeFirstResponder获取焦点场景，光标优先落在第一个placeHolder内
    public static func findPreferredSelectedRange(for attr: NSAttributedString) -> NSRange {
        var preferredSelectedRange = NSRange(location: attr.length, length: 0)
        attr.enumerateAttribute(.paramPlaceholderKey, in: attr.fullRange) { value, range, stop in
            if value != nil {
                preferredSelectedRange.location = range.location
                stop.pointee = true
            }
        }
        return preferredSelectedRange
    }
    
    public static func transformContentToString(quickAction: InlineAIPanelModel.QuickAction,
                                                attributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        //构建快捷指令
        let content = NSMutableAttributedString()
        
        //快捷指令名称
        let title = NSMutableAttributedString(string: quickAction.displayName + Cons.periodMark, attributes: attributes)
        title.addAttribute(.titleKey, value: quickAction.displayName)
        title.setBoldFont()
        content.append(title)
        
        for param in quickAction.paramDetails {
            
            let paramString = NSMutableAttributedString()
            
            // 参数 Title
            let paramTitleString = NSMutableAttributedString(string: param.name + Cons.colonMark, attributes: attributes)
            paramTitleString.addAttribute(.paramTitleKey, value: param.key)
            paramTitleString.setBoldFont()
            paramString.append(paramTitleString)

            
            let defaultContent = param.content ?? ""
            let placeHolder = param.placeHolder ?? ""
            // placeHolder
            if !defaultContent.isEmpty {
                // 如果有默认值，填充默认值
                var defaultContentString = NSMutableAttributedString(string: defaultContent, attributes: attributes)
                if let richContent = param.richContent?.value {
                    defaultContentString = NSMutableAttributedString(attributedString: richContent)
                }
                defaultContentString.addAttribute(.paramContentKey, value: param.key)
                paramString.append(defaultContentString)
            } else {
                let placeholderString = NSMutableAttributedString(string: placeHolder, attributes: attributes)
                placeholderString.addAttributes([.paramPlaceholderKey: param.key, .foregroundColor: Cons.placeholderColor])
                paramString.append(placeholderString)
            }
            //参数最后的空格，作为和其他参数的分割
            let endString = NSMutableAttributedString(string: Cons.dividerMark, attributes: attributes)
            endString.addAttribute(.dividerKey, value: param.key)
            paramString.append(endString)

            //Param整体添加paramKey
            paramString.addAttribute(.paramKey, value: ParamInfo(
                name: param.key,
                nameLength: paramTitleString.length,
                placeholder: placeHolder,
                defaultValue: defaultContent
            ).toString() ?? "")
            
            content.append(paramString)
        }
        return content
    }
}

