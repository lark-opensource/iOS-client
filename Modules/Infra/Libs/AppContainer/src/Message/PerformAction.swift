//
//  PerformAction.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import UIKit
import Foundation

public struct PerformAction: Message {
    public static let name = "PerformAction"
    public let shortcutItem: UIApplicationShortcutItem
    public let context: AppContext
    public let completionHandler: (Bool) -> Void
}
