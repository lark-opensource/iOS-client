//
//  LarkMicroApp.swift
//  Lark
//
//  Created by lichen on 2018/8/13.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import EEMicroAppSDK
import EENavigator
import Foundation
import LarkAccountInterface
import LarkAppLinkSDK
import LarkContainer
import LarkModel
import RxSwift
import Swinject
import LarkAlertController
import LKCommonsLogging
import LarkFeatureGating
import EEMicroAppSDK
import OPSDK
import LarkNavigator
import ECOInfra
import TTMicroApp

public final class LarkMicroApp: MicroAppService {
    public static let logger = Logger.oplog(LarkMicroApp.self, category: "Module.LarkMicroApp")

    public let resolver: Resolver
    public let disposeBag = DisposeBag()
    private let sslocalOpenPrefix = "sslocal://"
//    private let feishuOpenPrefix = "https://applink.feishu.cn/client/mini_program/open"
//    private let larkSuiteOpenPrefix = "https://applink.larksuite.com/client/mini_program/open"
//    private let backupFeishuOpenPrefix = "lark://applink.feishu.cn/client/mini_program/open"
//    private let backupLarkSuiteOpenPrefix = "lark://applink.larksuite.com/client/mini_program/open"
    private let gadgetPathPrefix = "/client/mini_program/open"
    private let setupAction: (LarkMicroApp, Resolver) -> ()
    public init(resolver: Resolver, setup: @escaping (LarkMicroApp, Resolver) -> ()) {
        self.resolver = resolver
        self.setupAction = setup
    }

    public func setup() {
        
    }

    public func vote(in chat: Chat) {
        let voteAppID = "tt26b3500eb9998b36"
        EERoute.shared().clearTaskCache(with: OPAppUniqueID(appID: voteAppID, identifier: nil, versionType: .current, appType: .gadget))
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-_.!~*'()")
        
        let navigator = OPUserScope.userResolver().navigator
        if let uriencodeStr = "pages/vote-index/index?groupid=\(chat.id)".addingPercentEncoding(withAllowedCharacters: characterSet),
        let url = URL(string: "sslocal://microapp?app_id=\(voteAppID)&start_page=\(uriencodeStr)"),
        let fromVC = navigator.mainSceneWindow?.fromViewController {
            navigator.present(url, from: fromVC)
        }
    }

