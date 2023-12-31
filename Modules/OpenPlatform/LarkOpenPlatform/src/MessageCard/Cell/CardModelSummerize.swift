//
//  CardModelSummerize.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/12/10.
//

import Foundation
import LarkMessageBase
import LarkMessageCore
import LarkModel
import LarkCore
import LarkSDKInterface
import LKCommonsLogging
import NewLarkDynamic
import LarkRichTextCore
import RustPB
import LarkFeatureGating

class CardModelSummerizeFactory: MetaModelSummerizeFactory {
    static let spaceStr = " "
    static let colonStr = ": "
    static let newlineStr = "\n"
    static let logger = Logger.log(CardModelSummerizeFactory.self,
                                   category: "Module.Openplatform.CardModelSummerizeFactory")
    required public init() {
        CardModelSummerizeFactory.logger.info("CardModelSummerizeFactory: init start")
        super.init()
    }
    
    static let richTextIgnoreTags: [RustPB.Basic_V1_RichTextElement.Tag] = [.button, .img, .selectmenu, .datepicker, .datetimepicker, .timepicker, .overflowmenu]
    /// 只支持Card类型
    override func canHandle(_ message: Message) -> Bool {
        return message.type == .card
    }
    /// 支持Card类型提取摘要信息，与翻译反馈的原文实现保持一致MessageTranslateFeedbackInputView.parseMessageContent
    override func getSummerize(message: Message,
                               chatterName: String,
                               fontColor: UIColor,
                               urlPreviewProvider: URLPreviewProvider? = nil) -> NSAttributedString? {
        let defautAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: fontColor
        ]

        let attrStr = chatterName.isEmpty ? NSMutableAttributedString() : NSMutableAttributedString(string: chatterName + CardModelSummerizeFactory.colonStr, attributes: defautAttributes)

        if let cardContent = message.content as? CardContent {
            let lynxcardRenderFG = LarkFeatureGating.shared.getFeatureBoolValue(for: "lynxcard.client.render.enable")
            if let summary = MessageSummarizeUtil.getMesssageCardSummary(cardContent, lynxcardRenderFG: lynxcardRenderFG) {
                //使用JsonCard服务端摘要
                attrStr.append(NSAttributedString(string: summary, attributes: defautAttributes))
            } else {
                //使用richtext摘要
                /// 如果存在标题，添加标题
                if var titleText = cardContent.header.getTitle() {
                    if cardContent.header.hasSubtitle {
                        titleText +=  (CardModelSummerizeFactory.spaceStr + cardContent.header.subtitle)
                    }
                    attrStr.append(NSAttributedString(string: titleText + CardModelSummerizeFactory.spaceStr, attributes: defautAttributes))
                }
                /// 去掉图片和媒体标签的描述
                let fixRichText = cardContent.richText.lc.convertText(tags: [.img, .media])
                /// 普通文本提取
                var messageCardSummerizeOpts = defaultRichTextSummerizeOpts
                messageCardSummerizeOpts[.button] = {option -> [String] in
                    return option.results
                }
                let stringArray = fixRichText.lc.walker(options: messageCardSummerizeOpts)
                var resultText = stringArray.joined(separator: "")
                /// 去掉头尾的换行，中间的连续空格
                resultText = resultText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .opPregReplace(pattern: "\n+| +|\r+", target: " ")
                attrStr.append(NSAttributedString(string: resultText, attributes: defautAttributes))
            }
            return attrStr
        }
        CardModelSummerizeFactory.logger.warn("CardModelSummerizeFactory: getSummerize cardContent is nil")
        return nil
    }

    public  func getCopySummerize(message: Message,context: LDContext) -> String {
        var copyStr = ""
        guard let cardContent = message.content as? CardContent,
               cardContent.type == .text else {
             return copyStr
        }
        /// 如果存在标题，添加标题
        if var titleText = cardContent.header.getTitle() {
            if cardContent.header.hasSubtitle {
                titleText +=  (CardModelSummerizeFactory.newlineStr + cardContent.header.subtitle)
            }
            copyStr += (titleText + CardModelSummerizeFactory.newlineStr)
        }
        /// 普通文本提取
        var copyRichTextSummerizeOpts = defaultRichTextSummerizeOpts
        for tag in CardModelSummerizeFactory.richTextIgnoreTags {
            copyRichTextSummerizeOpts[tag] = { option -> [String] in
                return []
            }
        }
        copyRichTextSummerizeOpts[.time] = {option -> [String] in
            var timeStr = getFormatTime(formatType: option.element.property.time.formatType,
                                        timestamp: option.element.property.time.millisecondSince1970,
                                                  translateLocale: nil,
                                                  context: context) ?? ""
            return [timeStr]
        }
        copyRichTextSummerizeOpts[.textablearea] = { option -> [String] in
            return [option.results.joined()]
        }
        let stringArray = cardContent.richText.lc.walker( options: copyRichTextSummerizeOpts)
        var resultText = stringArray.joined(separator:  CardModelSummerizeFactory.newlineStr)
        copyStr += resultText
        return copyStr
    }
}

extension String {
    /// 使用正则表达式替换
    func opPregReplace(pattern: String, target: String,
                       options: NSRegularExpression.Options = []) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            return regex.stringByReplacingMatches(in: self, options: [],
                                                  range: NSMakeRange(0, self.count),
                                                  withTemplate: target)
        } catch {
            /// 因为本次业务中涉及到的正则表达式pattern是固定的不会抛出错误，所以这里不监控错误
            CardModelSummerizeFactory.logger.error("opPregReplace \(pattern) result error: ",
                                                   error: error)
            return target
        }
    }
}
