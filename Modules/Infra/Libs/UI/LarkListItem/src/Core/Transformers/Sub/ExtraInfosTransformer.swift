//
//  ExtraInfosTransformer.swift
//  LarkListItem
//
//  Created by Yuri on 2023/6/1.
//

import UIKit
import RustPB
import UniverseDesignIcon

class ExtraInfosTransformer {
    static func transform(extraInfos: [Search_V2_ExtraInfoBlock]?, extraInfoSeparator: String, font: UIFont) -> NSAttributedString? {
        guard let extraInfos = extraInfos, !extraInfos.isEmpty else { return nil }
        let attributedString = NSMutableAttributedString(string: "")
        for (i, info) in extraInfos.enumerated() {
            if info.hasBlockIcon {
                // 创建UIImage对象
                let pointSize: CGFloat = font.pointSize
                let imageSize = CGSize(width: pointSize, height: pointSize)
                let iconImage = UDIcon.getIconByKey(.wikiBookOutlined).ud.withTintColor(UIColor.ud.iconN3).ud.resized(to: imageSize)
                let yOffset = (font.capHeight - pointSize) / 2.0// - 4
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(x: 0, y: yOffset, width: pointSize, height: pointSize)
                attachment.image = iconImage
                // 创建NSAttributedString对象
                let attachmentString = NSAttributedString(attachment: attachment)
                attributedString.append(attachmentString)
                // 增加一点间距
                attributedString.append(NSAttributedString(string: " "))
            }
            for segment in info.blockSegments {
                var text = NSAttributedString(string: "")
                switch segment.type {
                case .text:
                    text = SearchAttributeString(searchHighlightedString: segment.textHighlighted).attributeText
                case .timestamp:
                    let interval = Int64(segment.textHighlighted) ?? 0
                    text = NSAttributedString(string: ItemDateUtil.dataString(interval))
                @unknown default: break
                }
                attributedString.append(text)
            }
            if i < extraInfos.count - 1 {
                attributedString.append(NSAttributedString(string: extraInfoSeparator))
            }
        }
        return attributedString
    }
}
