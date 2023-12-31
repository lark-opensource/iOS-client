//
//  SpaceBaseModel.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/4/3.
//

import Foundation
import LarkDocsIcon

public typealias DocsType = LarkDocsIcon.CCMDocsType

// 定位 Wiki 的基本信息
// 不要轻易增加属性，而是基于 WikiMeta 再包装新的数据结构
public struct WikiMeta: Equatable {
    public let wikiToken: String
    public let spaceID: String
    public init(wikiToken: String, spaceID: String) {
        self.wikiToken = wikiToken
        self.spaceID = spaceID
    }

    public init(location: WikiPickerLocation) {
        wikiToken = location.wikiToken
        spaceID = location.spaceID
    }
}

// 定位文档实体的基本信息
public struct SpaceMeta: Equatable {
    public let objToken: String
    public let objType: DocsType
    public init(objToken: String, objType: DocsType) {
        self.objToken = objToken
        self.objType = objType
    }
}

// 需要关注文档挂载点时的基本信息
public struct WorkspaceMeta {
    public enum MountLocation {
        case wiki(meta: WikiMeta)
        case space(nodeToken: String)
    }
    public let mountLocation: MountLocation
    public let contentMeta: SpaceMeta
}

public struct WikiPickerLocation: Equatable {

    public var wikiToken: String
    public var nodeName: String
    public var spaceID: String
    public var spaceName: String
    // 是否是 mainRoot 节点，目前仅在 wiki 移动到场景有意义需要关注
    public var isMainRoot: Bool
    // 是否是在文档库操作
    public var isMylibrary: Bool

    public init(wikiToken: String,
                nodeName: String,
                spaceID: String,
                spaceName: String,
                isMainRoot: Bool = false,
                isMylibrary: Bool) {
        self.wikiToken = wikiToken
        self.nodeName = nodeName
        self.spaceID = spaceID
        self.spaceName = spaceName
        self.isMainRoot = isMainRoot
        self.isMylibrary = isMylibrary
    }
}

public struct SpaceFolderPickerLocation: Equatable {
    public typealias TargetModule = WorkspacePickerTracker.TargetModule
    public typealias TargetFolderType = WorkspacePickerTracker.TargetFolderType

    public var folderToken: String
    public var folderType: FolderType
    public var isSingleContainerNode: Bool {
        folderType.v2
    }
    public var isExternal: Bool
    // 暂时只用到 createSubNode 点位，未来有需要再拓展为对应的权限数据结构
    public var canCreateSubNode: Bool
    // 以下为埋点用参数，不做业务逻辑
    public var targetModule: TargetModule
    public var targetFolderType: TargetFolderType

    public init(folderToken: String,
                folderType: FolderType,
                isExternal: Bool,
                canCreateSubNode: Bool,
                targetModule: TargetModule,
                targetFolderType: TargetFolderType) {
        self.folderToken = folderToken
        self.folderType = folderType
        self.isExternal = isExternal
        self.canCreateSubNode = canCreateSubNode
        self.targetModule = targetModule
        self.targetFolderType = targetFolderType
    }
}

public enum DataModelLabel: String {
    case personal
    case recent
    case pin
    case favorites
    case unpinFiles
    case shareFiles
    case shareFolder
    case trash
    case myFolderList //个人文件夹根目录
    case folderDetail //文件夹子目录
    case feed
    case none
    case manuOffline
    case bitableLanding
    case spaceTabRecent
}

/// wiki节点信息基本信息
/// wikiToken: wiki token
/// objToken: wiki节点对应的单品真实token
/// docsType: wiki节点对应的单品类型
/// spaceID: wiki节点所在知识库ID
public struct WikiNodeMeta {
    public let wikiToken: String
    public let objToken: String
    public let docsType: DocsType
    public let spaceID: String

    public init(wikiToken: String,
                objToken: String,
                docsType: DocsType,
                spaceID: String) {
        self.wikiToken = wikiToken
        self.objToken = objToken
        self.docsType = docsType
        self.spaceID = spaceID
    }
}

// 根据owner_type判断 https://bytedance.feishu.cn/docs/doccnOkqTF827k0MKCEtv2rYVJc#OuVLBC
public enum FolderType: Equatable, Hashable {
    case common
    case share
    case v2Common
    case v2Shared
    case unknown(type: Int)

    // disable-lint-next-line: magic number
    public static let unknownDefaultType: FolderType = .unknown(type: 999)
    static let oldShareFolder = FolderType.share
    public var isOldShareFolder: Bool {
        return FolderType.oldShareFolder == self
    }

    public var v2: Bool {
        switch self {
        case .v2Shared, .v2Common:
            return true
        default:
            return false
        }
    }
    public var isSupportedType: Bool {
        return FolderType.common == self || isShareFolder || v2
    }

    public var ownerType: Int {
        switch self {
        case .common:
            return 0
        case .share:
            return 1
        case .v2Common, .v2Shared:
            return 5
        case let .unknown(type):
            return type
        }
    }

    public var isShareFolder: Bool {
        switch self {
        case .share, .v2Shared:
            return true
        default:
            return false
        }
    }

    public init(ownerType: Int, shareVersion: Int?, isShared: Bool?) {
        switch ownerType {
        case 0:
            self = .common
        case 1:
            self = .oldShareFolder
        case 5:
            if isShared == true {
                self = .v2Shared
            } else {
                self = .v2Common
            }
        default: self = .unknown(type: ownerType)
        }
    }
}
