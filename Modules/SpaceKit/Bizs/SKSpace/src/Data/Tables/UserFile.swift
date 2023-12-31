//
//  UserFile.swift
//  FileResource
//
//  Created by weidong fu on 29/1/2018.
//

import Foundation
import SKCommon
import SKInfra

///在数据库里的key
public enum DocFolderKey: Int, Equatable, Hashable, CaseIterable {
    case pins = 1
    case fav = 2
    case share = 3
    case recent = 4
    case personal = 5
    case shareFolder = 6
    case trash = 7
    case manuOffline = 8
    case myFolderList = 10
    case shareFolderV2 = 11
    case hiddenFolder = 12
    case bitableRecent = 13
    // 新Space首页顶部独立最近列表
    case spaceTabRecent = 14
    // 新space首页共享目录树列表
    case spaceTabShared = 15
    case personalFolderV2 = 16
    // 未整理列表
    case personalFileV3 = 17
    // Bitable 首页快速访问
    case baseQuickAccess = 18
    // Bitable 首页收藏列表
    case baseFavorites = 19
    // 快速访问文件夹列表
    case pinFolderList = 20

    // 打印在日志使用的名字
    public var name: String {
        switch self {
        case .pins:
            return "pins"
        case .fav:
            return "favorites"
        case .share:
            return "share"
        case .recent:
            return "recent"
        case .personal:
            return "personal"
        case .shareFolder:
            return "shareFolder"
        case .trash:
            return "trash"
        case .manuOffline:
            return "manualOffline"
        case .myFolderList:
            return "myFolderList"
        case .shareFolderV2:
            return "shareFolderV2"
        case .hiddenFolder:
            return "hiddenFolder"
        case .bitableRecent:
            return "bitableRecent"
        case .spaceTabRecent:
            return "spaceTabRecent"
        case .spaceTabShared:
            return "spaceTabShared"
        case .personalFolderV2:
            return "personalFolderV2"
        case .personalFileV3:
            return "personalFileV3"
        case .baseFavorites:
            return "baseFavorites"
        case .baseQuickAccess:
            return "baseQuickAccess"
        case .pinFolderList:
            return "pinFolderList"
        }
    }

    ///  精简模式下是否要对列表做额外的过滤操作
    var affectByLeanMode: Bool {
        switch self {
        case .pins, .bitableRecent, .recent, .spaceTabRecent, .personal, .personalFolderV2, .personalFileV3, .baseQuickAccess, .pinFolderList:
            return true
        case .fav, .share, .shareFolder, .trash, .manuOffline, .myFolderList, .shareFolderV2, .hiddenFolder, .spaceTabShared, .baseFavorites:
            return false
        }
    }

    /// 列表内的 token 字段是否同时存在 ObjToken 与 nodeToken，对应 needCheckNode 参数
    var mixUsingObjTokenAndNodeToken: Bool {
        switch self {
        case .personal, .personalFolderV2, .personalFileV3:
            //单容器的情况下, 可能出现归我所有token为nodeToken和objToken混合
            return SettingConfig.singleContainerEnable
        case .shareFolder, .myFolderList:
            return true
        case .pins, .bitableRecent, .recent, .spaceTabRecent, .fav, .share, .trash, .manuOffline,
             .shareFolderV2, .hiddenFolder, .spaceTabShared, .baseFavorites, .baseQuickAccess,
             .pinFolderList:
            return false
        }
    }

    static func getAffectByLocalFakeEntriesKeys(isWiki: Bool) -> [DocFolderKey] {
        if isWiki {
            return [.recent, .bitableRecent, .spaceTabRecent]
        } else {
            return [.recent, .bitableRecent, .spaceTabRecent, .personal, .personalFileV3]
        }
    }
    /// 文档与文件夹混排的列表，影响文档插入的逻辑
    var mixShowFolderAndFiles: Bool {
        // 文件夹有单独的插入处理流程，暂时不算进来
        switch self {
        case .personal:
            return true
        default:
            return false
        }
    }

    /// 属于最近列表的 key，适配最近列表的一些本地维护逻辑
    static var recentListKeys: [DocFolderKey] {
        [.recent, bitableRecent, spaceTabRecent]
    }

    /// 属于我的空间的列表 key
    static var personalListKeys: [DocFolderKey] {
        [.personal, .personalFolderV2, .personalFileV3]
    }
    
    /// 属于共享文件列表的 key
    static var shareFileListKeys: [DocFolderKey] {
        [.share, .spaceTabShared]
    }

    static var quickAccessListKeys: [DocFolderKey] {
        [.pins, .baseQuickAccess, .pinFolderList]
    }

    static var favoritesListKeys: [DocFolderKey] {
        [.fav, .baseFavorites]
    }
}

public struct UserFile {
    /// 所有特殊列表，对应 DocFolderKey
    public var specialListMap: [DocFolderKey: FolderInfo] = [:]
    /// 我的文档里的所有文件夹，包括我的文档里的所有信息
    public var folderInfoMap = FolderInfoMap()

    public var basicInfo: String {
        var info: [String: Int] = ["folderInfoMap": folderInfoMap.folders.count]
        specialListMap.forEach { folderKey, folderInfo in
            info[folderKey.name] = folderInfo.files.count
        }
        return "\(info)"
    }
}
