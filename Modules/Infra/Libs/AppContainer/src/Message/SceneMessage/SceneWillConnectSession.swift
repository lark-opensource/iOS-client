//
//  SceneWillConnectSession.swift
//  AppContainer
//
//  Created by Meng on 2019/8/6.
//

import UIKit
import Foundation

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public struct SceneWillConnectSession: Message {
    public static let name = "SceneWillConnectSession"
    public let context: AppContext
    public let session: UISceneSession
    public let scene: UIScene
    public let connectionOptions: UIScene.ConnectionOptions
}
#endif
