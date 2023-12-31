//
//  WillEnterForeground.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct WillEnterForeground: Message {
    public static let name = "WillEnterForeground"
    public let context: AppContext
}
