//
//  DocsVersionLoader.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/8/29.
//  swiftlint:disable operator_usage_whitespace
// swiftlint:disable file_length

import Foundation
import SwiftyJSON
import HandyJSON
import SKFoundation
import SKResource
import SKUIKit
import SpaceInterface
import SKInfra

public enum VersionErrorCode: Int {
    case noError                        = 0
    case undefine                       = -1000
    case responseDataInvalid            = -1001
    case responseNoData                 = -1002
    case versionDataError               = -1003
    case versionDataDecodeErr           = -1004
    case versionFormatError             = -1005
    case versionEditionIdLengthErr      = 528010000 // edtion_id长度不合法
    case versionNotPermission           = 528021002 // 没有权限
    case versionEditionIdForbidden      = 528032011 // edtion_id不合法
    case sourceDelete                   = 528032012 // 源文档已删除
    case sourceNotFound                 = 528021015 // 源文档不存在
    case versionNotFound                = 528021016 // 版本不存在
    
    public var failViewType: EmptyListPlaceholderView.EmptyType {
        switch self {
        case .sourceDelete, .sourceNotFound, .versionNotFound:
            return .fileDeleted
        default:
            return .openFileFail
        }
    }
    
    public var pageErrorDescription: String {
        switch self {
        case .sourceDelete, .sourceNotFound, .versionNotFound:
            return BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Deleted
        default:
            return BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_title
        }
    }
}
    
final public class DocsVersionManager: NSObject {
    
    public static let shared = DocsVersionManager()
    
    // 存储不同类型的文档，拉取过的版本信息
    private var versionInfoCacahe = ThreadSafeDictionary<DocsType, ThreadSafeDictionary<String, Set<DocsVersionItemData>>>()
    // 存储不同类型的文档，不同文档历史版本的名称
    private var versionNameListCache = ThreadSafeDictionary<DocsType, ThreadSafeDictionary<String, Set<String>>>()
    
    // 从缓存里查询versiontoken
    public func getVersionTokenForToken(token: String, type: DocsType, version: String) -> (String?, String?, UInt64?, UInt64?, String?, String?, UserAliasInfo?) {
        let data = getVersionTokenFromCache(type: type, token: token, version: version)
        return (data?.versionToken,
                data?.name,
                data?.create_time,
                data?.update_time,
                data?.creator_name,
                data?.creator_name_en,
                data?.aliasInfo)
    }
    
    // 用url拉取版本token
    public func getVersionTokenForUrl(_ url: URL, result: @escaping (String?, String?, String?, Int) -> Void) {
        guard url.isVersion else {
            result(nil, nil, nil, VersionErrorCode.versionFormatError.rawValue)
            return
        }
        
        guard let type = DocsType(url: url) else {
            result(nil, nil, nil, VersionErrorCode.versionFormatError.rawValue)
            return
        }
        
        guard let token = DocsUrlUtil.getFileToken(from: url) else {
            result(nil, nil, nil, VersionErrorCode.versionFormatError.rawValue)
            return
        }
        
        guard let version = URLValidator.getVersionNum(url) else {
            result(nil, nil, nil, VersionErrorCode.versionFormatError.rawValue)
            return
        }
        
        return getVersionTokenWith(token: token, type: type, version: version, needRequest: true, result: result)
    }
    
    // 源文档token拉取版本token
    public func getVersionTokenWith(token: String, type: DocsType, version: String, needRequest: Bool = false, result: @escaping (String?, String?, String?, Int) -> Void) {
        // 先查缓存，没有缓存去请求
        let data = getVersionTokenFromCache(type: type, token: token, version: version)
        if let versionToken = data?.versionToken {
            result(versionToken, version, data?.name, VersionErrorCode.noError.rawValue)
            if needRequest {
                requestVersionTokenWith(token: token, type: type, version: version) { _, _, _, errCode in
                    self.checkNeedDeleteCacheData(type: type, token: token, errCode: errCode)
                }
            }
        } else {
            requestVersionTokenWith(token: token, type: type, version: version, result: result)
        }
    }
    
