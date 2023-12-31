//
//  WillTerminate.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct WillTerminate: Message {
    public static let name = "WillTerminate"
    public let context: AppContext
}
