//
//  SpaceEntry+Space.swift
//  SKECM
//
//  Created by guoqp on 2020/6/29.
//

import Foundation
import SKFoundation
import SKCommon
import SKResource
import SKInfra

private let externalSwitchKey = "externalSwitch"

// MARK: 链接分享
extension SpaceEntry {
    /// 分享时的链接
    public var urlForShare: String {
        if DomainConfig.isNewDomain, let url = shareUrl { return url }
        return DocsUrlUtil.url(type: type, token: objToken).absoluteString
    }

    // 权限设置-开启对外开关
    public var externalSwitch: Bool? {
        get { return storedExtensionProperty[externalSwitchKey] as? Bool }
        set { updateStoredExtensionProperty(key: externalSwitchKey, value: newValue as Any) }
    }
    //当前用户是file owner
    public var ownerIsCurrentUser: Bool {
        guard let ownerID = self.ownerID, let uid = User.current.info?.userID, ownerID == uid else {
            return false
        }
        return true
    }
    // 当前用户与Owner是否同租户
    public var isSameTenantWithOwner: Bool {
        if ownerTenantID != nil, User.current.info?.tenantID != nil {
            return ownerTenantID == User.current.info?.tenantID
        }
        return false
    }
}



// MARK: - 手动离线和离线创建文件的状态图片判断
extension SpaceEntry {
    public struct SyncUIConfig: Equatable {
        let show: Bool
        let image: UIImage?
        let title: String
        public let isSyncing: Bool
        
        public static func == (lhs: SyncUIConfig, rhs: SyncUIConfig) -> Bool {
            return lhs.show == rhs.show
                && lhs.image == rhs.image
                && lhs.title == rhs.title
        }
    }

    static var upWaitingImage: UIImage { BundleResources.SKResource.Common.Tool.icon_tool_waituploading }
    static var downWaitingImage: UIImage { BundleResources.SKResource.Common.Tool.icon_tool_waitdownload }
    static var syncingImage: UIImage { BundleResources.SKResource.Common.Tool.icon_tool_synching }
    static var finishImage: UIImage { BundleResources.SKResource.Common.Tool.icon_tool_finish }
    static var successImage: UIImage { BundleResources.SKResource.Common.Tool.icon_tool_offlinesuccess }
    static var failedImage: UIImage { BundleResources.SKResource.Common.Tool.icon_tool_offlinefail }

    func needShowSyncImage(source: FileSource, sortType: SpaceSortHelper.SortType) -> SyncUIConfig {
        // 优先展示上传的同步状态，然后再判断是否要展示下载同步状态
        guard type.isSupportSyncStatus else {
            // 判断是否显示下载同步
            return judgeDownloadUIConfig(source: source, sortType: sortType)
        }

        let upStatus = syncStatus.upSyncStatus
        guard upStatus != .none else {
            // 判断是否显示下载同步
            return judgeDownloadUIConfig(source: source, sortType: sortType)
        }

        // 下面是判断离线上传文件的状态
        var show = true
        var title = ""
        let image: UIImage?
        var isSyncing = false
        switch upStatus {
        case .none:
            show = false
            image = nil //理论上不会走到这里
        case .waiting:
            title = BundleI18n.SKResource.Doc_List_WaitingForSync
            image = SpaceEntry.upWaitingImage
        case .uploading:
            title = BundleI18n.SKResource.Doc_List_Syncing
            image = SpaceEntry.syncingImage
            isSyncing = true
        case .finish:
            title = BundleI18n.SKResource.Doc_Normal_FinishSynchronizing
            image = SpaceEntry.finishImage
        case .finishOver1s:
            // 判断是否显示下载同步
            return judgeDownloadUIConfig(source: source, sortType: sortType)
        case .failed: // 目前跟等待是一个UI样式
            image = SpaceEntry.failedImage
            title = BundleI18n.SKResource.Doc_List_SyncFailed
        }

        return SyncUIConfig(show: show,
                            image: image,
                            title: title,
                            isSyncing: isSyncing)
    }

    func judgeDownloadUIConfig(source: FileSource, sortType: SpaceSortHelper.SortType) -> SyncUIConfig {

        guard canSetManualOffline, isSetManuOffline else {
            return SyncUIConfig(show: false,
                                image: nil,
                                title: subtitle(listSource: source, sortType: sortType),
                                isSyncing: false)
        }

        let downloadStatus = syncStatus.downloadStatus

        var show = true
        var title = ""
        var image: UIImage?
        var isSyncing = false

        guard !hadShownManuStatus else {
            /// 相当于 downloadStatus == .successOver2s
            title = subtitle(listSource: source, sortType: sortType)
            image = SpaceEntry.successImage
            return SyncUIConfig(show: show,
                                image: image,
                                title: title,
                                isSyncing: isSyncing)
        }

        switch downloadStatus {
        case .none:
            show = false
        case .waiting:
            title = BundleI18n.SKResource.Doc_List_OfflineWaitDownload
            image = SpaceEntry.downWaitingImage
        case .downloading:
            title = BundleI18n.SKResource.Doc_List_OfflineDownloading
            image = SpaceEntry.syncingImage
            isSyncing = true
        case .success:
            title = BundleI18n.SKResource.Doc_List_OfflineDownloadSucceed
            image = SpaceEntry.successImage
        case .successOver2s:
            //            show = false
            // 这里理论上不会走到
            title = subtitle(listSource: source, sortType: sortType)
            image = SpaceEntry.successImage
        case .fail:
            title = BundleI18n.SKResource.Doc_List_OfflineDownloadFailed
            image = SpaceEntry.failedImage
        }

        if !DocsConfigManager.isShowOffline {
            show = false
        } else if show == false, isSetManuOffline {
            DocsLogger.info("file: \(type) is set manualOffline, but don't show download status, hadShownManuStatus:\(hadShownManuStatus)", component: LogComponents.manuOffline)

        }

        return SyncUIConfig(show: show,
                            image: image,
                            title: title,
                            isSyncing: isSyncing)
    }
}
