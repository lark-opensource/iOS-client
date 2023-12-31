//
//  PublicSubPermissionBridgeHandler.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/4/19.
//

import Foundation
import BDXBridgeKit
import BDXServiceCenter
import SKFoundation
import SwiftyJSON

protocol PublicSubPermissionUpdateHandler: AnyObject {
    typealias PublicSubPermissionType = PublicSubPermissionBridgeHandler.PublicSubPermissionType
    func updatePublicSubPermission(publicPermissionMeta: PublicPermissionMeta, subPermission: PublicSubPermissionType)
}

class PublicSubPermissionBridgeHandler: BridgeHandler {

    /// 1. 添加协作者设置
    /// 2. 安全（创建副本、打印、导出、复制）
    /// 3. 评论（哪些人可以评论文档）
    enum PublicSubPermissionType: String {
        case manageCollaboratorEntity = "manage_collaborator_entity"
        case securityEntity = "security_entity"
        case commentEntity = "comment_entity"
        case showCollaboratorInfoEntity = "show_collaborator_info_entity"
        case copyEntity = "copy_entity"
    }

    let methodName = "ccm.permission.updatePublicSubPermission"
    let handler: BDXLynxBridgeHandler
    private weak var hostController: PublicSubPermissionUpdateHandler?

    init(hostController: PublicSubPermissionUpdateHandler) {
        self.hostController = hostController
        handler = { [weak hostController] (_, _, params, callback) in
            guard let hostController = hostController else { return }
            Self.handleEvent(hostController: hostController, params: params, completion: callback)
        }
    }

    private static func handleEvent(hostController: PublicSubPermissionUpdateHandler, params: [AnyHashable: Any]?, completion: @escaping (Int, [AnyHashable: Any]?) -> Void) {
        guard let params = params,
              let updateType = params["updateType"] as? String,
              let subPermissionType = PublicSubPermissionType(rawValue: updateType),
              let isFolder = params["isFolder"] as? Bool,
              let publicPermissionInfo = params["publicPermissionInfo"] as? [String: Any] else {
            DocsLogger.error("failed to parse update sub permission params")
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }

        let json = JSON(publicPermissionInfo)
        let meta: PublicPermissionMeta?
        if isFolder {
            meta = PublicPermissionMeta(v2FolderJson: json)
        } else {
            meta = PublicPermissionMeta(newJson: json)
        }
        guard let meta = meta else {
            DocsLogger.error("failed to parse public permission meta params")
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }
        hostController.updatePublicSubPermission(publicPermissionMeta: meta, subPermission: subPermissionType)
        completion(BDXBridgeStatusCode.succeeded.rawValue, nil)
    }
}
