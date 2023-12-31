//
//  Notification.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation

extension Notification.Name {
    //From DocBrowserView
    public static let BrowserFullscreenMode: Notification.Name = Notification.Name("commentcard.status.changed.notification")

    public static let DocsThemeChanged: Notification.Name = Notification.Name("docs.theme.changed.notification")

    //From BrowserOrientationManager
    public static let motionDidChangeOrientationNotification = Notification.Name(rawValue: "\(Notification.Name.Docs.nameSpace).motionDidChangeOrientationNotification")

    //From ReactionService.swift
    public static let ReactionShowDetail = NSNotification.Name("space.reaction.show.detail")

    public static let SearchStatusBarChanged: Notification.Name = Notification.Name("searchreplace.status.changed.notification")
    public static let MakeDocsAnimationStartIgnoreKeyboard: Notification.Name = Notification.Name("com.bytedance.ee.docs.startIgnoreKeyboard")
    public static let MakeDocsAnimationEndIgnoreKeyboard: Notification.Name = Notification.Name("com.bytedance.ee.docs.endIgnoreKeyboard")
    public static let FeatchAtUserPermissionResult: Notification.Name = Notification.Name("com.bytedance.ee.docs.featchAtUserPermission")
    public static let SpaceTabItemTapped: Notification.Name = Notification.Name("com.bytedance.ee.docs.spaceTabItemTapped")
    public static let BaseTabItemTapped: Notification.Name = Notification.Name("com.bytedance.ee.baseTabItemTapped")
    public static let SimulateWebViewUnresponsive = Notification.Name("docs.simulateWebViewUnresponsive.notification")
    public static let KillWebContentProcess = Notification.Name("docs.killWebContentProcess.notification")
    public static let SpaceTabDidAppear: Notification.Name = Notification.Name("com.bytedance.ee.docs.spaceTabDidAppear")
    
    public static let SetupDocsRNEnvironment: Notification.Name = Notification.Name("com.bytedance.rn.docs.setupRNEnv")
}


//From  ReactionService.swift   ReactionService.NotificationKey
public enum ReactionNotificationKey: String {
    case reactions
    case referType
    case referKey
    case replyId
}

public enum SpaceTabItemTappedNotificationKey: String {
    case isSameTab // 是否重复点击tab
}