    private func requestVersionTokenWith(token: String, type: DocsType, version: String, result: @escaping (String?, String?, String?, Int) -> Void) {
        DocsLogger.info("requestVersionToken: \(version)")
        // 去查询当前文档的版本信息
        var params: [String: Any] = [String: Any]()
        params["parent_token"] = token
        params["obj_type"] = type.rawValue
        params["edition_id"] = version
        params["need_user_info"] = true
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getVersionToken, params: params)
            .set(method: .GET)
            .set(headers: ["Content-Type": "application/x-www-form-urlencoded"])
        request.start(callbackQueue: DispatchQueue.main) { [weak self] (object, error) in
            if let error = error {
                DocsLogger.error("get version token failed", error: error, component: LogComponents.version)
                let nsErr = error as NSError
                self?.checkNeedDeleteCacheData(type: type, token: token, errCode: nsErr.code)
                result(nil, nil, nil, nsErr.code)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("get version token data invalide", component: LogComponents.version)
                result(nil, nil, nil, VersionErrorCode.responseDataInvalid.rawValue)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("get version token failed server code: \(code)", component: LogComponents.version)
                result(nil, nil, nil, code)
                return
            }
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("get version toke failed no data", component: LogComponents.version)
                result(nil, nil, nil, VersionErrorCode.responseNoData.rawValue)
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
               let json = try? JSON(data: jsonData) {
                let parentToken = json["version_meta"]["parent_token"].string
                let versionNum = json["version_meta"]["version"].string
                let versionToken = json["version_meta"]["token"].string
                let name = json["version_meta"]["name"].string
                let creatorid = json["version_meta"]["creator_id"].uInt64Value
                let createtime = json["version_meta"]["create_time"].uInt64Value
                let updatetime = json["version_meta"]["update_time"].uInt64Value
                    
                guard parentToken != nil, versionNum != nil, versionToken != nil, name != nil else {
                    DocsLogger.error("get version token decode data failed", component: LogComponents.version)
                    result(nil, nil, nil, VersionErrorCode.versionDataError.rawValue)
                    return
                }
                var creator_name: String?
                var creator_name_en: String?
                var aliasInfo: UserAliasInfo?
                if let users = json["users"].dictionaryObject,
                   let userInfo = users["\(creatorid)"] as? NSDictionary {
                    creator_name = userInfo["name"] as? String
                    creator_name_en = userInfo["en_name"] as? String
                    aliasInfo = UserAliasInfo(data: userInfo["display_name"] as? [String: Any] ?? [:])
                }
                let item = DocsVersionItemData(docToken: parentToken!,
                                               versionToken: versionToken!,
                                               name: name!.trimmingCharacters(in: .whitespacesAndNewlines),
                                               version: versionNum!,
                                               createtime: createtime,
                                               updatetime: updatetime,
                                               creatorName: creator_name,
                                               creatorNameEn: creator_name_en,
                                               aliasInfo: aliasInfo)
                self?.saveDocsVersionData(type: type, token: token, itemData: item)
                result(versionToken, versionNum, name, VersionErrorCode.noError.rawValue)
            } else {
                DocsLogger.error("get version toke request failed: decode data failed", component: LogComponents.version)
                result(nil, nil, nil, VersionErrorCode.versionDataDecodeErr.rawValue)
            }
        }
        request.makeSelfReferenced()
        
    }
    
    // 从缓存里查询文档是否有版本数据
    public func docsHasVersionData(token: String, type: DocsType) -> Bool {
        guard let data = versionInfoCacahe.value(ofKey: type) else {
            return false
        }
        guard let versionData = data.value(ofKey: token) else {
            return false
        }
        if versionData.count > 0 {
            return true
        }
        return false
    }
    
    // 某个版本的版本token是否已经拉到
    public func hasVersionToken(token: String, type: DocsType, version: String) -> Bool {
        guard let data = versionInfoCacahe.value(ofKey: type) else {
            return false
        }
        guard let versionData = data.value(ofKey: token) else {
            return false
        }
        
        for element in versionData where element.version == version {
            return true
        }
        return false
    }
    
    // 请求文档的版本数据
    public func getVersionDataFor(token: String, type: DocsType) {
        getVersionDataForToken(token: token, type: type, pageToken: nil) { _, _, _, _ in }
    }
    
    // 用token请求版本数据，每次都会重新请求
    private func getVersionDataForToken(token: String, type: DocsType, pageToken: String?, pageSize: Int = 20, result: @escaping ([DocsVersionItemData]?, Bool, Bool, String?) -> Void) {
        // 去查询当前文档的版本信息
        var params: [String: Any] = [String: Any]()
        params["parent_token"] = token
        params["obj_type"] = type.rawValue
        if pageToken != nil {
            params["page_token"] = pageToken
        }
        params["page_size"] = pageSize
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getVersionData, params: params)
            .set(method: .GET)
            .set(headers: ["Content-Type": "application/x-www-form-urlencoded"])
        request.start(callbackQueue: DispatchQueue.main) { [weak self] (object, error) in
            if let error = error {
                DocsLogger.error("get version history failed", error: error, component: LogComponents.version)
                result(nil, false, false, nil)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("get version history data invalide", component: LogComponents.version)
                result(nil, false, false, nil)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("get version history failed server code: \(code)", component: LogComponents.version)
                result(nil, false, false, nil)
                return
            }
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("get version history failed no data", component: LogComponents.version)
                result(nil, false, false, nil)
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
               let json = try? JSON(data: jsonData) {
                var resultData = [DocsVersionItemData]()
                let hasMore = json["has_more"].boolValue
                let pageToken = json["page_token"].string
                let list = json["version_metas"].array
                list?.forEach({ subData in
                    let subjson = subData
                    let parentToken = subjson["parent_token"].string
                    let versionNum = subjson["version"].string
                    let versionToken = subjson["token"].string
                    let name = subjson["name"].string
                    let creatorid = subjson["creator_id"].uInt64Value
                    let createtime = subjson["create_time"].uInt64Value
                    let updatetime = subjson["update_time"].uInt64Value
                    
                    guard parentToken != nil, versionNum != nil, versionToken != nil, name != nil else {
                        DocsLogger.error("get version history decode data failed", component: LogComponents.version)
                        return
                    }
                    var creator_name: String?
                    var creator_name_en: String?
                    var aliasInfo: UserAliasInfo?
                    if let users = json["users"].dictionaryObject,
                       let userInfo = users["\(creatorid)"] as? NSDictionary {
                        creator_name = userInfo["name"] as? String
                        creator_name_en = userInfo["en_name"] as? String
                        aliasInfo = UserAliasInfo(data: userInfo["display_name"] as? [String: Any] ?? [:])
                    }
                    let item = DocsVersionItemData(docToken: parentToken!,
                                                   versionToken: versionToken!,
                                                   name: name!.trimmingCharacters(in: .whitespacesAndNewlines),
                                                   version: versionNum!,
                                                   createtime: createtime,
                                                   updatetime: updatetime,
                                                   creatorName: creator_name,
                                                   creatorNameEn: creator_name_en,
                                                   aliasInfo: aliasInfo)
                    self?.saveDocsVersionData(type: type, token: parentToken!, itemData: item)
                    resultData.append(item)
                })
                DocsLogger.info("get version history success, \(token.encryptToken), count:\(resultData.count)", component: LogComponents.version)
                // 如果当前文档没有版本，要把旧的数据清掉
                if resultData.count == 0, hasMore == false {
                    self?.deleteAllVersionData(type: type, token: token)
                }
                result(resultData, true, hasMore, pageToken)
            } else {
                DocsLogger.error("get version history request failed: decode data failed", component: LogComponents.version)
                result(nil, false, false, nil)
            }
        }
        request.makeSelfReferenced()
    }
    
    // 从缓存里查询versionToken
    private func getVersionTokenFromCache(type: DocsType, token: String, version: String) -> DocsVersionItemData? {
        guard let data = versionInfoCacahe.value(ofKey: type) else {
            return nil
        }
        guard let versionData = data.value(ofKey: token) else {
            return nil
        }
        for element in versionData where element.version == version {
            return element
        }
        return nil
    }

    public func saveDocsVersionData(type: DocsType, token: String, itemData: DocsVersionItemData) {
        var data = versionInfoCacahe.value(ofKey: type)
        if data == nil {
            data = ThreadSafeDictionary<String, Set<DocsVersionItemData>>()
        }
        var itemSet = data?.value(ofKey: token)
        if itemSet == nil {
            itemSet = Set<DocsVersionItemData>()
        }
        itemSet?.update(with: itemData)
        data?.updateValue(itemSet!, forKey: token)
        versionInfoCacahe.updateValue(data!, forKey: type)
    }
    
    // 删除某个token的所有版本数据
    public func deleteAllVersionData(type: DocsType, token: String) {
        let data = versionInfoCacahe.value(ofKey: type)
        if data != nil {
            data!.removeValue(forKey: token)
            versionInfoCacahe.updateValue(data!, forKey: type)
        }
    }
    // 删除某个token的某个版本数据
    public func deleteVerisonData(type: DocsType, token: String, versionToken: String) {
        let data = versionInfoCacahe.value(ofKey: type)
        if data != nil {
            let itemSet = data?.value(ofKey: token)
            let newSet = itemSet?.filter({ $0.versionToken != versionToken })
            if newSet != nil {
                data?.updateValue(newSet!, forKey: token)
            }
            versionInfoCacahe.updateValue(data!, forKey: type)
        }
    }
    
    // 检查当前文档url中token的合法性，如果是版本token，要跳到提示页
    public func checkDocsToken(type: DocsType, token: String) {
        var params: [String: Any] = [String: Any]()
        params["token"] = token
        params["type"] = type.rawValue
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.checkDocsToken, params: params)
            .set(method: .GET)
            .set(headers: ["Content-Type": "application/x-www-form-urlencoded"])
        request.start { object, error in
            if let error = error {
                DocsLogger.error("checkDocsToken failed", error: error, component: LogComponents.version)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("checkDocsToken data invalide", component: LogComponents.version)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("checkDocsToken failed server code: \(code)", component: LogComponents.version)
                return
            }
            
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("checkDocsToken failed no data", component: LogComponents.version)
                return
            }
            
            guard let subtype = data["real_sub_type"] as? Int else {
                DocsLogger.error("checkDocsToken real_sub_type is nil", component: LogComponents.version)
                return
            }
            if subtype == 4 {
                let userInfo: [String: Any] = ["token": token, "type": type]
                NotificationCenter.default.post(name: Notification.Name.Docs.docsTokenCheckFailNotifictaion, object: nil, userInfo: userInfo)
            }
        }
        request.makeSelfReferenced()
    }
    
    private func checkNeedDeleteCacheData(type: DocsType, token: String, errCode: Int) {
        if errCode == VersionErrorCode.sourceDelete.rawValue ||
            errCode == VersionErrorCode.sourceNotFound.rawValue ||
            errCode == VersionErrorCode.versionNotFound.rawValue {
            self.deleteAllVersionData(type: type, token: token)
            let userInfo: [String: Any] = ["token": token, "type": type]
            NotificationCenter.default.post(name: Notification.Name.Docs.versionDeleteNotifictaion, object: nil, userInfo: userInfo)
        } else if errCode == VersionErrorCode.versionNotPermission.rawValue {
            let userInfo: [String: Any] = ["token": token, "type": type]
            NotificationCenter.default.post(name: Notification.Name.Docs.versionPermissionChangeNotifictaion, object: nil, userInfo: userInfo)
        }
    }
}

