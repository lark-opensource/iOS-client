//
//  UserPermissionEntity.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation

/// CCM 内涉及 UserPermission 的实体数据类型
/// 按对应的后端接口维度进行区分
public enum UserPermissionEntity {
    /// CCM 内的文档用户权限模型，如果是文档附件，需要同时传入父文档的token和type
    /// 对应 /document/actions/state/ 接口
    case document(token: String, type: DocsType, parentMeta: SpaceMeta? = nil)
    /// Space 2.0 文件夹权限模型
    case folder(token: String)
    /// Space 1.0 文件夹权限模型
    case legacyFolder(info: SpaceV1FolderInfo)

    public static var personalRootFolder: Self {
        .folder(token: "")
    }

    public var meta: SpaceMeta {
        switch self {
        case let .document(token, type, _):
            return SpaceMeta(objToken: token, objType: type)
        case let .folder(token):
            return SpaceMeta(objToken: token, objType: .folder)
        case let .legacyFolder(info):
            return SpaceMeta(objToken: info.token, objType: .folder)
        }
    }
}

// TODO: 移到 Space 的 Interface 目录下
/// Space 1.0 文件夹数据模型
public struct SpaceV1FolderInfo: Equatable {
    public enum FolderType: Equatable {
        /// Space 1.0 个人文件夹
        case personal
        /// Space 1.0 共享文件夹，有 spaceID 额外参数
        case share(spaceID: String, isRoot: Bool, ownerID: String?)
    }

    public let token: String
    public let folderType: FolderType

    public init(token: String, folderType: FolderType) {
        self.token = token
        self.folderType = folderType
    }
}
