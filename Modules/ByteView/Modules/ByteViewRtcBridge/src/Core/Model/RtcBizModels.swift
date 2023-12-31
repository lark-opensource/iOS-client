//
//  RtcBizModels.swift
//  ByteView
//
//  Created by kiri on 2022/8/19.
//

import Foundation
import ByteViewCommon

public struct RtcAudioScene: RawRepresentable, Hashable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { "RtcAudioScene(\(rawValue))" }
}

public struct RtcCameraScene: RawRepresentable, Hashable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// 有rtc流的scene，目前只有inMeet
    @RwAtomic private static var streamScenes: Set<RtcCameraScene> = [.inMeet]
    public static func addStreamScene(_ scene: RtcCameraScene) {
        streamScenes.insert(scene)
    }

    /// 是否有rtc流，目前只有inMeet有
    public var hasStream: Bool {
        RtcCameraScene.streamScenes.contains(self)
    }

    public var description: String { "RtcCameraScene(\(rawValue))" }
}

public extension RtcCameraScene {
    static let preview = RtcCameraScene(rawValue: "preview")
    static let inMeet = RtcCameraScene(rawValue: "inMeet")
}

public enum RtcCameraInterruptionReason {
    case unknown
    case notAvailableInBackground
    case videoInUseByAnotherClient
    case notAvailableWithMultipleForegroundApps
    case notAvailableDueToSystemPressure
}

public enum RtcCameraEffectType {
    case virtualbg     // 虚拟背景
    case animoji       // Animoji
    case filter        // 滤镜
    case retuschieren  // 新美颜

    var effectStatus: RtcCameraEffectStatus {
        switch self {
        case .virtualbg:
            return .virtualbg
        case .animoji:
            return .animoji
        case .filter:
            return .filter
        case .retuschieren:
            return .retuschieren
        }
    }
}

public struct RtcCameraEffectStatus: OptionSet {
    public let rawValue: Int8
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
}

public extension RtcCameraEffectStatus {
    static let none = RtcCameraEffectStatus([])
    static let virtualbg = RtcCameraEffectStatus(rawValue: 1 << 0)
    static let animoji = RtcCameraEffectStatus(rawValue: 1 << 1)
    static let filter = RtcCameraEffectStatus(rawValue: 1 << 2)
    static let retuschieren = RtcCameraEffectStatus(rawValue: 1 << 3)

    static let filterAndRetuschieren: RtcCameraEffectStatus = [.filter, .retuschieren]
}
