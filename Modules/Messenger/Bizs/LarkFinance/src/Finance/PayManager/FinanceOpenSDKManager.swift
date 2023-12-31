//
//  DouyinOpenSDKManager.swift
//  LarkFinance
//
//  Created by ByteDance on 2023/10/10.
//

import Foundation
import UIKit
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast
import LarkSetting
#if canImport(DouyinOpenPlatformSDK)
import DouyinOpenPlatformSDK
#endif

public final class FinanceOpenSDKManager: FinanceOpenSDKService, UserResolverWrapper {
    static let logger = Logger.log(FinanceOpenSDKManager.self, category: "finance.pay.openSDKManager")
    static let validBundleIDs = ["com.bytedance.ee.lark"] //飞书正式
    public var userResolver: LarkContainer.UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    public func sendDouyinOpenAuth(callback: ((String?) -> Void)?) {
        guard let window = self.userResolver.navigator.mainSceneWindow, let vc = window.rootViewController else {
            return
        }
        FinanceOpenSDKManager.sendDouyinOpenAuth(fromVc: vc, callback: callback)
    }

    public static func sendDouyinOpenAuth(fromVc: UIViewController,
                                          callback: ((String?) -> Void)?) {
        let closeDouyinPayFG = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.redpacket.douyin.pay.close"))
        guard !closeDouyinPayFG else {
            Self.logger.info("douyin open auth failure closeDouyinPayFG:\(closeDouyinPayFG)")
            callback?(nil)
            return
        }
#if canImport(DouyinOpenPlatformSDK)
        let openAuthRequest = DouyinOpenSDKAuthRequest()
        let orderedSet = Self.douyinAuthParams
        openAuthRequest.permissions = orderedSet
        let completeBlock: DouyinOpenSDKAuthCompleteBlock = { response in
            // 在这里处理授权完成的结果
            Self.logger.info("douyin open auth result code:\(String(describing: response?.code)) errorCode:\(String(describing: response?.errCode))")
            guard response?.errCode.rawValue == 0 else {
                DispatchQueue.main.async {
                    UDToast.showFailure(with: response?.errString ?? BundleI18n.LarkFinance.Lark_Legacy_UnknownError, on: fromVc.view)
                }
                callback?(nil)
                return
            }
            callback?(response?.code)
        }
        openAuthRequest.send(fromVc, complete: completeBlock)
#endif
    }

    static var douyinAuthParams: NSOrderedSet {
        return NSOrderedSet(objects: "user_info")
    }

    static var douyinOpenAppId: String {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let isOnAllowed = (Self.validBundleIDs.contains(bundleID))
        Self.logger.info("douyinOpenAppId isOnAllowed:\(isOnAllowed)")
        if isOnAllowed {
            //飞书正式
            return "aw9rks9bctrbc4gj"
        } else {
            //飞书内测
            return "awl9bniytezcqhjv"
        }
    }
}

public protocol FinanceOpenSDKService {
    func sendDouyinOpenAuth(callback: ((String?) -> Void)?)
}
