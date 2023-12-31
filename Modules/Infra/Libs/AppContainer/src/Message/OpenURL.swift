//
//  OpenURL.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import UIKit
import Foundation

public struct OpenURL: Message {
    public static let name = "OpenURL"
    public let url: URL
    public let options: [UIApplication.OpenURLOptionsKey: Any]
    public let context: AppContext
}
