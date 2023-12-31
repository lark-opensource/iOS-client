//
//  Notification.swift
//  LarkResource
//
//  Created by 李晨 on 2020/3/17.
//

import Foundation

extension Notification.Name {
    public static let DefaultIndexDidChange: Notification.Name = Notification.Name(rawValue: "resouce.manager.default.index.did.change")

    public static let GlobalIndexDidChange: Notification.Name = Notification.Name(rawValue: "resouce.manager.global.index.did.change")
}
