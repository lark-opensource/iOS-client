//
//  DidFailToRegisterForRemoteNotifications.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct DidFailToRegisterForRemoteNotifications: Message {
    public static let name = "DidFailToRegisterForRemoteNotifications"
    public let error: Error
    public let context: AppContext
}
