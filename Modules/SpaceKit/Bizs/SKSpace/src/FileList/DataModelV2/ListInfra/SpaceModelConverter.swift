//
//  SpaceModelConverter.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/7/1.
//

import Foundation
import SKFoundation
import SKCommon
import SKResource
import UniverseDesignEmpty

private let spaceItemHandlerQueue = DispatchQueue(label: "space.list-item.handler")

enum SpaceModelConverter {

    typealias Parser = SpaceList.ItemDataParser

    struct Context {
        let sortType: SpaceSortHelper.SortType
        let folderEntry: FolderEntry?
        let listSource: FileSource
    }

    struct Config {
        // 密级是否启用
        let secretLabelEnable: Bool
        let netMonitor: SKNetStatusService
        var preferSquareDefaultIcon: Bool

        static var `default`: Config {
            Config(secretLabelEnable: LKFeatureGating.sensitivtyLabelEnable,
                   netMonitor: DocsNetStateMonitor.shared, preferSquareDefaultIcon: false)
        }
        
        static var baseHome: Config {
            Config(secretLabelEnable: LKFeatureGating.sensitivtyLabelEnable,
                   netMonitor: DocsNetStateMonitor.shared, preferSquareDefaultIcon: true)
        }
    }

    static func convert(entries: [SpaceEntry], context: Context, config: Config = .default, handler: SpaceListItemInteractHandler) -> [SpaceListItem] {
        return innerConvert(entries: entries,
                            context: context,
                            config: config,
                            handler: handler)
    }

    private static func innerConvert(entries: [SpaceEntry], context: Context, config: Config, handler: SpaceListItemInteractHandler) -> [SpaceListItem] {
        let start = Date().timeIntervalSince1970
        let folderEntry = context.folderEntry
        let isReachable = config.netMonitor.isReachable
        let allowShowStar = DocsConfigManager.isShowStar && context.listSource != .favorites
        let models = entries.map { (entry) -> SpaceListItem in
            let itemEnable = isReachable || entry.canOpenWhenOffline
            let shouldShowNoPermBiz = entry.type.isBiz
            let title = Parser.mainTitle(file: entry, shouldShowNoPermBiz: shouldShowNoPermBiz)
            let moreEnable = entry.hasPermission || !shouldShowNoPermBiz
            let isStar = allowShowStar && entry.stared
            let isExternal = Parser.showExternalLabelInCell(file: entry, folderFile: folderEntry, source: context.listSource)
            // 如果在 folder 中，且 folder 有关联组织 tag，则所有列表里的文档都不展示关联组织 tag
            let organizationTagValue = folderEntry?.organizationTagValue == nil ? entry.organizationTagValue : nil
            let listIconType = Parser.listIconType(file: entry, shouldShowNoPermBiz: shouldShowNoPermBiz, preferSquareDefaultIcon: config.preferSquareDefaultIcon)
            let gridIconType = Parser.gridIconType(file: entry, shouldShowNoPermBiz: shouldShowNoPermBiz, preferSquareDefaultIcon: config.preferSquareDefaultIcon)
            let syncStatus = entry.needShowSyncImage(source: context.listSource, sortType: context.sortType)
            let subtitle: String?
            if !syncStatus.show && shouldShowNoPermBiz && !entry.hasPermission {
                subtitle = nil
            } else {
                subtitle = entry.subtitle(listSource: context.listSource, sortType: context.sortType)
            }
            let thumbnailType = generateThumbnail(for: entry, shouldShowNoPermBiz: shouldShowNoPermBiz)

            let (showPermissionTip, tipImage) = Parser.permTipButton(file: entry, folderFile: folderEntry)
            let accessoryItem: SpaceListItem.AccessoryItem?
            if showPermissionTip,
               let permissionImage = tipImage,
               let handler = handler.handlePermissionTips(for: entry) {
                accessoryItem = SpaceListItem.AccessoryItem(identifier: "permission-tips", image: permissionImage, handler: handler)
            } else {
                accessoryItem = nil
            }
            let slideConfigs: SpaceListItem.SlideConfig?
            if shouldShowNoPermBiz, !entry.hasPermission {
                slideConfigs = handler.generateSlideConfigForNoPermissionEntry(entry: entry)
            } else {
                slideConfigs = handler.generateSlideConfig(for: entry)
            }

            var secureLabelName: String?
            if config.secretLabelEnable, entry.ownerTenantID == User.current.info?.tenantID,
               entry.secureLabelName?.isEmpty == false,
               entry.secLabelCode == .success, entry.typeSupportSecurityLevel {
                secureLabelName = entry.secureLabelName
            }

            // 目前发现更新排序规则时，存在 item 没有正确刷新问题，把排序状态作为 ID 的一部分触发强制刷新
            let itemID = "\(entry.objToken)_\(context.sortType)"

            let item = SpaceListItem(enable: itemEnable,
                                     title: title,
                                     moreEnable: moreEnable,
                                     moreHandler: handler.handleMoreAction(for: entry),
                                     needRedPoint: false,
                                     isStar: isStar,
                                     isShortCut: entry.isShortCut,
                                     accessoryItem: accessoryItem,
                                     hasTemplateTag: entry.hasTemplateTag,
                                     isExternal: isExternal,
                                     listIconType: listIconType,
                                     gridIconType: gridIconType,
                                     syncStatus: syncStatus,
                                     subtitle: subtitle,
                                     secureLabelName: secureLabelName,
                                     thumbnailType: thumbnailType,
                                     slideConfig: slideConfigs,
                                     entry: entry,
                                     itemID: itemID,
                                     organizationTagValue: organizationTagValue,
                                     sortType: context.sortType)
            return item
        }
        DocsLogger.debug("CellVM 总数: \(entries.count), 耗时: \(Date().timeIntervalSince1970 - start)")
        return models
    }

