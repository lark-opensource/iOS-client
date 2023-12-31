//
//  SearchExtraInfoLabel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/4/17.
//

import UIKit
import Foundation
import LarkSDKInterface
import RustPB
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import LarkSearchCore
import LarkListItem

final class SearchExtraInfoLabel: UILabel {
    override public var text: String? {
        get { super.text }
        set {
            super.attributedText = nil
            super.text = newValue
        }
    }
    override public var attributedText: NSAttributedString? {
        get { super.attributedText }
        set {
            super.attributedText = newValue
        }
    }
    enum IconKey: String {
      case wiki
    }
    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.textColor = UIColor.ud.textPlaceholder
        self.font = UIFont.systemFont(ofSize: 14)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView(extraInfoBlock: Search_V2_ExtraInfoBlock) {
        text = nil
        attributedText = nil
        var infoTextHighlighted: NSMutableAttributedString = NSMutableAttributedString()
        for segment in extraInfoBlock.blockSegments {
            if segment.type == .timestamp {
                let segmentTime = Int(segment.textHighlighted) ?? 0
                infoTextHighlighted.append(NSAttributedString(string: Date.lf.getNiceDateString(TimeInterval(segmentTime))))
            } else {
                var attributeString = SearchAttributeString(searchHighlightedString: segment.textHighlighted).attributeText
                // 兜底，防止特殊字符导致富文本解析失败
                if attributeString.string.isEmpty, !segment.textHighlighted.isEmpty {
                    attributeString = NSAttributedString(string: segment.textHighlighted)
                }
                infoTextHighlighted.append(attributeString)
            }
        }

        var image: UIImage?
        let pointSize = self.font.pointSize
        if IconKey.wiki.rawValue.elementsEqual(extraInfoBlock.blockIcon.iconKey) {
            let icon = UDIcon.getIconByKey(.wikiBookOutlined).ud.withTintColor(UIColor.ud.iconN3)
            UIGraphicsBeginImageContextWithOptions(CGSize(width: pointSize * 1.25, height: pointSize), false, UIScreen.main.scale)
            icon.draw(in: CGRect(x: 0, y: 0, width: pointSize, height: pointSize))
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        if let _image = image {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = _image
            imageAttachment.bounds = CGRect(
                x: 0,
                y: (self.font.capHeight - pointSize) / 2,
                width: pointSize * 1.25,
                height: pointSize
            )
            let imageAttr = NSAttributedString(attachment: imageAttachment)

            infoTextHighlighted.insert(imageAttr, at: 0)
        }
        self.attributedText = infoTextHighlighted
    }

    //当前文案，单行所需宽度
    //UILabel 在使用snpkit布局后，sizeToFit不准，所以单开函数计算
    func singleLineLength() -> CGFloat {
        let label = SearchExtraInfoLabel()
        if attributedText != nil {
            label.attributedText = attributedText
        } else {
            label.text = text
        }
        label.sizeToFit()
        return label.frame.size.width
    }
}
