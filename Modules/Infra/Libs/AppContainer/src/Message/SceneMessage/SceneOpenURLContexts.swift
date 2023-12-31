//
//  SceneOpenURLContexts.swift
//  AppContainer
//
//  Created by Meng on 2019/8/6.
//

import UIKit
import Foundation

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public struct SceneOpenURLContexts: Message {
    public static let name = "SceneOpenURLContexts"
    public let context: AppContext
    public let scene: UIScene
    public let urlContexts: Set<UIOpenURLContext>
}
#endif
