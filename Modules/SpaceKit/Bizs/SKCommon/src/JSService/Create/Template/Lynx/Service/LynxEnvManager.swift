//
//  LynxEnvManager.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/10/12.
//  


import SKFoundation
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit
import BDXResourceLoader
import IESGeckoKit
import Swinject
import EENavigator
import Foundation
import UIKit
import SKResource
import LarkAccountInterface
import LarkContainer
import SKInfra

public final class LynxEnvManager {
    public typealias LynxView = UIView & BDXLynxViewProtocol
    
    static let bizID = "ccm-lynx-bid"
    
    static let channel = "docs_lynx_channel"
    
    static let imageFetcher = ImageFetcher()    
    
    static let devtoolDelegate = SKDevToolCaller()
    
    static var lynxViews: NSHashTable<LynxView> = NSHashTable(options: .weakMemory)
    
    static private let accessKey: String = {
        #if DEBUG
        return "2f8feb7db4d71d6ddf02e76668896c41"
        #else
        return "170fde123c7a011616dd5e6856ec443b"
        #endif
    }()
    static private let prefix: String = {
        #if DEBUG
        return "internal/ccm/lynx"
        #else
        return "online/ccm/lynx"
        #endif
    }()
    // 目前host没有实际意义，传啥都行
    static private let host: String = {
//        if DomainConfig.envInfo.isChinaMainland {
//            #if DEBUG
//            return "https://tosv.byted.org/obj/gecko-internal/"
//            #else
//            return "https://lf-sourcecdn-tos.bytegecko.com/obj/byte-gurd-source/"
//            #endif
//        } else {
//            #if DEBUG
//            return "https://tosv.byted.org/obj/gecko-internal-sg/"
//            #else
//            return "https://lf16-sourcecdn-tos.ibytedtos.com/obj/byte-gurd-source-sg/"
//            #endif
//        }
        return "ccm-lynx://lynxview"
    }()
    
    public static func setupLynx() {
        struct Once {
            static let once = Once()
            init() {
                #if canImport(CJPay)
                #else
                LynxEnvManager.commonSetup()
                #endif
                guard let lynxKit = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol else {
                    return
                }
                lynxKit.addDevtoolDelegate(LynxEnvManager.devtoolDelegate)
                LynxHotfixPkgProcessor.clearHotfixPkgIfNeeded()
                LynxEnvManager.logCurrentLynxVersion()
            }
        }
        _ = Once.once
    }
    
    static func createLynxView(frame: CGRect, params: BDXLynxKitParams) -> LynxView? {
        guard let lynxKit = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol else {
            DocsLogger.error("can't get BDXLynxKitProtocol service")
            return nil
        }
        if params.imageFetcher == nil {
            params.imageFetcher = Self.imageFetcher
        }
        guard let lynxView = lynxKit.createView(withFrame: frame, params: params) else {
            DocsLogger.error("create lynx view fail")
            return nil
        }
        registerCommonHandlers(for: lynxView)
        registerUIElements(for: lynxView)
        registerNativeModules(for: lynxView)
        lynxView.skSourceUrl = params.sourceUrl
        lynxViews.add(lynxView)
        return lynxView
    }
    
    static func createLynxViewV2(frame: CGRect, params: BDXLynxKitParams, hotfixLoadStrategy: LynxGeckoLoadStrategy = .localFirstNotWaitRemote) -> LynxView? {
        guard let lynxKit = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol else {
            DocsLogger.error("can't get BDXLynxKitProtocol service")
            return nil
        }
        
        var customTemplateProvider: SKTemplateProvider?
        if let proxyIPAndPort = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.lynxTemplateSourceURL) {
            params.sourceUrl = "http://\(proxyIPAndPort)/\(channel)/\(params.bundle)"
        } else {
            params.channel = channel
            params.accessKey = accessKey
            params.sourceUrl = url(with: params)
            customTemplateProvider = createTemplateProvider(with: hotfixLoadStrategy)
            params.templateProvider = customTemplateProvider
        }
        let context = BDXContext()
        if let monitorClass = BDXServiceManager.getClassWith(BDXMonitorProtocol.self, bizID: nil) as? NSObject.Type {
            let monitor = monitorClass.init()
            context.registerStrongObj(monitor, forKey: "lifeCycleTracker")
        }
        let passportService = try? Container.shared.resolve(assert: PassportService.self)
        let deviceId = passportService?.deviceID ?? ""
        context.registerStrongObj(
            ["deviceId": deviceId],
            forKey: kBDXContextKeyGlobalProps
        )
        params.context = context
        
