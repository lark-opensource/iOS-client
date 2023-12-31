//
//  FinancePayManager+Bullet.swift
//  LarkFinance
//
//  Created by 李晨 on 2021/6/7.
//

import UIKit
#if canImport(CJPay)
import Foundation
import BDXServiceCenter
import BDXLynxKit
import BDXBridgeKit
import EENavigator
import LarkMessengerInterface
import Swinject
import LKCommonsTracker
import LKCommonsLogging
import LarkLocalizations
import UniverseDesignTheme
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignActionPanel
import LarkAccountInterface
import Lynx
import IESGeckoKit
import LarkEnv
import LarkContainer
import LarkNavigator
import LarkUIKit

//let AccessKey = "80f3d6f8eb94aad0dc181ca3a881adcc" //PPE
let AccessKey = "f2e97c8d28fd14414ce871534b57db7e" // online
let DebugAccessKey = "80f3d6f8eb94aad0dc181ca3a881adcc"

extension FinancePayManager {

    static let lynxRegExpPattern = "^(sslocal|snssdk)\\://(lynxview|lynx_page|lynxview_page)"

    static var lynxLifecycleDelegate = LynxLifecycleDelegate()
    static func setupBullet() {
        guard let loader = BDXServiceManager.getObjectWith(BDXResourceLoaderProtocol.self, bizID: nil) as? BDXResourceLoaderProtocol else {
            Self.logger.error("bullet init failed, get service failed")
            return
        }

        // setup X Bridge
        BDXBridge.registerEngineClass(BDXBridgeEngineAdapter_TTBridgeUnify.self, inDevelopmentMode: true)
        BDXBridge.registerDefaultGlobalMethods(filter: nil)
        // setup loader
        var accessKey = AccessKey
        if EnvManager.env.isStaging {
            accessKey = DebugAccessKey
        }

        loader.getAdvancedOperator?()
            .registeAccessKey(
                accessKey,
                withPrefixList: ["lark/feoffline/lynx", "wallet/lynx/bullet"]
            )
        let loaderConfig = BDXResourceLoaderConfig()
        loaderConfig.accessKey = accessKey
        loader.update(loaderConfig)
        IESGurdKit.syncResources(withAccessKey: accessKey,
                                 channels: ["wallet_portal_lynx", "caijing_lynx_lark_wallet"],
                                 resourceVersion: nil) { (_, _) in
        }
        // setup bridge
        setupBulletBridgeService()
    }

    static func setupBulletBridgeService() {
        BDXBridgeServiceManager.shared.bindProtocl(BDXBridgeInfoServiceProtocol.self, to: InfoServiceBridgeService.self)
        BDXBridgeServiceManager.shared.bindProtocl(BDXBridgeRouteServiceProtocol.self, to: RouterServiceBridgeService.self)
        BDXBridgeServiceManager.shared.bindProtocl(BDXBridgeLogServiceProtocol.self, to: LogServiceBridgeService.self)
        BDXBridgeServiceManager.shared.bindProtocl(BDXBridgeUIServiceProtocol.self, to: UIServiceBridgeService.self)
    }

    static func routerHander(userResolver: UserResolver, req: EENavigator.Request, res: EENavigator.Response) throws {
        let service = try userResolver.resolve(assert: PayManagerService.self)
        res.wait()
        service.cjpayInitIfNeeded { error in
            if let error = error {
                Self.logger.error("setup cjpay failed with error \(error)")
                res.end(resource: nil)
            } else {
                guard let service = BDXServiceManager.getObjectWith(BDXRouterProtocol.self, bizID: nil) as? BDXRouterProtocol else {
                    res.end(resource: nil)
                    return
                }
                let context = BDXContext()
                context.registerStrongObj([], forKey: kBDXContextKeyCustomUIElements)
                @InjectedUnsafeLazy var deviceService: DeviceService // Global
                context.registerStrongObj(
                    ["deviceId": deviceService.deviceId],
                    forKey: kBDXContextKeyGlobalProps
                )
                if let controller = service.container(withUrl: req.url.absoluteString, context: context, autoPush: false) as? UIViewController {
                    if let container = controller as? BDXContainerProtocol {
                        container.containerLifecycleDelegate = self.lynxLifecycleDelegate
                    }
                    IESGurdKit.activeAllInternalPackages(withBundleName: "CJPay") { [weak res] success in
                        Self.logger.error("gurd source sync " + "\(success)")
                        guard let response = res else { return }
                        response.end(resource: controller)
                    }
                } else {
                    res.end(resource: nil)
                }
            }
        }
    }

