//
//  DocsInfoDetailHelper.swift
//  SKCommon
//
//  Created by Weston Wu on 2020/10/19.
//

import Foundation
import SKFoundation
import RxSwift
import SwiftyJSON
import SpaceInterface
import SKInfra

public enum DocsInfoDetailError: Error {
    case redundantRequest
    case typeUnsupport
    case dataNotFound
    case parseDataFailed
    case wikiTokenNotFound
}

public enum DocsInfoDetailHelper {

    public static func detailUpdater(for docsInfo: DocsInfo?) -> DocsInfoDetailUpdater {
        guard let docsInfo = docsInfo else {
            assertionFailure()
            return DefaultDocsInfoDetailUpdater()
        }
        if docsInfo.isFromWiki {
            return WikiDocsInfoDetailUpdater()
        } else {
            return DefaultDocsInfoDetailUpdater()
        }
    }
    public static func fetchEntityInfo(objToken: String, objType: DocsType) -> Single<Int> {
        var params: [String: Any] = [String: Any]()
        params["obj_token"] = objToken
        params["obj_type"] = objType.rawValue
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getEntityInfo, params: ["entities": [params]])
            .set(encodeType: .jsonEncodeDefault)
            .set(method: .POST)
            .set(needVerifyData: false)
        return request.rxStart().map { data -> (Int) in
            guard let json = data else {
                throw DocsInfoDetailError.dataNotFound
            }
            guard DocsNetworkError.isSuccess(json["code"].int),
                let ownerType = json["data"][objToken]["owner_type"].int else {
                throw DocsInfoDetailError.parseDataFailed
            }
            return (ownerType)
        }
    }


    public static func fetchDetail(token: String, type: DocsType, headers: [String: String] = SpaceHttpHeaders.common) -> Single<(type: DocsType, detailInfo: [String: Any])> {
        guard let metaAPIPath = Self.metaAPIPath(type: type, token: token) else {
            return .error(DocsInfoDetailError.typeUnsupport)
        }

        let request = DocsRequest<JSON>(path: metaAPIPath, params: nil)
            .set(method: .GET)
            .set(headers: headers)
        return request.rxStart().map { data -> (type: DocsType, detailInfo: [String: Any]) in
            guard let json = data else {
                throw DocsInfoDetailError.dataNotFound
            }
            guard let detailData = json["data"].dictionaryObject else {
                throw DocsInfoDetailError.parseDataFailed
            }
            guard let rawTypeValue = detailData["type"] as? Int else {
                throw DocsInfoDetailError.parseDataFailed
            }
            let docsType = DocsType(rawValue: rawTypeValue)
            guard !docsType.isUnknownType else {
                throw DocsInfoDetailError.typeUnsupport
            }
            return (type: docsType, detailInfo: detailData)
        }
    }

    public static func update(docsInfo: DocsInfo, detailInfo: [String: Any], needUpdateStar: Bool) {
        let assigner = DataAssigner(target: docsInfo, data: detailInfo)

        assigner.assignIfPresent(key: "revision", keyPath: \.revision)
        assigner.assignIfPresent(key: "title", keyPath: \.title)
        assigner.assignIfPresent(key: "creator_user_name", keyPath: \.creator)
        assigner.assignIfPresent(key: "creator_uid", keyPath: \.creatorID)
        assigner.assignIfPresent(key: "owner_id", keyPath: \.ownerID)
        assigner.assignIfPresent(key: "tenant_id", keyPath: \.tenantID)
        assigner.assignIfPresent(key: "create_time", keyPath: \.createTime)
        assigner.assignIfPresent(key: "server_time", keyPath: \.serverTime)
        assigner.assignIfPresent(key: "create_date", keyPath: \.createDate)
        assigner.assignIfPresent(key: "edit_user_name", keyPath: \.editor)
        assigner.assignIfPresent(key: "edit_time", keyPath: \.editTime)
        assigner.assignIfPresent(key: "delete_flag", keyPath: \.delete)
        assigner.assignIfPresent(key: "version", keyPath: \.version)
        // wiki 需要忽略本体的收藏/快速访问状态
        if needUpdateStar {
            assigner.assignIfPresent(key: "is_stared", keyPath: \.stared)
            assigner.assignIfPresent(key: "is_pined", keyPath: \.pined)
        }
        assigner.assignIfPresent(key: "url", keyPath: \.shareUrl)
        assigner.assignIfPresent(key: "owner_user_name", keyPath: \.ownerName)
        
        if let templateTypeValue = detailInfo["template_type"] as? Int {
            docsInfo.setTemplateType(DocsInfo.TemplateType(rawValue: templateTypeValue))
        }

        if let iconTypeValue = detailInfo["icon_type"] as? Int,
           let iconType = IconType(rawValue: iconTypeValue),
           let iconKey = detailInfo["icon_key"] as? String, !iconKey.isEmpty,
           let fsunit = detailInfo["icon_fsunit"] as? String {
            let customIcon = CustomIcon(iconKey: iconKey, iconType: iconType, iconFSUnit: fsunit)
            docsInfo.updateIconInfo(customIcon)
        }
        if let titleSecureKeyDeleted = detailInfo["title_secure_key_deleted"] as? Bool {
            docsInfo.titleSecureKeyDeleted = titleSecureKeyDeleted
        }
        if let ownerAliasData = detailInfo["owner_user_display_name"] as? [String: Any] {
            docsInfo.ownerAliasInfo = UserAliasInfo(data: ownerAliasData)
        }
        if let objId = detailInfo["obj_id"] as? String {
            docsInfo.objId = objId
        }
        if let iconInfo = detailInfo["icon_info"] as? String {
            docsInfo.iconInfo = iconInfo
        }
        if docsInfo.originType != .sync {
            docsInfo.secLabel = SecretLevel(json: JSON(detailInfo))
        }

        if let freshInfoValue = detailInfo["fresh_info"] as? [String: Any] {
            docsInfo.freshInfo = FreshInfo(data: freshInfoValue)
        }
    }

    private static func metaAPIPath(type: DocsType, token: String) -> String? {
        switch type {
        case .doc, .mindnote, .file, .slides, .docX, .wikiCatalog, .wiki, .sheet, .bitable, .whiteboard, .sync, .baseAdd:
            return OpenAPI.APIPath.meta(token, type.rawValue)
        case .folder, .trash, .mediaFile, .unknown, .minutes:
            return "/api\(type.path)\(token)/"
        case .myFolder, .imMsgFile:
            spaceAssertionFailure("type unsupport for DocsInfo detail")
            return nil
        }
    }
}

