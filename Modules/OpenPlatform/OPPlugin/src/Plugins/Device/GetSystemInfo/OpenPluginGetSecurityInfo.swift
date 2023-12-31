//
//  OpenPluginGetSecurityInfo.swift
//  OPPlugin
//
//  Created by houjihu on 2021/7/6.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import ECOProbe
import OPFoundation
import LarkContainer

/// 设备安全信息API实现类，支持打卡反作弊需求
/// 技术方案：
/// https://bytedance.feishu.cn/wiki/wikcnRgqo6uMFs6kdO0DkGjjOpf
/// https://bytedance.feishu.cn/docs/doccnQvMXJxcGUTaAYGgRF67Vtg
/// https://bytedance.feishu.cn/docs/doccnDAWdnpmC4wHGqnNGTJR1zg
class OpenPluginGetSecurityInfo: OpenBasePlugin {
    /// 初始化设备安全信息API实现类
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        /// 注册反作弊API handler
        registerInstanceAsyncHandler(for: "getSecurityInfo", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIGetSecurityInfoResult.self) { (this, params, context, callback) in
            

            this.getSecurityInfo(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "getSecurityEnv", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIGetSecurityEnvResult.self) { (this, params, context, gadgetContext, callback) in
            

            this.getSecurityEnv(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

extension OpenPluginGetSecurityInfo {
    /// 反作弊API实现
    public func getSecurityInfo(params: OpenAPIBaseParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetSecurityInfoResult>) -> Void) {
        context.apiTrace.info("getSecurityInfo params: \(params)")
        let isCracked = OpenSecurityHelper.isCracked()
        let isEmulator = OpenSecurityHelper.isEmulator()
        let isDebug = OpenSecurityHelper.isDebug()
        let timestamp = OpenSecurityHelper.timestamp()
        OPMonitor(EPMClientOpenPlatformApiAntiCheatingCode.get_securityinfo_success)
            .addCategoryValue("isCracked", isCracked)
            .addCategoryValue("isDebug", isDebug)
            .addCategoryValue("isEmulator", isEmulator)
            .flush()
        let result = OpenAPIGetSecurityInfoResult(isCracked: isCracked, isEmulator: isEmulator, isDebug: isDebug, timestamp: timestamp)
        callback(.success(data: result))
        context.apiTrace.info("getSecurityInfo success: data(\(result.toJSONDict())")
    }

    /// 反作弊API (返回的参数不同, 目前供部分KA使用)
    public func getSecurityEnv(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetSecurityEnvResult>) -> Void) {
        // 检查组织组织权限
        var scopes = [AnyHashable : Any]()
        if let authorization = gadgetContext.authorization {
            scopes = authorization.source.orgAuthMap
        } else {
            context.apiTrace.info("authorization is nil")
        }

        let orgAuthMapState: EMAOrgAuthorizationMapState = BDPIsEmptyDictionary(scopes) ? .empty : .notEmpty
        let hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: scopes, invokeName: "getSecurityEnv")
        context.apiTrace.info("hasAuth: \(hasAuth)")

        guard hasAuth else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.organizationAuthDeny)
            callback(.failure(error: error))
            return
        }

        let isCracked = OpenSecurityHelper.isCracked()
        let isEmulator = OpenSecurityHelper.isEmulator()
        let isDebug = OpenSecurityHelper.isDebug()
        let timestamp = OpenSecurityHelper.timestamp()

        let result = OpenAPIGetSecurityEnvResult(isCracked: isCracked,
                                                 isEmulator: isEmulator,
                                                 isDebug: isDebug,
                                                 timestamp: timestamp)

        OPMonitor(EPMClientOpenPlatformApiAntiCheatingCode.get_securityenv_success)
            .addMap(["isCracked"     : result.isCracked,
                     "isEmulator"    : result.isEmulator,
                     "isDebug"       : result.isDebug,
                     "existBlackApp" : result.existBlackApp,
                     "org_auth_map"  : "\(orgAuthMapState.rawValue)"])
            .flush()

        callback(.success(data: result))
        context.apiTrace.info("getSecurityEnv success: data: \(result.toJSONDict())")
    }
}

/// getSecurityInfo API出参封装对象
/// 鉴于iOS端拿不到准确的应用列表，appList参数只在Android端提供
final class OpenAPIGetSecurityInfoResult: OpenAPIBaseResult {
    /// 是否越狱或root
    public let isCracked: Bool
    /// 是否是模拟器环境
    public let isEmulator: Bool
    /// 是否是调试模式
    public let isDebug: Bool
    /// 当前时间戳
    public let timestamp: NSNumber
    /// 初始化getSecurityInfo API出参封装对象
    public init(
        isCracked: Bool,
        isEmulator: Bool,
        isDebug: Bool,
        timestamp: NSNumber
    ) {
        self.isCracked = isCracked
        self.isEmulator = isEmulator
        self.isDebug = isDebug
        self.timestamp = timestamp
        super.init()
    }
    /// 为getSecurityInfo API出参封装对象生成可序列化对象
    public override func toJSONDict() -> [AnyHashable : Any] {
        var jsonDict: [AnyHashable : Any] = [:]
        jsonDict["isCracked"] = isCracked
        jsonDict["isEmulator"] = isEmulator
        jsonDict["isDebug"] = isDebug
        jsonDict["timestamp"] = timestamp
        return jsonDict
    }
}


/// getSecurityEnv API出参封装对象
/// 鉴于iOS端拿不到准确的应用列表，existBlackApp参数只在Android端提供, iOS默认返回false
final class OpenAPIGetSecurityEnvResult: OpenAPIBaseResult {
    /// 是否越狱或root
    public let isCracked: Bool
    /// 是否是模拟器环境
    public let isEmulator: Bool
    /// 是否是调试模式
    public let isDebug: Bool
    /// 当前时间戳
    public let timestamp: NSNumber
    /// 是否存在作弊App(iOS当前不支持获取Applist列表, 这边默认返回false)
    public let existBlackApp: Bool
    /// 初始化getSecurityInfo API出参封装对象
    public init(
        isCracked: Bool,
        isEmulator: Bool,
        isDebug: Bool,
        timestamp: NSNumber,
        existBlackApp: Bool = false
    ) {
        self.isCracked = isCracked
        self.isEmulator = isEmulator
        self.isDebug = isDebug
        self.timestamp = timestamp
        self.existBlackApp = existBlackApp
        super.init()
    }
    /// 为getSecurityEnv API出参封装对象生成可序列化对象
    public override func toJSONDict() -> [AnyHashable : Any] {
        var jsonDict: [AnyHashable : Any] = [:]
        jsonDict["isCracked"] = isCracked
        jsonDict["isEmulator"] = isEmulator
        jsonDict["isDebug"] = isDebug
        jsonDict["timestamp"] = timestamp
        jsonDict["existBlackApp"] = existBlackApp
        return jsonDict
    }
}
