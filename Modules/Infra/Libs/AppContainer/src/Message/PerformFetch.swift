//
//  PerformFetch.swift
//  AppContainer
//
//  Created by 李勇 on 2020/2/12.
//

import UIKit
import Foundation

public struct PerformFetch: Message {
    public static let name = "PerformFetch"
    public let context: AppContext
    public let completionHandler: (UIBackgroundFetchResult) -> Void
}