    static func setupBulletRouter(container: Container) -> Router {
        return Navigator.shared.registerRoute.regex(lynxRegExpPattern).priority(.high)
        .handle(compatibleMode: { FinanceSetting.userScopeCompatibleMode }, self.routerHander)
    }
}

final class LynxLifecycleDelegate: NSObject, BDXContainerLifecycleProtocol {
    func containerDidStartLoading(_ container: BDXContainerProtocol) {
        if let lynxView = container.kitView.rawView as? LynxView {
            let theme = LynxTheme()
            var themeMode = "light"
            if #available(iOS 12.0, *) {
                if lynxView.traitCollection.userInterfaceStyle == .dark {
                    themeMode = "dark"
                }
            }
            theme.updateValue(LanguageManager.tableName, forKey: "language")
            theme.updateValue(themeMode, forKey: "mode")
            lynxView.setTheme(theme)
        }
    }
}

final class InfoServiceBridgeService: NSObject, BDXBridgeInfoServiceProtocol {
    func channel() -> String? {
        return nil
    }

    func language() -> String? {
        return LanguageManager.tableName
    }

    func appTheme() -> String? {
        if #available(iOS 13.0, *) {
            if UDThemeManager.getRealUserInterfaceStyle() == .light {
                return "day"
            } else {
                return "night"
            }
        } else {
            return "day"
        }
    }

    func isTeenMode() -> Bool {
        return false
    }

    func setting(forKeyPath keyPath: String) -> Any? {
        return nil
    }
}

final class RouterServiceBridgeService: NSObject, BDXBridgeRouteServiceProtocol {
    static let logger = Logger.log(RouterServiceBridgeService.self, category: "finance.pay.manager")

    func openSchema(with paramModel: BDXBridgeOpenMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        guard let view = paramModel.bridgeContext[BDXBridgeContextContainerKey] as? UIView,
              let window = view.window else {
            assertionFailure()
            Self.logger.error("bridge context not contain view")
            completionHandler(nil, BDXBridgeStatus(statusCode: .failed))
            return
        }

        guard let url = URL(string: paramModel.schema) else {
            Self.logger.error("url is invaild")
            completionHandler(nil, BDXBridgeStatus(statusCode: .failed))
            return
        }
        let isPresent = url.queryParameters["isPresent"] ?? "false"
        Self.logger.info("open scheme isPresent: \(isPresent)")
        if url.host?.contains("popup") ?? false {
            //popup使用bullet容器自身路由能力
            Self.logger.info("use bdx route")
            guard let service = BDXServiceManager.getObjectWith(BDXRouterProtocol.self, bizID: nil) as? BDXRouterProtocol else {
                return
            }
            let context = BDXContext()
            context.registerStrongObj([], forKey: kBDXContextKeyCustomUIElements)
            @InjectedUnsafeLazy var deviceService: DeviceService // Global
            context.registerStrongObj(
                ["deviceId": deviceService.deviceId],
                forKey: kBDXContextKeyGlobalProps
            )
            service.open(withUrl: url.absoluteString, context: context)
        } else {
            if isPresent.boolValue && !Display.pad {
                guard let fromVc = view.parentViewController() else { return }
                Navigator.shared.present(url, from: fromVc, prepare: { (vc) in
                    if vc.parent != nil {
                        vc.removeFromParent()
                    }
                    vc.modalPresentationStyle = .overFullScreen
                })
            } else {
                var naviParams = NaviParams()
                naviParams.forcePush = true
                var context = [String: Any]()
                context = context.merging(naviParams: naviParams)
                Navigator.shared.push(url, context: context, from: window)
            }
        }
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }
}

extension UIView {
    func parentViewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension String {
    var boolValue: Bool {
        switch self.lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return false
        }
    }
}

