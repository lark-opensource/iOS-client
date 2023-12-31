//
//  VCNotification.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/15.
//

import Foundation

public struct VCNotification {
    /// 账号切换通知，第一次获取到账号（初始化）时不会触发。
    public static let didChangeAccountNotification = Notification.Name("ByteView.App.didChangeAccount")

    public static let didReceiveRemoteNotification = Notification.Name("ByteView.App.didReceiveRemoteNotification")

    public static let didReceiveContinueUserActivityNotification = Notification.Name("ByteView.App.didReceiveContinueUserActivityNotification")

    public static let didUpdateWindowSceneNotification = Notification.Name("ByteView.App.didUpdateWindowSceneNotification")

    /// String
    /// - didChangeAccountNotification
    public static let userIdKey: String = "userId"

    /// [String: Any]
    /// - didReceiveRemoteNotification
    /// - didReceiveLocalNotification
    public static let userInfoKey: String = "userInfo"

    /// NSUserActivity
    /// - didReceiveContinueUserActivityNotification
    public static let userActivityKey: String = "userActivity"

    /// WindowSceneLayoutContext
    /// - didUpdateWindowSceneNotification
    public static let previousLayoutContextKey: String = "previousLayoutContext"
    /// WindowSceneLayoutContext
    /// - didUpdateWindowSceneNotification
    public static let layoutContextKey: String = "layoutContext"
}
