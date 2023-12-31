//
//  DidBecomeActive.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct DidBecomeActive: Message {
    public static let name = "DidBecomeActive"
    public let context: AppContext
}
