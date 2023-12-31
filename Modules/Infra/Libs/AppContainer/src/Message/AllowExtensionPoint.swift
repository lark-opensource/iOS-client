//
//  KeyboardChange.swift
//  AppContainer
//
//  Created by ByteDance on 2022/10/25.
//

import UIKit
import Foundation

public struct AllowExtensionPoint: Message {
    public static let name = "KeyboardChange"
    public let identifier: UIApplication.ExtensionPointIdentifier
    public typealias HandleReturnType = Bool
}
