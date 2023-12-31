//
//  FileItem.swift
//  DocsCommon
//
//  Created by weidong fu on 25/11/2017.
//

import Foundation
import SKCommon
import SKResource
import UniverseDesignIcon
import UIKit
import SKInfra

public enum SlideAction {
    // 仅点击删除按钮（尚未二次确认删除）
    case readyToDelete
    case delete
    case deleteDisable // 临时禁用的delete按钮 参考DM-802
    case share
    case shareDisable // share按钮的禁用态，目前 DocX 不支持分享，需要禁用
    case more
    case move
    case rename
    case copyURL
    case cancel
    case addTo
    case addShortCut
    case remove
    // 在回收站中彻底删除
    case trashDelete
    // 从回收站中恢复
    case trashRestore

    /// 收藏
    case star
    /// 取消收藏
    case unstar
    case subscribe
    /// for file
    case openWithOtherApp
    case saveToLocal
    case moveToTop
    case addToPin
    case removeFromPin
    /// 将.docs/.excel/.xmind等drive文件导入成为在线文档
    case importToOnlineFile
    /// 手动离线
    case manualOffline
    /// 取消手动离线
    case unmanualOffline
    // 共享文件夹，显示态和隐藏态的转换
    case changeHiddenStatus
    ///副本
    case copyFile
    /// 将docs/sheet 导出为Word/PDF/Excel
    case exportDocument

}

extension SlideAction {
    var offlineTips: String? {
        switch self {
        case .addToPin, .star:
            return BundleI18n.SKResource.Doc_List_AddFailedRetry
        case .removeFromPin, .unstar:
            return BundleI18n.SKResource.Doc_List_RemoveFaildRetry
        default:
            return nil
        }
    }
}

extension SlideAction {
    public var newTagIdentifiler: String? {
        switch self {
        case .exportDocument:
            return UserDefaultKeys.exportDocumentNewTag
        default:
            return nil
        }
    }
}

extension SlideAction {
    // 转换为 UIAction 所需的 title 和 image，目前用于 iPad ContextMenu
    var actionRepresentation: (title: String, image: UIImage)? {
        switch self {
        case .more:
            return (title: BundleI18n.SKResource.Doc_Settings_More,
                    image: BundleResources.SKResource.Common.Icon.icon_more_outlined_20.ud.withTintColor(UIColor.ud.iconN1))
        case .share:
            return (title: BundleI18n.SKResource.Doc_More_Share,
                    image: BundleResources.SKResource.Common.Icon.icon_share_outlined_20.ud.withTintColor(UIColor.ud.iconN1))
        case .delete:
            return (title: BundleI18n.SKResource.Doc_Facade_Delete,
                    image: BundleResources.SKResource.Common.Icon.icon_delete_trash_outlined_20.ud.withTintColor(UIColor.ud.iconN1))
        case .star:
            return (title: BundleI18n.SKResource.Doc_Facade_AddToFavorites,
                    image: BundleResources.SKResource.Common.Icon.icon_actionsheet_favorites_on_20.ud.withTintColor(UIColor.ud.iconN1))
        case .unstar:
            return (title: BundleI18n.SKResource.Doc_Facade_Remove_From_Favorites,
                    image: BundleResources.SKResource.Common.Icon.icon_slide_favorites_off_20.ud.withTintColor(UIColor.ud.iconN1))
        case .removeFromPin:
            return (title: BundleI18n.SKResource.Doc_List_Remove_Access,
                    image: BundleResources.SKResource.Common.Icon.icon_pop_quickaccessoff_nor_20.ud.withTintColor(UIColor.ud.iconN1))
        case .remove:
            return (title: BundleI18n.SKResource.Doc_More_Remove,
                    image: UDIcon.getIconByKey(.noOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)))
        default:
            return nil
        }
    }
}
