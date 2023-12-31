//
//  WorkplaceTrackWrapper.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/9.
//

import Foundation
import LKCommonsTracker

/// 对 Tracker 的封装，业务不应该直接使用此类型。
final class WorkplaceTrackWrapper: WorkplaceTrackable {
    let name: WorkplaceTrackEventName
    let userId: String
    private var params: [String: Any] = [:]

    init(name: WorkplaceTrackEventName, userId: String) {
        self.name = name
        self.userId = userId
    }

    @discardableResult
    func setValue(_ value: Any?, for key: WorkplaceTrackEventKey) -> WorkplaceTrackable {
        if let value = value {
            params[key.rawValue] = value
        }
        return self
    }

    func setMap(_ map: [String : Any]) -> WorkplaceTrackable {
        map.forEach({ key, value in
            params[key] = value
        })
        return self
    }

    func post() {
        Tracker.post(TeaEvent(name.rawValue, userID: userId, params: params))
    }
}

