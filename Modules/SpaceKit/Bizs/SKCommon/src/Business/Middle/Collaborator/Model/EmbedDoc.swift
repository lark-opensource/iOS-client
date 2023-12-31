//
//  EmbedDoc.swift
//  SKCommon
//
//  Created by guoqp on 2022/4/6.
//

import Foundation
import SwiftyJSON
import HandyJSON
import SKFoundation
import RxSwift
import UniverseDesignIcon
import SpaceInterface

enum EmbedAuthResult {
    case Success([EmbedDoc]) //成功
    case AllFail //全部失败
    case PartFail([EmbedDoc]) //部分失败
    case NoPermisson // 无权限
    case CollaboratorLimit //协作者上限
    ///批量授权不在这个场景内
    case cacBlocked //cac管控
}

enum EmbedAuthRole: Int {
    case None = 0 // 删除时传该枚举
    case CanView = 1
    // 单页面协作者
    case SinglePageNone = 10 // 删除时传该枚举
    case SinglePageCanView = 11
}

enum EmbedDocPermType: Int {
    /// 容器权限
    case container = -1
    /// 单页面权限
    case singlePage = 2
}

class EmbedAuthModel {
    var token: String
    var type: Int
    var collaboratorId: Int
    var collaboratorType: Int
    var collaboratorRole: EmbedAuthRole
    init(token: String, type: Int, collaboratorId: String, collaboratorType: Int, collaboratorRole: EmbedAuthRole) {
        self.token = token
        self.type = type
        self.collaboratorId = Int(collaboratorId) ?? 0
        self.collaboratorType = collaboratorType
        self.collaboratorRole = collaboratorRole
    }
}

class EmbedAuthRecodeStatus {
    var token: String
    var type: Int
    var permission: Int
    var permType: EmbedDocPermType
    init(token: String, type: Int, permission: Int, permType: EmbedDocPermType) {
        self.token = token
        self.type = type
        self.permission = permission
        self.permType = permType
    }
}

class EmbedDoc {
    /// 接受者是否有阅读权限
    var chatHasPermission: Bool
    /// 内嵌文档Token，Wiki文档时，返回DocToken。object_token用于授权
    let objectToken: String
    /// 用于授权
    let objectType: Int
    /// token，Wiki文档时，返回原token，Doc文档时，返回DocToken，用于端上类型判断和链接打开
    let token: String
    /// 对其token的类型，wiki的时候返回wiki_type,doc文档返回具体的doc_type
    let type: Int
    /// 文档ownerId
    let ownerId: String
    /// 文档owner名称
    let ownerName: String
    /// 发送者是否有阅读权限
    let senderHasPermission: Bool
    /// 发送者是否有分享权限
    var senderHasSharePermission: Bool
    /// 文档标题
    private let title: String
    /// 权限类型
    let permType: EmbedDocPermType

    init(objectToken: String, token: String, type: Int, objectType: Int, ownerId: String,
         ownerName: String, title: String, permType: EmbedDocPermType, chatHasPermission: Bool, senderHasPermission: Bool, senderHasSharePermission: Bool) {
        self.objectToken = objectToken
        self.objectType = objectType
        self.token = token
        self.type = type
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.title = title
        self.permType = permType
        self.chatHasPermission = chatHasPermission
        self.senderHasPermission = senderHasPermission
        self.senderHasSharePermission = senderHasSharePermission
    }

    public var displayTitle: String {
        if title.isEmpty {
            return DocsType(rawValue: type).untitledString
        } else {
            return title
        }
    }

    public var defaultIcon: UIImage {
        let docsType = DocsType(rawValue: type)
        guard docsType.isSupportedType else {
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        }
        switch docsType {
        case .folder:
            spaceAssertionFailure("Should be override by FolderEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .trash:
            spaceAssertionFailure("Trash type should not exist.")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        case .myFolder:
            spaceAssertionFailure("Should be override by FolderEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .file:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundImageColorful)
        case .wiki, .wikiCatalog:
            spaceAssertionFailure("Should be override by WikiEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocColorful)
        case .mediaFile:
            spaceAssertionFailure("Should be override by DriveEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundImageColorful)
        default:
            return UDIcon.getIconByKeyNoLimitSize(docsType.roundColorfulIconKey)
        }
    }
}

public final class EmbedDocAuthListResponse {
    /// 已授权文档数量（cursor为空时返回第一页，第1页才会返回）
    var hasPermissionCount: Int = 0
    /// 未授权文档数量和用户没有权限的文档数量之和（cursor为空时返回第一页，第1页才会返回）
    var noPermissonCount: Int = 0
    /// 内嵌文档列表
    private(set) var embedDocs: [EmbedDoc] = []

    func addEmbedDocs(nodes: [EmbedDoc]) {
        self.embedDocs.append(contentsOf: nodes)
    }
    func clear() {
        self.embedDocs = []
        self.hasPermissionCount = 0
        self.noPermissonCount = 0
    }
}
