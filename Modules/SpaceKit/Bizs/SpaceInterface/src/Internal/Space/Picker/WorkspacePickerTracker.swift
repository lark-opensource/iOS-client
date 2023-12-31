//
//  WorkspacePickerTracker.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2022/5/31.
//

import Foundation

public extension WorkspacePickerTracker {
    // wiki 相关操作的目录树操作的触发位置
    enum TriggerLocation: String, Equatable {
        // 从首页触发
        case wikiHome = "wiki_home"
        // 从目录树触发
        case wikiTree = "wiki_tree"
        // 从文件夹列表内item上触发
        case catalogListItem = "list_item"
        // 从文件夹列表的 FAB 上触发
        case catalogAddIcon = "add_icon"
        // 导航栏、More 面板内
        case topBar = "docs_topbar"
        // 置顶云文档节点新建
        case sidebarPinDocs = "sidebar_pin_docs"
        // 置顶知识库节点新建
        case sidebarPinWiki = "sidebar_pin_wiki"
        // 我的文档库_tab新建
        case sidebarMyDocsTab = "sidebar_my_docs_tab"
        // 我的文档库_节点新建
        case sidebarMyDocsNode = "sidebar_my_docs_node"
    }

    // Wiki picker 内的埋点参数，对应 viewType
    enum ActionType: String {
        case createFile = "create_file"
        case makeCopyTo = "make_a_copy_to"
        case moveTo = "move_to"
        case moveToWiki = "move_to_wiki"
        case shortcutTo = "shortcut_to"
        case uploadTo = "upload_file_to"
    }

    // picker 选中的位置
    enum TargetModule: String, Equatable {
        // 我的空间内的位置
        case personal
        // 共享空间内的位置
        case shared
        // 知识库内的位置
        case wiki
        // 默认位置，如在当前位置
        case defaultLocation = "default_location"
        // 无法区分我的空间、共享空间时，用这个兜底，如通过搜索进入文件夹
        case space
        // 我的文档库
        case myLibrary = "my_docs"
    }

    enum TargetFolderType: String, Equatable {
        // 普通个人文件夹
        case folder
        // 共享文件夹
        case sharedFolder = "shared_folder"
    }
}

public struct WorkspacePickerTracker {

    public var actionType: ActionType
    public var triggerLocation: TriggerLocation

    public init(actionType: ActionType, triggerLocation: TriggerLocation) {
        self.actionType = actionType
        self.triggerLocation = triggerLocation
    }
}
