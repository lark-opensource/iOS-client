//
//  ContinueUserActivity.swift
//  AppContainer
//
//  Created by yinyuan on 2019/8/25.
//

import UIKit
import Foundation

public struct ContinueUserActivity: Message {
    public static let name = "ContinueUserActivity"
    public let userActivity: NSUserActivity
    public let restorationHandler: ([UIUserActivityRestoring]?) -> Void
    public let context: AppContext
}
