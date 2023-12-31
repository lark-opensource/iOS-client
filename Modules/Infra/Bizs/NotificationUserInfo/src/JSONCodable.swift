//
//  JSONCodable.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/19.
//

import Foundation

public protocol JSONCodable {
    init?(dict: [String: Any])

    func toDict() -> [String: Any]
}
