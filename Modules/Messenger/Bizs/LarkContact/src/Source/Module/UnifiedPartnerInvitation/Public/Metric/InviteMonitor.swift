//
//  InviteMonitor.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/12/3.
//

import UIKit
import Foundation
import ThreadSafeDataStructure
import LKCommonsTracker
import LarkSnsShare
import enum AppReciableSDK.Event
import struct AppReciableSDK.Extra
import class AppReciableSDK.DisposedKey
import class AppReciableSDK.AppReciableSDK
import struct AppReciableSDK.ErrorParams
import enum AppReciableSDK.ErrorType

enum ReciableState {
    case success, failed
}

final class InviteMonitor {
    enum ErrorField {
        static let errorCode = "error_code"
        static let errorMsg = "error_msg"
    }
    var timeDic: SafeDictionary<String, TimeInterval> = [:] + .readWriteLock
    var disposeKeyMap: SafeDictionary<String, DisposedKey> = [:] + .readWriteLock

    func startEvent(
        name: String,
        indentify: String = "",
        reciableEvent: Event? = nil,
        reciableExtra: Extra? = nil
    ) {
        let key = name + indentify
        timeDic[key] = CACurrentMediaTime()

        if let reciableEvent = reciableEvent {
            let disposedKey = AppReciableSDK.shared.start(
                biz: .UserGrowth,
                scene: .Invite,
                event: reciableEvent,
                page: nil,
                userAction: nil,
                extra: reciableExtra
            )
            disposeKeyMap[reciableEvent.rawValue] = disposedKey
        }
    }

    func endEvent(
        name: String,
        indentify: String = "",
        metric: [AnyHashable: Any] = [:],
        category: [AnyHashable: Any] = [:],
        extra: [AnyHashable: Any] = [:],
        reciableState: ReciableState? = nil,
        needNet: Bool = true,
        reciableEvent: Event? = nil
    ) {
        let key = name + indentify
        guard let startTime = timeDic[key] else { return }
        timeDic[key] = nil
        let cost = CACurrentMediaTime() - startTime
        var metric = metric
        metric["cost"] = cost

        Tracker.post(
            SlardarEvent(
                name: name,
                metric: metric,
                category: category,
                extra: extra
            )
        )

        if let reciableEvent = reciableEvent,
           let reciableState = reciableState,
           let disposedKey = disposeKeyMap[reciableEvent.rawValue],
           let errorCode = category[ErrorField.errorCode] as? Int {

            let reciableExtra = Extra(
                isNeedNet: needNet,
                metric: metric as? [String: Any],
                category: category as? [String: Any],
                extra: extra as? [String: Any]
            )
            switch reciableState {
            case .success:
                AppReciableSDK.shared.end(key: disposedKey, extra: reciableExtra)
            case .failed:
                var errorType: ErrorType = .Other
                if needNet {
                    errorType = .Network
                }
                AppReciableSDK.shared.error(params: ErrorParams(
                    biz: .UserGrowth,
                    scene: .UGCenter,
                    event: reciableEvent,
                    errorType: errorType,
                    errorLevel: .Exception,
                    errorCode: errorCode,
                    userAction: nil,
                    page: nil,
                    errorMessage: category[ErrorField.errorMsg] as? String,
                    extra: reciableExtra
                ))
            }
        }
    }

    static func post(
        name: String,
        metric: [AnyHashable: Any] = [:],
        category: [AnyHashable: Any] = [:],
        extra: [AnyHashable: Any] = [:]
    ) {
        Tracker.post(
            SlardarEvent(
                name: name,
                metric: metric,
                category: category,
                extra: extra
            )
        )
    }
}

extension String {
    static func desc(with itemType: LarkShareItemType) -> String {
        var itemDesc = "unknown"
        switch itemType {
        case .wechat:
            itemDesc = "wechat_session"
        case .weibo:
            itemDesc = "weibo"
        case .qq:
            itemDesc = "qq"
        case .copy:
            itemDesc = "copy"
        case .more:
            itemDesc = "system_share"
        default: break
        }
        return itemDesc
    }
}
