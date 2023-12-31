//
//  PermissonManager+EmbededDoc.swift
//  SKCommon
//
//  Created by guoqp on 2022/3/3.
//

import Foundation
import SwiftyJSON
import HandyJSON
import SKFoundation
import RxSwift
import SKInfra

///内嵌文档授权相关
extension PermissionManager {
    /// 获取内嵌文档列表
    public func embededDocAuthList(token: String,
                                   type: Int,
                                   taskId: String,
                                   cursor: String? = nil,
                                   previousData: EmbedDocAuthListResponse? = nil,
                                   complete: @escaping ((EmbedDocAuthListResponse?, Error?) -> Void)) {
        var subpath = "?origin_object_type=\(type)"
        if let cursor = cursor {
            subpath = "\(subpath)&cursor=\(cursor.urlEncoded())"
        }
        subpath = "\(subpath)&origin_object_token=\(token)"

        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.embedDocAuthList(taskId) + subpath,
            params: nil
        // nolint-next-line: magic number
        ).set(method: .GET).set(timeout: 20).makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { [weak self] json, error in
            guard error == nil else {
                DocsLogger.error("embededDocAuthList failed", error: error)
                DispatchQueue.main.async {
                    complete(previousData, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("embededDocAuthList no code key")
                DispatchQueue.main.async {
                    complete(previousData, error)
                }
                return
            }
            if let err = DocsNetworkError(code) {
                DocsLogger.error("embededDocAuthList code is \(code)")
                DispatchQueue.main.async {
                    complete(previousData, err)
                }
                return
            }
            let data = json["data"]
            let result = data["result"].arrayValue
            var model = previousData
            if model == nil {
                model = EmbedDocAuthListResponse()
            }

            let docs: [EmbedDoc] = result.compactMap { json in
                guard let objectToken = json["object_token"].string,
                      let token = json["token"].string,
                      let objectType = json["object_type"].int,
                      let ownerId = json["owner_id"].string,
                      let owneName = json["owner_name"].string,
                      let title = json["title"].string,
                      let chatHasPermission = json["chat_has_permission"].bool,
                      let permType = json["perm_type"].int,
                      let senderHasPermission = json["sender_has_permission"].bool,
                      let senderHasSharePermission = json["sender_has_share_permission"].bool else {
                          return nil
                      }
                let type = json["type"].int
                return EmbedDoc(objectToken: objectToken,
                                token: token,
                                type: type ?? objectType,
                                objectType: objectType,
                                ownerId: ownerId,
                                ownerName: owneName,
                                title: title,
                                permType: EmbedDocPermType(rawValue: permType) ?? .container,
                                chatHasPermission: chatHasPermission,
                                senderHasPermission: senderHasPermission,
                                senderHasSharePermission: senderHasSharePermission)
            }

            model?.addEmbedDocs(nodes: docs)

            if let hasPermissionCount = data["total_has_permission"].int {
                model?.hasPermissionCount = hasPermissionCount
            }
            if let noPermissonCount = data["total_no_permission"].int {
                model?.noPermissonCount = noPermissonCount
            }

            guard let isLast = data["is_last"].bool, isLast == false,
                  let nextCusor = data["next_cusor"].string, !nextCusor.isEmpty else {
                      DispatchQueue.main.async {
                          complete(model, nil)
                      }
                      return
                  }
            DocsLogger.error("embededDocAuthList have more docs next_cusor is \(nextCusor)")
            self?.embededDocAuthList(token: token, type: type, taskId: taskId,
                                     cursor: nextCusor, previousData: model, complete: complete)
        })
    }