// MARK: - 删除版本
extension DocsVersionManager {
    public func deleteVersion(token: String, type: DocsType, versionToken: String, result: @escaping (String, Bool) -> Void) {
        var params: [String: Any] = [String: Any]()
        params["token"] = versionToken
        params["obj_type"] = type.rawValue
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteVersion, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(method: .POST)
        request.set(headers: ["Content-Type": "application/json"])
        request.start { [weak self] object, error in
            if let error = error {
                DocsLogger.error("renameVersion version failed", error: error, component: LogComponents.version)
                result(versionToken, false)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("renameVersion data invalide", component: LogComponents.version)
                result(versionToken, false)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("renameVersion failed server code: \(code)", component: LogComponents.version)
                result(versionToken, false)
                return
            }
            self?.deleteVerisonData(type: type, token: token, versionToken: versionToken)
            result(versionToken, true)
        }
        request.makeSelfReferenced()
    }
}

// MARK: - 重命名版本
extension DocsVersionManager {
    // 重命名版本
    public func renameVersion(token: String, type: DocsType, name: String, result: @escaping (String, Bool) -> Void) {
        var params: [String: Any] = [String: Any]()
        params["token"] = token
        params["obj_type"] = type.rawValue
        params["name"] = name
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.renameVersion, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(method: .POST)
        request.set(headers: ["Content-Type": "application/x-www-form-urlencoded"])
        request.start { object, error in
            if let error = error {
                DocsLogger.error("renameVersion version failed", error: error, component: LogComponents.version)
                result(token, false)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("renameVersion data invalide", component: LogComponents.version)
                result(token, false)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("renameVersion failed server code:\(code)", component: LogComponents.version)
                result(token, false)
                return
            }
            result(token, true)
        }
        request.makeSelfReferenced()
    }
    