    public func getPermissionDataArrayWith(appID: String, appType: OPAppType) -> [MicroAppPermissionData] {
        let optionalOriginDataArray = EERoute.shared().getPermissionDataArray(with: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: appType))
        guard let originDataArray = optionalOriginDataArray else {
            return [MicroAppPermissionData]()
        }
        var dataArray = [MicroAppPermissionData]()
        for data in originDataArray {
            let scope = data.scope
            let name = data.name
            let mod = MicroAppPermissionData.Mod.init(rawValue: data.mod) ?? .readWrite
            let isGranted = data.isGranted
            let realData = MicroAppPermissionData(scope: scope, name: name, isGranted: isGranted, mod: mod)
            dataArray.append(realData)
        }
        return dataArray
    }

    public func getAppVersion(appID: String) -> String {
        let appVersion : String = EMAAppAboutUpdateManager.shared().getAppVersion(with: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)) ?? ""
        return appVersion
    }

    public func fetchAuthorizeData(appID: String, appType: OPAppType, storage: Bool, completion: @escaping ([AnyHashable: Any]?, [AnyHashable: Any]?, Error?) -> Void) {
        EERoute.shared().fetchAuthorizeData(OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: appType), storage: storage) { (result, bizData, error) in
            completion(result, bizData, error)
        }
    }
    
    public func setPermissonWith(appID: String, scope: String, isGranted: Bool, appType: OPAppType) {
        EERoute.shared().setPermissons([scope: (isGranted as NSNumber)], uniqueID: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: appType))
    }

    public func fetchMetaAndDownload(appID: String, statusChanged: @escaping (MicroAppUpdateStatus, String?) -> Void) {
        EMAAppAboutUpdateManager.shared().fetchMetaAndDownload(with: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)) { (status, latestVersion) in
            let ret = MicroAppUpdateStatus(rawValue: status.rawValue)
            statusChanged(ret ?? .none, latestVersion)
        }
    }

    public func download(appID: String, statusChanged: @escaping (MicroAppUpdateStatus, String?) -> Void) {
        EMAAppAboutUpdateManager.shared().download(with: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)) { (status, latestVersion) in
            let ret = MicroAppUpdateStatus(rawValue: status.rawValue)
            statusChanged(ret ?? .none, latestVersion)
        }
    }

    public func canRestartApp(appID: String) -> Bool {
        guard let updateManager = EMAAppAboutUpdateManager.shared() else {
            return false
        }
        return updateManager.canRestartApp(for: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget))
    }

    public func restartApp(appID: String) {
        EMAAppAboutUpdateManager.shared()?.restartApp(for: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget))
    }

    public func addLifeCycleListener(appid: String, listener: MicroAppLifeCycleListener) {
        EMALifeCycleManager.sharedInstance().add(EMALifeCycleListenerImpl(listener), for: OPAppUniqueID(appID: appid, identifier: nil, versionType: .current, appType: .gadget))
    }

    public func addLifeCycleListener(listener: MicroAppLifeCycleListener) {
        EMALifeCycleManager.sharedInstance().add(EMALifeCycleListenerImpl(listener))
    }

    public func closeMicroAppWith(appID: String) {
        EMALifeCycleManager.sharedInstance().closeMicroApp(with: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget))
    }

    public func canOpen(url: String) -> Bool {
//        return url.hasPrefix(sslocalOpenPrefix) ||
//            url.hasPrefix(feishuOpenPrefix) ||
//            url.hasPrefix(larkSuiteOpenPrefix) ||
//            url.hasPrefix(backupFeishuOpenPrefix) ||
//            url.hasPrefix(backupLarkSuiteOpenPrefix)
        if let parsedUrl = URL(string: url) {
            if parsedUrl.path.hasPrefix(gadgetPathPrefix) {
                return resolver.resolve(AppLinkService.self)?.isAppLink(parsedUrl) ?? false
            } else {
                return false
            }
        } else {
            return false
        }
        
        // 兼容头条圈
        // 暂时不考虑兼容http跳转方式
    }

    /// 网页应用新容器想要调用新整合的API
    /// - Parameters:
    ///   - method: 方法名
    ///   - args: 参数列表
    ///   - api: 网页应用容器
    ///   - sdk: 遵循OPJsSDKImplProtocol的对象
    ///   - needAuth: 调用API是否要走授权体系
    public func invokeWeb(method: String, args: [String: Any], api: UIViewController, sdk: AnyObject, needAuth: Bool) {
        assertionFailure("no implemention, should not enter here")
    }

    /// 网页应用新容器想要调用新整合的API 提供给全新的LarkWebViewController使用，其他控制器请勿调用
    /// 网页调用tt系列API， params 必须封装为如下字典，否则无法兼容遗留代码的字典取值，本次修改增加一个shouldUseNewbridgeProtocol用于灰度
    /*
    {
     "params": {
        业务数据
     },
     "callbackId": ""
    }
    */
    /// - Parameters:
    ///   - method: 方法名
    ///   - params: 参数列表
    ///   - api: 网页应用容器
    ///   - sdk: 遵循OPJsSDKImplProtocol的对象
    ///   - needAuth: 调用API是否要走授权体系
    ///   - shouldUseNewbridgeProtocol: 代表是否使用了新的协议，webappengine看了一下代码是和controller生命周期挂钩，但是webvc加载不同的网页的时候，不同网页引入的jssdk可能是新的也可能是老的，需要兼容
    public func invokeWeb(method: String, params: [String: Any], api: UIViewController, sdk: AnyObject, needAuth: Bool, shouldUseNewbridgeProtocol: Bool) {
        assertionFailure("no implemention, should not enter here")
    }

    public func realMachineDebug(schema: String) {
        let fg = LarkFeatureGating.shared.getFeatureBoolValue(for: .gadgetDevtoolVSCDebug)
        let url = URL(string: schema)
        LarkMicroApp.logger.info("realMachineDebug schema:\(String(describing: url)) fg:\(fg)")
        guard let schemaURL = url, fg, schema.isEmpty == false else {
            return
        }

        EERoute.shared().realMatchineDebugOpen(schemaURL, window: OPWindowHelper.fincMainSceneWindow())
    }
}

