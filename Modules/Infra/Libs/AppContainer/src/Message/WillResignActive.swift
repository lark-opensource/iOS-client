//
//  WillResignActive.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct WillResignActive: Message {
    public static let name = "WillResignActive"
    public let context: AppContext
}
