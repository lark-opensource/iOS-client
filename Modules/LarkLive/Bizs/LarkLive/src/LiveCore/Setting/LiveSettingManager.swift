//
//  LiveSettingManager.swift
//  ByteView
//
//  Created by panzaofeng on 2021/11/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class LiveSettingManager {

    private let logger = Logger.live

    private let settingService = LiveSettingService()

    public static let shared = LiveSettingManager()

    public init() {
    }

    public func setupSettingService() {
        settingService.setup()
    }

    public func verifyURL(url: URL?) -> Bool {
        return settingService.verifyURL(url: url)
    }
    
    public func isFeishuHost(url: URL?) -> Bool {
        return settingService.isFeishuHost(url: url)
    }
}
