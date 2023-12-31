//
//  FinanceLaunchTask.swift
//  LarkFinance
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import UIKit
import BootManager
import LarkContainer
import LKCommonsLogging
import LarkEnv
import LarkPrivacySetting

#if canImport(DouyinOpenPlatformSDK)
import DouyinOpenPlatformSDK
#endif

#if canImport(DouyinOpenPlatformSDK)
final class FinanceLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "FinanceLaunchTask"
    static let logger = Logger.log(FinanceLaunchTask.self, category: "finance.pay.launchTask")
    var logService: FinanceLaunchLogService?

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 获取权限SDK支付开关，默认打开，无权限则不拉取token
        let isPay = LarkPayAuthority.checkPayAuthority()
        let closeDouyinPayFG = userResolver.fg.dynamicFeatureGatingValue(with: "lark.redpacket.douyin.pay.close")
        Self.logger.info("DouyinOpenSDK isPay: \(isPay) closeDouyinPayFG:\(closeDouyinPayFG)")
        guard isPay, !closeDouyinPayFG else {
            Self.logger.info("DouyinOpenSDK not register")
            return
        }
        if logService == nil {
            logService = try? self.userResolver.resolve(assert: FinanceLaunchLogService.self)
            logService?.registerLogDelegate()
        }
        FinanceAuthBridge.registerBridge()
        // 初始化Launch相关关服务
        let result = DouyinOpenSDKApplicationDelegate.sharedInstance().registerAppId(FinanceOpenSDKManager.douyinOpenAppId)
        Self.logger.info("DouyinOpenSDK registerAppId result:\(result)")
        DouyinOpenSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions: context.globelContext.launchOptions)
    }
}
#endif

#if canImport(DouyinOpenPlatformSDK)
protocol FinanceLaunchLogService {
    func registerLogDelegate()
}

final class FinanceLaunchLogImpl: NSObject, UserResolverWrapper, FinanceLaunchLogService {
    static let logger = Logger.log(FinanceLaunchLogImpl.self, category: "finance.pay.launchlog")
    var userResolver: LarkContainer.UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    func registerLogDelegate() {
        DouyinOpenSDKApplicationDelegate.sharedInstance().logDelegate = self
    }
}

extension FinanceLaunchLogImpl: DouyinOpenSDKLogDelegate {
    func onLog(_ logInfo: String) {
        Self.logger.info("DouyinOpenSDK onLog :\(logInfo)")
    }
}
#endif
