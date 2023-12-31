//
//  OPLoginHelper.swift
//  TTMicroApp
//
//  Created by laisanpin on 2021/9/1.
//  这个文件是提供主端调用小程序登录接口;
//  该方案是临时的,后续会有新方案进行替换;

import Foundation
import LarkOPInterface
import TTMicroApp
import LKCommonsLogging

public final class OPLoginHelper: NSObject {
    static let logger = Logger.log(OPLoginHelper.self, category: "OPLoginHelper")

    lazy var workQuee = DispatchQueue(label: "com.bytedance.OPGadgetLogin", attributes: .init(rawValue: 0))

    var engineReadyCallback: ((_ isReady: Bool) -> Void)?
}

extension OPLoginHelper: OPApiLogin {
    public func gadgetLogin(_ appId: String, _ completion: @escaping(_ result: Result<String, Error>) -> Void) {
        self.workQuee.async {
            //主端调用可能是在EERoute更新[BDPSDKConfig sharedConfig].userLoginURL之前, 因此这边进行判断;
            if (EERoute.shared().isFinishLogin) {
                Self.logger.info("[OPLoginHelper] EERoute isFinishLogin, call login imp")
                self.loginImp(appId, completion)
            } else {
                Self.logger.info("[OPLoginHelper] EERoute is not finish, call login imp later")
                //这个block在调用后会设置成nil;
                EERoute.shared().loginFinishCallback = {
                    self.loginImp(appId, completion)
                }
            }
        }
    }

    /// 添加小程序引擎ready通知
    public func onGadgetEngineReady(_ callback: @escaping(_ isReady: Bool) -> Void) {
        Self.logger.info("[OPLoginHelper] onGadgetEnginReady, add notification listener")
        if let _ = engineReadyCallback {
            Self.logger.info("[OPLoginHelper] remove old listener and add new one")
            NotificationCenter.default.removeObserver(self, name: Notification.Name.kEERouteLoginFinishedNotification, object: nil)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(eeRouteLoginFinishNotificationHandler(notification:)), name: Notification.Name.kEERouteLoginFinishedNotification, object: nil)
        engineReadyCallback = callback
    }

    /// 移除小程序引擎ready通知
    public func offGadgetEngineReady() {
        Self.logger.info("[OPLoginHelper] offGadgetEnginReady, remove notification listener")
        engineReadyCallback = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name.kEERouteLoginFinishedNotification, object: nil)
    }
}

extension OPLoginHelper {
    public func loginImp(_ appId: String, _ completion: @escaping(_ result: Result<String, Error>) -> Void) {
        let mockUniqueID = OPAppUniqueID(appID: appId, identifier: "com.bytedance.mockUniqueID", versionType: .current, appType: .gadget)
        let mockEngine = OPMockEngine(mockUniqueID)

        let userPlugin = BDPPluginUser()

        userPlugin.login(withParam: [:], callback: { result, data in
            guard result == .success else {
                let errCode = Int(result.rawValue)
                let errMsg = data?["errMsg"] as? String ?? "unknown error"
                let error = NSError(domain: "miniAppLogin", code: errCode, userInfo: [NSLocalizedDescriptionKey : errMsg])
                Self.logger.error("[OPLoginHelper] BDPPluginUser login failed: \(error)")
                completion(.failure(error))
                return
            }
            let code = data?["code"] as? String ?? ""
            completion(.success(code))
        }, engine: mockEngine, controller: nil)
    }

    @objc
    private func eeRouteLoginFinishNotificationHandler(notification: Notification) {
        if let callback = engineReadyCallback {
            Self.logger.info("[OPLoginHelper] get kEERouteLoginFinishedNotification callback")
            self.workQuee.async {
                callback(true)
            }
        }
    }
}

// 该类是为了调用plugin对象方法而创建的, 只是在4.1版本使用, 后续不会采用该方式;
private class OPMockEngine: NSObject, BDPJSBridgeEngineProtocol {
    var uniqueID: OPAppUniqueID

    var bridgeController: UIViewController?

    var bridgeType: BDPJSBridgeMethodType = .unknown

    var authorization: BDPJSBridgeAuthorization?

    init(_ uniqueID: OPAppUniqueID) {
        self.uniqueID = uniqueID
    }

    func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {

    }

    func bdp_fireEventV2(_ event: String, data: [AnyHashable : Any]?) {

    }

    func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable : Any]?) {

    }
}

extension Notification.Name {
    static public let kEERouteLoginFinishedNotification = Notification.Name("kEERouteLoginFinishedNotification")
}
