//
//  WorkspacePickerExtension.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/7/12.
//  


import Foundation
import SpaceInterface
import SKResource
import SKFoundation

extension WorkspacePickerEntrance {

    public static var spaceOnly: [WorkspacePickerEntrance] {
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            return [.cloudDriverHeader, .mySpace, .sharedSpace]
        } else {
            return [.mySpace, .sharedSpace]
        }
    }

    public static var wikiOnly: [WorkspacePickerEntrance] {
        if UserScopeNoChangeFG.WWJ.cloudDriveEnabled, MyLibrarySpaceIdCache.get() != nil {
            return [.myLibrary, .wiki]
        }
        return [.wiki]
    }

    public static var wikiAndSpace: [WorkspacePickerEntrance] {
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            // 虽说新首页用户一定有文档库，保险起见还是判断是否有文档库ID，否则打开会失败
            if MyLibrarySpaceIdCache.get() != nil {
                return [.myLibrary, .wiki, .cloudDriverHeader, .mySpace, .sharedSpace]

            } else {
                return [.wiki, .cloudDriverHeader, .mySpace, .sharedSpace]
            }
        }
        // 我的文档库FG开启，且用户进入过文档库缓存到了spaceID(文档库有可能未创建)
        if UserScopeNoChangeFG.WWJ.cloudDriveEnabled, MyLibrarySpaceIdCache.get() != nil {
            return [.myLibrary, .mySpace, .sharedSpace, .wiki]
        }
        return [.mySpace, .sharedSpace, .wiki]
    }
}

public extension Array where Element == WorkspacePickerEntrance {

    static var spaceOnly: [WorkspacePickerEntrance] {
        WorkspacePickerEntrance.spaceOnly
    }

    static var wikiOnly: [WorkspacePickerEntrance] {
        WorkspacePickerEntrance.wikiOnly
    }

    static var wikiAndSpace: [WorkspacePickerEntrance] {
        WorkspacePickerEntrance.wikiAndSpace
    }
}

public extension WorkspacePickerConfig {
    init(title: String,
                action: WorkspacePickerAction,
                extraEntranceConfig: PickerEntranceConfig? = nil,
                entrances: [WorkspacePickerEntrance],
                ownerTypeChecker: WorkspaceOwnerTypeChecker? = nil,
                disabledWikiToken: String? = nil,
                usingLegacyRecentAPI: Bool = false,
                tracker: WorkspacePickerTracker,
                completion: @escaping WorkspacePickerCompletion) {
        self.init(title: title,
                  actionName: BundleI18n.SKResource.Doc_Wiki_Confirm, // 默认都用 "确定" 的文案
                  action: action,
                  extraEntranceConfig: extraEntranceConfig,
                  entrances: entrances,
                  ownerTypeChecker: ownerTypeChecker,
                  disabledWikiToken: disabledWikiToken,
                  usingLegacyRecentAPI: usingLegacyRecentAPI,
                  tracker: tracker,
                  completion: completion)
    }
}