        if params.imageFetcher == nil {
            params.imageFetcher = imageFetcher
        }
        guard let lynxView = lynxKit.createView(withFrame: frame, params: params) else {
            DocsLogger.error("create lynx view fail")
            return nil
        }
        registerCommonHandlers(for: lynxView)
        registerUIElements(for: lynxView)
        registerNativeModules(for: lynxView)
        lynxView.skSourceUrl = params.sourceUrl
        lynxView.skCustomTemplateProvider = customTemplateProvider
        lynxViews.add(lynxView)
        return lynxView
    }
    
    static private func createTemplateProvider(with hotfixLoadStrategy: LynxGeckoLoadStrategy) -> SKTemplateProvider {
        var customPkgUnzipURL: SKFilePath?
        if LynxCustomPkgManager.shared.shouldUseCustomPkg {
            customPkgUnzipURL = LynxCustomPkgManager.shared.savePathOfCustomPkg(with: LynxEnvManager.channel)
        }
        
        var buildInZipURL: SKFilePath?
        if let url = I18n.resourceBundle.url(forResource: "Lynx/docs_lynx_channel", withExtension: "7z") {
            buildInZipURL = SKFilePath(absUrl: url)
        }
        
        var buildInVersionURL: SKFilePath?
        if let url = I18n.resourceBundle.url(forResource: "Lynx/current_revision", withExtension: "") {
            buildInVersionURL = SKFilePath(absUrl: url)
        }
        
        let params = LynxTemplateLoader.Params(
            bizId: bizID,
            accessKey: accessKey,
            channel: channel,
            buildInZipURL: buildInZipURL,
            buildInVersionURL: buildInVersionURL,
            customPkgUnzipURL: customPkgUnzipURL
        )
        return SKTemplateProvider(params: params, hotfixLoadStrategy: hotfixLoadStrategy)
    }
    
    static private func url(with params: BDXLynxKitParams) -> String {
        return "\(host)/\(prefix)/\(params.channel)/\(params.bundle)"
    }
    
    private static func commonSetup() {
        guard let lynxKit = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol else {
            return
        }
        lynxKit.initLynxKit()
        
        // setup X Bridge
        #if DEBUG
        let inDevelopmentMode = false
        #else
        let inDevelopmentMode = false
        #endif
        BDXBridge.registerEngineClass(BDXBridgeEngineAdapter_TTBridgeUnify.self, inDevelopmentMode: inDevelopmentMode)
        BDXBridge.registerDefaultGlobalMethods(filter: nil)
    }
    
    public static func registerRouter() -> Router {
        return Navigator.shared.registerRoute_(
            regExpPattern: "//remote_debug_lynx",
            priority: .high
        ) { req, res in
            guard let service = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol else {
                res.end(resource: nil)
                return
            }
            service.enableLynxDevtool(req.url, withOptions: ["App": "Lark", "AppVersion": "1.0.0"])
            res.end(resource: nil)
        }
    }
    
    private static func registerCommonHandlers(for lynxView: LynxView) {
        let logHandler: BDXLynxBridgeHandler = { (container, name, params, callback) in
            let level = params?["level"] as? String ?? "info"
            let message = params?["message"] as? String ?? ""
            let tag = params?["tag"] as? String
            switch level {
            case "info": DocsLogger.info(message, component: tag)
            case "warn": DocsLogger.warning(message, component: tag)
            case "error": DocsLogger.error(message, component: tag)
            default:
                break
            }
            let statusCode = BDXBridgeStatusCode.succeeded.rawValue
            callback(statusCode, nil)
        }
        lynxView.registerHandler(logHandler, forMethod: "ccm.log")
        
        let teaEventHandler: BDXLynxBridgeHandler = { (container, name, params, callback) in
            guard let eventName = params?["eventName"] as? String else {
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }
            DocsTracker.newLog(event: eventName, parameters: params?["params"] as? [AnyHashable: Any])
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }
        lynxView.registerHandler(teaEventHandler, forMethod: "ccm.teaSendEvent")
        
        let fgEventHandler: BDXLynxBridgeHandler = { (container, name, params, callback) in
            guard let keys = params?["keys"] as? [String] else {
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }
            var map: [String: Bool] = [:]
            keys.forEach { key in
                map[key] = HostAppBridge.shared.call(GetLarkFeatureGatingService(key: key, isStatic: false, defaultValue: false)) as? Bool ?? false
            }
            callback(BDXBridgeStatusCode.succeeded.rawValue, ["fg": map])
        }
        lynxView.registerHandler(fgEventHandler, forMethod: "ccm.getFg")
        
        let httpBridgeHandler = HttpBridgeHandler()
        lynxView.registerHandler(httpBridgeHandler.handler, forMethod: httpBridgeHandler.methodName)
        let readCacheBridgeHandler = ReadCacheBridgeHandler()
        lynxView.registerHandler(readCacheBridgeHandler.handler, forMethod: readCacheBridgeHandler.methodName)
        let writeCacheBridgeHandler = WriteCacheBridgeHandler()
        lynxView.registerHandler(writeCacheBridgeHandler.handler, forMethod: writeCacheBridgeHandler.methodName)
    }
    
    private static func registerUIElements(for lynxView: LynxView) {
        // tab pager
        lynxView.registerUI?(LynxViewPagerElement.self, withName: LynxViewPagerElement.name)
        lynxView.registerUI?(LynxViewPagerItem.self, withName: LynxViewPagerItem.name)
        lynxView.registerUI?(LynxTabbar.self, withName: LynxTabbar.name)
        // refresher
        lynxView.registerUI?(LynxRefreshViewElement.self, withName: LynxRefreshViewElement.name)
        lynxView.registerUI?(LynxRefreshHeaderElement.self, withName: LynxRefreshHeaderElement.name)
        lynxView.registerUI?(LynxRefreshFooterElement.self, withName: LynxRefreshFooterElement.name)
        // empty view
        lynxView.registerUI?(LynxEmptyElement.self, withName: LynxEmptyElement.name)
        // lottie view
        lynxView.registerUI?(LynxLottieElement.self, withName: LynxLottieElement.name)
        // UDSwitch
        lynxView.registerUI?(LynxSwitch.self, withName: LynxSwitch.name)
        // UDCheckBox
        lynxView.registerUI?(LynxCheckBox.self, withName: LynxCheckBox.name)
        // icon view
        lynxView.registerUI?(LynxIconView.self, withName: LynxIconView.name)
    }
    
    private static func registerNativeModules(for lynxView: LynxView) {
        lynxView.registerModule(DateTimeFormatModule.self)
    }
    
    private static func logCurrentLynxVersion() {
        let action = {
            let info = SKTemplateInfoRecorder.shared.currentUsingResourceInfo()
            DocsLogger.info("(opt FG) using lynx version: \(info)")
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 10, execute: action)
    }
}

extension UIView {
    private static var SKSourceURLKey: Void = ()
    var skSourceUrl: String? {
        get {
            return objc_getAssociatedObject(self, &LynxView.SKSourceURLKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &LynxView.SKSourceURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private static var SKCustomTemplateProviderKey: Void = ()
    var skCustomTemplateProvider: LynxTemplateProvider? {
        get {
            return objc_getAssociatedObject(self, &LynxView.SKCustomTemplateProviderKey) as? LynxTemplateProvider
        }
        set {
            objc_setAssociatedObject(self, &LynxView.SKCustomTemplateProviderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

class SKDevToolCaller: NSObject, BDXLynxDevtoolProtocol {
    func openDevtoolCard(_ urlStr: String) -> Bool {
        DocsLogger.info("devtool open \(urlStr)")
        var canRespond = false
        for obj in LynxEnvManager.lynxViews.objectEnumerator() {
            guard let lynxView = obj as? LynxEnvManager.LynxView else {
                continue
            }
            if lynxView.skSourceUrl == urlStr {
                lynxView.load()
                DocsLogger.info("devtool reload lynxView")
                canRespond = true
            }
        }
        return canRespond
    }
}
