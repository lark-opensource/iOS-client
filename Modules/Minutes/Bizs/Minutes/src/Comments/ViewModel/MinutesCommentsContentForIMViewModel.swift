//
//  MinutesCommentsContentForIMViewModel.swift
//  Minutes
//
//  Created by ByteDance on 2023/10/25.
//

import Foundation
import YYText
import UniverseDesignColor
import LarkContainer
import LarkAccountInterface
import LarkEmotion
import UniverseDesignIcon
import MinutesNetwork

class MinutesCommentsContentForIMViewModel : MinutesCommentsContentViewModel {
    private lazy var attributedTextForIM: NSMutableAttributedString = {
        guard let contents = self.contentForIM else { return NSMutableAttributedString() }
        return getAttributedTextForIM(content: contents, maxWidth: contentWidth, height: MinutesCommentsContentCell.LayoutContext.contentLineHeight, font: MinutesCommentsContentCell.LayoutContext.font, color: UIColor.ud.textTitle)
    }()
    
    private lazy var originalAttributedTextForIM: NSMutableAttributedString? = {
        guard let contents = self.originalContentForIM else { return nil }
        return getAttributedTextForIM(content: contents, maxWidth: contentWidth, height: MinutesCommentsContentCell.LayoutContext.contentLineHeight, font: MinutesCommentsContentCell.LayoutContext.originalFont, color: UIColor.ud.textPlaceholder)
    }()
    
    private func getContentByItem(item: ContentForIMItem, foregroundColor: UIColor, font: UIFont)  -> NSMutableAttributedString {
        switch item.contentType {
        case "link":
            let linkAttrString = NSMutableAttributedString(string: item.content, attributes: [.foregroundColor: foregroundColor, .font: font])
            linkAttrString.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: NSRange(location: 0,length: item.content.count))
            let range = NSRange(location: 0, length: item.content.count)
            linkAttrString.yy_setTextHighlight(range, color: nil, backgroundColor: nil) { [weak self] (_, _, _, _) in
                if let href = item.attr?.href {
                    self?.delegate?.didSelectUrl(url: href)
                }
            }
            return linkAttrString
        case "docs":
            let docsAttrString = NSMutableAttributedString()
            let iconSize = CGSize(width: 16, height: 16)
            let ironImageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: iconSize.width, height: iconSize.height))
            ironImageView.image = UDIcon.getIconByKey(.fileLinkOtherfileOutlined, iconColor: UIColor.ud.colorfulBlue, size: iconSize)
            let attrStr = NSMutableAttributedString.yy_attachmentString(withContent: ironImageView, contentMode: .scaleAspectFit, attachmentSize: iconSize, alignTo: font, alignment: YYTextVerticalAlignment.center)
            docsAttrString.append(attrStr)
            let contentAttrString = NSMutableAttributedString(string: item.content, attributes: [.foregroundColor: foregroundColor, .font: font])
            contentAttrString.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: NSRange(location: 0,length: item.content.count))
            let range = NSRange(location: 0, length: item.content.count)
            contentAttrString.yy_setTextHighlight(range, color: nil, backgroundColor: nil) { [weak self] (_, _, _, _) in
                if let href = item.attr?.href {
                    self?.delegate?.didSelectUrl(url: href)
                }
            }
            docsAttrString.append(creatEmptyAttributeString(width: 2))
            docsAttrString.append(contentAttrString)
            docsAttrString.append(creatEmptyAttributeString(width: 2))
            return docsAttrString
        case "at":
            let atAttrString = NSMutableAttributedString(string: item.content, attributes: [.foregroundColor: foregroundColor, .font: font])
            atAttrString.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: NSRange(location: 0,length: item.content.count))
            atAttrString.yy_setTextHighlight(NSRange(location: 0, length: item.content.count), color: nil, backgroundColor: nil) { [weak self] (_, _, _, _) in
                if let token = item.attr?.token {
                    self?.delegate?.didSelectUser(userId: token)
                }
            }
            return atAttrString
        case "emoji":
            let emojiAttrStr = NSMutableAttributedString()
            guard let key = item.attr?.key else { return emojiAttrStr }
            if let icon = EmotionResouce.shared.imageBy(key: key) {
                let fontSize = font.pointSize
                if let attrStr = NSMutableAttributedString.yy_attachmentString(withEmojiImage: icon, fontSize: fontSize) {
                    emojiAttrStr.append(creatEmptyAttributeString(width: 2))
                    emojiAttrStr.append(attrStr)
                    emojiAttrStr.append(creatEmptyAttributeString(width: 2))
                } else {
                    emojiAttrStr.append(NSAttributedString(string: key, attributes: [.foregroundColor: foregroundColor, .font: font]))
                }
            } else {
                emojiAttrStr.append(NSAttributedString(string: key, attributes: [.foregroundColor: foregroundColor, .font: font]))
            }
            return emojiAttrStr
        default:
            return NSMutableAttributedString(string: item.content, attributes: [.foregroundColor: foregroundColor, .font: font])
        }
    }
    
    private func getAttributedTextForIM(content: [ContentForIMItem], maxWidth: CGFloat, height: CGFloat, font: UIFont, color: UIColor) -> NSMutableAttributedString {
        if content.isEmpty {
            return NSMutableAttributedString()
        }
        let attributedText = NSMutableAttributedString()
        for item in content {
            attributedText.append(getContentByItem(item: item, foregroundColor: color, font: font))
        }
        return attributedText
    }
    
    private lazy var layoutForIM: YYTextLayout? = {
        let size = CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
        let layout = YYTextLayout(containerSize: size, text: attributedTextForIM)
        return layout
    }()

    private lazy var originalLayoutForIM: YYTextLayout? = {
        if let originalAttributedText = originalAttributedTextForIM {
            let size = CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: originalAttributedText)
            return layout
        } else {
            return nil
        }
    }()

    
    override func calculateHeight(_ width : CGFloat) {
        let textHeight: CGFloat = layoutForIM?.textBoundingSize.height ?? 0
        let originalTextHeight: CGFloat = originalLayoutForIM?.textBoundingSize.height ?? 0
        var height: CGFloat = 0.0

        height += MinutesCommentsContentCell.LayoutContext.topMargin
            + MinutesCommentsContentCell.LayoutContext.nameHeight
            + MinutesCommentsContentCell.LayoutContext.verticalOffset
            + textHeight
            + MinutesCommentsContentCell.LayoutContext.verticalOffset2
            + MinutesCommentsContentCell.LayoutContext.timeHeight
            + MinutesCommentsContentCell.LayoutContext.bottomMargin

        let imageHeight = calculateImageHeight(width)
        height += imageHeight
        
        if isInTranslationMode {
            height += originalTextHeight + imageHeight + MinutesCommentsContentCell.LayoutContext.verticalOffset2 + 6 * 2
        }
        cellHeight = height
    }
    
    override init(resolver: UserResolver, contentWidth: CGFloat, content: CommentContent, originalContent: CommentContent? = nil, isInTranslationMode: Bool) {
        super.init(resolver: resolver, contentWidth: contentWidth, content: content, originalContent: originalContent, isInTranslationMode: isInTranslationMode)

    }
    
    override func getTextLayout() -> YYTextLayout? {
        return self.layoutForIM
    }
    
    override func getOriginalTextLayout() -> YYTextLayout? {
        return self.originalLayoutForIM
    }
    
    override func getAttributedText() -> NSAttributedString {
        return self.attributedTextForIM
    }
    
    override func getOriginalAttributedText() -> NSMutableAttributedString? {
        return self.originalAttributedTextForIM
    }
    
}
