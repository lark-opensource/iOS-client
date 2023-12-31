//
//  MuteAudioConfig.swift
//  ByteViewSetting
//
//  Created by FakeGourmet on 2023/9/4.
//

import Foundation

public struct MuteAudioConfig: Decodable {
    public let enableRuntimeVersion: String
    public let enableNotiVersion: String
    public let enableSyncVersion: String
    public let enableDialMuteVersion: String

    static let `default` = MuteAudioConfig(enableRuntimeVersion: "99.0", enableNotiVersion: "99.0", enableSyncVersion: "99.0", enableDialMuteVersion: "99.0")

    /// 允许走 runtime
    public var enableRuntime: Bool {
        if #available(iOS 17.0, *) {
            return greater(than: enableRuntimeVersion)
        } else {
            return false
        }
    }

    /// 允许响应通知
    public var enableNotification: Bool {
        if #available(iOS 17.0, *) {
            return greater(than: enableNotiVersion)
        } else {
            return false
        }
    }

    /// 允许同步麦克风状态
    public var enableSyncMuteState: Bool {
        if #available(iOS 17.0, *) {
            return greater(than: enableSyncVersion)
        } else {
            return false
        }
    }

    /// 允许响铃页执行静音逻辑
    public var enableDialMute: Bool {
        if #available(iOS 17.0, *) {
            return greater(than: enableDialMuteVersion)
        } else {
            return false
        }
    }

    private func greater(than version: String) -> Bool {
        let currentVersion = UIDevice.current.systemVersion
        switch currentVersion.compare(version, options: .numeric) {
            //如果当前系统版本号>=下发的版本号，则开启
        case .orderedSame, .orderedDescending:
            return true
        case .orderedAscending:
            return false
        }
    }
}