class EMALifeCycleListenerImpl: NSObject, EMALifeCycleListener {
    weak var listener: MicroAppLifeCycleListener?

    init(_ listener: MicroAppLifeCycleListener) {
        self.listener = listener
    }

    func onStart(_ uniqueID: BDPUniqueID) {
        listener?.onStart(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                       traceId: getTraceId(appID: uniqueID.appID)))
    }

    func onLaunch(_ uniqueID: BDPUniqueID) {
        listener?.onLaunch(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                        traceId: getTraceId(appID: uniqueID.appID)))
    }

    func onCancel(_ uniqueID: BDPUniqueID) {
        listener?.onCancel(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                        traceId: getTraceId(appID: uniqueID.appID)))
    }

    func onShow(_ uniqueID: BDPUniqueID, startPage: String?) {
        listener?.onShow(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                      traceId: getTraceId(appID: uniqueID.appID),
                                                      startPage: startPage))
    }

    func onHide(_ uniqueID: BDPUniqueID) {
        listener?.onHide(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                      traceId: getTraceId(appID: uniqueID.appID)))
    }

    func onDestroy(_ uniqueID: BDPUniqueID) {
        listener?.onDestroy(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                         traceId: getTraceId(appID: uniqueID.appID)))
    }

    func getTraceId(appID: String) -> String {
        return BDPTracingManager.sharedInstance().getTracingBy(OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget))?.traceId ?? ""
    }

    func onFailure(_ uniqueID: BDPUniqueID, code: EMALifeCycleErrorCode, msg: String?) {
        listener?.onFailure(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                         traceId: getTraceId(appID: uniqueID.appID)),
                            code: MicroAppLifeCycleError(rawValue: Int(code.rawValue)) ?? .unknown, msg: msg)
    }

    func blockLoading(_ uniqueID: BDPUniqueID, startPage:String?, callback: EMALifeCycleBlockCallback) {
        listener?.blockLoading(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                            traceId: getTraceId(appID: uniqueID.appID),
                                                            startPage:startPage),
                               callback: MicroAppLifeCycleBlockCallbackImpl(callback))
    }
    
    func onFirstAppear(_ uniqueID: BDPUniqueID) {
        listener?.onFirstAppear(context: EMALifeCycleContext(uniqueID: uniqueID,
                                                             traceId: getTraceId(appID: uniqueID.appID)))
    }
    
    //重写 isEqaul 判断，修正外部集合类 containObject 的逻辑
    override func isEqual(_ object: Any?) -> Bool {
        if let listener = self.listener as? NSObject,
           let listenerToCompare = object as? EMALifeCycleListenerImpl {
            let result = listener == (listenerToCompare.listener as? NSObject)
            LarkMicroApp.logger.info("compare with real listener, result:\(result)")
            return result
        } else {
            return super.isEqual(object)
        }
    }

    class MicroAppLifeCycleBlockCallbackImpl: MicroAppLifeCycleBlockCallback {
        let callback: EMALifeCycleBlockCallback

        init(_ callback: EMALifeCycleBlockCallback) {
            self.callback = callback
        }

        func continueLoading() {
            callback.continueLoading()
        }

        func cancelLoading() {
            callback.cancelLoading()
        }
    }
}