    public func requestAllVersionNames(token: String, type: DocsType) {
        DocsLogger.info("requestAllVersionNames start", component: LogComponents.version)
        var params: [String: Any] = [String: Any]()
        params["parent_token"] = token
        params["obj_type"] = type.rawValue
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.versionNameList, params: params)
            .set(method: .GET)
        request.start { object, error in
            if let error = error {
                DocsLogger.error("requestAllVersionNames failed", error: error, component: LogComponents.version)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("requestAllVersionNames invalide", component: LogComponents.version)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("requestAllVersionNames server code:\(code)", component: LogComponents.version)
                return
            }
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("requestAllVersionNames failed no data", component: LogComponents.version)
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []), let json = try? JSON(data: jsonData) {
                var itemSet = Set<String>()
                let list = json["names"].array
                list?.forEach({ subData in
                    let parentToken = subData.string
                    if parentToken != nil {
                        itemSet.insert(parentToken!)
                    }
                })
                if itemSet.count > 0 {
                    self.saveDocsVersionList(type: type, token: token, itemData: itemSet)
                }
            }
        }
        request.makeSelfReferenced()
    }
    
    // 用缓存中的数据判断某个名称是否已经存在了
    public func hasSameVersionName(token: String, type: DocsType, newName: String) -> Bool {
        guard let data = versionNameListCache.value(ofKey: type) else {
            return false
        }
        guard let versionData = data.value(ofKey: token) else {
            return false
        }
        
        for element in versionData where element == newName {
            return true
        }
        
        return false
    }
    
    public func updateVersinName(token: String, vertionToken: String, type: DocsType, name: String) {
        guard let data = versionInfoCacahe.value(ofKey: type) else {
            return
        }
        guard let itemSet = data.value(ofKey: token) else {
            return
        }
        for element in itemSet where element.versionToken == vertionToken {
            element.name = name
        }
        data.updateValue(itemSet, forKey: token)
        versionInfoCacahe.updateValue(data, forKey: type)
    }
    
    private func saveDocsVersionList(type: DocsType, token: String, itemData: Set<String>) {
        var data = versionNameListCache.value(ofKey: type)
        if data == nil {
            data = ThreadSafeDictionary<String, Set<String>>()
        }
        data?.updateValue(itemData, forKey: token)
        versionNameListCache.updateValue(data!, forKey: type)
    }
}
