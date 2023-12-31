//
//  UpdateFrequencyManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/9.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkContainer
import LarkPolicyEngine

final class UpdateFrequencyManager: UserResolverWrapper {
    @ScopedProvider var settings: Settings?

    private lazy var timeInterval: Int = {
        guard let timeInterval = settings?.fileStrategyUpdateFrequencyControl else { return 2 }
        return timeInterval
    }()
    var timer: Timer?
    var isFullUpdate: Bool = false {
        didSet {
            SPLogger.debug("security policy: update frequency manager: is full updata is set to \(isFullUpdate)")
        }
    }
    var callback: ((_ isFullUpdate: Bool,
                    _ trigger: StrategyEngineCallTrigger,
                    _ complete: (([ValidateResponse]) -> Void)?) -> Void)?

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    deinit {
        timer?.invalidate()
    }

    func call(trigger: SecurityPolicyUpdateTrigger, isFullUpdate: Bool) {
        if isFullUpdate { self.isFullUpdate = isFullUpdate }
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.timeInterval), repeats: false) { [weak self] _ in
            guard let self else { return }
            self.callback?(self.isFullUpdate, trigger.callTrigger, nil)
            self.isFullUpdate = false
            self.timer?.invalidate()
        }
    }
}
