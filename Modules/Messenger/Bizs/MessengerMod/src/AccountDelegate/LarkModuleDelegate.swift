//
//  LarkModuleDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/11/27.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkModel
import LarkMine
import RxSwift
import LarkCore
import EENavigator
import Kingfisher
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import RunloopTools
import LarkKeyboardKit
import LarkMessengerInterface
import LarkGuide
import LarkFoundation
import LarkLocalizations
import LKCommonsLogging

public final class LarkModulePassportDelegate: PassportDelegate {
    public let name: String = "LarkModule"

    private let container: Container

    private var disposeBag = DisposeBag()
    static let log = Logger.log(LarkModuleDelegate.self, category: "AccountDelegate.LarkModuleDelegate")

    public init(container: Container) {
        self.container = container
    }

    public func userDidOnline(state: PassportState) {
        if state.action == .switch {
            Navigator.shared.clearHandlerCache() // foregroundUser
            guard let id = state.user?.userID else { return }
            let userResolver = try? container.getUserResolver(userID: id)
            let newGuideService = try? userResolver?.resolve(assert: NewGuideService.self)
            newGuideService?.fetchUserGuideInfos(finish: nil)
            Self.log.info("[LarkGuide]: fetchUserGuideInfos afterSwitchAccout")
        }
    }

    public func userDidOffline(state: PassportState) {
        Navigator.shared.clearHandlerCache() // foregroundUser
    }
}

public final class LarkModuleDelegate: LauncherDelegate {
    public let name: String = "LarkModule"

    private let resolver: Resolver

    private var disposeBag = DisposeBag()
    static let log = Logger.log(LarkModuleDelegate.self, category: "AccountDelegate.LarkModuleDelegate")

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func afterLogout(_ context: LauncherContext) {
        Navigator.shared.clearHandlerCache() // foregroundUser
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        Navigator.shared.clearHandlerCache() // foregroundUser
        let newGuideManager = self.resolver.resolve(NewGuideService.self)! // foregroundUser
        newGuideManager.fetchUserGuideInfos(finish: nil)
        Self.log.info("[LarkGuide]: fetchUserGuideInfos afterSwitchAccout")
        return .just(())
    }
}
