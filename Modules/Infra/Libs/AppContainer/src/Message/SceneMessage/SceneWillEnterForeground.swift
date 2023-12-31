//
//  SceneWillEnterForeground.swift
//  AppContainer
//
//  Created by Meng on 2019/8/6.
//

import UIKit
import Foundation

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public struct SceneWillEnterForeground: Message {
    public static let name = "SceneWillEnterForeground"
    public let context: AppContext
    public let scene: UIScene
}
#endif
