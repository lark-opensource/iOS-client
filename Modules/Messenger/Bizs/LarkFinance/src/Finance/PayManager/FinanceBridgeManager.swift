//
//  FinanceBridgeManager.swift
//  LarkFinance
//
//  Created by ByteDance on 2023/10/13.
//

import Foundation
import UIKit
import TTBridgeUnify
import RxSwift

public final class FinanceAuthBridge: TTBridgePlugin {
    let disposeBag = DisposeBag()

    @objc
    func openAuth(withParam params: [AnyHashable: Any],
                  callback: TTBridgeCallback?,
                  engine _: TTBridgeEngine,
                  controller fromVc: UIViewController) {
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { _ in
                //前端只会接受一次回调，如果授权code回调已经成功，此回调会被前端丢弃，不会导致重复回调
                FinanceOpenSDKManager.logger.info("openAuth become active")
                let authInfo: [String: Any] = [
                    "errMsg": "becomeActive"
                ]
                callback?(TTBridgeMsg.failed, authInfo, nil)
            }).disposed(by: disposeBag)
        FinanceOpenSDKManager.sendDouyinOpenAuth(fromVc: fromVc) { authCode in
            FinanceOpenSDKManager.logger.info("openAuth authCode:\(String(describing: authCode))")
            guard let code = authCode else {
                callback?(TTBridgeMsg.failed, [:], nil)
                return
            }
            let authInfo: [String: Any] = [
                        "authCode": code,
                        "clientKey": FinanceOpenSDKManager.douyinOpenAppId
                    ]
            callback?(TTBridgeMsg.success, authInfo, nil)
        }
    }

    public override class func instanceType() -> TTBridgeInstanceType {
        return TTBridgeInstanceType.associated
    }

    public static func registerBridge() {
        TTRegisterAllBridge("\(NSStringFromClass(FinanceAuthBridge.classForCoder())).openAuth", "ttcjpay.openAuth")
    }
}
