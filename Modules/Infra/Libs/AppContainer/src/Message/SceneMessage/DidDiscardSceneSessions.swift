//
//  DidDiscardSceneSessions.swift
//  AppContainer
//
//  Created by Meng on 2019/8/11.
//

import UIKit
import Foundation

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public struct DidDiscardSceneSessions: Message {
    public static let name = "DidDiscardSceneSessions"
    public let context: AppContext
    public let sceneSessions: Set<UISceneSession>
}
#endif
