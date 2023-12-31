//
//  FontPreprocess.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2020/12/25.
//

import Foundation
import RustPB
import LarkModel
import LarkZoomable
import RichLabel

class RichTextFontPreProcessor {
    private let context: LDContext?
    private let originRichText: RichText
    private let flexParser: FlexStyleParser
    /**
     * 消息卡片中分隔符的style key
     */
    private let styleKeyPlaceHolderOne = "block_action_placeholder_1"

    /**
     * 消息卡片中换行符的style key
     */
    private let styleKeyPlaceHolderTwo = "block_action_placeholder_2"
    init(context: LDContext?, richText: RichText, flexParser: FlexStyleParser) {
        self.context = context
        self.originRichText = richText
        self.flexParser = flexParser
    }
    func parseStyle(style: [String: String], context: LDContext?, elementId: String? = nil) -> LDStyle {
        let ldStyle = LDStyle(context: context, elementId: elementId)
        flexParser.parse(style: ldStyle, map: style)
        ldStyle.styleValues = StyleParser.parse(style)
        return ldStyle
    }
    /// 自适应放大之后的richText
    //swiftlint:disable all
    func richTextAfterZoom() -> RichText {
        var resultRichText = originRichText
        guard let context = context,
              context.zoomAble() else {
            return originRichText
        }
        /// 处于正常模式或者缩小模式的时候不进行处理
        guard Zoom.currentZoom != .small1 && Zoom.currentZoom != .normal else {
            return originRichText
        }
        /// 找出所有Action的下面的Text，记录对应的elementId
        originRichText.elements.forEach { (_, element) in
            if element.tag == .button ||
                element.tag == .datepicker ||
                element.tag == .datetimepicker ||
                element.tag == .timepicker ||
                element.tag == .overflowmenu ||
                element.tag == .selectmenu {
                for childId in element.childIds where resultRichText.elements[childId]?.tag == .text {
                    context.recordButtonText(elementId: childId,
                                             parentElement: ElementContext(parentElement: element))
                }
            }
        }
        var adjustFontSize: [(RichTextElement, CGFloat)] = []
        for (pId, element) in originRichText.elements where element.tag == .p {
            guard let pElement = originRichText.elements[pId] else {
                return originRichText
            }
            var delimiterPlaceHolder: RichTextElement?
            var buttonsOneRow: [(String, RichTextElement)] = []
            var buttonCount: Int = 1
            for childId in element.childIds {
                /// 获取一列button的个数
                if let subElement = originRichText.elements[childId] {
                    /// 如果P标签下面的子标签是button
                    if subElement.tag == .button {
                        buttonsOneRow.append((childId, subElement))
                    } else if subElement.tag == .p {
                        if delimiterPlaceHolder == nil && subElement.styleKeys.contains(styleKeyPlaceHolderOne) {
                            /// 如果是分隔符
                            delimiterPlaceHolder = subElement
                        } else if subElement.styleKeys.contains(styleKeyPlaceHolderTwo) {
                            break
                        }
                    }
                }
            }
            buttonCount = max(buttonsOneRow.count, buttonCount)
            /// 获取P标签的最大宽度
            var maxCardWidth = context.cardAvailableMaxWidth
            let pElementStyle = context.wideCardMode ? pElement.wideStyle: pElement.style
            let pStyle = parseStyle(style: pElementStyle, context: context, elementId: pId)
            if pStyle.marginLeft.unit == .point && pStyle.marginLeft.value > 0 {
                maxCardWidth -= CGFloat(pStyle.marginLeft.value)
            }
            if pStyle.marginRight.unit == .point && pStyle.marginRight.value > 0 {
                maxCardWidth -= CGFloat(pStyle.marginRight.value)
            }
            /// LDRoot padding left right 12
            let ldrootPaddingLeft: CGFloat = 12.0
            let ldrootPaddingRight: CGFloat = 12.0
            maxCardWidth -= (ldrootPaddingLeft + ldrootPaddingRight)
            /// Ceell + P + button + Text 标签的线宽
            maxCardWidth -= 16
            /// 遍历P标签下面的子元素, 每个button单独计算最合适的字体
            for (buttonId, button) in buttonsOneRow {
                /// 取button的style
                let buttonElementStyle = context.wideCardMode ? button.wideStyle: button.style
                let buttonStyle = parseStyle(style: buttonElementStyle, context: context, elementId: buttonId)
                ///
                var buttonMarginLeft: CGFloat = 0
                var buttonMarginRight: CGFloat = 0
                var buttonPaddingLeft: CGFloat = 0
                var buttonPaddingRight: CGFloat = 0
                if buttonStyle.marginLeft.unit == .point && buttonStyle.marginLeft.value > 0 {
                    buttonMarginLeft = CGFloat(buttonStyle.marginLeft.value)
                }
                if buttonStyle.marginRight.unit == .point && buttonStyle.marginRight.value > 0 {
                    buttonMarginRight = CGFloat(buttonStyle.marginRight.value)
                }
                if buttonStyle.paddingLeft.unit == .point && buttonStyle.paddingLeft.value > 0 {
                    buttonPaddingLeft = CGFloat(buttonStyle.paddingLeft.value)
                }
                if buttonStyle.paddingRight.unit == .point && buttonStyle.paddingRight.value > 0 {
                    buttonPaddingRight = CGFloat(buttonStyle.paddingRight.value)
                }
                /// 取TextElement
                var tempTextElement: RichTextElement?
                var textId: String?
                for childId in button.childIds {
                    if let childElement = originRichText.elements[childId],
                       childElement.tag == .text {
                        tempTextElement = childElement
                        textId = childId
                        break
                    }
                }
                guard let textElement = tempTextElement else {
                    return originRichText
                }
                let textElementStyle = context.wideCardMode ? textElement.wideStyle: textElement.style
                let textStyle = parseStyle(style: textElementStyle, context: context, elementId: textId)
                if buttonCount == 2 {
                    if let placeHolder = delimiterPlaceHolder {
                        //读取分隔符的宽度
                        let placeHolderElementStyle = context.wideCardMode ? placeHolder.wideStyle: placeHolder.style
                        let placeHolderStyle = parseStyle(style: placeHolderElementStyle, context: context)
                        if placeHolderStyle.width.unit == .point && placeHolderStyle.width.value > 0 {
                            //宽度为具体数字
                            maxCardWidth -= CGFloat(placeHolderStyle.width.value)
                        } else if placeHolderStyle.width.unit == .percent && placeHolderStyle.width.value > 0 {
                            //宽度为百分比
                            maxCardWidth -= CGFloat(placeHolderStyle.width.value / 100.0) * maxCardWidth
                        }
                    }
                } else if buttonCount == 3 {
                    if let placeHolder = delimiterPlaceHolder {
                        //读取分隔符的宽度
                        let placeHolderElementStyle = context.wideCardMode ? placeHolder.wideStyle: placeHolder.style
                        let placeHolderStyle = parseStyle(style: placeHolderElementStyle, context: context)
                        if placeHolderStyle.width.unit == .point && placeHolderStyle.width.value > 0 {
                            //宽度为具体数字
                            maxCardWidth -= CGFloat(placeHolderStyle.width.value) * 2
                        } else if placeHolderStyle.width.unit == .percent && placeHolderStyle.width.value > 0 {
                            //宽度为百分比
                            maxCardWidth -= CGFloat(placeHolderStyle.width.value / 100.0) * maxCardWidth * 2
                        }
                    }
                }
                ///当前按钮文字的最大展示宽度
                maxCardWidth /= CGFloat(buttonCount)
                let availableWidth = maxCardWidth - (buttonMarginLeft +
                                                        buttonMarginRight +
                                                        buttonPaddingLeft +
                                                        buttonPaddingRight)
                /// 字体的原始尺寸
                let originFontSize = textStyle.originFontSize
                /// 字体的放大之后的尺寸
                let zoomFontSize = textStyle.fontSize
                /// 文字的原始大小
                let text = textElement.property.text.content
                /// 放大的字体必须比原始字体大
                if zoomFontSize <= originFontSize {
                    continue
                }
                /// 开放平台 非 Office 场景，暂时逃逸
                // swiftlint:disable ban_linebreak_byChar
                var attrbuties = attributedBuilder(style: textStyle, lineBreakMode: .byCharWrapping, context: context)
                // swiftlint:enable ban_linebreak_byChar
                var attributeString = NSAttributedString(string: text, attributes: attrbuties)
                var zoomTextSize = sizeWithText(attributeText: attributeString,
                                                maxWidth: context.cardAvailableMaxWidth,
                                                maxHeight: CGFloat.greatestFiniteMagnitude)
                var startFontSize = zoomFontSize
                /// 找出放大模式下面最合适的字体大 小
                while startFontSize >= originFontSize && zoomTextSize.width > availableWidth {
                    startFontSize -= 1.0
                    attrbuties.updateValue(textStyle.font.withSize(startFontSize),
                                           forKey: NSAttributedString.Key.font)
                    attributeString = NSAttributedString(string: text, attributes: attrbuties)
                    zoomTextSize = sizeWithText(attributeText: attributeString,
                                                    maxWidth: context.cardAvailableMaxWidth,
                                                    maxHeight: CGFloat.greatestFiniteMagnitude)
                }
                let zoomScale = zoomFontSize / originFontSize
                /// 这个得到的fontSize最后还是会进行放大，算出原始的大小
                let originScaleSize = floor(originFontSize / zoomScale)
                let zoomScaleSize = floor(startFontSize / zoomScale)
                let maxSize = max(originScaleSize, zoomScaleSize)
                adjustFontSize.append((textElement, maxSize))
            }
        }
        /// 找到最小的字体
        if let minFontSize = adjustFontSize.min(by: {(left, right) -> Bool in
            return left.1 < right.1
        }) {
            /// 更新button的最小字体
            for (_, element) in originRichText.elements where element.tag == .p {
                for subId in element.childIds {
                    if let subElement = originRichText.elements[subId], subElement.tag == .button {
                        for subSubId in subElement.childIds {
                            if let textNode = originRichText.elements[subSubId], textNode.tag == .text {
                                let fontSizeKey = "fontSize"
                                if context.wideCardMode {
                                    var originStyle = textNode.wideStyle
                                    originStyle[fontSizeKey] = "\(minFontSize.1)"
                                    resultRichText.elements[subSubId]?.wideStyle = originStyle
                                } else {
                                    var originStyle = textNode.style
                                    originStyle[fontSizeKey] = "\(minFontSize.1)"
                                    resultRichText.elements[subSubId]?.style = originStyle
                                }
                            }
                        }
                    }
                }
            }
        }
        return resultRichText
    }
    //swiftlint:enable all
    /// 计算text需要的size
    private func sizeWithText(attributeText: NSAttributedString,
                              maxWidth: CGFloat,
                              maxHeight: CGFloat) -> CGSize {
        let layoutEngine = LKTextLayoutEngineImpl()
        layoutEngine.attributedText = attributeText
        let size = layoutEngine.layout(size: CGSize(width: maxWidth, height: maxHeight))
        return size
    }
}
