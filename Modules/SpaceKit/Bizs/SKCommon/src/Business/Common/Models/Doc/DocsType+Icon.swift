//
//  DocsType+Icon.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/12/8.
//

import Foundation
import UniverseDesignIcon
import SKFoundation
import SKResource
import SpaceInterface

public extension DocsType {

    var imageForCreate: UIImage? {
        switch self {
        case .file:
            return UDIcon.fileColorful
        case .mediaFile:
            return UDIcon.fileImageColorful
        default:
            return UDIcon.getIconByKey(squareColorfulIconKey)
        }
    }

    var imageForTemplateShadow: UIImage? {
        var image: UIImage?
        switch self {
        case .doc: image = BundleResources.SKResource.Space.Create.template_shadow_doc
        case .sheet: image = BundleResources.SKResource.Space.Create.template_shadow_Sheet
        case .mindnote: image = BundleResources.SKResource.Space.Create.template_shadow_MindNote
        case .docX:
            // TODO-DocX: DocX 支持模板创建后更新 icon
            spaceAssertionFailure("不支持docx类型")
            image = BundleResources.SKResource.Space.Create.template_shadow_doc
        case .bitable:
            image = BundleResources.SKResource.Space.Create.template_shadow_bitable
        default:
            spaceAssertionFailure("不支持类型")
        }
        if let img = image {
            let imageSize = img.size
            let centerY = imageSize.height / 2
            let centerX = imageSize.width / 2
            image = img.resizableImage(withCapInsets: UIEdgeInsets(top: centerY, left: centerX, bottom: centerY, right: centerX), resizingMode: .stretch)
        }
        return image
    }

    // 获取相关Icon
    var iconForSuspendable: UIImage? {
        return UDIcon.getIconByKey(roundColorfulIconKey, size: CGSize(width: 48, height: 48))
    }

    var squareColorfulIconKey: UDIconType {
         switch self {
        case .doc:
            return .fileDocColorful
        case .docX:
            return .fileDocxColorful
        case .sheet:
            return .fileSheetColorful
        case .mindnote:
            return .fileMindnoteColorful
        case .slides:
            return .wikiSlidesColorful
        case .bitable, .baseAdd:
            return .fileBitableColorful
        case .sync:
            return .syncedblockColorful
        case .file:
            spaceAssertionFailure("use DriveFileType Icon instead")
            return .fileColorful
        case .wiki:
            spaceAssertionFailure("use content DocsType Icon instead")
            return .fileDocColorful
        case .folder:
            return .fileFolderColorful
        default:
            return .fileUnknowColorful
        }
    }

    var roundColorfulIconKey: UDIconType {
        switch self {
        case .doc:
            return .fileRoundDocColorful
        case .docX:
            return .fileRoundDocxColorful
        case .sheet:
            return .fileRoundSheetColorful
        case .mindnote:
            return .fileRoundMindnoteColorful
        case .slides:
            return .wikiSlidesCircleColorful
        case .bitable, .baseAdd:
            return .fileRoundBitableColorful
        case .file:
            spaceAssertionFailure("use DriveFileType Icon instead")
            return .fileRoundImageColorful
        case .wiki:
            spaceAssertionFailure("use content DocsType Icon instead")
            return .fileRoundDocColorful
        case .sync:
            return .syncedblockColorful
        default:
            return .fileRoundUnknowColorful
        }
    }

    var outlinedIconKey: UDIconType {
        switch self {
        case .doc:
            return .fileLinkWordOutlined
        case .docX:
            return .fileLinkDocxOutlined
        case .sheet:
            return .fileLinkSheetOutlined
        case .mindnote:
            return .fileLinkMindnoteOutlined
        case .slides:
            return .fileLinkSlidesOutlined
        case .bitable, .baseAdd:
            return .fileLinkBitableOutlined
        case .file:
            spaceAssertionFailure("use DriveFileType Icon instead")
            return .fileLinkOtherfileOutlined
        case .wiki:
            spaceAssertionFailure("use content DocsType Icon instead")
            return .fileLinkWordOutlined
        case .folder:
            return .folderOutlined
        case .sync:
            return .linkRecordOutlined
        default:
            return .fileLinkUnknowOutlined
        }
    }

    var shortcutOutlinedIconKey: UDIconType {
        switch self {
        case .doc:
            return .wikiDocShortcutOutlined
        case .docX:
            return .fileLinkDocxShortcutOutlined
        case .sheet:
            return .wikiSheetShortcutOutlined
        case .mindnote:
            return .wikiMindnoteShortcutOutlined
        case .slides:
            return .fileLinkSlidesShortcutOutlined
        case .bitable, .baseAdd:
            return .filelinkBitableShortcutOutlined
        case .file:
            spaceAssertionFailure("use DriveFileType Icon instead")
            return .fileLinkOtherfileShortcutOutlined
        case .wiki:
            spaceAssertionFailure("use content DocsType Icon instead")
            return .wikiDocShortcutOutlined
        case .folder:
            return .folderOutlined
        default:
            return .fileLinkOtherfileShortcutOutlined
        }
    }
}
