//
//  AppLockSettingBody.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/9.

import Foundation
import EENavigator

public struct AppLockSettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/AppLockSetting"
    public static let appLinkPattern = "/client/applock/setting"

    public init() {}
}
