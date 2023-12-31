//
//  CardMetaProvider.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/17.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging
import OPFoundation

private let log = Logger.oplog(CardMetaProvider.self, category: "CardMetaProvider")

/// meta请求超时时间
private let cardMetaRequestTimeoutInterval: TimeInterval = 15

/// meta请求参数，后端要求必须小写
private let platformIOS = "ios"

/// 卡片Meta 能力提供协议，例如组装meta请求和组装meta实体
@objcMembers
public final class CardMetaProvider: NSObject, MetaProviderProtocol, MetaTTCodeProtocol {
    public func buildMetaModelWithDict(_ dict: [String : Any], ttcode: BDPMetaTTCode, context: MetaContext) throws -> AppMetaProtocol {
        throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "CardMetaProvider buildMetaModelWithDict need to implement")
    }
    /// 通过Meta上下文获取请求（期望架构组封装业务网络层，这一种网络请求参数拼装的代码散在整个引擎，不好，需要有网络层建设了）
    /// - Parameter context: Meta上下文
    public func getMetaRequestAndTTCode(with context: MetaContext) throws -> MetaRequestAndTTCode {
        //  组装URL
        guard let urlstr = BDPSDKConfig.shared().cardMetaUrls?.first,
            let url = URL(string: urlstr) else {
                let msg = "url for card meta is invaild, url: \(BDPSDKConfig.shared().cardMetaUrls?.first ?? "")"
                let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
                assertionFailure(opError.description)
                throw opError
        }
        //  组装请求
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: cardMetaRequestTimeoutInterval)
        request.httpMethod = "POST"
        //  组装HTTPHeader
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let userPlugin = BDPTimorClient.shared().userPlugin.sharedPlugin() as? BDPUserPluginDelegate,
            let sessionID = userPlugin.bdp_sessionId() else {
                let msg = "build meta request failed, BDPUserPluginDelegate is invaild or has no info you know for authentication"
                let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
                assertionFailure(opError.description)
                throw opError
        }
        request.setValue(sessionID, forHTTPHeaderField: "X-Tma-Host-Sessionid")
        request.setValue(BDPUserAgent.getString(), forHTTPHeaderField: "User-Agent")
        //  组装HTTPBODY
        let ttcode = BDPMetaTTCodeFactory.fetchPreGenerateTTCode()
        let language = BDPApplicationManager.language() ?? ""
        let appVersion = BDPDeviceTool.bundleShortVersion ?? ""
        let platform = platformIOS
        let need_pc_mini = false
        let need_mobile_mini = false
        let need_card_info = true
        let app_meta_requests: [[String: Any]] = [[
            "appid": context.uniqueID.appID,
            "version": OPAppVersionTypeToString(context.uniqueID.versionType),
            "card_ids": [context.uniqueID.identifier],
            "token": context.token
            ]]
        let httpBodyparams: [String: Any] = [
            "app_meta_requests": app_meta_requests,
            "ttcode": ttcode.ttcode ?? "",
            "sessionid": sessionID,
            "language": language,
            "app_version": appVersion,
            "platform": platform,
            "need_pc_mini": need_pc_mini,
            "need_mobile_mini": need_mobile_mini,
            "need_card_info": need_card_info
        ]
        guard JSONSerialization.isValidJSONObject(httpBodyparams) else {
            let msg = "http body for card meta is invaild for transform to data"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: httpBodyparams, options: .prettyPrinted)
        return MetaRequestAndTTCode(request: request, ttcode: ttcode)
    }

    /// 通过后端返回数据获取Meta实体
    /// - Parameters:
    ///   - data: 后端返回的二进制数据
    ///   - ttcode: ttcode校验对象
    ///   - context: Meta上下文
    public func buildMetaModel(
        with data: Data,
        ttcode: BDPMetaTTCode,
        context: MetaContext
    ) throws -> AppMetaProtocol {
        var tempResponse = try JSONSerialization.jsonObject(with: data)
        guard let responseDic = tempResponse as? [String: Any] else {
            let msg = "build meta model error: response data type error, not [String: Any]"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
            throw opError
        }
        //  基本校验
        guard let data = responseDic["data"] as? [String: Any] else {
            let msg = "Meta Gateway Response: code: " + String((responseDic["code"] as? Int) ?? -1) + " ,msg: " + (responseDic["msg"] as? String ?? "unknown")
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
            throw opError
        }
        //  meta后端业务返回的错误码和错误信息
        let metaResponseInfo = "New Card Meta business response: code:" + String((data["error"] as? Int) ?? 0) + "msg:" + (data["message"] as? String ?? "unknown")
        log.info(metaResponseInfo, tag: BDPTag.cardProvider)
        guard let appMetasDic = data["app_metas"] as? [String: Any] else {
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: metaResponseInfo)
            throw opError
        }
        //  转换后端数据为Meta Model Array
        let metaModelArray = try appMetasDic
            .flatMap { $1 as? [String: [[String: Any]]] }
            .flatMap { $0["card_meta"] as? [[String: Any]] }
            .flatMap { $0 }
            .flatMap { (metaDic) -> CardMeta? in
                guard let identifier = metaDic["cardid"] as? String,
                    let appid = metaDic["appid"] as? String,
                    let version = metaDic["card_version"] as? String,
                    let name = metaDic["name"] as? String,
                    let icon = metaDic["icon"] as? String,
                    let minClientVersion = metaDic["min_client_version"] as? String,
                    let urlStrs = metaDic["mobile_path"] as? [String],
                    let md5 = metaDic["mobile_md5"] as? String,
                    let versionTypeString = metaDic["version_type"] as? String,
                    let extra = metaDic["extra"] as? String else {
                        let msg = "invaild meta data structure"
                        let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
                        throw opError
                }
                let urls = urlStrs.flatMap { URL(string: $0) }
                let model = CardMeta(
                    uniqueID: context.uniqueID,
                    version: version,
                    name: name,
                    iconUrl: icon,
                    minClientVersion: minClientVersion,
                    packageData: CardMetaPackage(
                        urls: urls,
                        md5: md5
                    ),
                    authData: CardMetaAuth(),
                    businessData: CardBusinessData(extra: extra)
                )
                return model
        }
        
        guard let cardMeta = metaModelArray.first else {
            let msg = "metaModelArray is empty"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
            throw opError
        }
        return cardMeta
    }

    /// 通过数据库meta str转换为metamodel
    /// - Parameter metaJsonStr: meta json字符串
    public func buildMetaModel(with metaJsonStr: String, context: MetaContext) throws -> AppMetaProtocol {
        guard let data = metaJsonStr.data(using: .utf8) else {
            let msg = "jsonStr cannot transform to data"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            throw opError
        }
        var json = try JSONSerialization.jsonObject(with: data)
        guard let jsonDic = json as? [String: Any] else {
            let msg = "jsonDic form data is nil"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        //  考虑到需要加字段，这里需要使用默认值，和GadgetMetaProvider一致
        let identifier = jsonDic["identifier"] as? String ?? ""
        let appID = jsonDic["appID"] as? String ?? ""
        let version = jsonDic["version"] as? String ?? ""
        let versionTypeString = jsonDic["versionType"] as? String ?? ""
        let name = jsonDic["name"] as? String ?? ""
        let iconUrl = jsonDic["iconUrl"] as? String ?? ""
        let minClientVersion = jsonDic["minClientVersion"] as? String ?? ""
        let packageData = jsonDic["packageData"] as? [String: Any] ?? [String: Any]()
        let urls = packageData["urls"] as? [String] ?? [String]()
        let md5 = packageData["md5"] as? String ?? ""
        let businessData = jsonDic["businessData"] as? [String: String] ?? [String: String]()
        let extra = businessData["extra"] as? String ?? ""

        let meta = CardMeta(
            uniqueID: context.uniqueID,
            version: version,
            name: name,
            iconUrl: iconUrl,
            minClientVersion: minClientVersion,
            packageData: CardMetaPackage(
                urls: urls.flatMap { URL(string: $0) },
                md5: md5
            ),
            authData: CardMetaAuth(),
            businessData: CardBusinessData(extra: extra)
        )
        return meta
    }
}
