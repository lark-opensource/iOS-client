//
//  OpenPluginMockUtils.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/3.
//

import Foundation
import OPJSEngine
import LarkOpenPluginManager
import LarkOpenAPIModel
import TTMicroApp

// MARK: - Mock BDPEngineProtocol & BDPJSBridgeEngineProtocol

class OPTestMetaWithAuth: NSObject, BDPMetaWithAuthProtocol {
    var uniqueID: OPAppUniqueID = OPAppUniqueID(appID: "cli_9f4623178bbe500c", identifier: "blk_5fcc9f0a2a868003b127e616", versionType: .current, appType: .block)
    
    var name: String = ""
    
    var icon: String = ""
    
    var version: String = ""
    
    var version_code: Int64 = 0
    
    var domainsAuthMap: [String : [String]] = [:]
    
    var whiteAuthList: [String] = []
    
    var blackAuthList: [String] = []
    
    var authPass: Int = 0
    
    var orgAuthMap: [AnyHashable : Any] = [:]
    
    var userAuthMap: [AnyHashable : Any] = [:]
    
    
    public override init() {
    }
    
}

class TestAuthStorage: NSObject, BDPAuthStorage {
    func setObject(_ object: Any!, forKey key: String!) -> Bool {
        return true
    }
    
    func object(forKey key: String!) -> Any! {
        return ""
    }
    
    func removeObject(forKey key: String!) -> Bool {
        return true
    }
    
    
}

@available(iOS 13.0, *)
public final class OPMockEngine: NSObject {
    
    public private(set) var uniqueID: OPAppUniqueID
    
    public var authorization: BDPJSBridgeAuthorization?
    
    public private(set) var bridgeType: BDPJSBridgeMethodType
    
    public private(set) var bridgeController: UIViewController?
    
    public let appID = "testAppID"
    
    public init(appType: OPAppType, bridgeType: BDPJSBridgeMethodType, bridgeController: UIViewController?) {
        let auth = BDPAuthorization(authDataSource: OPTestMetaWithAuth(), storage: TestAuthStorage())
        authorization = auth
        uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: appType)
        self.bridgeType = bridgeType
        self.bridgeController = bridgeController
    }
}

@available(iOS 13.0, *)
extension OPMockEngine: BDPEngineProtocol {
    
    public func bdp_fireEventV2(_ event: String, data: [AnyHashable : Any]?) {
        print("OPGadgetMockEngine bdp_fireEventV2 event: \(event), data: \(String(describing: data))") }
    
    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable : Any]?) {
        print("OPGadgetMockEngine bdp_fireEvent event: \(event), sourceID: \(sourceID), data: \(String(describing: data))")
    }
}

@available(iOS 13.0, *)
 extension OPMockEngine: BDPJSBridgeEngineProtocol {
    
     public func bdp_evaluateJavaScript(_ script: String) async throws -> Any {
        print("OPGadgetMockEngine bdp_evaluateJavaScript script: \(script)")
    }
}

// MARK: - Mock BDPJSBridgeAuthorization

@available(iOS 13.0, *)
class BDPJSBridgeAuthorizationMock: NSObject, BDPJSBridgeAuthorization {
    public func checkAuthorization(_ method: BDPJSBridgeMethod?, engine: BDPJSBridgeEngine?) async -> BDPAuthorizationPermissionResult {
        return .enabled
    }
    
    @objc public func checkAuthorizationURL(_ url: String, authType: BDPAuthorizationURLDomainType) -> Bool {
        return true
    }
}

// MARK: - OPMockUtils

@available(iOS 13.0, *)
struct OPMockUtils {
    static func getAPIContext(pluginManager: OpenPluginManagerProtocol, engine: BDPEngineProtocol, controller: UIViewController) -> OpenAPIContext {
        
        // 构造context
        let appContext = BDPAppContext()
        appContext.engine = engine
        appContext.controller = controller
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(engine.uniqueID)
        let apiTrace = OPTraceService.default().generateTrace(withParent: appTrace, bizName: "UnitTest")
        let additionalInfo: [AnyHashable: Any] = ["gadgetContext": GadgetAPIContext(with: appContext)]
        let context = OpenAPIContext(trace: apiTrace,
                                     dispatcher: pluginManager,
                                     additionalInfo: additionalInfo)
        return context
    }
}

struct TestUtilsConfig {
    let bizDomain: OpenAPIBizDomain
    let bizType: OpenAPIBizType
    let appType: OPAppType
    let bridgeType: BDPJSBridgeMethodType
}

/// 小程序Mock测试模块
@available(iOS 13.0, *)
public final class OpenPluginGadgetTestUtils: OpenPluginTestUtils {
    
    public init() {
        let config = TestUtilsConfig(bizDomain: .openPlatform, bizType: .gadget, appType: .gadget, bridgeType: .nativeApp)
        super.init(config: config)
    }
}

/// 网页应用Mock测试模块
@available(iOS 13.0, *)
public final class OpenPluginWebAppTestUtils: OpenPluginTestUtils {
    
    public init() {
        let config = TestUtilsConfig(bizDomain: .openPlatform, bizType: .webApp, appType: .webApp, bridgeType: .webApp)
        super.init(config: config)
    }
}

/// Block Mock测试模块
@available(iOS 13.0, *)
public final class OpenPluginBlockTestUtils: OpenPluginTestUtils {
    
    public init() {
        let config = TestUtilsConfig(bizDomain: .openPlatform, bizType: .block, appType: .block, bridgeType: .block)
        super.init(config: config)
    }
}

@available(iOS 13.0, *)
public class OpenPluginTestUtils {
    
    public lazy var appID = {
        engine.uniqueID.appID
    }()

    public lazy var uniqueID = {
        engine.uniqueID
    }()
    
    public let pluginManager: OpenPluginManager
    public let context: OpenAPIContext
    let engine: BDPEngineProtocol
    let controller: UIViewController
    
    init(config: TestUtilsConfig) {
        pluginManager = OpenPluginManager(bizDomain: config.bizDomain, bizType: config.bizType, bizScene: "")
        controller = UIViewController()
        engine = OPMockEngine(appType: config.appType, bridgeType: config.bridgeType, bridgeController: controller)
        context = OPMockUtils.getAPIContext(pluginManager: pluginManager, engine: engine, controller:controller)
    }
    
    public func asyncCall(apiName: String, params: [AnyHashable : Any], callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        pluginManager.asyncCall(apiName: apiName, params: params, canUseInternalAPI: false, context: context, callback: callback)
    }
    
    public func syncCall(apiName: String, params: [AnyHashable : Any]) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        pluginManager.syncCall(apiName: apiName, params: params, canUseInternalAPI: false, context: context)
    }
    
    /// 准备文件路径
    public private(set) var sandbox: BDPSandboxProtocol?
    public func prepareGadgetSandboxPath(pkgName: String) {
        if sandbox == nil,
           let module = BDPModuleManager(of: self.uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol {
            sandbox = module.createSandbox(with: self.uniqueID, pkgName: pkgName)
            sandbox?.clearTmpPath()
            sandbox?.clearPrivateTmpPath()
            //clearUser Dir
            if let userPath = sandbox?.userPath(), FileManager.default.fileExists(atPath: userPath){
                try? FileManager.default.removeItem(atPath: userPath)
                try? FileManager.default.createDirectory(atPath: userPath, withIntermediateDirectories: true)
            }
        }
    }
}
