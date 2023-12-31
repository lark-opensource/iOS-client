//
//  MeegoSettingManager.swift
//  LarkMeego
//
//  Created by mzn on 2022/8/22.
//

import Foundation
import RxSwift
import LarkContainer
import LarkSetting
import LarkMeegoLogger

/// Meego Setting 管理类
public class MeegoSettingManager {
    private let disposeBag = DisposeBag()

    public static let shared = MeegoSettingManager()

    private init() {}

    public func getLarkSettings(with keys: [String]) -> [String: Any] {
        var settings: [String: Any] = [:]
        keys.forEach({ key in
            if let settingService = try? Container.shared.getCurrentUserResolver().resolve(type: SettingService.self),
               let value = try? settingService.setting(with: key) {
                settings[key] = value
            }
        })
        MeegoLogger.info("getLarkSettings settings: \(settings)")
        return settings
    }
}
