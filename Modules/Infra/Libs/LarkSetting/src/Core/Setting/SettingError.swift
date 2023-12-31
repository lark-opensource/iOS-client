//
//  SettingError.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/7/29.
//

/// setting error
import Foundation
public enum SettingError: Error {
    case localSettingDefaultDataNotFound
    case parseLocalSettingDataFailed
    case settingKeyNotFound
    case wrappedError(_ error: Error)

    static func error(with error: Error) -> SettingError { (error as? SettingError) ?? .wrappedError(error) }
}
