//
//  GadgetMetaProvider.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/29.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging
import OPSDK
import OPFoundation

private let log = GadgetLog(GadgetMetaProvider.self, category: "GadgetMetaProvider")

/// 小程序 H5小程序 Meta 能力提供协议，例如组装meta请求和组装meta实体
@objcMembers
public final class GadgetMetaProvider: NSObject, MetaProviderProtocol, MetaTTCodeProtocol {

    /// 应用类型
    private let type: BDPType

    public init(type: BDPType) {
        self.type = type
        super.init()
    }

    /// 通过Meta上下文获取请求
    /// - Parameter contexts: Meta上下文数组 小程序只会有一个元素
    /// - Throws: 异常
    /// - Returns: 请求和ttcode的综合结构
    public func getMetaRequestAndTTCode(with context: MetaContext) throws -> MetaRequestAndTTCode {
        //  组装参数
        let uniqueID = context.uniqueID
        let ttcode = BDPMetaTTCodeFactory.fetchPreGenerateTTCode()
        let request = try metaRequest(with: uniqueID, token: context.token, ttCode: ttcode)
        return MetaRequestAndTTCode(request: request, ttcode: ttcode)

    }
    
    /// 通过批量请求列表，获取信息
    /// - Parameter contexts: Meta上下文数组 小程序只会有一个元素
    /// - Throws: 异常
    /// - Returns: 请求和ttcode的综合结构
    public func getBatchMetaRequestAndTTCodeWith(_ entities: [String: String], scene: String) throws -> MetaRequestAndTTCode {
        //  组装参数
        let ttcode = BDPMetaTTCodeFactory.fetchPreGenerateTTCode()
        let request = try batchMetaRequestWith(entities, scene: scene, ttCode: ttcode)
        return MetaRequestAndTTCode(request: request, ttcode: ttcode)

    }