    private static func generateThumbnail(for entry: SpaceEntry, shouldShowNoPermBiz: Bool) -> SpaceListItem.ThumbnailType? {
        if entry.type == .folder {
            return .bigType(image: entry.defaultIcon)
        }

        // drive 的密钥失效缩略图需要特殊处理一下
        if entry.type == .file,
           entry.secretKeyDelete == true {
            return .bigType(image: UDEmptyType.ccmDocumentKeyUnavailable.defaultImage())
        }

        let unencryptURL: URL?
        if let urlString = entry.thumbnailURL {
            unencryptURL = URL(string: urlString)
        } else {
            unencryptURL = nil
        }
        if entry.hasPermission,
           let thumbInfo = SpaceThumbnailInfo(unencryptURL: unencryptURL, extraInfo: entry.thumbExtraInfo) {
            let thumbnailInfo = SpaceList.ThumbnailInfo(token: entry.objToken,
                                                        thumbInfo: thumbInfo,
                                                        source: .spaceList,
                                                        fileType: entry.docsType,
                                                        failedImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail,
                                                        placeholder: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
            return .thumbnail(info: thumbnailInfo)
        }

        if shouldShowNoPermBiz, !entry.hasPermission {
            guard let noPermissionIcon = entry.noPermIcon else {
                return nil
            }
            return .bigType(image: noPermissionIcon)
        } else {
            return .bigType(image: entry.defaultIcon)
        }
    }
}

enum SpaceVerticalGridModelConverter {
    static func convert(entries: [SpaceEntry], netMonitor: SKNetStatusService = DocsNetStateMonitor.shared) -> [SpaceVerticalGridItem] {
        return innerConvert(entries: entries, netMonitor: netMonitor)
    }

    private static func innerConvert(entries: [SpaceEntry], netMonitor: SKNetStatusService) -> [SpaceVerticalGridItem] {
        let isReachable = netMonitor.isReachable
        let items = entries.map { entry -> SpaceVerticalGridItem in
            let itemEnable = isReachable || entry.canOpenWhenOffline
            let title = entry.name
            let iconType = verticalGridIconType(for: entry)
            return SpaceVerticalGridItem(enable: itemEnable, title: title, needRedPoint: false,
                                         iconType: iconType, entry: entry)
        }
        return items
    }

    private static func verticalGridIconType(for entry: SpaceEntry) -> SpaceList.IconType {
        if let iconInfo = entry.customIcon,
           iconInfo.iconType.isCurSupported,
           !iconInfo.iconKey.isEmpty,
           !iconInfo.iconFSUnit.isEmpty {
            let placeHolder = entry.defaultIcon
            let iconData = SpaceList.NewIconData(iconKey: iconInfo.iconKey, fsUnit: iconInfo.iconFSUnit, placeHolder: placeHolder)
            return .newIcon(data: iconData)
        }
        return .icon(image: entry.quickAccessImage)
    }
}
