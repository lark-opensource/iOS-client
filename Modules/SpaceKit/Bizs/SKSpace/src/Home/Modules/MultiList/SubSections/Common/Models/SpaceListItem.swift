//
//  SpaceListItem.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import Foundation
import SKCommon
import SwiftyJSON
import SKFoundation
import SKResource

extension SpaceListItem {

    typealias IconType = SpaceList.IconType
    typealias SyncStatus = SpaceEntry.SyncUIConfig

    struct SlideConfig {
        let actions: [SlideAction]
        let handler: (UIView, SlideAction) -> Void
    }

    struct AccessoryItem {
        let identifier: String
        let image: UIImage
        let handler: (UIView) -> Void
    }

    enum ThumbnailType: Equatable {
        case bigType(image: UIImage)
        case thumbnail(info: SpaceList.ThumbnailInfo)
    }
}

enum SpaceListItemType: Equatable {
    case driveUpload(item: DriveStatusItem)
    case spaceItem(item: SpaceListItem)
    // 在当前section中插入一个分割 cell
    case inlineSectionSeperator(title: String)
    // 用于避免单个 cell 在 grid 模式下不居中的问题，仅在共享文件夹根目录有此场景
    case gridPlaceHolder

    static var hiddenFolderSeperator: SpaceListItemType {
        .inlineSectionSeperator(title: BundleI18n.SKResource.Doc_List_HiddenFolders)
    }

    // 是否是文档，主要用于排除掉列表中的非文档内容，计算实际的列表下标
    var isDocument: Bool {
        switch self {
        case .spaceItem:
            return true
        case .driveUpload, .inlineSectionSeperator, .gridPlaceHolder:
            return false
        }
    }
}

struct SpaceListItem {
    let enable: Bool
    let title: String

    let moreEnable: Bool
    let moreHandler: ((UIView) -> Void)?

    let needRedPoint: Bool
    let isStar: Bool
    let isShortCut: Bool

    let accessoryItem: AccessoryItem?
    let hasTemplateTag: Bool
    let isExternal: Bool

    // list 和 grid 下的 icon 逻辑不一致，暂时区分存放
    let listIconType: IconType
    let gridIconType: IconType

    let syncStatus: SyncStatus
    let subtitle: String?
    // 密级标签名字
    let secureLabelName: String?

    let thumbnailType: ThumbnailType?
    // 侧滑菜单配置
    let slideConfig: SlideConfig?
    // 暂时为了点击事件中取到对应的Entry，后续优化掉
    let entry: SpaceEntry
    // 通过几个关键属性推导出来的唯一 ID
    let itemID: String
    // 关联组织自定义标签
    let organizationTagValue: String?
    // 当前文档的排序方式
    let sortType: SpaceSortHelper.SortType
}

extension SpaceListItem: Equatable {
    static func == (lhs: SpaceListItem, rhs: SpaceListItem) -> Bool {
        return lhs.enable == rhs.enable
            && lhs.title == rhs.title
            && lhs.moreEnable == rhs.moreEnable
            && lhs.needRedPoint == rhs.needRedPoint
            && lhs.isStar == rhs.isStar
            && lhs.accessoryItem?.identifier == rhs.accessoryItem?.identifier
            && lhs.hasTemplateTag == rhs.hasTemplateTag
            && lhs.isExternal == rhs.isExternal
            && lhs.listIconType == rhs.listIconType
            && lhs.syncStatus == rhs.syncStatus
            && lhs.subtitle == rhs.subtitle
            && lhs.thumbnailType == rhs.thumbnailType
            && lhs.slideConfig?.actions == rhs.slideConfig?.actions
            && lhs.secureLabelName == rhs.secureLabelName
            && lhs.organizationTagValue == rhs.organizationTagValue
            && lhs.sortType == rhs.sortType
            // 直接比较 item 有 bad case，如设置快速访问、订阅等状态后，item 无法反应 entry 的变化，导致 action handler 没有更新，所以需要额外比较一下 entry
            && lhs.entry.equalTo(rhs.entry)
    }
}

protocol SpaceListItemInteractHandler {
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)?
    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)?
    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig?
    // 为无权限文件生成侧滑菜单，仅在子文件夹内需要处理
    func generateSlideConfigForNoPermissionEntry(entry: SpaceEntry) -> SpaceListItem.SlideConfig?
}

extension SpaceListItemInteractHandler {
    func generateSlideConfigForNoPermissionEntry(entry: SpaceEntry) -> SpaceListItem.SlideConfig? { nil }
}