/// 文档聚合接口: https://bytedance.feishu.cn/docs/doccntkBnqL2HqedQER8SWKv9oh
public extension DocsInfoDetailHelper {
    enum AggregationResult {
        case success(info: AggregationInfo)
        case allFailed
        case partialSuccess(info: AggregationInfo)
        case invalidParameter
        case fileNotFound
        case internalUnknownError
    }
    /// 请求聚合信息的场景
    enum AggregationInfoScence: String {
        /// 文档详情页
        case objDetail = "obj_detail"
        /// 列表页
        case listDetail = "list_detail"
    }

    enum AggregationInfoType: String {
        case isPined = "is_pined"
        case isStared = "is_stared"
        case isSubscribed = "is_subscribed"
        case isWiki = "is_wiki"
        case objUrl = "obj_url"
    }

    struct AggregationInfo {
        public let isPined: Bool?
        public let isStared: Bool?
        public let isSubscribed: Bool?
        public let isSubscribedComment: Bool?
        public let wikiToken: String?
        public let url: String?
    }

    // nolint: magic number
    static func getAggregationInfoWithLogID(token: String,
                                            objType: DocsType,
                                            infoTypes: Set<AggregationInfoType>,
                                            scence: AggregationInfoScence) -> Single<(AggregationResult, String?)> {
        let infoTypesQuery: String = infoTypes.map { "info_types=\($0.rawValue)" }.joined(separator: "&")
        let query = "?token=\(token)&obj_type=\(objType.rawValue)&scence=\(scence.rawValue)&\(infoTypesQuery)"
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getAggregationInfo + query, params: nil)
            .set(method: .GET)
            .set(needVerifyData: false)
        return request.rxStartWithLogID().map { data, logID in
            guard let json = data else {
                throw DocsInfoDetailError.dataNotFound
            }
            guard let code = json["code"].int else {
                DocsLogger.error("failed to parse code")
                throw DocsInfoDetailError.parseDataFailed
            }
            let isPartialSuccess: Bool
            switch code {
            case 226915020:
                return (.allFailed, logID)
            case 226914000:
                return (.invalidParameter, logID)
            case 226914041:
                return (.fileNotFound, logID)
            case 226915000:
                return (.internalUnknownError, logID)
            case 0:
                isPartialSuccess = false
            case 226915021:
                isPartialSuccess = true
            default:
                throw DocsNetworkError(code, extraStr: json["msg"].string) ?? DocsInfoDetailError.parseDataFailed
            }
            guard let detailData = json["data"].dictionary else {
                throw DocsInfoDetailError.parseDataFailed
            }
            let isPined = detailData["is_pined"]?.bool
            let isStared = detailData["is_stared"]?.bool
            let isSubscribed = detailData["is_subscribed"]?.bool
            let isSubscribedComment = detailData["is_subscribed_comment"]?.bool
            let url = detailData["meta_info"]?["url"].string
            var wikiToken: String?
            if let isWiki = detailData["wiki_info"]?["is_wiki"].boolValue,
               isWiki {
                wikiToken = detailData["wiki_info"]?["wiki_token"].string
            }
            let info = AggregationInfo(isPined: isPined,
                                       isStared: isStared,
                                       isSubscribed: isSubscribed,
                                       isSubscribedComment: isSubscribedComment,
                                       wikiToken: wikiToken,
                                       url: url)
            if isPartialSuccess {
                return (.partialSuccess(info: info), logID)
            } else {
                return (.success(info: info), logID)
            }
        }
    }
    // enable-lint

    static func getAggregationInfo(token: String,
                                   objType: DocsType,
                                   infoTypes: Set<AggregationInfoType>,
                                   scence: AggregationInfoScence) -> Single<AggregationResult> {
        getAggregationInfoWithLogID(token: token, objType: objType, infoTypes: infoTypes, scence: scence)
            .map(\.0)
    }
}
