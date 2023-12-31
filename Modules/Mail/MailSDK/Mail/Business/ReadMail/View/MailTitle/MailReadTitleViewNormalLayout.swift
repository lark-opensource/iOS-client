//
//  MailReadTitleViewLayout.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/5/13.
//

import Foundation

struct LabelDisplayInfo: Equatable {
    let labelName: String
    let isLTR: Bool
    let textColor: UIColor
    let bgColor: UIColor
    let frame: CGRect
}

struct MailReadTitleViewNormalLayout {
    /// 计算获得view相关尺寸
    static func calcViewSizeAndLabelsFrame(config: MailReadTitleViewConfig,
                                           attributedString: NSAttributedString?,
                                           containerWidth: CGFloat) -> MailReadTitleView.TitleViewSizeInfo {
        var translatedInfo = config.translatedInfo
        if let translatedTitle = translatedInfo?.translatedTitle {
            translatedInfo?.translatedTitle = translatedTitle.components(separatedBy: .newlines).joined(separator: " ")
        }

        let titleLabelInsets = MailReadTitleView.titleLabelInsets()
        let textContainerSize = CGSize(width: containerWidth - titleLabelInsets.left - titleLabelInsets.right, height: .greatestFiniteMagnitude)
        var textContentRect = (config.title as NSString)
            .boundingRect(with: textContainerSize,
                          options: .usesLineFragmentOrigin,
                          attributes: MailReadTitleView.titleAttributes(MailReadTitleView.getTitleColor(config.title)),
                          context: nil)
        textContentRect = CGRect(x: titleLabelInsets.left, y: titleLabelInsets.top, width: textContainerSize.width, height: textContentRect.height)
        let attrs = attributedString ?? MailReadTitleView.titleAttributedString(title: config.title,
                                                                                translatedInfo: config.translatedInfo)
        let charRect = boundingRectForLastCharInString(attributedString: attrs,
                                                       textContainerWidth: textContentRect.size.width) ?? .zero

        //layout labels
        let filterLabels = MailMessageListLabelsFilter.filterLabels(config.labels,
                                                                    atLabelId: config.fromLabel,
                                                                    permission: .none)
        let labelInfos = calcLabelFrames(lastCharRect: charRect,
                                         textContainerWidth: textContainerSize.width,
                                         textContentRect: textContentRect,
                                         filteredLabels: filterLabels,
                                         isExternal: config.isExternal,
                                         newline: !(config.translatedInfo?.onlyTranslation ?? true)) // start a new line only when both original and translated subjects are shown
        let posMaxY = labelInfos.last?.frame.maxY ?? textContentRect.maxY
        let height = ceil(posMaxY + titleLabelInsets.bottom)
        let desiredSize = CGSize(width: textContainerSize.width, height: height)

        return (desiredSize, textContentRect.height, labelInfos)
    }


    ///计算labels布局frames
    private static func calcLabelFrames(lastCharRect: CGRect,
                                        textContainerWidth: CGFloat,
                                        textContentRect: CGRect,
                                        filteredLabels: [MailClientLabel],
                                        isExternal: Bool,
                                        newline: Bool) -> [LabelDisplayInfo] {
        // 添加uilabel的x,y偏移
        let lastCharRect = CGRect(x: textContentRect.minX + lastCharRect.minX,
                                  y: textContentRect.minY + lastCharRect.minY, width: lastCharRect.width, height: lastCharRect.height)
        let padding: CGFloat = 4
        var posMinX = lastCharRect.maxX + padding
        var posCenterY = lastCharRect.center.y

        var labelInfos = [LabelDisplayInfo]()

        typealias LabelDisplaying = (labelName: String, isLTR: Bool, textColor: UIColor, bgColor: UIColor)
        var displyLabels: [LabelDisplaying] = filteredLabels.map({($0.displayLongName,
                                                                   $0.parentID.isEmpty,
                                                                   UIColor.mail.argb($0.displayFontColor),
                                                                   UIColor.mail.argb($0.displayBgColor))})
        if isExternal {
            // 添加外部标签
            let externalLabel = (BundleI18n.MailSDK.Mail_SecurityWarning_External,
                                 false, UIColor.ud.udtokenTagTextSBlue, UIColor.ud.udtokenTagBgBlue)
            displyLabels.insert(externalLabel, at: 0)
        }

        var newline = newline
        for label in displyLabels {
            let labelName = label.labelName
            let tagSize = MailReadTag.sizeThatFit(text: labelName, isLTR: label.isLTR)
            // tag最大宽度为label宽度
            let tagWidth = min(tagSize.width + 1, textContainerWidth)
            let tagHeight = tagSize.height

            // 判断label当前行是否有足够的位置，有的话，继续放，没有的话下一行
            let remainWidth = textContainerWidth - posMinX
            if newline || remainWidth < tagWidth {
                posMinX = textContentRect.minX
                posCenterY = posCenterY + lastCharRect.height
                newline = false
            }
            let tagFrame = CGRect(x: posMinX, y: posCenterY - (tagHeight / 2), width: tagWidth, height: tagHeight)
            let labelInfo = LabelDisplayInfo(labelName: labelName, isLTR: label.isLTR, textColor: label.textColor, bgColor: label.bgColor, frame: tagFrame)
            labelInfos.append(labelInfo)
            posMinX = posMinX + tagWidth + padding
        }
        return labelInfos
    }

    ///计算string中最后一个字符的frame
    static private func boundingRectForLastCharInString(attributedString: NSAttributedString, textContainerWidth: CGFloat) -> CGRect? {
        let string = attributedString.string
        guard let lastChar = string.last,
              let range = string.nsRange(of: String(lastChar), options: .backwards, range: nil, locale: nil) else {
            return nil
        }
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: textContainerWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}
