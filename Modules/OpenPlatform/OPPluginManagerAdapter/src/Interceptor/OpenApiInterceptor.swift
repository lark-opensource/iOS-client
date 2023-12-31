//
//  OpenApiInterceptor.swift
//  TTMicroApp
//
//  Created by zhangxudong on 5/26/22.
//

import Foundation
import OPSDK
import LarkSetting
import MapKit
import LarkFeatureGating
import LKCommonsLogging
import OPFoundation

/// ApiInvoke 拦截器作用于 JSBrige 与 pluginManager之间
@objc public protocol OpenApiInvokeInterceptor {
    /// 作用于JSBrige 收到调用后通知PluginManger之前一般是 JSbrige收到 js调用的第一行代码
    func preInvoke(method: BDPJSBridgeMethod, extra: Any?) throws
}
/// ApiInvoke 拦截器链
@objc public protocol OpenApiInvokeInterceptorChain: OpenApiInvokeInterceptor {
    var interceptors: [OpenApiInvokeInterceptor] { get }
    /// 拦截器执行的顺序与register的先后顺序相同
    func register(inteceptor: OpenApiInvokeInterceptor)
}
/// webApp的拦截器初始化使用
public protocol WebAppInterceptorContext: AnyObject {
    var appID: String? { get }
}

/// ApiInvoke 拦截器链的实现
public final class OpenApiInvokeInterceptorChainImp: NSObject, OpenApiInvokeInterceptorChain {
    static let logger = Logger.log(OpenApiInvokeInterceptorChainImp.self, category: "OpenAPI")
    /// 小程序使用
    public convenience init(gadget uniqueID: OPAppUniqueID, developerConfig: (() -> [String: Any]?)?) {
        self.init()
        register(inteceptor: OpenApiGadgetDispatchInvokeInterceptor(uniqueID: uniqueID, developerConfig: developerConfig))
    }
    /// 网页使用
    public convenience init(webAppContext :WebAppInterceptorContext) {
        self.init()
        register(inteceptor: OpenApiWebAppDispatchInvokeInterceptor(appContext: webAppContext))
    }
    
    public override init(){
        super.init()
    }
    
    private(set) public var interceptors: [OpenApiInvokeInterceptor] = []
    let semaphore = DispatchSemaphore(value: 1)

    
    public func register(inteceptor: OpenApiInvokeInterceptor) {
        
        semaphore.wait()
        interceptors.append(inteceptor)
        semaphore.signal()
        Self.logger.info("register inteceptor \(inteceptor) done")
    }
    
    public func preInvoke(method: BDPJSBridgeMethod, extra: Any?) throws {
       
        for interceptor in interceptors {
            do {
                try interceptor.preInvoke(method: method, extra: extra)
            } catch {
                Self.logger.error("interceptor preInvoke execute methodName: \(method.name) methodName: \(String(describing: method.params)) extra: \(String(describing: extra)) error\(error)")
                throw error
            }
        }
    }
}
extension OpenApiInvokeInterceptor {
    /// 构造方法名
    func construction(originName: String, version: Int) -> String {
        guard version > 1 else {
            return originName
        }
        return originName + "V\(version)"
    }
}
/// 小程序 api 派发拦截器
private final class OpenApiGadgetDispatchInvokeInterceptor: NSObject, OpenApiInvokeInterceptor {
    static let logger = Logger.log(OpenApiGadgetDispatchInvokeInterceptor.self, category: "OpenAPI")
    let uniqueID: OPAppUniqueID
    private lazy var setting: OpenApiInvokeInterceptorConfig? = OpenApiInvokeInterceptorConfig.settingsValue()
    
    private var developerConfig: (() -> [String: Any]?)?
    
    init(uniqueID: OPAppUniqueID, developerConfig: (() -> [String: Any]?)?) {
        self.uniqueID = uniqueID
        self.developerConfig = developerConfig
        super.init()
    }
    /// 只有在白名单中的api 以及版本 才会被拦截，
    private let whiteList: Set<String> = ["getLocationV2",
                                          "chooseLocationV2",
                                          "openLocationV2",
                                          "startLocationUpdateV2",
                                          "stopLocationUpdateV2"]
    
