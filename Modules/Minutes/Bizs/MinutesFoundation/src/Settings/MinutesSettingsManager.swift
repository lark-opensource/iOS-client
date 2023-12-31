//
//  MinutesSettingsManager.swift
//  MinutesFoundation
//
//  Created by yangyao on 2022/10/10.
//

import Foundation
import LarkSetting
import LarkAccountInterface
import LarkContainer

public final class MinutesSettingsManager {
    @Provider var passportService: PassportService
    public static let shared = MinutesSettingsManager()

    public let FirstFetchCount = 30
    public let MaxFetchCount = 3000
    
    var loadSettings: MinutesLoadSetting? {
        let loadSettings = try? SettingManager.shared.setting(with: MinutesLoadSetting.self)
        return loadSettings
    }
    
    // 是否启用分段加载
    public var isSegRequestEnabled: Bool {
        return loadSettings?.isEnable ?? false
    }
    
    // 首次请求的个数
    public var firstRequestCount: Int {
        return loadSettings?.initialPageCount ?? FirstFetchCount
    }
    
    // 最大请求的个数
    public var maxRequestCount: Int {
        return loadSettings?.pageCount ?? MaxFetchCount
    }

    public var tnsReportDomain: String? {
        DomainSettingManager.shared.currentSetting[.tnsReport]?.first
    }

    public func tnsReportDomain(with minutesURL: URL) -> String? {
        if passportService.isFeishuBrand {
            return DomainSettingManager.shared.currentSetting[.tnsReport]?.first
        } else {
            return DomainSettingManager.shared.currentSetting[.tnsLarkReport]?.first
        }
    }
}
