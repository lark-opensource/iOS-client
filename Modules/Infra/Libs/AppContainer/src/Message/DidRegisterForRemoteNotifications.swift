//
//  DidRegisterForRemoteNotifications.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct DidRegisterForRemoteNotifications: Message {
    public static let name = "DidRegisterForRemoteNotifications"
    public let deviceToken: Data
    public let context: AppContext
}
