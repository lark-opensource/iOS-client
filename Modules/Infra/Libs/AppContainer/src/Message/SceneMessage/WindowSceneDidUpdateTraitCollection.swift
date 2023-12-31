//
//  WindowSceneDidUpdateTraitCollection.swift
//  AppContainer
//
//  Created by Meng on 2019/8/6.
//

import UIKit
import Foundation

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public struct WindowSceneDidUpdateTraitCollection: Message {
    public static let name = "WindowSceneDidUpdateTraitCollection"
    public let context: AppContext
    public let windowScene: UIWindowScene
    public let previousCoordinateSpace: UICoordinateSpace
    public let previousInterfaceOrientation: UIInterfaceOrientation
    public let previousTraitCollection: UITraitCollection
}
#endif
