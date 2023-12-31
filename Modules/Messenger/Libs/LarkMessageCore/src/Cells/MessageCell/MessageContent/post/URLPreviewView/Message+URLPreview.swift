//
//  Message+URLPreview.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2020/5/27.
//

import UIKit
import Foundation
import LarkModel
import RustPB

/// 解析RustPB.Basic_V1_RichText,将所有叶子结点有序输出
func parseRichText(elements: [String: RustPB.Basic_V1_RichTextElement], elementIds: [String], leafs: inout [RustPB.Basic_V1_RichTextElement]) {
    for elementId in elementIds {
        if let element = elements[elementId] {
            if element.childIds.isEmpty {
                leafs.append(element)
            } else {
                parseRichText(elements: elements, elementIds: element.childIds, leafs: &leafs)
            }
        }
    }
}

/*
 |---------------------------|
 | iconURL+iconKey   urlTitle|
 |                           |
 |           content         |
 |---------------------------|
 |                           |
 |        coverImageSet      |（pin列表/un-pin弹窗无此）
 |                           |
 |---------------------------|
 */
/// 展示URLPreview需要的方法
extension Message {
    /// 带预览的urls
    var previewUrls: [PreviewUrlContent] {
        if let content = self.content as? TextContent {
            return content.previewUrls
        }
        if let content = self.content as? PostContent {
            return content.previewUrls
        }
        return []
    }

    /// 要预览的url内容
    var urlContent: PreviewUrlContent? {
        return self.previewUrls.first
    }

    /// 要预览的url视频封面图片
    var coverImageSet: ImageSet? {
        if self.urlContent?.hasCoverImage ?? false {
            return self.urlContent?.coverImage
        }
        return nil
    }
}

public extension Message {
    /// 要预览的url内容地址
    var iconURL: String {
        return self.urlContent?.icon.thumbnail.urls.first ?? self.urlContent?.icon.origin.urls.first ?? ""
    }

    /// 要预览的url内容图标
    var iconKey: String {
        return self.urlContent?.icon.thumbnail.key ?? self.urlContent?.icon.origin.key ?? ""
    }

    /// 要预览的url内容标题
    var urlTitle: String {
        return (self.urlContent?.title ?? "").lf.trimCharacters(
            in: .whitespacesAndNewlines,
            postion: .both
        )
    }

    /// 要预览的url内容描述
    func urlContent(textColor: UIColor) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 1
        style.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: UIFont.ud.body2,
            .paragraphStyle: style
        ]
        return NSAttributedString(string: urlContent?.summary ?? "", attributes: attributes)
    }

    /// 是否有url预览：只在有一个url时才显示，多个相同的url算一个
    var hasUrlPreview: Bool {
        guard let firstItem = self.urlContent else { return false }
        let uniquePreviewUrls = self.previewUrls.map({ $0.url }).lf_unique()
        return uniquePreviewUrls.count == 1 && !firstItem.isHidden && !firstItem.title.isEmpty
    }

    /// 内容本身是否只是一个URLLink
    func onlyHasURLLink() -> Bool {
        /// 内容
        func richText() -> RustPB.Basic_V1_RichText? {
            if let content = self.content as? TextContent {
                return content.richText
            }
            if let content = self.content as? PostContent {
                return content.richText
            }
            return nil
        }

        guard let richText = richText(), let url = previewUrls.first?.url else { return false }
        var leafs: [RustPB.Basic_V1_RichTextElement] = []
        parseRichText(elements: richText.elements, elementIds: richText.elementIds, leafs: &leafs)
        return leafs.count == 1 && leafs.first?.property.anchor.content ?? "" == url
    }
}
