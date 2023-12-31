//
//  ABTestLaunchDelegate.swift
//  LarkApp
//
//  Created by shizhengyu on 2019/11/20.
//

import Foundation
import LarkAccountInterface
import Swinject
import LKCommonsTracker
import LKCommonsLogging
import TTNetworkManager
import RxSwift
import LarkSetting
import LarkContainer

public final class ABTestLaunchDelegate: LauncherDelegate, PassportDelegate {
    private static let logger = Logger.log(ABTestLaunchDelegate.self, category: "ABTestLaunch")

    public let name = "ABTestLaunch"

    private let resolver: Resolver

    public init(resolver: Resolver) { self.resolver = resolver }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        guard error == nil else { return .just(()) }
        DispatchQueue.global().async { self.fetchAndSaveExperimentData() }
        return .just(())
    }
    public func userDidOnline(state: PassportState) {
        if state.action == .switch {
            DispatchQueue.global().async { self.fetchAndSaveExperimentData() }
        }
    }

    func updateABTestExperimentData() { DispatchQueue.global().async { self.fetchAndSaveExperimentData() } }

    @Provider var passport: PassportService // Global
    private func fetchAndSaveExperimentData() {
        guard FeatureGatingManager.shared.featureGatingValue(with: "tt_ab_test"),
              let abtestDomain = DomainSettingManager.shared.currentSetting[.ttAbtest]?.first else { return }

        guard let userId = passport.foregroundUser?.userID else { return }
        // TODO: 用户隔离: 这里只是保存，依赖二方库，保存时没有区分UID，无法隔离

        // Fetch abtest experiment data, internally do storage automatically
        Tracker.fetchAndSaveExperimentData(url: "https://\(abtestDomain)/common/?uid=\(userId)") { (error, data) in
            DispatchQueue.global().async { self.afterReciveData(error: error, data: data) }
        }
    }

    private func afterReciveData(error: Error?, data: [AnyHashable: Any]?) {
        /// Only for logging
        error == nil ? Self.logger.info("Receive A/B test experiment data: \(String(describing: data))") : {
            guard let err = error else { return }
            Self.logger.info(err.localizedDescription)
        }()
        // 发出'当前用户实验数据获取成功'通知，此通知发出后获取某个key实验数据才准确，否则是cache或者默认值
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: Tracker.LKExperimentDataDidFetch),
            object: nil,
            userInfo: nil)
    }
}
