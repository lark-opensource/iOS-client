//
//  Utils.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/4/9.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration
import LarkModel
import RustPB
import LarkCore
import LarkBizAvatar
import LarkFeatureGating
import LarkSDKInterface
import LarkSearchCore

final class Utils {
    class func replaceUrl(meta: SearchMetaMessageType, subtitle: NSAttributedString, font: UIFont) -> NSAttributedString {
        let infos = meta.docExtraInfosType
        if infos.isEmpty {
            return subtitle
        }
        let subAttributedString = NSMutableAttributedString(attributedString: subtitle)
        infos.forEach { (docExtraInfo) in
            var location = 0
            let searchRange = NSRange(location: location, length: subAttributedString.string.count)

            let foundRange = (subAttributedString.string as NSString).range(of: docExtraInfo.url, options: [.caseInsensitive], range: searchRange)
            if foundRange.location != NSNotFound {
                let docAttributedString = NSMutableAttributedString(string: docExtraInfo.name)
                let attachment = NSTextAttachment()
                UIGraphicsBeginImageContextWithOptions(CGSize(width: font.pointSize * 1.5, height: font.pointSize), false, UIScreen.main.scale)
                let image = LarkCoreUtils.docUrlIcon(docType: docExtraInfo.type)
                image.draw(in: CGRect(x: font.pointSize * 0.25, y: 0, width: font.pointSize, height: font.pointSize))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                attachment.image = newImage
                attachment.bounds = CGRect(
                    x: 0,
                    y: (font.capHeight - font.pointSize) / 2,
                    width: font.pointSize * 1.5,
                    height: font.pointSize
                )
                let icon = NSAttributedString(attachment: attachment)
                docAttributedString.insert(icon, at: 0)
                subAttributedString.replaceCharacters(in: foundRange, with: docAttributedString)
                location += foundRange.location + foundRange.length
            }
        }
        return NSAttributedString(attributedString: subAttributedString)
    }

    class func setAttributeString(for label: UILabel, attributedString: NSAttributedString, terms: [String], highlightColor: UIColor) {
        label.attributedText = NSAttributedString()

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        var text: NSString = mutableAttributedString.string as NSString
        while text.contains("\n") {
            let wrapRange = text.range(of: "\n")
            mutableAttributedString.replaceCharacters(in: wrapRange, with: NSAttributedString(string: ""))
            text = mutableAttributedString.string as NSString
        }
        var attributedText = NSAttributedString(attributedString: mutableAttributedString)
        if let info = firstHitAttrTextInfo(attributedText: attributedText, terms: terms) {
            let textWithFirstHitTerm = info.0
            let remainText = info.1
            // 为了判断第一个hitTerm是否能在label上显示完全
            // 先让第一个hitTerm显示出来，看看这个时候label有多宽
            // 为了确保width是hitTerm完全展示出来的宽度，多计算两个空格的长度
            // 一些极端情况，不加空格计算出来的width仍然展示不全hitTerm， 应该是是后面又加了attribute导致的
            // 这里没有把textWithFirstHitTerm加上attribute执行sizeToFit是为了保证效率。
            label.text = textWithFirstHitTerm.string + "  "
            if label.isTruncated {
                attributedText = remainText
            }
        }
        label.attributedText = SearchResult.attributedText(attributedString: attributedText, withHitTerms: terms, highlightColor: highlightColor)
    }

    /// example:  text = "I am a very very very long text" terms = ["long"]
    /// 返回的第一个值是包含第一个hitText的字符串， 这里是"I am a very very very long"
    /// 返回的第二个值是从第一个hitText位置前5个字符开始，到text结束的字符串，并在开头加上"..." 这里是"...very long text"
    private class func firstHitAttrTextInfo(attributedText: NSAttributedString, terms: [String]) -> (textWithFirstHitTerm: NSAttributedString, remainText: NSAttributedString)? {

        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        let text: NSString = mutableAttributedText.string as NSString
        guard let firstTerm = terms.first else { return nil }
        let range = (text as NSString).range(of: firstTerm, options: [.caseInsensitive])
        if range.location == NSNotFound {
            return nil
        }
        let remainTextAtt: NSAttributedString
        let textWithFirstHitTermAtt = mutableAttributedText.attributedSubstring(from: NSRange(location: 0, length: range.location + range.length))
        if range.location > 5 {
            let remainTextMuAtt: NSMutableAttributedString = NSMutableAttributedString(string: "...")
            remainTextMuAtt.append(mutableAttributedText.attributedSubstring(from: NSRange(location: range.location - 5, length: mutableAttributedText.length - (range.location - 5))))
            remainTextAtt = NSAttributedString(attributedString: remainTextMuAtt)
        } else {
            remainTextAtt = textWithFirstHitTermAtt
        }

        return (textWithFirstHitTermAtt, remainTextAtt)

    }
}

extension UILabel {
    var isTruncated: Bool {
        guard let labelText = text else { return false }
        layoutIfNeeded()
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font = font {
            attributes[.font] = font
        }
        let labelTextSize = (labelText as NSString).boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil).size
        return labelTextSize.height > bounds.size.height
    }
}

extension UIImage {
    public static func searchCombineImages(_ image1: UIImage, _ image2: UIImage) -> UIImage? {
        // 获取两张图片的大小
        let size = image1.size

        // 使用UIGraphicsImageRenderer绘制组合图像
        let renderer = UIGraphicsImageRenderer(size: size)
        let combinedImage = renderer.image { _ in
            // 将两张图片绘制到同一个图形上下文中
            image1.draw(in: CGRect(origin: .zero, size: size))
            image2.draw(in: CGRect(origin: .zero, size: size))
        }
        return combinedImage
    }
}

// 目前该逻辑用于doc上，后续迁移到其他(如chat、chatter)上， see: https://bytedance.feishu.cn/docs/doccnS2ELTGP2DQoekKYHow4hJg#
extension SearchResultType {
    func docAvatarKey(_ enableCustomAvatar: Bool) -> String {
        if !enableCustomAvatar {
            return ""
        }
        guard let icon = self.icon else { return avatarKey }
        switch icon.type {
        case .image:
            return icon.value
        @unknown default:
            return avatarKey
        }
    }
}

extension Search.Meta {
    var miniIcon: MiniIconProps? {
        var props = MiniIconProps()
        switch self {
        case .thread:
            props.type = .topic
        case .doc(let meta):
            switch meta.type {
            case .slide, .slides:
                props.type = .ppt
            case .doc:
                props.type = .docs
            case .sheet:
                props.type = .sheet
            case .mindnote:
                props.type = .mindmap
            case .bitable:
                props.type = .table
            @unknown default:
                return nil
            }
        case .chat(let meta):
            switch meta.type {
            case .topicGroup:
                props.type = .thread
            @unknown default:
                return nil
            }
        case .wiki(let meta):
            switch meta.docMetaType.type {
            case .slide, .slides:
                props.type = .ppt
            case .doc:
                props.type = .docs
            case .sheet:
                props.type = .sheet
            case .mindnote:
                props.type = .mindmap
            case .bitable:
                props.type = .table
            @unknown default:
                return nil
            }
        case .openApp:
            props.type = .micoApp
        default:
            return nil
        }
        return props
    }
}