final class LogServiceBridgeService: NSObject, BDXBridgeLogServiceProtocol {

    static let logger = Logger.log(LogServiceBridgeService.self, category: "finance.pay.manager")

    func reportADLog(with paramModel: BDXBridgeReportADLogMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        Self.logger.info("event: \(paramModel.label) params: \(paramModel.extraParams)", tag: paramModel.tag)
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }

    func reportAppLog(with paramModel: BDXBridgeReportAppLogMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        Tracker.post(TeaEvent(paramModel.eventName, params: paramModel.params))
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }

    func reportMonitorLog(with paramModel: BDXBridgeReportMonitorLogMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {

        var metricDic: [String: Any] = [:]
        let logType = paramModel.logType
        let service = paramModel.service
        let number = paramModel.status
        metricDic["value"] = number
        let value = paramModel.value

        if logType == "service_monitor" {
            Tracker.post(SlardarEvent(name: service, metric: metricDic, category: [:], extra: value))
        } else {
            Tracker.post(SlardarCustomEvent(name: logType, params: value))
        }
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }
}

final class UIServiceBridgeService: NSObject, BDXBridgeUIServiceProtocol {

    static let logger = Logger.log(UIServiceBridgeService.self, category: "finance.pay.manager")

    var hud: UDToast?

    func showLoading(inContainer container: BDXBridgeContainerProtocol, withParamModel paramModel: BDXBridgeModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        guard let view = paramModel.bridgeContext[BDXBridgeContextContainerKey] as? UIView,
              let window = view.window else {
            assertionFailure()
            Self.logger.error("bridge context not contain view")
            completionHandler(nil, BDXBridgeStatus(statusCode: .failed))
            return
        }
        self.hud?.remove()
        self.hud = UDToast.showLoading(on: window)
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }

    func hideLoading(inContainer container: BDXBridgeContainerProtocol, withParamModel paramModel: BDXBridgeModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        self.hud?.remove()
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }

    func showModal(with paramModel: BDXBridgeShowModalMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        guard let view = paramModel.bridgeContext[BDXBridgeContextContainerKey] as? UIView,
              let window = view.window else {
            assertionFailure()
            Self.logger.error("bridge context not contain view")
            completionHandler(nil, BDXBridgeStatus(statusCode: .failed))
            return
        }

        let alertVC = UDDialog()
        alertVC.setTitle(text: paramModel.title)
        alertVC.setContent(text: paramModel.content)
        if paramModel.showCancel {
            alertVC.addSecondaryButton(text: paramModel.cancelText)
        }
        alertVC.addPrimaryButton(text: paramModel.confirmText)
        Navigator.shared.present(alertVC, from: window)
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }

    func showToast(with paramModel: BDXBridgeShowToastMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        guard let view = paramModel.bridgeContext[BDXBridgeContextContainerKey] as? UIView,
              let window = view.window else {
            assertionFailure()
            Self.logger.error("bridge context not contain view")
            completionHandler(nil, BDXBridgeStatus(statusCode: .failed))
            return
        }
        switch paramModel.type {
        case .success:
            UDToast.showSuccess(with: paramModel.message, on: window)
        case .error:
            UDToast.showFailure(with: paramModel.message, on: window)
        default:
            UDToast.showTips(with: paramModel.message, on: window)
        }
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }

    func showActionSheet(with paramModel: BDXBridgeShowActionSheetMethodParamModel, completionHandler: @escaping BDXBridgeMethodCompletionHandler) {
        guard let view = paramModel.bridgeContext[BDXBridgeContextContainerKey] as? UIView,
              let window = view.window else {
            assertionFailure()
            Self.logger.error("bridge context not contain view")
            completionHandler(nil, BDXBridgeStatus(statusCode: .failed))
            return
        }
        let actionsheet = UDActionSheet(config: .init())
        actionsheet.setTitle(paramModel.title)
        paramModel.actions.forEach { action in
            actionsheet.addDefaultItem(text: action.title, action: nil)
        }
        Navigator.shared.present(actionsheet, from: window)
        completionHandler(nil, BDXBridgeStatus(statusCode: .succeeded))
    }
}
#endif
