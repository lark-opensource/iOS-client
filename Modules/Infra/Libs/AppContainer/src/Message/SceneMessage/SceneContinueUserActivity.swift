//
//  SceneContinueUserActivity.swift
//  AppContainer
//
//  Created by 李晨 on 2021/1/24.
//

import UIKit
import Foundation

@available(iOS 13.0, *)
public struct SceneContinueUserActivity: Message {
    public static let name = "SceneContinueUserActivity"
    public let context: AppContext
    public let scene: UIScene
    public let userActivity: NSUserActivity
}

@available(iOS 13.0, *)
public struct SceneWillContinueUserActivity: Message {
    public static let name = "SceneWillContinueUserActivity"
    public let context: AppContext
    public let scene: UIScene
    public let userActivityType: String
}

@available(iOS 13.0, *)
public struct SceneDidFailToContinueUserActivity: Message {
    public static let name = "SceneDidFailToContinueUserActivity"
    public let context: AppContext
    public let scene: UIScene
    public let userActivityType: String
    public let error: Error
}

@available(iOS 13.0, *)
public struct SceneDidUpdateUserActivity: Message {
    public static let name = "SceneDidUpdateUserActivity"
    public let context: AppContext
    public let scene: UIScene
    public let userActivity: NSUserActivity
}
