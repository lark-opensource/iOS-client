//
//  DidReceiveMemoryWarning.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct DidReceiveMemoryWarning: Message {
    public static let name = "DidReceiveMemoryWarning"
    public let context: AppContext
}
