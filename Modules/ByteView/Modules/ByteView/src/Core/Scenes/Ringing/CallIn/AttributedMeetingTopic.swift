//
//  AttributedMeetingTopic.swift
//  ByteView
//
//  Created by ByteDance on 2023/8/17.
//

import Foundation
import UIKit
import RichLabel


struct AttributedMeetingTopic {
    let attributedText: NSMutableAttributedString
    let outOfRangeText: NSMutableAttributedString

    init(topic: String, meetingTagType: MeetingTagType) {
        let (attributedText, outOfRangeText) = Self.buildAttributeTitle(topic: topic, meetingTagType: meetingTagType)
        self.attributedText = attributedText
        self.outOfRangeText = outOfRangeText
    }

    func height(width: CGFloat) -> CGFloat {
        Self.attributeHeight(attributeString: self.attributedText, width: width)
    }

    private static func buildAttributeTitle(topic: String, meetingTagType: MeetingTagType) -> (NSMutableAttributedString, NSMutableAttributedString) {
        let textColor = UIColor.ud.textTitle
        let font = UIFont.systemFont(ofSize: 17, weight: .medium)
        let attributedString = NSMutableAttributedString(string: topic)

        // disable-lint: magic number
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 22.0
        style.maximumLineHeight = 22.0
        style.lineSpacing = 1
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        // enable-lint: magic number

        attributedString.addAttributes([.foregroundColor: textColor, .font: font, .paragraphStyle: style], range: NSRange(location: 0, length: NSString(format: "%@", topic).length))
        let outOfRangeText = NSMutableAttributedString(string: "...", attributes: [.foregroundColor: textColor,
                                                                                   .font: font,
                                                                                   .backgroundColor: UIColor.clear])
        if let tagText = meetingTagType.text {
            let rect = NSString(string: tagText)
                .boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 18),
                              options: [.usesLineFragmentOrigin, .usesFontLeading],
                              attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium)],
                              context: nil)
            let tagWidth = rect.width + 4 * 2
            let tagAttachment = LKAsyncAttachment(viewProvider: {
                let tagLabel = PaddingLabel()
                tagLabel.text = tagText
                tagLabel.textAlignment = .center
                tagLabel.textInsets = UIEdgeInsets(top: 0.0, left: 4, bottom: 0.0, right: 4)
                tagLabel.font = .systemFont(ofSize: 12, weight: .medium)
                tagLabel.textColor = .ud.udtokenTagTextSBlue
                tagLabel.backgroundColor = .ud.udtokenTagBgBlue
                tagLabel.layer.cornerRadius = 4
                tagLabel.layer.masksToBounds = true
                return tagLabel
            }, size: CGSize(width: tagWidth, height: 18))
            tagAttachment.verticalAlignment = .middle
            tagAttachment.fontAscent = font.ascender
            tagAttachment.fontDescent = font.descender
            tagAttachment.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
            let tagAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                             attributes: [LKAttachmentAttributeName: tagAttachment])
            attributedString.append(tagAttr)
            outOfRangeText.append(tagAttr)
            return (attributedString, outOfRangeText)
        } else {
            return (attributedString, outOfRangeText)
        }
    }

    private static func attributeHeight(attributeString: NSAttributedString, width: CGFloat) -> CGFloat {
        let textParser = LKTextParserImpl()
        textParser.originAttrString = attributeString
        textParser.parse()
        let layoutEngine = LKTextLayoutEngineImpl()
        layoutEngine.attributedText = textParser.renderAttrString
        layoutEngine.preferMaxWidth = width
        layoutEngine.numberOfLines = 2
        let topicSize = layoutEngine.layout(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return topicSize.height
    }
}
