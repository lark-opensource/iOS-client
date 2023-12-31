//
//  URLProtocolApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import LarkRustHTTP
import Swinject
import LarkRustClient
import RustPB
import LarkDebug
import LarkContainer
import HTTProtocol
import Heimdallr
import LarkSetting

final class URLProtocolApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "URLProtocol", daemon: true)

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) {
            URLProtocolIntegration.shared.willEnterForeground($1)
        }
    }
}
final class URLProtocolIntegration {
    static let shared = URLProtocolIntegration()

    func setup() {
        @Provider var rustService: GlobalRustService // Global
        // rusthttp urlprotocol config
        // 使用一个用户无关的全局client来直接往rust发消息
        RustHttpManager.rustService = { rustService }
        // wait TTNet and rust init finish. this task should ok
        rustService.wait {
            RustHttpManager.ready = true
        }

        monitorURLProtocolThread()
    }

    var monitored = false
    func monitorURLProtocolThread() {
        // 使用CCM日志一样的FG控制观察效果
        if !monitored, FeatureGatingManager.shared.featureGatingValue(with: "ccm.common.enable_network_optimize") {
            monitored = true
            BaseHTTProtocol.setupProtocolThreadMonitor(timeout: 5) { (_) in
                let parameters = HMDUserExceptionParameter.initAllThreadParameter(
                    withExceptionType: "URLProtocol-Blocked",
                    customParams: nil, filters: nil)
                HMDUserExceptionTracker.shared().trackThreadLog(with: parameters)
            }
        }
    }

    func willEnterForeground(_ message: WillEnterForeground) {
        monitorURLProtocolThread()
    }
}