    // nolint: duplicated_code
    /// 对内嵌文档进行批量授权
    func embededDocAuth(token: String,
                        embedAuthModels: [EmbedAuthModel],
                        complete: @escaping ((JSON?, Error?) -> Void)) {
        
        var dictionary = [[String: Any]]()
        dictionary = embedAuthModels.map {
            return ["token": $0.token,
                    "entity_type": $0.type,
                    "collaborator":
                     ["id": $0.collaboratorId,
                       "type": $0.collaboratorType,
                      "role": $0.collaboratorRole.rawValue]
                   ]
        }
        //        let collaboratorString: String
        //        do {
        //            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        //            collaboratorString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        //        } catch {
        //            collaboratorString = ""
        //        }
        let parameters: [String: Any] = ["authorize_pair_list": dictionary]
        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.embededDocAuth,
            params: parameters
        )
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard error == nil else {
                DocsLogger.error("embededDocAuth failed! error", error: error)
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("embededDocAuth failed! code key is nil")
                DispatchQueue.main.async {
                    complete(nil, CollaboratorsError.parseError)
                }
                return
            }
            if let err = DocsNetworkError(code) {
                DocsLogger.error("embededDocAuth failed! code is \(code)")
                DispatchQueue.main.async {
                    complete(json, err)
                }
                return
            }
            let data = json["data"]
            DispatchQueue.main.async {
                DocsLogger.info("embededDocAuth success!")
                complete(data, nil)
            }
        })
    }


    ///对文档进行批量取消授权
    func embededDocCancelAuth(token: String,
                              embedAuthModels: [EmbedAuthModel],
                              complete: @escaping ((JSON?, Error?) -> Void)) {

        var dictionary = [[String: Any]]()
        dictionary = embedAuthModels.map {
            return ["token": $0.token,
                    "entity_type": $0.type,
                    "collaborator":
                     ["id": $0.collaboratorId,
                       "type": $0.collaboratorType,
                      "role": $0.collaboratorRole.rawValue]
                   ]
        }
        //        let collaboratorString: String
        //        do {
        //            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        //            collaboratorString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        //        } catch {
        //            collaboratorString = ""
        //        }
        let parameters: [String: Any] = ["authorize_pair_list": dictionary]
        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.embededDocCancelAuth,
            params: parameters
        )
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard error == nil else {
                DocsLogger.error("embededDocCancelAuth failed! error", error: error)
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("embededDocCancelAuth failed! code key is nil")
                DispatchQueue.main.async {
                    complete(nil, CollaboratorsError.parseError)
                }
                return
            }
            if let err = DocsNetworkError(code) {
                DocsLogger.error("embededDocCancelAuth failed! code is \(code)")
                DispatchQueue.main.async {
                    complete(json, err)
                }
                return
            }
            let data = json["data"]
            DispatchQueue.main.async {
                DocsLogger.info("embededDocCancelAuth success!")
                complete(data, nil)
            }
        })
    }

    /// 记录内嵌文档授权状态
    func embedDocRecord(token: String,
                        type: Int,
                        taskId: String,
                        status: [EmbedAuthRecodeStatus],
                        complete: @escaping ((Bool, Error?) -> Void)) {

        var dictionary = [[String: Any]]()
        dictionary = status.map {
            return ["auth_object_token": $0.token,
                    "auth_object_type": $0.type,
                    "permission": $0.permission,
                    "perm_type": $0.permType.rawValue]
        }

        let parameters: [String: Any] = ["origin_object_token": token,
                                         "origin_object_type": type,
                                         "auth_object_list": dictionary]
        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.embedDocRecord(taskId),
            params: parameters
        )
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard error == nil else {
                DocsLogger.error("embedDocRecord failed! error", error: error)
                DispatchQueue.main.async {
                    complete(false, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("embedDocRecord failed! code key is nil")
                DispatchQueue.main.async {
                    complete(false, CollaboratorsError.parseError)
                }
                return
            }
            if let err = DocsNetworkError(code) {
                DocsLogger.error("embedDocRecord failed! code is \(code)")
                DispatchQueue.main.async {
                    complete(false, err)
                }
                return
            }
            DispatchQueue.main.async {
                DocsLogger.info("embedDocRecord success!")
                complete(true, nil)
            }
        })
    }
    // enable-lint: duplicated_code

    ///更新内嵌文档卡片状态
    func embededDocUpdateCard(token: String,
                              type: Int,
                              taskId: String,
                              complete: @escaping ((Bool, Error?) -> Void)) {
        let parameters: [String: Any] = ["origin_object_token": token,
                                         "origin_object_type": type]
        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.embededDocUpdateCard(taskId),
            params: parameters
        )
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard error == nil else {
                DocsLogger.error("embededDocUpdateCard failed! error", error: error)
                DispatchQueue.main.async {
                    complete(false, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("embededDocUpdateCard failed! code key is nil")
                DispatchQueue.main.async {
                    complete(false, CollaboratorsError.parseError)
                }
                return
            }
            if let err = DocsNetworkError(code) {
                DocsLogger.error("embededDocUpdateCard failed! code is \(code)")
                DispatchQueue.main.async {
                    complete(false, err)
                }
                return
            }
            DispatchQueue.main.async {
                DocsLogger.info("embededDocUpdateCard success!")
                complete(true, nil)
            }
        })
    }

    ///更新文档卡片状态
    static func updateDocCard(token: String, type: Int, cardId: String) -> Completable {
        let parameters: [String: Any] = ["origin_object_token": token,
                                         "origin_object_type": type,
                                         "update_doc_card_type": 1]

        let path = OpenAPI.APIPath.updateDocCard(cardId)
        return DocsRequest<JSON>(path: path, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
            .asCompletable()
    }
}
