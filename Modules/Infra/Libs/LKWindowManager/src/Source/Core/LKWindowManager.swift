//
//  LkWindowManager.swift
//  LKWindowManager
//
//  Created by Yaoguoguo on 2022/12/13.
//

import UIKit
import Foundation

extension LKWindowManager {

    /// Create LKWindow by id
    /// - Parameters:
    ///   - id: LKWindow unique identifier
    ///   - isVirtual: Used to determine whether to create a virtual window
    /// - Returns: LKWindowProtocol. Returns nil if your id is not registered
    public func createLKWindow(byID id: LKWindowKey, isVirtual: Bool) -> LKWindowProtocol? {
        if isVirtual {
            for value in windowConfigMap.values {
                if let virtual = value.virtuals[id] {
                    var virtualwindow = LKVirtualWindow()
                    for windowClass in registerVirtualWindowMap {
                        if windowClass.canCreate(by: virtual),
                           let window = windowClass.create(by: virtual) {
                            virtualwindow = window
                            break
                        }
                    }
                    virtualwindow.identifier = id.rawValue
                    virtualwindow.windowLevel = virtual.level
                    self.addVirtualWindow(virtualwindow)
                    return virtualwindow
                }
            }
        } else if let windowConfig  = windowConfigMap[id] {
            var lkwindow = LKWindow()
            for windowClass in registerWindowMap {
                if windowClass.canCreate(by: windowConfig), let new = windowClass.create(by: windowConfig) {
                    lkwindow = new
                }
            }
            lkwindow.identifier = id.rawValue
            lkwindow.windowLevel = windowConfig.level
            self.windowMap[id.rawValue] = lkwindow
            return lkwindow
        }
        return nil
    }

    /// Get a LKWindow by id
    /// - Parameter id: LKWindow unique identifier
    /// - Returns: LKWindowProtocol. Returns nil if your id is not registered
    public func getLKWindow(byID id: LKWindowKey) -> LKWindowProtocol? {
        return self.windowMap[id.rawValue]
    }

    /// Get all windows of the current Manager
    /// - Returns: LKWindowProtocol array
    public func getLKWindows() -> [LKWindowProtocol] {
        return Array(self.windowMap.values)
    }

    /// Get the key window of the current application
    /// - Returns: UIWindow
    public func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication
                    .shared
                    .connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    /// Get the key window of the current application
    /// - Returns: UIWindow
    public func getLKKeyWindow() -> LKWindowProtocol? {
        guard let lkwindow = self.getKeyWindow() as? LKWindow else { return nil}
        return lkwindow.virtualKeyWindow
    }

//    /// Add a window to LKWindow
//    /// - Parameters:
//    ///   - window: added window
//    ///   - superWindow: Target Window
//    public func add(_ window: LKWindowProtocol) {
//        self.windowMap[window.identifier] = window
//    }

    /// remove a window
    /// - Parameter window: current window
    public func remove(_ window: LKWindowProtocol) {
        window.removeFromSuperview()
        self.windowMap.removeValue(forKey: window.identifier)
    }

    public func registerWindow(_ window: LKWindowProtocol.Type) {
        if let new = window as? LKWindow.Type, !registerWindowMap.contains(where: { new == $0 }) {
            registerWindowMap.append(new)
        } else if let new = window as? LKVirtualWindow.Type, !registerVirtualWindowMap.contains(where: { new == $0 }) {
            registerVirtualWindowMap.append(new)
        }

    }
}

/// Lark Window Manager
final public class LKWindowManager {

    public static var shared: LKWindowManager = LKWindowManager()

    private var windowMap: [String: LKWindow] = [:]

    private var registerWindowMap: [LKWindow.Type] = []

    private var registerVirtualWindowMap: [LKVirtualWindow.Type] = []

    private init() {}

    private func addVirtualWindow(_ window: LKVirtualWindow) {
        var floor = UIWindow.Level.normal

        if window.windowLevel > .statusBar {
            floor = .statusBar
        } else if window.windowLevel > .alert {
            floor = .alert
        }

        let sortValues = windowMap.values.sorted {
            $0.windowLevel < $1.windowLevel
        }

        var lkWindow: LKWindow?
        for value in sortValues {
            if value.windowLevel > window.windowLevel {
                break
            } else if value.windowLevel >= floor , value.windowLevel <= window.windowLevel {
                lkWindow = value
            }
        }

        if lkWindow == nil {
            lkWindow = createDefaultWindowBy(floor)
        }

        lkWindow?.addVirtualWindow(window)
        lkWindow?.isHidden = false
    }

    private func createDefaultWindowBy(_ level: UIWindow.Level) -> LKWindow {
        var lkWindow = LKWindow()
        lkWindow.rootViewController = LKWindowRootController()
        lkWindow.backgroundColor = .clear
        let id = "\(level.rawValue)"
        lkWindow.identifier = id
        lkWindow.windowLevel = level
        self.windowMap[id] = lkWindow
        return lkWindow
    }
}
