//
//  IconTransformer.swift
//  LarkListItem
//
//  Created by Yuri on 2023/6/2.
//

import Foundation
import RustPB
import LarkModel
import UniverseDesignIcon
import LarkRichTextCore

final public class IconTransformer {
    static let iconSize = CGSize(width: 48, height: 48)
    public static func transform(meta: PickerDocMeta) -> ListItemNode.Icon {
        if let info = meta.iconInfo, !info.isEmpty {
            return .docIcon(.init(iconInfo: info))
        }
        if let doc = meta.meta {
            if doc.isShareFolder {
                return .local(UDIcon.getIconByKey(.fileRoundSharefolderColorful))
            } else {
                let name = meta.title ?? ""
                return transform(doc: meta, fileName: name)
            }
        } else {
            return .local(nil)
        }
    }

    public static func transform(doc: PickerDocMeta, fileName: String) -> ListItemNode.Icon {
        return DocIconTransformer.transform(doc: doc, fileName: fileName, iconSize: self.iconSize)
    }

    public static func transform(meta: PickerWikiMeta, fileName: String? = nil) -> ListItemNode.Icon {
        if let info = meta.iconInfo, !info.isEmpty {
            return .docIcon(.init(iconInfo: info))
        }
        if let wiki = meta.meta {
            let name = meta.title ?? ""
            return transform(meta: wiki, fileName: name)
        } else {
            return .local(nil)
        }
    }

    public static func transform(meta: PickerWikiSpaceMeta) -> ListItemNode.Icon {
        if let wiki = meta.meta {
            return transform(meta: wiki)
        } else {
            return .local(nil)
        }
    }

    public static func transform(meta: RustPB.Search_V2_WikiMeta, fileName: String) -> ListItemNode.Icon {
        if meta.type == .shortcut {
            let entityType = meta.oriType
            let entityImage = LarkRichTextCoreUtils.docIcon(
                docType: entityType, fileName: fileName
            )
            let shortcutImage = UDIcon.getIconByKey(.wikiShortcutarrowColorful, size: iconSize)
            let image = ImageUtil.combineImages(entityImage, shortcutImage)
            return .local(image)
        } else {
            return .local(DocIconTransformer.transform(docType: meta.type, fileName: fileName, size: iconSize))
        }
    }
    public static func transform(meta: RustPB.Search_V2_WikiSpaceMeta) -> ListItemNode.Icon {
        return .local(UDIcon.getIconByKey(.wikibookCircleColorful))
    }
}
