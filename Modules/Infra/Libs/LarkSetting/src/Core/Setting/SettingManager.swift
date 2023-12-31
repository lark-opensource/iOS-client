//
//  SettingManager.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/3.
//

import Foundation
import LarkCombine
import LKCommonsLogging
import RxSwift
import ThreadSafeDataStructure
import EEAtomic
import LarkAccountInterface

/// Setting管理类，单例，提供Setting获取接口
public final class SettingManager { private init() {} }

/// 通用对外接口
public extension SettingManager {
    /// shared
    static let shared = SettingManager()

    /// 当前用户id
    static var currentChatterID: (() -> String) = { AccountServiceAdapter.shared.currentChatterId } // foregroundUser
}

extension SettingManager: SettingService { public var id: String { Self.currentChatterID() } }
