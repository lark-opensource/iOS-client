//
// Created by duanxiaochen.7 on 2021/2/18.
// Affiliated with SKSheet.
//
// Description:

import SKFoundation
import SKUIKit
import SKResource
import SKCommon
import HandyJSON
import UniverseDesignIcon
import SpaceInterface
import LarkDocsIcon

struct SheetAttachmentInfo: HandyJSON {
    
    enum AttachmentType: String, HandyJSONEnum {
        case url
        case mention
        case attachment
        case unknown
        case cellPosition
    }
    
    var token: String = ""
    var mimeType: String = ""
    var name: String = ""
    var size: UInt64 = 0
    var sheetId: String = ""    //即将跳转到的 sheetId
    var rangeId: String = ""    //即将跳转到 sheet 的 rangeId
    
    var shouldShowSize: Bool {
        type == .attachment
    }
    
    var type: AttachmentType = .unknown
    var mentionType: Int = -1
    var link: String = ""
    var fileType: DriveFileType { DriveFileType(fileExtension: SKFilePath.getFileExtension(from: name)) }
    var isFileType: Bool {
        if self.type == .attachment {
            return true
        } else if self.type == .mention {
            let docsType = DocsType(rawValue: mentionType)
            return docsType == .folder || docsType == .mediaFile || docsType == .myFolder || docsType == .file
        }
        return false
    }
    var iconImage: UIImage {
        switch type {
        case .url, .cellPosition:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundLinkColorful)
        case .mention:
            let docsType = DocsType(rawValue: mentionType)
            switch docsType {
            case .folder:
                return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
            case .trash:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
            case .doc:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocColorful)
            case .sheet:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundSheetColorful)
            case .myFolder:
                return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
            case .bitable:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundBitableColorful)
            case .mindnote:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundMindnoteColorful)
            case .file:
                return fileType.roundImage ?? UDIcon.getIconByKeyNoLimitSize(.fileRoundImageColorful)
            case .slides:
                return UDIcon.getIconByKeyNoLimitSize(.wikiSlidesCircleColorful)
            case .wiki, .wikiCatalog:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocColorful)
            case .mediaFile:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundImageColorful)
            case .docX:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocxColorful)
            case .unknown:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
            default:
                return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
            }
        case .attachment:
            return fileType.roundImage ?? UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        case .unknown:
            break
        }
        return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
    }
}