    @objc func preInvoke(method: BDPJSBridgeMethod, extra: Any?) throws {
        /// settings 配置优先级> app.config
        let appID = uniqueID.appID
        if !appID.isEmpty,
           let apiVersion = setting?.apiVersionFor(appID: appID, methodName: method.name) {
            let apiName = construction(originName: method.name, version: apiVersion)
            if whiteList.contains(apiName) {
                method.name = apiName
            }
            Self.logger.info("appid:\(uniqueID.appID) preInvoke method.name \(method.name) use settings to newName\(method.name)")
            return
        }
        
        if let config = self.developerConfig?()?[method.name] as? [String : Any],
           let apiVersion = config["version"] as? Int {
            let apiName = construction(originName: method.name, version: apiVersion)
            if whiteList.contains(apiName) {
                method.name = apiName
            }
            Self.logger.info("appid:\(uniqueID.appID) preInvoke method.name \(method.name) use appConfig to newName \(method.name)")
            return
        }
    }
    
}
/// SetAPIConfig API 调用成功后发送的通知 用于通知 OpenApiWebAppDispatchInvokeInterceptor 保存Config
public extension Notification.Name {
    static let openApiWebAppDeveloperDidSetConfig = Notification.Name.init(rawValue: "openApiWebAppDeveloperDidSetConfig")
}

public struct WebAppInvokeInterceptorExtra {
    /// 调用方objectID。JS环境中生成的UUID。 由h5SDK保证不同的tt object的callerID 不同
    public private(set) var callerID: String?
    public init(callerID: String?) {
        self.callerID = callerID
    }
}
/// web应用api 派发拦截器
private final class OpenApiWebAppDispatchInvokeInterceptor: NSObject, OpenApiInvokeInterceptor {
    static let logger = Logger.log(OpenApiWebAppDispatchInvokeInterceptor.self, category: "OpenAPI")
    struct ApiInvokeConfig {
        private let source: [AnyHashable: Any]
        init(source: [AnyHashable: Any]) {
            self.source = source
        }
        func apiVersionFor(methodName: String) -> Int? {
            guard let config = source[methodName] as? [String: Any],
                  let version = config["version"] as? Int else {
                return nil
            }
            return version
        }
    }
    
    let appContext: WebAppInterceptorContext
    private lazy var setting: OpenApiInvokeInterceptorConfig? = OpenApiInvokeInterceptorConfig.settingsValue()
    typealias TTCallerID = String
    /// web页面级别的配置 key为 JS环境中TT生成的UUID 不同的tt object 的callerID 不同由 h5SDK保证
    private var developerConfig: [TTCallerID: ApiInvokeConfig] = [:]
    
    /// 只有在白名单中的api 以及版本 才会被拦截，
    private let whiteList: Set<String> = ["getLocationV2",
                                          "chooseLocationV2",
                                          "openLocationV2",
                                          "startLocationUpdateV2",
                                          "stopLocationUpdateV2"]
    
    init(appContext: WebAppInterceptorContext) {
        self.appContext = appContext

        super.init()
        addObserver()
    }
    
    @objc func preInvoke(method: BDPJSBridgeMethod, extra: Any?) throws {
      
        /// settings 配置优先级> app.config
        if !appID.isEmpty,
           let apiVersion = setting?.apiVersionFor(appID: appID, methodName: method.name) {
            let apiName = construction(originName: method.name, version: apiVersion)
            if whiteList.contains(apiName) {
                method.name = apiName
                Self.logger.info("appid:\(appID) preInvoke method.name \(method.name) use settins to newName \(method.name)")
            } else {
                Self.logger.warn("appid:\(appID) preInvoke method.name \(method.name) whiteList not contains \(apiName)")
            }
            
            return
        }
        
        /// 拦截器 判断extra 后置。确保即使用户不使用新版本H5SDK settings也可以生效， extra必须有callerID，因为要维护 developerConfig
        guard let extra = extra as? WebAppInvokeInterceptorExtra,
            let callerID = extra.callerID else {
            Self.logger.info("preInvoke method appid:\(appID) extra callID is nil")
            return
        }
        
        /// 对于SetAPIConfig 需要补充 callerID。
        if method.name == "setAPIConfig" {
            Self.logger.info("appid:\(appID) preInvoke method.name \(method.name) add webAppContext for setAPIConfig")
            method.params?["callerID"] = callerID
            return
        }
        
        /// 开发者通过 setAPIConfig 配置的API版本
        if let apiVersion = self.developerConfig[callerID]?.apiVersionFor(methodName: method.name) {
            let apiName = construction(originName: method.name, version: apiVersion)
            if whiteList.contains(apiName) {
                method.name = apiName
            } else {
                if whiteList.contains(apiName) {
                    method.name = apiName
                    Self.logger.info("appid:\(appID) preInvoke  method.name \(method.name) use appConfig to newName \(method.name)")
                } else {
                    Self.logger.warn("appid:\(appID) preInvoke method.name \(method.name) cannot use appConfig, whiteList not contains \(apiName)")
                }
            }
            return
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(developerDidSetConfig(notification:)), name: .openApiWebAppDeveloperDidSetConfig, object: nil)
    }
    
