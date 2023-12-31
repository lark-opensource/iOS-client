//
//  DataModel+SpaceList.swift
//  SKECM
//
//  Created by guoqp on 2020/6/28.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import Kingfisher
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SpaceInterface
import LarkDocsIcon

//共享文件夹中的文件 授权提示类型
enum AuthPromptType: Int {
    case none = 0 //不展示
    case highlight  //高亮
    case normal //普通
}
extension SpaceEntry {
    var authPromptType: AuthPromptType {
        guard let external = externalSwitch else {
            return .none
        }
        if external == false { return .none } //show_external_hint接口返回不需要显示
        if hasPermission == false { return .none } //user没有文件权限，不用显示
        return ownerIsCurrentUser ? .highlight : .normal  //owner高亮，非owner普通
    }
}

struct SpaceList {
    // 新版icon数据
    struct NewIconData: Equatable {
        let iconKey: String
        let fsUnit: String
        var placeHolder: UIImage?
        static func == (lhs: NewIconData, rhs: NewIconData) -> Bool {
            return lhs.iconKey == rhs.iconKey && lhs.fsUnit == rhs.fsUnit
        }
    }

    // 缩略图展示数据
    struct ThumbnailInfo: Equatable, DocsIconCustomModelProtocol {
        static var modelName: String {
            return "SKSpace.FileList." + String(describing: ThumbnailInfo.self)
        }
        
        let token: String
        let thumbInfo: SpaceThumbnailInfo
        let source: SpaceThumbnailStatistic.Source
        let fileType: DocsType
        let failedImage: UIImage?
        let placeholder: UIImage?
        static func == (lhs: ThumbnailInfo, rhs: ThumbnailInfo) -> Bool {
            return lhs.token == rhs.token
                && lhs.thumbInfo == rhs.thumbInfo
                && lhs.fileType == rhs.fileType
        }
    }

    // 列表 icon 类型数据
    enum IconType: Equatable {
        case newIcon(data: NewIconData) // 新版本icon数据
        case thumbIcon(thumbInfo: ThumbnailInfo) // 列表显示的drive缩略图，目前有drive
        case icon(image: UIImage?, preferSquareDefaultIcon: Bool = false) // 传统图标icon
        static func == (lhs: IconType, rhs: IconType) -> Bool {
            switch (lhs, rhs) {
            case let (.newIcon(data1), .newIcon(data2)):
                return data1 == data2
            case let (.thumbIcon(info1), .thumbIcon(info2)):
                return info1 == info2
            case let (.icon(image1), .icon(image2)):
                return image1 == image2
            default:
                return false
            }
        }
    }

    struct ItemDataParser {
        // 缓存icon解码图片
        private static var iconCache = NSCache<AnyObject, AnyObject>()

        // 标题： 显示无权限提示或者文件标题
        static func mainTitle(file: SpaceEntry, shouldShowNoPermBiz: Bool) -> String {
            if shouldShowNoPermBiz, file.hasPermission == false {
                return BundleI18n.SKResource.Doc_List_Unauthorized_File
            } else {
                return file.name
            }
        }

        // 对外分享打开提示
        static func permTipButton(file: SpaceEntry, folderFile: SpaceEntry?) -> (show: Bool, image: UIImage?) {
            var show = false
            var image: UIImage?
            if let folder = folderFile,
               folder.isOldShareFolder,
               folder.isExternal,
               file.type.isBiz {
                show = true
            } else {
                show = false
            }
            switch file.authPromptType {
            case .highlight:
                image = UDIcon.getIconByKey(.warningOutlined, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 20, height: 20))
            case .normal:
                image = UDIcon.getIconByKey(.warningOutlined, iconColor: UDColor.iconDisabled, size: CGSize(width: 20, height: 20))
            default: break
            }
            return (show, image)
        }

