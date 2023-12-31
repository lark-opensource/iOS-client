//
//  MailReadTitleViewCoverTitleLayout.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/5/23.
//

import Foundation

struct MailReadTitleViewCoverTitleLayout {
    static let labelHorizonInset: CGFloat = 8
    static let labelVerticalInset: CGFloat = 12

    /// 计算封面情况下的label布局
    static private func calcLabelFrames(textContainerWidth: CGFloat,
                                        coverRect: CGRect,
                                        filteredLabels: [MailClientLabel],
                                        isExternal: Bool) -> [LabelDisplayInfo] {
        let padding: CGFloat = 4
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
        var initHeight: CGFloat = 0
        if let temp = displyLabels.first {
            initHeight = MailReadTag.sizeThatFit(text: temp.labelName, isLTR: temp.isLTR).height
        }

        var posMinX = labelHorizonInset
        var posCenterY = coverRect.bottom + labelVerticalInset + initHeight / 2

        for label in displyLabels {
            let labelName = label.labelName
            let tagSize = MailReadTag.sizeThatFit(text: labelName, isLTR: label.isLTR)
            // tag最大宽度为label宽度
            let tagWidth = min(tagSize.width + 1, textContainerWidth - 2 * labelHorizonInset)
            let tagHeight = tagSize.height

            // 判断label当前行是否有足够的位置，有的话，继续放，没有的话下一行
            let remainWidth = textContainerWidth - posMinX - labelHorizonInset
            if remainWidth < tagWidth {
                posMinX = labelHorizonInset
                posCenterY = posCenterY + tagHeight + 6
            }
            let tagFrame = CGRect(x: posMinX, y: posCenterY - (tagHeight / 2), width: tagWidth, height: tagHeight)
            let labelInfo = LabelDisplayInfo(labelName: labelName, isLTR: label.isLTR, textColor: label.textColor, bgColor: label.bgColor, frame: tagFrame)
            labelInfos.append(labelInfo)
            posMinX = posMinX + tagWidth + padding
        }
        return labelInfos
    }

    static func calcViewSizeAndLabelsFrame(config: MailReadTitleViewConfig,
                                           attributedString: NSAttributedString?,
                                           containerWidth: CGFloat) -> MailReadTitleView.TitleViewSizeInfo {
        var translatedInfo = config.translatedInfo
        if let translatedTitle = translatedInfo?.translatedTitle {
            translatedInfo?.translatedTitle = translatedTitle.components(separatedBy: .newlines).joined(separator: " ")
        }
        let textContainerSize = CGSize(width: containerWidth, height: .greatestFiniteMagnitude)
        let (text, subText, _) = MailReadTitleView.coverTitleAttributedString(title: config.title,
                                                                           translatedInfo: config.translatedInfo)
        let coverSize = MailCoverDisplayView.calcPreferredSize(width: containerWidth, text: text, subText: subText)
        let coverRect = CGRect(x: 0, y: 0, width: coverSize.width, height: coverSize.height)

        //layout labels
        let filterLabels = MailMessageListLabelsFilter.filterLabels(config.labels,
                                                                    atLabelId: config.fromLabel,
                                                                    permission: .none)
        let textContainerWidth = textContainerSize.width
        let labelInfos = calcLabelFrames(textContainerWidth: textContainerWidth,
                                         coverRect: coverRect,
                                         filteredLabels: filterLabels,
                                         isExternal: config.isExternal)
        let posMaxY = labelInfos.last?.frame.maxY ?? coverRect.maxY
        let height = ceil(posMaxY + labelVerticalInset)
        let desiredSize = CGSize(width: textContainerSize.width, height: height)
        return (desiredSize, coverSize.height, labelInfos)
    }
}
