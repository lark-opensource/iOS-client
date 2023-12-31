//
//  AtAppReciableTracker.swift
//  LarkChat
//
//  Created by qihongye on 2020/10/25.
//

import UIKit
import Foundation
import LarkSDKInterface
import AppReciableSDK

struct AtAppReciableTracker {
    ///             |             === (firstRender) ==>                               |
    /// startTimestamp  | =(initViewCost)=> initViewEnd ==> viewDidLoad |
    /// chatterAPI.fetchAtList | ==(fetch_atlist_cost)=> response
    struct TrackerInfo {
        var startTimestamp: CFTimeInterval = CACurrentMediaTime()
        var initViewCost: CFTimeInterval = 0
        var firstRenderCost: CFTimeInterval = 0
        var sdkCost: CFTimeInterval = 0
        var chatType: Int = 0
        var isRemote: Bool = false
    }

    enum SyncType: Int {
        case unknown = 0
        case local
        case remote

        static func from(isRemote: Bool) -> SyncType {
            if isRemote {
                return .remote
            }
            return .local
        }
    }

    enum ChatType: Int {
        case unknown = 0
        case single
        case group
        case topic
        case threadDetail
    }

    private static var map: [DisposedKey: TrackerInfo] = [:]
    private static var disposedKey: DisposedKey?

    private static let pageName = "AtPickerController"

    @inline(__always)
    static func start() {
        let disposedKey = AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .atUserList, page: pageName)
        map.removeAll()
        map[disposedKey] = TrackerInfo()
        self.disposedKey = disposedKey
    }

    @inline(__always)
    static func update(chatType: ChatType) {
        guard let disposedKey = disposedKey else {
            return
        }
        map[disposedKey]?.chatType = chatType.rawValue
    }

    @inline(__always)
    static func initViewEnd() {
        guard let disposedKey = disposedKey, let trackerInfo = map[disposedKey] else {
            return
        }
        self.map[disposedKey]?.initViewCost = (CACurrentMediaTime() - trackerInfo.startTimestamp) * 1000
    }

    @inline(__always)
    static func firstRenderEnd() {
        guard let disposedKey = disposedKey, let trackerInfo = map[disposedKey] else {
            return
        }
        self.map[disposedKey]?.firstRenderCost = (CACurrentMediaTime() - trackerInfo.startTimestamp) * 1000
    }

    @inline(__always)
    static func updateSDKCost(cost: CFTimeInterval, isRemote: Bool) {
        guard let disposedKey = disposedKey else {
            return
        }
        map[disposedKey]?.isRemote = isRemote
        map[disposedKey]?.sdkCost = cost
    }

    @inline(__always)
    static func end() {
        guard let disposedKey = disposedKey, let trackerInfo = map.removeValue(forKey: disposedKey) else {
            return
        }
        AppReciableSDK.shared.end(key: disposedKey, extra: Extra(
            isNeedNet: true,
            latencyDetail: [
                "init_view_cost": trackerInfo.initViewCost,
                "first_render": trackerInfo.firstRenderCost,
                "sdk_cost": trackerInfo.sdkCost
            ],
            metric: nil,
            category: [
                "sync_type": SyncType.from(isRemote: trackerInfo.isRemote).rawValue,
                "chat_type": trackerInfo.chatType
            ]
        ))
    }

    @inline(__always)
    static func error(_ error: Error) {
        var syncType = SyncType.local
        var chatType = ChatType.unknown.rawValue
        var errorCode = 0
        var errorDesc: String?
        if let disposedKey = disposedKey, let trackerInfo = map[disposedKey] {
            syncType = .from(isRemote: trackerInfo.isRemote)
            chatType = trackerInfo.chatType
        }
        if let error = error.underlyingError as? APIError {
            errorCode = Int(error.code)
            errorDesc = error.errorDescription
        } else {
            let error = error as NSError
            errorCode = error.code
            errorDesc = error.localizedDescription
        }

        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Chat, event: .atUserList, errorType: .SDK, errorLevel: .Exception,
            errorCode: errorCode, userAction: nil, page: pageName, errorMessage: errorDesc,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: nil,
                metric: nil,
                category: [
                    "sync_type": syncType.rawValue,
                    "chat_type": chatType
                ]
            )
        ))
    }
}
