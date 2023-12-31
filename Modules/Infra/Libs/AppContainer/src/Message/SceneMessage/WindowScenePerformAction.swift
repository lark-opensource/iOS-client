//
//  WindowScenePerformAction.swift
//  AppContainer
//
//  Created by Meng on 2019/8/6.
//

import UIKit
import Foundation

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public struct WindowScenePerformAction: Message {
    public static let name = "WindowScenePerformAction"
    public let context: AppContext
    public let windowScene: UIWindowScene
    public let shortcutItem: UIApplicationShortcutItem
    public let completionHandler: (Bool) -> Void
}
#endif
