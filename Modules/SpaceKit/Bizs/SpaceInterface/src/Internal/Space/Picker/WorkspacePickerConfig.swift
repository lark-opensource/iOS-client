//
//  WorkspacePickerConfig.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2022/9/6.
//

import Foundation

public struct PickerEntranceConfig {
    public var icon: UIImage
    public var title: String
    public var handler: (UIViewController) -> Void

    public init(icon: UIImage, title: String, handler: @escaping (UIViewController) -> Void) {
        self.icon = icon
        self.title = title
        self.handler = handler
    }
}

public enum WorkspacePickerAction {
    case createWiki

    case createWikiShortcut
    case createSpaceShortcut

    case moveWiki
    case moveSpace

    case copyWiki
    case copySpace
}

public enum WorkspacePickerLocation: Equatable {
    case wikiNode(location: WikiPickerLocation)
    case folder(location: SpaceFolderPickerLocation)

    public var targetSpaceID: String {
        switch self {
        case let .wikiNode(location):
            return location.spaceID
        case let .folder(location):
            return location.folderToken
        }
    }

    public var targetModule: WorkspacePickerTracker.TargetModule {
        switch self {
        case let .wikiNode(location):
            return location.isMylibrary ? .myLibrary : .wiki
        case let .folder(location):
            return location.targetModule
        }
    }

    public var targetFolderType: WorkspacePickerTracker.TargetFolderType? {
        switch self {
        case .wikiNode:
            return nil
        case let .folder(location):
            return location.targetFolderType
        }
    }
    
    public var targetParentToken: String {
        switch self {
        case let .folder(location):
            return location.folderToken
        case let .wikiNode(location):
            return location.wikiToken
        }
    }
    
    public var targetBizType: Int {
        switch self {
        case .folder:
            return 1
        case .wikiNode:
            return 2
        }
    }
}

public typealias WorkspacePickerCompletion = (WorkspacePickerLocation, UIViewController) -> Void
// TODO: Space 1.0 待删
// 入参为目标文件夹是否是 2.0 文件夹，需要报错则返回一个 toast 文案，返回 nil 表示通过检查，只有选择 space 文件夹时才会生效
public typealias WorkspaceOwnerTypeChecker = (Bool) -> String?

public enum WorkspacePickerEntrance: Equatable {
    case mySpace
    case sharedSpace
    case wiki
    case myLibrary
    case unorganized
    // 云盘子标题header
    case cloudDriverHeader
}

public struct WorkspacePickerConfig {
    // 标题名字
    public var title: String
    // 操作按钮名字
    public var actionName: String
    // 用于获取最近操作列表用，透传给后端，不涉及其他逻辑
    public var action: WorkspacePickerAction

    public var extraEntranceConfig: PickerEntranceConfig?

    public var entrances: [WorkspacePickerEntrance]
    // TODO: Space 1.0 待删
    public var ownerTypeChecker: WorkspaceOwnerTypeChecker?

    public var disabledWikiToken: String?
    // TODO: Space 1.0 待删
    // 仅在操作 Space 1.0 文档时才传 true
    public var usingLegacyRecentAPI: Bool
    // 收敛埋点上下文信息
    public var tracker: WorkspacePickerTracker

    public var completion: WorkspacePickerCompletion

    public init(title: String,
                actionName: String,
                action: WorkspacePickerAction,
                extraEntranceConfig: PickerEntranceConfig? = nil,
                entrances: [WorkspacePickerEntrance],
                ownerTypeChecker: WorkspaceOwnerTypeChecker? = nil,
                disabledWikiToken: String? = nil,
                usingLegacyRecentAPI: Bool = false,
                tracker: WorkspacePickerTracker,
                completion: @escaping WorkspacePickerCompletion) {
        self.title = title
        self.actionName = actionName
        self.action = action
        self.extraEntranceConfig = extraEntranceConfig
        self.entrances = entrances
        self.ownerTypeChecker = ownerTypeChecker
        self.disabledWikiToken = disabledWikiToken
        self.usingLegacyRecentAPI = usingLegacyRecentAPI
        self.tracker = tracker
        self.completion = completion
    }
}
