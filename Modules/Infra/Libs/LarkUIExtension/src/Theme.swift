//
//  Theme.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/11.
//

import UIKit
import Foundation
import LarkResource
import ThreadSafeDataStructure
import LKCommonsLogging

/// 皮肤策略
public enum ThemeStrategy {
    case system
    case light
    case dark
}

/// 当前皮肤
public enum Theme: String {
    case light
    case dark
}

extension ThemeManager {
    public static let ThemeWillChange = NSNotification.Name("theme.will.change.notification")

    public static let ThemeDidChange = NSNotification.Name("theme.did.change.notification")
}

public final class ThemeManager: NSObject {

    private static let logger = Logger.log(ThemeManager.self, category: "Lark.UI.Extension")

    private(set) static var didSetup: Bool = false

    private(set) static var finishLaunchingObserver: NSObjectProtocol?

    public static let shared: ThemeManager = {
        return ThemeManager()
    }()

    /// 当前皮肤策略
    public var strategy: Atomic<ThemeStrategy> = Atomic<ThemeStrategy>(.light)

    private lazy var lastTheme: Atomic<Theme> = Atomic<Theme>(self.current)

    /// 当前皮肤
    public static var current: Theme {
        return shared.current
    }

    public var current: Theme {
        switch strategy.value {
            case .system:
                return systemTheme
            case .light:
                return .light
            case .dark:
                return .dark
        }
    }

    private var systemTheme: Theme {
        if #available(iOS 13.0, *) {
            let userInterfaceStyle = UITraitCollection.current.userInterfaceStyle
            switch userInterfaceStyle {
                case .light:
                    return .light
                case .dark:
                    return .dark
                case .unspecified:
                    break
                @unknown default:
                    break
            }
        }
        return .light
    }

    private var observation: NSKeyValueObservation?

    override init() {
        super.init()
    }

    /// Do not call before didFinishLaunching
    public static func setupIfNeeded() {
        if didSetup { return }
        didSetup = true
        Swizzing.themeExtensionSwizzleMethod()
        Env.defaultTheme.value = ThemeManager.shared.lastTheme.value.rawValue
    }

    public func update(strategy: ThemeStrategy) {
        assert(ThemeManager.didSetup, "please setup by ThemeManager.setupIfNeeded()")
        if self.strategy.value != strategy {
            ThemeManager.logger.info("update theme strategy to \(strategy)")
            self.updateThemeValue(strategy)
        }
    }

    func setupLastTheme() {
        let systemTheme = self.systemTheme
        if self.strategy.value == .system,
            self.lastTheme.value != systemTheme {
            self.lastTheme.value = systemTheme
            Env.defaultTheme.value = systemTheme.rawValue
        }
    }

    func updateWhenTraitChange() {
        if self.strategy.value == .system,
            self.lastTheme.value != self.systemTheme {
            ThemeManager.logger.info("system user infterface change to \(self.systemTheme)")
            self.updateThemeValue()
        }
    }

    private func updateThemeValue(_ newStrategy: ThemeStrategy? = nil) {
        NotificationCenter.default.post(
            name: ThemeManager.ThemeWillChange,
            object: nil
        )
        if let strategy = newStrategy {
            self.strategy.value = strategy
        }
        let currentTheme = self.current
        self.lastTheme.value = currentTheme
        Env.defaultTheme.value = currentTheme.rawValue

        NotificationCenter.default.post(
            name: ThemeManager.ThemeDidChange,
            object: nil
        )
    }
}
