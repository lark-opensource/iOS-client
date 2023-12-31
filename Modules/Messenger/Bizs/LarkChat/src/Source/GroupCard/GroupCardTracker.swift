//
//  GroupCardTracker.swift
//  LarkChat
//
//  Created by qihongye on 2020/10/14.
//

import UIKit
import Foundation
import AppReciableSDK

struct GroupCardTracker {
    enum ProfileType: Int {
        case group = 1
    }

    struct TrackInfo {
        var sdkLocalCost: CFTimeInterval = 0
        var sdkNetCost: CFTimeInterval = 0
        var firstRenderCost: CFTimeInterval = 0
        var initViewCost: CFTimeInterval = 0
        var avatarLoadCost: CFTimeInterval = 0
        var startTimestamp = CACurrentMediaTime()

        func getExtra() -> Extra {
            return Extra(
                isNeedNet: true,
                latencyDetail: [
                    "init_view_cost": Int(initViewCost * 1000),
                    "first_render": Int(firstRenderCost * 1000),
                    "sdk_cost_local": Int(sdkLocalCost * 1000),
                    "sdk_cost_net": Int(sdkNetCost * 1000),
                    "avatar_load_cost": Int(avatarLoadCost * 1000)
                ],
                metric: nil,
                category: [
                    "profile_type": ProfileType.group.rawValue
                ]
            )
        }
    }

    private static var pageName = String(reflecting: GroupCardJoinViewController.self)
    private static var isReady = false
    private static var trackInfo: TrackInfo?

    static func startEnterGroupCard() {
        isReady = false
        trackInfo = TrackInfo()
    }

    static func initViewStart() {
        trackInfo?.initViewCost = CACurrentMediaTime()
    }

    static func initViewCostEnd() {
        if let trackInfo = trackInfo, trackInfo.initViewCost != 0 {
            self.trackInfo?.initViewCost = CACurrentMediaTime() - trackInfo.initViewCost
        }
    }

    static func loadAvatarStart() {
        trackInfo?.avatarLoadCost = CACurrentMediaTime()
    }

    static func sdkLocalStart() {
        trackInfo?.sdkLocalCost = CACurrentMediaTime()
    }

    static func sdkLocalEnd() {
        if let trackInfo = trackInfo, trackInfo.sdkLocalCost != 0 {
            self.trackInfo?.sdkLocalCost = CACurrentMediaTime() - trackInfo.sdkLocalCost
        }
    }

    static func sdkNetCostStart() {
        trackInfo?.sdkNetCost = CACurrentMediaTime()
    }

    static func sdkNetCostEnd() {
        if let trackInfo = trackInfo, trackInfo.sdkNetCost != 0 {
            self.trackInfo?.sdkNetCost = CACurrentMediaTime()
        }
    }

    static func firstRenderEnd() {
        if let trackInfo = trackInfo, trackInfo.startTimestamp != 0 {
            self.trackInfo?.firstRenderCost = CACurrentMediaTime() - trackInfo.startTimestamp
        }
    }

    static func reloadDataEnd() {
        guard let trackInfo = trackInfo, trackInfo.startTimestamp != 0 else {
            return
        }
        if isReady {
            let timeCost = CACurrentMediaTime() - trackInfo.startTimestamp
            AppReciableSDK.shared.timeCost(params: TimeCostParams(
                biz: .Messenger, scene: .Profile, event: .enterProfile,
                cost: Int(timeCost * 1000), page: pageName, extra: trackInfo.getExtra()
            ))
            Self.trackInfo = nil
        }
        isReady = true
    }

    static func loadAvatarEnd() {
        guard var trackInfo = trackInfo, trackInfo.startTimestamp != 0, trackInfo.avatarLoadCost != 0 else {
            return
        }
        let timestamp = CACurrentMediaTime()
        trackInfo.avatarLoadCost = timestamp - trackInfo.avatarLoadCost
        if isReady {
            let timeCost = timestamp - trackInfo.startTimestamp
            AppReciableSDK.shared.timeCost(params: TimeCostParams(
                biz: .Messenger, scene: .Profile, event: .enterProfile,
                cost: Int(timeCost * 1000), page: pageName, extra: trackInfo.getExtra()
            ))
            Self.trackInfo = nil
        }
        isReady = true
    }

    enum GroupCardJoinErrorType: Int {
        case other = -1
        case unknown
        case network
        case sdk

        func toAppReciableErrorType() -> ErrorType {
            switch self {
            case .other: return .Other
            case .unknown: return .Unknown
            case .network: return .Network
            case .sdk: return .SDK
            }
        }
    }

    static func trackError(errorType: GroupCardJoinErrorType, error: Error? = nil, errorMessage: String? = nil) {
        let extra = Extra(isNeedNet: true, latencyDetail: nil, metric: nil, category: nil)
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Profile, event: .enterProfile,
            errorType: errorType.toAppReciableErrorType(), errorLevel: .Exception,
            errorCode: 0, userAction: nil, page: pageName,
            errorMessage: errorMessage, extra: extra
        ))
    }
}
