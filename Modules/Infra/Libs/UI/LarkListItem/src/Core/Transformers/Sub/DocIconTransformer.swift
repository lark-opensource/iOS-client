//
//  DocIconTransformer.swift
//  LarkListItem
//
//  Created by Yuri on 2023/6/5.
//

import Foundation
import LarkModel
import RustPB
import LarkRichTextCore
import UniverseDesignIcon

final class DocIconTransformer {
    public static func transform(doc: PickerDocMeta, fileName: String, iconSize: CGSize) -> ListItemNode.Icon {
        if let info = doc.iconInfo, !info.isEmpty {
            return .docIcon(.init(iconInfo: info))
        }
        guard let meta = doc.meta else {
            return .local(nil)
        }
        if meta.isShareFolder {
            return .local(UDIcon.getIconByKey(.fileRoundSharefolderColorful))
        } else if meta.type == .shortcut {
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
    
    public static func transform(docType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String, size: CGSize) -> UIImage {
        let image = LarkRichTextCoreUtils.docIcon(docType: docType, fileName: fileName).ud.resized(to: size)
        return image
    }
}