    /// 通过后端返回数据获取Meta实体数组
    /// - Parameters:
    ///   - data: 后端返回的二进制数据
    ///   - ttcode: ttcode校验对象
    ///   - context: Meta上下文
    /// - Throws: 异常
    /// - Returns: 小程序Meta Model
    public func buildMetaModel(
        with data: Data,
        ttcode: BDPMetaTTCode,
        context: MetaContext
    ) throws -> AppMetaProtocol {
        return try buildMetaModelWith(JSONObject: JSONSerialization.jsonObject(with: data), ttcode: ttcode, context: context)
    }
    public func buildMetaModelWith(
        JSONObject: Any,
        ttcode: BDPMetaTTCode,
        context: MetaContext
    )throws -> AppMetaProtocol {
        let tempResponse = JSONObject
        guard let responseDic = tempResponse as? [String: Any] else {
            let msg = "build meta model error: response data type error, not [String: Any], response:\(tempResponse)"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invalid, message: msg)
            throw opError
        }
        log.info("build meta models with response: \(responseDic)")
        //  基本校验
        guard let data = responseDic["data"] as? [String: Any] else {
            // 这里的错误码会有两种类型
            // 类型1 error + message ，这种一般是 meta 的业务错误 可以查阅文档 https://bytedance.feishu.cn/docs/doccnrUH00oF0r1M1EGpGb37u6f
            // 类型2 code + msg ，这种可能是 龙虾网关 层的错误，可以查阅文档 https://bytedance.feishu.cn/docs/doccneqa1EzygWsaHQqx8mGHX0g#
            let errorCode = (responseDic["error"] as? Int) ?? (responseDic["code"] as? Int) ?? -1
            let errorMsg = (responseDic["message"] as? String) ?? (responseDic["msg"] as? String) ?? "unknown"
            let msg = "Gadget Meta business response: code: \(errorCode) ,msg: \(errorMsg), responseDic:\(responseDic)"
            let opError: OPError
            switch errorCode {
            case 10150, 10215:
                opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_invisible, message: msg)
            case 10209:
                opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_not_exist, message: msg)
            case 10210:
                opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_session_error, message: msg)
            default:
                opError = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_internal_error, message: msg)
            }
            throw opError
        }
        return try self.buildMetaModelWithDict(data, ttcode:ttcode, context: context)
    }
    public func buildMetaModelWithDict(
            _ dict: [String: Any],
            ttcode: BDPMetaTTCode,
            context: MetaContext
        ) throws -> AppMetaProtocol {
        let data = dict
        let identifier = data["appid"] as? String ?? ""
        let appID = data["appid"] as? String ?? ""
        let version = data["version"] as? String ?? ""
        let appVersion = data["app_version"] as? String ?? ""
        let compileVersion = data["compile_version"] as? String ?? ""
        let name = data["name"] as? String ?? ""
        let icon = data["icon"] as? String ?? ""
        let urlStrs = data["path"] as? [String] ?? [String]()
        let state = data["state"] as? UInt ?? 1
        let appStatus = BDPAppStatus(rawValue: state) ?? .normal
        let versionStateInt = data["version_state"] as? UInt ?? 0
        let versionState = BDPAppVersionStatus(rawValue: versionStateInt) ?? .normal
        //  处理加密字段
        let ttcodeStr = data["ttcode"] as? String ?? ""
        let ttblackcode = data["ttblackcode"] as? String ?? ""
        let decrypt = (ttcodeStr as NSString).tma_aesDecrypt(ttcode.aesKeyA, iv: ttcode.aesKeyB) ?? Data()
        let blackcodeDecrypt = (ttblackcode as NSString).tma_aesDecrypt(ttcode.aesKeyA, iv: ttcode.aesKeyB) ?? Data()
        let md5Code = data["md5"] as? String ?? ""
        let md5Decrypt = (md5Code as NSString).tma_aesDecrypt(ttcode.aesKeyA, iv: ttcode.aesKeyB) ?? Data()
        let authList = (decrypt as NSData).jsonValue() as? [String] ?? [String]()
        let blackList = (blackcodeDecrypt as NSData).jsonValue() as? [String] ?? [String]()
        let md5 = String(data: md5Decrypt, encoding: .utf8) ?? ""
        let domains = data["domains"] as? String ?? ""
        let domainsDict = (((domains as NSString).tma_aesDecrypt(ttcode.aesKeyA, iv: ttcode.aesKeyB) ?? Data()) as NSData).jsonValue() as? [String: [String]] ?? [String: [String]]()
        let extra = data["extra"] as? String ?? ""
        let extraDict = (((extra as NSString).tma_aesDecrypt(ttcode.aesKeyA, iv: ttcode.aesKeyB) ?? Data()) as NSData).jsonValue() as? [String: Any] ?? [String: Any]()

        let shareLevelInt = data["share_level"] as? UInt ?? 0
        let shareLevel = BDPAppShareLevel(rawValue: shareLevelInt) ?? .unknown
        let versionCode = data["version_code"] as? Int64 ?? 0
        let minJSsdkVersion = data["min_jssdk"] as? String ?? ""
        let minLarkVersion = extraDict["lark_version"] as? String ?? ""
        let webURL = data["web_url"] as? String ?? ""
        let abilityForMessageAction = data["message_action"] as? Bool ?? false
        let abilityForChatAction = data["chat_action"] as? Bool ?? false
        // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
        let components = data["components"] as? [[String:Any]] ?? []
        let gadgetSafeUrls = data["gadgetSafeUrls"] as? [String] ?? [String]()
        let versionUpdateTime = data["version_update_time"] as? Int64 ?? 0
        //fetch mobile subpackage data from json response
        let packages = data["mobileSubPackage"] as? [String: AnyHashable]
        // 小程序和H5小程序共用一个meta，这里的appType需要用运行时上层传入的类型
        let debugSocketAddress = data["socket_address"] as? String
        var realMachineDebugSocketAddress:String? 
        var performanceProfileAddress:String?
        // if enable & query exist
        if let debugSocketAddress = debugSocketAddress, debugSocketAddress.contains("performance_analysis") {
            performanceProfileAddress = debugSocketAddress
        } else {
            realMachineDebugSocketAddress = debugSocketAddress
        }
        // diff包路径信息
        let diffPkgPath = data["diff_path"] as? MetaDiffPkgPathInfo

        // 小程序和H5小程序共用一个meta，这里的appType需要用运行时上层传入的类型
        let meta = GadgetMeta(
            uniqueID: context.uniqueID,
            version: version,
            appVersion: appVersion,
            compileVersion: compileVersion,
            name: name,
            iconUrl: icon,
            // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
            components: components,
            packageData: GadgetMetaPackage(
                urls: urlStrs.flatMap { URL(string: $0) },
                md5: md5,
                packages: packages,
                diffPkgPath: diffPkgPath
            ),
            authData: GadgetMetaAuth(
                appStatus: appStatus,
                versionState: versionState,
                authList: authList,
                blackList: blackList,
                gadgetSafeUrls: gadgetSafeUrls,
                domainsAuthDict: domainsDict,
                versionUpdateTime: versionUpdateTime
            ),
            businessData: GadgetBusinessData(
                extraDict: extraDict,
                shareLevel: shareLevel,
                versionCode: versionCode,
                minJSsdkVersion: minJSsdkVersion,
                minLarkVersion: minLarkVersion,
                webURL: webURL,
                abilityForMessageAction: abilityForMessageAction,
                abilityForChatAction: abilityForChatAction,
                isFromBuildin: false,
                realMachineDebugSocketAddress: realMachineDebugSocketAddress,
                performanceProfileAddress: performanceProfileAddress
            )
        )
        return meta
    }

    /// 通过数据库meta str转换为metamodel
    /// - Parameter metaJsonStr: meta json字符串
    /// - Throws: 异常
    /// - Returns: 小程序Meta Model
    public func buildMetaModel(with metaJsonStr: String, context: MetaContext) throws -> AppMetaProtocol {
        try buildMetaModel(with: metaJsonStr, uniqueID: context.uniqueID)
    }

    public func buildMetaModel(with metaJsonStr: String, uniqueID: BDPUniqueID? = nil) throws -> AppMetaProtocol {
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
        log.info("build meta model with metastr: \(metaJsonStr)")
        let identifier = jsonDic["identifier"] as? String ?? ""
        let appID = jsonDic["appID"] as? String ?? ""
        let version = jsonDic["version"] as? String ?? ""
        let appVersion = jsonDic["appVersion"] as? String ?? ""
        let compileVersion = jsonDic["compile_version"] as? String ?? ""
        let versionTypeString = jsonDic["versionType"] as? String ?? ""
        let name = jsonDic["name"] as? String ?? ""
        let iconUrl = jsonDic["iconUrl"] as? String ?? ""
        // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
        let components = jsonDic["components"] as? [[String:Any]] ?? []
        let packageData = jsonDic["packageData"] as? [String: Any] ?? [String: Any]()
        let urls = packageData["urls"] as? [String] ?? [String]()
        let md5 = packageData["md5"] as? String ?? ""
        let diffPkgPath = packageData["diffPath"] as? MetaDiffPkgPathInfo
        let authData = jsonDic["authData"] as? [String: Any] ?? [String: Any]()
        let appStatusInt = authData["appStatus"] as? UInt ?? 1
        let appStatus = BDPAppStatus(rawValue: appStatusInt) ?? .normal
        let versionStateInt = authData["versionState"] as? UInt ?? 0
        let versionState = BDPAppVersionStatus(rawValue: versionStateInt) ?? .normal
        let authList = authData["authList"] as? [String] ?? [String]()
        let blackList = authData["blackList"] as? [String] ?? [String]()
        let gadgetSafeUrls = authData["gadgetSafeUrls"] as? [String] ?? [String]()
        let versionUpdateTime = authData["versionUpdateTime"] as? Int64 ?? 0
        let domainsAuthDict = authData["domainsAuthDict"] as? [String: [String]] ?? [String: [String]]()
        let businessData = jsonDic["businessData"] as? [String: Any] ?? [String: Any]()
        let extraDict = businessData["extraDict"] as? [String: Any] ?? [String: Any]()
        let shareLevelInt = businessData["shareLevel"] as? UInt ?? 0
        let shareLevel = BDPAppShareLevel(rawValue: shareLevelInt) ?? .unknown
        let versionCode = businessData["versionCode"] as? Int64 ?? 0
        let minJSsdkVersion = businessData["minJSsdkVersion"] as? String ?? ""
        let minLarkVersion = businessData["minLarkVersion"] as? String ?? ""
        let webURL = businessData["webURL"] as? String ?? ""
        let abilityForMessageAction = businessData["message_action"] as? Bool ?? false
        let abilityForChatAction = businessData["chat_action"] as? Bool ?? false
        let isFromBuildin = businessData["isFromBuildin"] as? Bool ?? false
        //fetch mobile subpackage data from json response
        let packages = jsonDic["mobileSubPackage"] as? [String: AnyHashable]
        // 小程序和H5小程序共用一个meta，这里的appType需要用运行时上层传入的类型
        // 外部如果传入了BDPUniqueID实例对象,则使用外部传入; 否则使用Json数据构造一个uniqueID对象
        let bdpUniqueID = uniqueID ?? BDPUniqueID(appID: appID, identifier: identifier, versionType: versionTypeString == "current" ? .current : .preview, appType: .gadget)
        let meta = GadgetMeta(
            uniqueID: bdpUniqueID,
            version: version,
            appVersion: appVersion,
            compileVersion: compileVersion,
            name: name,
            iconUrl: iconUrl,
            // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
            components: components,
            packageData: GadgetMetaPackage(
                urls: urls.compactMap { URL(string: $0) },
                md5: md5,
                packages: packages,
                diffPkgPath: diffPkgPath
            ),
            authData: GadgetMetaAuth(
                appStatus: appStatus,
                versionState: versionState,
                authList: authList,
                blackList: blackList,
                gadgetSafeUrls: gadgetSafeUrls,
                domainsAuthDict: domainsAuthDict,
                versionUpdateTime: versionUpdateTime
            ),
            businessData: GadgetBusinessData(
                extraDict: extraDict,
                shareLevel: shareLevel,
                versionCode: versionCode,
                minJSsdkVersion: minJSsdkVersion,
                minLarkVersion: minLarkVersion,
                webURL: webURL,
                abilityForMessageAction: abilityForMessageAction,
                abilityForChatAction: abilityForChatAction,
                isFromBuildin: isFromBuildin,
                realMachineDebugSocketAddress: nil,
                performanceProfileAddress: nil
            )
        )
        meta.batchMetaVersion = jsonDic["batchMetaVersion"] as? Int ?? 0;
        return meta
    }

    /// 自定义Meta请求
    /// - Parameters:
    ///   - uniqueID: 通用应用的唯一复合ID
    ///   - token: preview token
    ///   - ttCode: meta加密code
    /// - Throws: 错误
    /// - Returns: 请求
    private func metaRequest(
        with uniqueID: BDPUniqueID,
        token: String?,
        ttCode: BDPMetaTTCode
    ) throws -> URLRequest {
        let urlStr = BDPSDKConfig.shared().appMetaURL
        guard !urlStr.isEmpty else {
            let msg = "url for meta request is empty"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        //  构造参数
        let param = try generateRequestInfos(
            with: uniqueID,
            token: token,
            ttCode: ttCode
        )
        return BDPRouteMediator.appMetaRequest(withURL: urlStr, params: param, uniqueID: uniqueID) as URLRequest
    }
    
    /// 自定义批量Meta请求
    /// - Parameters:
    ///   - metaMap: [cli_xxxx: "0.2.3", cli_xxxx: "*"]
    ///   - ttCode: meta加密code
    /// - Throws: 错误
    /// - Returns: 请求
    private func batchMetaRequestWith(
        _ entities:[String: String],
        scene: String,
        ttCode: BDPMetaTTCode
    ) throws -> URLRequest {
        let urlStr = BDPSDKConfig.shared().batchAppMetaURL
        guard !urlStr.isEmpty else {
            let msg = "url for meta request is empty"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        if ttCode.ttcode.isEmpty {
            throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "ttcode is empty, please check ttcode system")
        }
        //  构造参数
        let queries = entities.keys.compactMap{ ["app_id":$0,
                                                 "app_version": entities[$0]] }
        var params: [String: Any] = ["queries": queries, "scene": scene, "tt_code": ttCode.ttcode]
        if let larkVersion = BDPDeviceTool.bundleShortVersion {
            params["lark_version"] = larkVersion
        }
        return BDPRouteMediator.appMetaRequest(withURL: urlStr, params:params , uniqueID: nil) as URLRequest
    }
    
    

    /// 生成请求参数
    /// - Parameters:
    ///   - uniqueID: 通用应用的唯一复合ID
    ///   - token: preview token
    ///   - ttCode: meta加密code
    /// - Returns: 请求参数
    private func generateRequestInfos(
        with uniqueID: BDPUniqueID,
        token: String?,
        ttCode: BDPMetaTTCode
    ) throws -> [String: Any] {
        if ttCode.ttcode.isEmpty {
            throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "ttcode is empty, please check ttcode system")
        }
        return [
            "bdp_device_platform": BDPDeviceHelper.isPadDevice() ? "ipad" : "iphone",
            "bdp_version_code": BDPApplicationManager.shared().applicationInfo[BDPAppVersionKey] ?? "",
            "appid": uniqueID.appID,
            "ttcode": ttCode.ttcode,
            "version": OPAppVersionTypeToString(uniqueID.versionType),
            "token": token ?? ""
        ]
    }

}

extension GadgetMetaProvider: MetaFromStringProtocol {
    //实现简单协议
    public func buildMetaModel(with metaJsonStr: String) throws -> AppMetaProtocol {
        return try buildMetaModel(with: metaJsonStr, uniqueID: nil)
    }
}