    var appID: String { appContext.appID ?? "" }
    @objc
    func developerDidSetConfig(notification: Notification) {
        Self.logger.info("appid:\(appID) received notiName\(Notification.Name.openApiWebAppDeveloperDidSetConfig) userInfo:\(String(describing: notification.userInfo))")
        guard let userInfo = notification.userInfo,
              let callerID = userInfo["callerID"] as? TTCallerID,
              !callerID.isEmpty,
            let apiConfig = userInfo["apiConfig"] as? [String: Any] else {
            return
        }
        Self.logger.info("appid:\(appID) callerID: \(callerID) set developerConfig\(apiConfig)")
        developerConfig[callerID] = ApiInvokeConfig(source: apiConfig)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: .openApiWebAppDeveloperDidSetConfig,
                                                  object: nil)
    }
    
}
/// Block API 派发拦截器
public final class OpenApiBlockDispatchInvokeInterceptor: NSObject, OpenApiInvokeInterceptor {
    
    @objc public func preInvoke(method: BDPJSBridgeMethod, extra: Any?) throws {
        let methodMap = [
            "getLocation": "getLocationV2",
            "startLocationUpdate": "startLocationUpdateV2",
            "stopLocationUpdate": "stopLocationUpdateV2",
        ]
        if let newMethodName = methodMap[method.name] {
            method.name = newMethodName
        }
    }
}
/// ApiConfig settings
extension OpenApiInvokeInterceptorConfig {
    func apiVersionFor(appID: String, methodName: String) -> Int? {
        /// whiteList 优先级 > forece
        if let apiVersion = apiConfig.whiteList[appID]?[methodName]?.version,
           apiVersion > 1 {
            return apiVersion
        }
        if let apiVersion = apiConfig.foreList[methodName]?.version,
           apiVersion > 1 {
            return apiVersion
        }
        return nil
    }
}

/// APIConfig settins配置
struct OpenApiInvokeInterceptorConfig: SettingDecodable {
    typealias ApiName = String
    typealias AppID = String
    static let settingKey = UserSettingKey.make(userKeyLiteral: "api_invoke_interceptor_config")
    
    struct ApiConfigItem: Decodable {
        let version: Int
        enum CodingKeys: String, CodingKey {
            case version = "version"
        }
    }
    struct ApiConfig: Decodable {
        let whiteList: [AppID: [ApiName: ApiConfigItem]]
        let foreList: [ApiName: ApiConfigItem]
        enum CodingKeys: String, CodingKey {
            case whiteList = "whiteList"
            case foreList = "force"
        }
    }
    let apiConfig: ApiConfig
    
    enum CodingKeys: String, CodingKey {
        case apiConfig = "apiConfig"
    }
}
extension OpenApiInvokeInterceptorConfig {
    static let logger = Logger.log(OpenApiInvokeInterceptorConfig.self, category: "OpenAPI")
    static func settingsValue() -> OpenApiInvokeInterceptorConfig? {
        let result: OpenApiInvokeInterceptorConfig?
        do {
            let value = try SettingManager.shared.setting(with: OpenApiInvokeInterceptorConfig.self)
            result = value
        } catch let error {
            Self.logger.error("settings featch api_invoke_interceptor_config error: \(error)")
            result = nil
        }
        return result
    }
    
}
