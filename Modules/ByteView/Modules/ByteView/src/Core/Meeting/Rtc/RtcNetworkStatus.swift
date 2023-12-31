//
//  RtcNetworkStatus.swift
//  ByteView
//
//  Created by kiri on 2022/10/12.
//

import Foundation
import UniverseDesignIcon
import ByteViewRtcBridge

struct RtcNetworkStatus: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    // 网络类型
    var networkType: RtcNetworkType = .begin {
        didSet {
            guard networkType != oldValue else { return }
            if networkType == .disconnected || !isIceDisconnected {
                updateShowStatus()
            }
            if networkType == .disconnected {
                clearQualityWith(networkQuality)
            }
        }
    }

    // ice连接情况
    var isIceDisconnected: Bool = false {
        didSet {
            guard isIceDisconnected != oldValue else { return }
            updateShowStatus()
            if isIceDisconnected {
                clearQualityWith(networkQuality)
            }
        }
    }

    // 网络质量
    var networkQuality: RtcNetworkQuality = .good {
        didSet {
            guard networkQuality != oldValue else { return }
            updateShowStatus()
        }
    }

    // 本地展示的网络状态
    private(set) var networkShowStatus: NetworkShowStatus = .connected
    private(set) var isRemote: Bool
    private(set) var lastChangeTime: TimeInterval = Date().timeIntervalSince1970

    var networkQualityInfo: RtcNetworkQualityInfo?

    var description: String {
        return "RtcNetworkStatus networkShowStatus: \(networkShowStatus), networkType: \(networkType), isIceDisconnected: \(isIceDisconnected), networkQuality: \(networkQuality)"
    }

    var debugDescription: String {
        return description + " lastNetworkQuality: \(lastNetworkQuality), detectCount: \(detectCount), direction: \(direction), info: \(networkQualityInfo?.description)"
    }

    fileprivate enum DetectDirection {
        case none
        case up
        case down
    }

    enum NetworkShowStatus: Hashable {
        case connected
        case disconnected
        case iceDisconnected
        case bad
        case weak
    }

    // 上次检测网络状态
    private var lastNetworkQuality: RtcNetworkQuality = .good
    // 检测次数
    private var detectCount: Int = 0
    // 网络变化方向
    private var direction: DetectDirection = .none

    private let isWeakNetworkEnabled: Bool

    init(isRemote: Bool = true, networkType: RtcNetworkType = .unknown,
         isWeakNetworkEnabled: Bool) {
        self.isRemote = isRemote
        self.networkType = networkType
        self.isWeakNetworkEnabled = isWeakNetworkEnabled
    }

    static func == (lhs: RtcNetworkStatus, rhs: RtcNetworkStatus) -> Bool {
        return lhs.isIceDisconnected == rhs.isIceDisconnected &&
        lhs.networkType == rhs.networkType &&
        lhs.networkQuality == rhs.networkQuality &&
        lhs.networkShowStatus == rhs.networkShowStatus
    }

    private mutating func updateShowStatus() {
        if self.networkType == .disconnected {
            networkShowStatus = .disconnected
        } else if self.isIceDisconnected {
            networkShowStatus = .iceDisconnected
        } else {
            switch self.networkQuality {
            case .bad:
                networkShowStatus = .bad
            case .weak:
                networkShowStatus = .weak
            default:
                networkShowStatus = .connected
            }
        }
    }
}

extension RtcNetworkStatus {
    func toastInfo() -> (String?, Bool) {
        if isRemote {
            switch networkShowStatus {
            case .iceDisconnected:
                return (I18n.View_G_OtherNetUnstable_Toast, true)
            case .bad:
                return (I18n.View_G_OtherConnectPoor_Toast, isWeakNetworkEnabled)
            default:
                return (nil, false)
            }
        } else {
            switch networkShowStatus {
            case .bad:
                return (I18n.View_G_ConnectionPoor_Toast, isWeakNetworkEnabled)
            default:
                return (nil, false)
            }
        }
    }

    func networkIcon(is1V1: Bool = false) -> (UIImage?, Bool) {
        if isRemote {
            switch networkShowStatus {
            case .connected, .disconnected:
                return (nil, false)
            case .iceDisconnected:
                return (Self.badImg, true)
            case .bad:
                return (Self.badImg, isWeakNetworkEnabled && is1V1)
            case .weak:
                return (Self.weakImg, isWeakNetworkEnabled && is1V1)
            }
        } else {
            switch networkShowStatus {
            case .connected:
                return (nil, false)
            case .disconnected:
                return (Self.disconnectedImg, true)
            case .iceDisconnected:
                return (Self.badImg, true)
            case .bad:
                return (Self.badImg, isWeakNetworkEnabled)
            case .weak:
                return (Self.weakImg, isWeakNetworkEnabled)
            }
        }
    }

    static let disconnectedImg = UDIcon.getIconByKey(.signal0Colorful, size: CGSize(width: 14, height: 14))
    static let badImg = UDIcon.getIconByKey(.signal1Colorful, size: CGSize(width: 14, height: 14))
    static let weakImg = UDIcon.getIconByKey(.signal2Colorful, size: CGSize(width: 14, height: 14))
}

extension RtcNetworkStatus {
    mutating func updateWith(qualityInfo: RtcNetworkQualityInfo, detectCountConfig: MeetingWeakNetworkDetect) -> Bool {
        if _updateWith(quality: qualityInfo.networkQuality, detectCountConfig: detectCountConfig) {
            self.networkQualityInfo = qualityInfo
            self.lastChangeTime = Date().timeIntervalSince1970
            return true
        }
        return false
    }

    private mutating func _updateWith(quality: RtcNetworkQuality, detectCountConfig: MeetingWeakNetworkDetect) -> Bool {
        //        if quality == .unknown || networkType == .disconnected || isIceDisconnected {
        //            clearQualityWith(networkQuality)
        //            return false
        //        }
        if quality != lastNetworkQuality || quality == networkQuality {
            // 如果不等于上次检测状态，或者等于当前显示状态，清空检测
            clearQualityWith(quality)
        } else {
            if direction == .none { return false }
            detectCount += 1
        }

        if direction == .up {
            if detectCount >= detectCountConfig.upgradeDetectCount {
                changeQualityWith(quality)
                return true
            }
        } else if direction == .down {
            if detectCount >= detectCountConfig.downgradeDetectCount {
                changeQualityWith(quality)
                return true
            }
        }
        return false
    }

    private mutating func clearQualityWith(_ quality: RtcNetworkQuality) {
        let direction = self.networkQuality.directionWithQuality(quality)
        self.lastNetworkQuality = quality
        self.detectCount = direction == .none ? 0 : 1
        self.direction = direction
    }

    private mutating func changeQualityWith(_ quality: RtcNetworkQuality) {
        self.networkQuality = quality
        self.lastNetworkQuality = quality
        self.detectCount = 0
        self.direction = .none
    }
}

private extension RtcNetworkQuality {
    func directionWithQuality(_ quality: RtcNetworkQuality) -> RtcNetworkStatus.DetectDirection {
        if quality == self {
            return .none
        } else if quality > self {
            return .down
        } else {
            return .up
        }
    }
}
