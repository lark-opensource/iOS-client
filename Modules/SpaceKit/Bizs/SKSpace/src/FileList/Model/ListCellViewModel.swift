//
//  ListCellViewModel.swift
//  SKECM
//
//  Created by bupozhuang on 2020/7/28.
//
// disable-lint: magic number

import Foundation
import SKFoundation
import SKCommon
import RxDataSources

public final class ListCellViewModel {
    typealias Parser = SpaceList.ItemDataParser

    private var showStarEnable: Bool = DocsConfigManager.isShowStar
    var synConfig: SpaceEntry.SyncUIConfig // 同步状态和subTitle
    var source: FileSource
    var mainTitle: String?
    var attributeTitle: NSAttributedString?
    var attributeDigest: NSAttributedString?
    var showStarButton: Bool = false // 是否展示收藏按钮
    var showPermTipButton: Bool = false // 是否展示权限提示按钮
    var permTipButtonImage: UIImage? // 权限提示图标
    var showRedpoint: Bool = false // 是否展示红点
    var iconType: SpaceList.IconType // 展示新版icon数据 或 旧版本文件类型icon 或 drive缩略图
    var showTemplateTag: Bool = false
    var showExternalLabel: Bool = false
    var showSubTitle: Bool = true
    var subTitle: String?
    var enableSwipe: Bool = true
    var enable: Bool = true
    var fileEntry: SpaceEntry
    var isShortCut: Bool { fileEntry.isShortCut }
    
    init(file: SpaceEntry,
         source: FileSource = .unknown,
         isShowCreateTime: Bool = false,
         folderFile: SpaceEntry? = nil) {
//        #if DEBUG
//        assert(!Thread.isMainThread, "Warning: Don't Parse data on Main Thread")
//        #endif
        self.fileEntry = file
        self.source = source
        // 生成同步状态数据
        let sortType: SpaceSortHelper.SortType = isShowCreateTime ? .createTime : .lastOpenTime
        synConfig = file.needShowSyncImage(source: source, sortType: sortType)
        //无权限文件
        let shouldShowNoPermBiz = file.type.isBiz
        // icon展示类型
        iconType = Parser.listIconType(file: file, shouldShowNoPermBiz: shouldShowNoPermBiz, preferSquareDefaultIcon: false)
        // 标题
        mainTitle = Parser.mainTitle(file: file, shouldShowNoPermBiz: shouldShowNoPermBiz)
        
        // 无权限提示按钮
        (showPermTipButton, permTipButtonImage) = Parser.permTipButton(file: file, folderFile: folderFile)
        // showStar: fg开启、非收藏列表 的被收藏文件
        showStarButton = showStarEnable && source != .favorites && file.stared

        showTemplateTag = file.hasTemplateTag
        // 外部标签
        showExternalLabel = Parser.showExternalLabelInCell(file: file, folderFile: folderFile as? FolderEntry, source: source)
        
        // 子标题
        if !synConfig.show && shouldShowNoPermBiz && !file.hasPermission {
            showSubTitle = false
        } else {
            showSubTitle = true
        }
        
        subTitle = file.makeSubtitle(source, isShowCreateTime: isShowCreateTime)
        
        //无权限文件限制左滑
        enableSwipe = true
        if shouldShowNoPermBiz, file.hasPermission == false {
            enableSwipe = false
        }

        let networkOn = DocsNetStateMonitor.shared.isReachable
        if !networkOn {
            enable = file.canOpenWhenOffline
        }
    }
}

extension ListCellViewModel: SpaceListData {
    public var dataType: ListDataType { return .listFile }
    public var height: CGFloat { return 67 }
    public var file: SpaceEntry? { return fileEntry }
}

extension ListCellViewModel: IdentifiableType, Equatable {
    public var identity: String {
        return fileEntry.objToken
    }
    
    public static func == (lhs: ListCellViewModel, rhs: ListCellViewModel) -> Bool {
        return lhs.synConfig == rhs.synConfig
            && lhs.mainTitle == rhs.mainTitle
            && lhs.showExternalLabel == rhs.showExternalLabel
            && lhs.showStarButton == rhs.showStarButton
            && lhs.showPermTipButton == rhs.showPermTipButton
            && lhs.permTipButtonImage == rhs.permTipButtonImage
            && lhs.showRedpoint == rhs.showRedpoint
            && lhs.iconType == rhs.iconType
            && lhs.showSubTitle == rhs.showSubTitle
            && lhs.subTitle == rhs.subTitle
            && lhs.enableSwipe == rhs.enableSwipe
            && lhs.enable == rhs.enable
    }
}
