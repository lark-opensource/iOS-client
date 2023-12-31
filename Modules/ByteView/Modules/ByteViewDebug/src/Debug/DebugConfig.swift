//
//  DebugConfig.swift
//  Action
//
//  Created by huangshun on 2019/4/30.
//

import Foundation
import RxSwift
import LarkEMM
import LarkSensitivityControl
import ByteViewCommon
import ByteViewSetting

public protocol DebugDependency {
    var userId: String { get }
    var setting: UserSettingManager? { get }
    var storage: LocalStorage? { get }
}

class DebugConfig {
    static let shared = DebugConfig()

    var dependency: DebugDependency?

    var userId: String {
        dependency?.userId ?? ""
    }

    var setting: UserSettingManager? {
        dependency?.setting
    }

    lazy var storage = dependency?.storage?.toStorage(Keys.self)

    var autoRotationDuration: TimeInterval {
        get {
            storage?.double(forKey: .autoRotationDuration) ?? 0
        }
        set {
            storage?.set(newValue, forKey: .autoRotationDuration)
        }
    }

    var autoRotationDispose = DisposeBag()

    var meetingWindowEnable: Bool {
        get {
            storage?.bool(forKey: .meetingWindowEnable) ?? false
        }
        set {
            storage?.set(newValue, forKey: .meetingWindowEnable)
        }
    }

    enum Keys: String, LocalStorageKey {
        case autoRotationDuration
        case meetingWindowEnable

        var domain: LocalStorageDomain {
            .child("ByteViewDebug")
        }
    }
}

final class Utils {
    static func setPasteboardString(_ string: String?) {
        SCPasteboard.general(PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))).string = string
    }
}
