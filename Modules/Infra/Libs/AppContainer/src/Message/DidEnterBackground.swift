//
//  DidEnterBackground.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct DidEnterBackground: Message {
    public static let name = "DidEnterBackground"
    public let context: AppContext
}
