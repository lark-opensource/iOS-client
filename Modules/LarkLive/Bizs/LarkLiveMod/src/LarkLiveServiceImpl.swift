//
//  LarkLiveServiceImpl.swift
//  ByteView
//
//  Created by Ruyue Hong on 2021/1/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import RxSwift
import RxRelay
import RustPB
import EENavigator
import LarkLiveInterface
import LarkLive
import LarkFeatureGating
import LKCommonsLogging

class LarkLiveServiceImpl: LarkLiveService {
    static let logger = LKCommonsLogging.Logger.log(LarkLiveServiceImpl.self, category: "LarkLive")
    
    /// 初始化方法
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func setupLive(url: URL?) {
        if let domain = url?.host {
            let urlString = "https://\(domain)"
            let defaultAPI = self.resolver.resolve(LiveAPI.self, argument: urlString)!
            LiveAPI.setup(defaultAPI)
        }
    }

    public func startLive(url: URL?, context: [String:Any]?) {
        guard let url = url else {
            return
        }
        Self.logger.info("go web")
        LarkLiveManager.shared.setup(resolver: resolver)
        LarkLiveManager.shared.startLive(url: url, fromLink: true)
    }

    public func isLiveURL(url: URL?) -> Bool {
        return LiveSettingManager.shared.verifyURL(url: url)
    }

    func isLiving() -> Bool {
        return LarkLiveManager.shared.isLiveInFloatView
    }

    func startVoip() {
        LarkLiveManager.shared.stopAndCleanLive()
    }

    /// 直播小窗冲突埋点
    func trackFloatWindow(isConfirm: Bool){

    }
}
