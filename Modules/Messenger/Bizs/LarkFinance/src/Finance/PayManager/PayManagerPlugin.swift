//
//  PayManagerTrackerProxy.swift
//  LarkFinance
//
//  Created by 李晨 on 2019/3/6.
//
import UIKit
#if canImport(CJPay)
import Foundation
import EENavigator
import LKCommonsLogging
import LarkContainer
import CJPay
import LarkBytedCert
import BDXServiceCenter
import BDXLynxKit
import BDXBridgeKit
import LarkAccountInterface

final class PayManagerTrackerProxy: NSObject, CJPayManagerBizDelegate {
    func event(_ event: String, params: [AnyHashable: Any]?) {
        if let params = params as? [String: Any] {
            FinanceTracker.track(event, params: params)
        } else {
            assertionFailure()
            FinanceTracker.track(event, params: [:])
        }
    }
}

final class PayManagerBizWebImpl: NSObject, CJBizWebDelegate {

    static let logger = Logger.log(PayManagerBizWebImpl.self, category: "finance.pay.manager")

    var userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
    }
    func needLogin(_ callback: ((CJBizWebCode) -> Void)? = nil) {
        callback?(.loginSuccess)
    }

    func openCJScheme(_ scheme: String, fromVC controller: UIViewController?, useModal: Bool) {
        Self.logger.error("open cj scheme \(scheme) useModal \(useModal)")
        guard let url = URL(string: scheme) else {
            Self.logger.error("open cj scheme failed \(scheme)")
            return
        }
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
            Self.logger.info("use parasitifer route")
            var fromVc: UIViewController?
            if let fromController = controller {
                fromVc = fromController
            } else if let topVc = userResolver.navigator.mainSceneWindow?.fromViewController {
                fromVc = topVc
            }
            guard let viewController = fromVc else {
                Self.logger.error("vc is nil \(fromVc == nil) \(controller == nil)")
                return
            }
            if useModal {
                let topMostFrom = WindowTopMostFrom(vc: viewController)
                userResolver.navigator.present(url, from: topMostFrom, prepare: { vc in
                    if vc.parent != nil {
                        vc.removeFromParent()
                    }
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        vc.modalPresentationStyle = .fullScreen
                    } else if UIDevice.current.userInterfaceIdiom == .pad {
                        vc.modalPresentationStyle = .formSheet
                    }
                })
            } else {
                let topMostFrom = WindowTopMostFrom(vc: viewController)
                let naviParams = NaviParams()
                var context = [String: Any]()
                context = context.merging(naviParams: naviParams)
                userResolver.navigator.push(url, context: context, from: topMostFrom)
            }
        }
    }
}

final class PayManagerFaceLiveness: NSObject, CJPayFaceLivenessProtocol {

    static let logger = Logger.log(PayManagerFaceLiveness.self, category: "finance.pay.manager")

    func doFaceLiveness(with params: [AnyHashable: Any], extraParams: [AnyHashable: Any], callback: @escaping CJPayFaceLivenessCallBack) {
        PayManagerFaceLiveness.logger.info("start face liveness")
        LarkBytedCert().doFaceLiveness(with: params, extraParams: extraParams) { (result, error) in
            if let error = error {
                PayManagerFaceLiveness.logger.info("face liveness failed error \(error)")
            } else {
                PayManagerFaceLiveness.logger.error("face liveness success")
            }
            callback(result, error)
        }
    }
}

#endif
