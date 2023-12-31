//
//  LarkLiveSetupTask.swift
//  LarkLive
//
//  Created by yangyao on 2021/6/10.
//

import Foundation
import BootManager
import LarkLive
import Swinject
import LarkRustClient
import LarkFeatureGating
import LarkReleaseConfig

class LarkLiveSetupTask: FlowBootTask, Identifiable {
    static var identify: TaskIdentify {
        "LarkLiveSetupTask"
    }

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    override var scope: Set<BizScope> {
        [.vc]
    }

    override var runOnlyOnce: Bool {
        false
    }
    
    override func execute(_ context: BootContext) {
        HttpClient.setup(rustService: resolver.resolve(RustService.self)!)
        LiveSettingManager.shared.setupSettingService()
    }
}
