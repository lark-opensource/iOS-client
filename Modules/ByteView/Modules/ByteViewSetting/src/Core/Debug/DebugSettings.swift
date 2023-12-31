//
//  DebugSettings.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/11.
//

import Foundation
import ByteViewCommon

public final class DebugSettings {
    public static var multiResolutionConfig: MultiResolutionConfig?
    public static var isPiPEnabled: Bool = false {
        didSet {
            if oldValue != isPiPEnabled {
                listeners.invokeListeners(for: .pip) { $0.didChangeDebugSetting(for: .pip) }
            }
        }
    }

    public static var isPiPSampleBufferRenderEnabled: Bool = false {
        didSet {
            if oldValue != isPiPSampleBufferRenderEnabled {
                listeners.invokeListeners(for: .pipSampleBufferRender) { $0.didChangeDebugSetting(for: .pipSampleBufferRender) }
            }
        }
    }

    public static var isCallKitEnabled = false {
        didSet {
            if oldValue != isCallKitEnabled {
                listeners.invokeListeners(for: .callKit) { $0.didChangeDebugSetting(for: .callKit) }
            }
        }
    }

    public static var isCallKitOutgoingEnabled = false {
        didSet {
            if oldValue != isCallKitOutgoingEnabled {
                listeners.invokeListeners(for: .callKitOutgoing) { $0.didChangeDebugSetting(for: .callKitOutgoing) }
            }
        }
    }

    private static let listeners = HashListeners<DebugSettingKey, DebugSettingListener>()
    static func addListener(_ listener: DebugSettingListener, for keys: Set<DebugSettingKey>) {
        listeners.addListener(listener, for: keys)
    }

    static func removeListener(_ listener: DebugSettingListener) {
        listeners.removeListener(listener)
    }
}

enum DebugSettingKey: String, CustomStringConvertible {
    case pip
    case callKit
    /// 主动入会开启 callkit
    case callKitOutgoing
    /// 画中画 SampleBuffer 渲染
    case pipSampleBufferRender

    var description: String { rawValue }
}

protocol DebugSettingListener: AnyObject {
    func didChangeDebugSetting(for key: DebugSettingKey)
}
