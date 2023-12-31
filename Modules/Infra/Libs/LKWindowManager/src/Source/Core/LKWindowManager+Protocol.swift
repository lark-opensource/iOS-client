//
//  LkWindowManager+Protocol.swift
//  LKWindowManager
//
//  Created by Yaoguoguo on 2022/12/13.
//

import UIKit
import Foundation

public protocol LKWindowProtocol: UIView {
    var identifier: String { get set }

    /// The root view controller for the window.
    var rootViewController: UIViewController? { get set }

    /// The position of the window in the z-axis.
    var windowLevel: UIWindow.Level { get set }

    /// A Boolean value that indicates whether the window's constraint-based content determines its size.
    var canResizeToFitContent: Bool { get set }

    /// A Boolean value that indicates whether the window is the key window.
    var isKeyWindow: Bool { get }

    /// A Boolean value that indicates whether the window can become the key window.
    @available(iOS 15.0, *)
    var canBecomeKey: Bool { get }

    /// The scene containing the window.
    @available(iOS 13.0, *)
    var windowScene: UIWindowScene? { get set }

    /// Shows the window and makes it the key window.
    func makeKeyAndVisible()

    /// Makes the window the key window.
    func makeKey()

    /// Tells the window that it’s the key window.
    func becomeKey()

    /// Tells the window that it’s no longer the key window.
    func resignKey()

    /// Converts a point from the current window’s coordinate system to the coordinate system of another window.
    /// - Parameters:
    ///   - point: A point specifying a location in the logical coordinate system of the current window object.
    ///   - to: The window defining the destination coordinate system for point. Specify nil to convert the point to the logical coordinate system of the screen, which is measured in points.
    /// - Returns: The point converted to the coordinate system of window.
    func convert(_ point: CGPoint, to window: UIWindow?) -> CGPoint

    /// Converts a point from the coordinate system of a given window to the coordinate system of the current window.
    /// - Parameters:
    ///   - point: A point specifying a location in the coordinate system of window.
    ///   - window: The source window containing the specified point. Specify nil to convert the point from the logical coordinate system of the screen, which is measured in points.
    /// - Returns: The point converted to the coordinate system of the current window.
    func convert(_ point: CGPoint, from window: UIWindow?) -> CGPoint

    /// Converts a rectangle from the current window’s coordinate system to the coordinate system of another window.
    /// - Parameters:
    ///   - rect: A rectangle in the current window’s coordinate system.
    ///   - to: The window defining the destination coordinate system for rect. Specify nil to convert the rectangle to the logical coordinate system of the screen, which is measured in points.
    /// - Returns: The rectangle converted to the coordinate system of window.
    func convert(_ rect: CGRect, to window: UIWindow?) -> CGRect

    /// Converts a rectangle from the coordinate system of another window to coordinate system of the current window.
    /// - Parameters:
    ///   - rect: A rectangle in the coordinate system of window.
    ///   - from: The source window containing the specified rect. Specify nil to convert the rectangle from the logical coordinate system of the screen, which is measured in points.
    /// - Returns: The converted rectangle.
    func convert(_ rect: CGRect, from window: UIWindow?) -> CGRect

}
