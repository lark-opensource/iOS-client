//
//  SignificantTimeChange.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/20.
//

import Foundation

public struct SignificantTimeChange: Message {
    public static let name = "SignificantTimeChange"
    public let context: AppContext
}
