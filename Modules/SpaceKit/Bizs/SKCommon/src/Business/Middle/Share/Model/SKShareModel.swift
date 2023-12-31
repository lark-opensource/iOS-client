//
//  SKShareModel.swift
//  SKCommon
//
//  Created by guoqp on 2021/7/23.
//

import Foundation
import SwiftyJSON
import SKFoundation
import RxSwift
import SKInfra


public enum ShareBizMetaError: Error {
    case parseDataFailed
    case wrongCode
}


public struct ShareBizMeta {
    var createDate: String?
    var createSource: Int?
    var createTime: Int?
    var createUid: String?
    var createUserName: String?
    var deleteFlag: Int?
    var docVersion: Int?
    var editTime: Int?
    var editUserName: String?
    var isExternal: Bool?
    var isPined: Bool?
    var isStared: Bool?
    var objType: String?
    var ownerID: String?
    var ownerUserName: String?
    var realSubType: Int?
    var serverTime: Int?
    var subType: String?
    var tenantId: String?
    var title: String?
    var type: Int?
    var url: String?
    var version: Int?
    // 密级信息
    public var secretLevel: SecretLevel?

    // swiftlint:disable cyclomatic_complexity
    init(_ json: JSON) {

        if let createDate = json["create_date"].string { self.createDate = createDate }
        if let createSource = json["create_source"].int { self.createSource = createSource }
        if let createTime = json["create_time"].int { self.createTime = createTime }
        if let deleteFlag = json["delete_flag"].int { self.deleteFlag = deleteFlag }
        if let editTime = json["edit_time"].int { self.editTime = editTime }
        if let editUserName = json["edit_user_name"].string { self.editUserName = editUserName }
        if let title = json["title"].string { self.title = title }
        if let type = json["type"].int { self.type = type }
        if let url = json["url"].string { self.url = url }
        if let version = json["version"].int { self.version = version }
        if let tenantId = json["tenant_id"].string { self.tenantId = tenantId }
        if let subType = json["sub_type"].string { self.subType = subType }
        if let serverTime = json["server_time"].int { self.serverTime = serverTime }
        if let realSubType = json["real_sub_type"].int { self.realSubType = realSubType }
        if let ownerUserName = json["owner_user_name"].string { self.ownerUserName = ownerUserName }
        if let ownerID = json["owner_id"].string { self.ownerID = ownerID }
        if let objType = json["obj_type"].string { self.objType = objType }
        if let isStared = json["is_stared"].bool { self.isStared = isStared }
        if let isPined = json["is_pined"].bool { self.isPined = isPined }
        if let isExternal = json["is_external"].bool { self.isExternal = isExternal }
        if let docVersion = json["doc_version"].int { self.docVersion = docVersion }
        if let createUserName = json["create_user_name"].string { self.createUserName = createUserName }
        if let createUid = json["create_uid"].string { self.createUid = createUid }
        self.secretLevel = SecretLevel(json: json)
    }


    public static func fetchBizMeta(token: String,
                                     type: ShareDocsType,
                                     completion: ((ShareBizMeta?, Error?) -> Void)?) -> DocsRequest<JSON> {
        let metaAPIPath = Self.metaAPIPath(type: type, token: token)
        return  DocsRequest<JSON>(path: metaAPIPath, params: nil)
            .set(method: .GET)
            .start { data, error in
                guard let result = data,
                      let code = result["code"].int else {
                    DocsLogger.error("fetch biz meta failed", error: error, component: LogComponents.shareModule)
                    completion?(nil, error)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("fetch biz meta fail failed, code is \(code)", error: error, component: LogComponents.shareModule)
                    completion?(nil, error)
                    return
                }

                completion?(ShareBizMeta(result["data"]), nil)
            }
    }

    public static func metaSingle(token: String,
                                     type: ShareDocsType) -> Single<ShareBizMeta> {
        let metaAPIPath = Self.metaAPIPath(type: type, token: token)
        let request = DocsRequest<JSON>(path: metaAPIPath, params: nil)
            .set(method: .GET)
        return request.rxStart().map { data -> ShareBizMeta in
            guard let result = data,
                  let code = result["code"].int else {
                DocsLogger.error("fetch biz meta failed")
                throw(ShareBizMetaError.parseDataFailed)
            }
            guard code == 0 else {
                DocsLogger.error("fetch biz meta fail failed, code is \(code)")
                throw(ShareBizMetaError.wrongCode)
            }
            return ShareBizMeta(result["data"])
        }
    }

    private static func metaAPIPath(type: ShareDocsType, token: String) -> String {
        switch type {
        case .doc, .mindnote, .file, .slides, .docX, .minutes, .wikiCatalog, .wiki, .sheet, .bitable, .sync:
            return OpenAPI.APIPath.meta(token, type.rawValue)
        case .folder:
            return "/api\(type.path)\(token)/"
        default:
            spaceAssertionFailure("type unsupport for DocsInfo detail")
            return ""
        }
    }
}
