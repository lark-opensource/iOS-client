//
//  PickerItemTransformer.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/29.
//

import Foundation
import LarkModel
import RustPB
import UniverseDesignIcon

final public class PickerItemTransformer {

    public var accessoryTransformer: PickerItemAccessoryTransformer?

    public init(accessoryTransformer: PickerItemAccessoryTransformer? = nil) {
        self.accessoryTransformer = accessoryTransformer
    }

    public func transform(
        indexPath: IndexPath,
        item: PickerItem,
        checkBox: ListItemNode.CheckBoxState = .init()
    ) -> ListItemNode {
        var node = Self.transform(indexPath: indexPath, item: item, checkBox: checkBox)
        if let accessoryTransformer {
            node.accessories = accessoryTransformer.transform(item: item)
        }
        return node
    }

    static let descFont = UIFont.systemFont(ofSize: 14)

    public static func transform(
        indexPath: IndexPath,
        item: PickerItem,
        checkBox: ListItemNode.CheckBoxState = .init()
    ) -> ListItemNode {
        var node = ListItemNode(indexPath: indexPath, checkBoxState: checkBox)
        switch item.meta {
        case .chatter(let meta):
            fullChatter(node: &node, item: item, meta: meta)
        case .doc(let meta):
            fullDoc(node: &node, item: item, meta: meta)
        case .wiki(let meta):
            fullWiki(node: &node, item: item, meta: meta)
        case .wikiSpace(let meta):
            fullWikiSpace(node: &node, item: item, meta: meta)
        case .mailUser(let meta):
            if let renderData = item.renderData {
                node.title = renderData.titleHighlighted
                node.desc = renderData.summaryHighlighted
            } else {
                node.title = NSAttributedString(string: meta.title ?? "")
                node.desc = NSAttributedString(string: meta.summary ?? "")
            }
            if let imagerURLStr = meta.imageURL, !imagerURLStr.isEmpty, let imageURL = URL(string: imagerURLStr) {
                node.icon = .avatarImageURL(imageURL)
            }
        default: break
        }
        return node
    }

    // nolint: duplicated_code 不同实体的转换逻辑有差异
    private static func fullChatter(node: inout ListItemNode, item: PickerItem, meta: PickerChatterMeta) {
        if let renderData = item.renderData {
            if let title = renderData.title {
                node.title = SearchAttributeString(searchHighlightedString: title).attributeText
            }
            if let subtitle = meta.description, !subtitle.isEmpty {
                node.subtitle = NSAttributedString(string: subtitle)
            }
            if let summary = renderData.summary, !summary.isEmpty {
                let attrStr = NSMutableAttributedString(attributedString: SearchAttributeString(searchHighlightedString: summary).attributeText)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byTruncatingHead
                attrStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrStr.length))
                node.desc = attrStr
            }
        }
        node.status = meta.status
        if let key = meta.avatarKey {
            node.icon = .avatar(meta.avatarId ?? "", key)
        } else if let url = meta.avatarUrl {
            node.icon = .avatarImageURL(URL(string: url))
        }
    }
    // nolint: duplicated_code 不同实体的转换逻辑有差异
    private static func fullDoc(node: inout ListItemNode, item: PickerItem, meta: PickerDocMeta) {
        if let renderData = item.renderData {
            if let titleHighlighted = renderData.titleHighlighted {
                node.title = titleHighlighted
            }
            if let summaryHighlighted = renderData.summaryHighlighted,
               !summaryHighlighted.string.isEmpty {
                node.content = summaryHighlighted
            }
            let extraInfoSeparator = renderData.extraInfoSeparator ?? " · "
            node.desc = ExtraInfosTransformer.transform(extraInfos: renderData.extraInfos, extraInfoSeparator: extraInfoSeparator, font: descFont)
        } else {
            node.title = NSAttributedString(string: meta.title ?? "")
            if let desc = meta.desc {
                node.desc = NSAttributedString(string: desc)
            }
        }
        if meta.meta?.isCrossTenant == true {
            node.tags = [.external]
        }
        node.icon = IconTransformer.transform(doc: meta, fileName: node.title?.string ?? "")
    }
    // nolint: duplicated_code 不同实体的转换逻辑有差异
    private static func fullWiki(node: inout ListItemNode, item: PickerItem, meta: PickerWikiMeta) {
        if let renderData = item.renderData {
            if let titleHighlighted = renderData.titleHighlighted {
                node.title = titleHighlighted
            }
            if let summaryHighlighted = renderData.summaryHighlighted,
               !summaryHighlighted.string.isEmpty {
                node.content = summaryHighlighted
            }

            let extraInfoSeparator = renderData.extraInfoSeparator ?? " · "
            node.desc = ExtraInfosTransformer.transform(extraInfos: renderData.extraInfos, extraInfoSeparator: extraInfoSeparator, font: descFont)
        } else {
            node.title = NSAttributedString(string: meta.title ?? "")
            if let desc = meta.desc {
                node.desc = NSAttributedString(string: desc)
            }
        }
        node.icon = IconTransformer.transform(meta: meta, fileName: node.title?.string ?? "")
    }
    // nolint: duplicated_code 不同实体的转换逻辑有差异
    private static func fullWikiSpace(node: inout ListItemNode, item: PickerItem, meta: PickerWikiSpaceMeta) {
        if let renderData = item.renderData {
            node.title = renderData.titleHighlighted
            if let desc = meta.meta?.description_p,
               !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                node.desc = NSAttributedString(string: desc)
            }
        } else {
            node.title = NSAttributedString(string: meta.title ?? "")
            if let desc = meta.desc,
               !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                node.desc = NSAttributedString(string: desc)
            }
        }
        if let wikiSpaceMeta = meta.meta {
            node.icon = IconTransformer.transform(meta: wikiSpaceMeta)
        } else {
            node.icon = .local(nil)
        }
    }
    // enable-lint: duplicated_code
}