        // Grid cell 显示自定义icon数据 或 文件类型icon
        static func gridIconType(file: SpaceEntry, shouldShowNoPermBiz: Bool, preferSquareDefaultIcon: Bool) -> IconType {
            if let iconType = file.customIcon?.iconType, iconType.isCurSupported,
               let iconKey = file.customIcon?.iconKey, !iconKey.isEmpty,
               let fsUnit = file.customIcon?.iconFSUnit, !fsUnit.isEmpty {
                let quickAccessImage = file.quickAccessImage
                let data = NewIconData(iconKey: iconKey, fsUnit: fsUnit, placeHolder: quickAccessImage)
                return IconType.newIcon(data: data)
            } else if shouldShowNoPermBiz, file.hasPermission == false {
                let noPermIcon = file.noPermIcon
                return IconType.icon(image: noPermIcon, preferSquareDefaultIcon: preferSquareDefaultIcon)
            } else {
                let quickAccessImage = file.quickAccessImage
                return IconType.icon(image: quickAccessImage, preferSquareDefaultIcon: preferSquareDefaultIcon)
            }
        }

        // 判断是否展示externalLabel
        static func showExternalLabelInCell(file: SpaceEntry, folderFile: FolderEntry?, source: FileSource) -> Bool {
            guard EnvConfig.CanShowExternalTag.value else { return false }
            if User.current.info?.isToNewC == true { return false }
            //文件夹快捷方式不展示外部标签
            if file.type == .folder, file.isShortCut {
                return false
            }
            //一个有外部标签的文件夹，它的子列表不展示外部标签
            if let inFolder = folderFile, inFolder.isExternal {
                return false
            }
            // 如果在文件夹列表内，且没有传入 folderFile，表明此刻无法判断是否要展示外部标签，暂时不展示，避免闪烁问题
            if source == .subFolder, folderFile == nil {
                return false
            }
            return file.isExternal
        }

        // List cell 显示icon数据：包括新版icon、文件类型icon、drive文件缩略图
        static func listIconType(file: SpaceEntry, shouldShowNoPermBiz: Bool, preferSquareDefaultIcon: Bool) -> IconType {
            if  let iconType = file.customIcon?.iconType, iconType.isCurSupported,
                let iconKey = file.customIcon?.iconKey, !iconKey.isEmpty,
                let fsUnit = file.customIcon?.iconFSUnit, !fsUnit.isEmpty {
                let listIcon = file.defaultIcon
                let data = NewIconData(iconKey: iconKey, fsUnit: fsUnit, placeHolder: listIcon)
                return IconType.newIcon(data: data)
            } else if let iconUrl = file.driveInfo?.iconUrl,
                      let imageUrl = URL(string: iconUrl),
                      let iconKey = file.driveInfo?.iconKey,
                      let nonce = file.driveInfo?.iconNonce,
                      file.driveInfo?.iconEncrytedTyped == true,
                      // KA 场景下，如果关闭 Drive 功能，缩略图使用默认的占位图
                      DriveFeatureGate.driveEnabled,
                      file.secretKeyDelete != true {
                
                let listIcon = file.defaultIcon
                
                //如果图片有自定义icon，则不显示缩略图
                if let iconInfo = DocsIconInfo.createDocsIconInfo(json: file.iconInfo ?? ""), iconInfo.type != .none {
                    return IconType.icon(image: listIcon, preferSquareDefaultIcon: preferSquareDefaultIcon)
                }
                
                let extraInfo = SpaceThumbnailInfo.ExtraInfo(url: imageUrl, encryptType: .GCM(secret: iconKey, nonce: nonce))
                let info = SpaceThumbnailInfo.encryptedOnly(encryptInfo: extraInfo)
                let thumbInfo = ThumbnailInfo(token: file.objToken,
                                              thumbInfo: info,
                                              source: .spaceList,
                                              fileType: .file,
                                              failedImage: listIcon,
                                              placeholder: listIcon)
                return IconType.thumbIcon(thumbInfo: thumbInfo)
            } else if shouldShowNoPermBiz, file.hasPermission == false {
                let noPermIcon = file.noPermIcon
                return IconType.icon(image: noPermIcon, preferSquareDefaultIcon: preferSquareDefaultIcon)
            } else {
                let listIcon = file.defaultIcon
                return IconType.icon(image: listIcon, preferSquareDefaultIcon: preferSquareDefaultIcon)
            }
        }
    }
}
