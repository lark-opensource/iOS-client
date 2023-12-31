//
//  SceneSwitcher.swift
//  LarkSceneManager
//
//  Created by Saafo on 2021/3/24.
//

import UIKit
import Foundation
import LarkKeyCommandKit
import LKCommonsLogging
import LarkExtensions

/// Scene 切换器
@available(iOS 13.4, *)
public final class SceneSwitcher {

    static let logger = Logger.log(SceneSwitcher.self, category: "Module.LarkSceneManager.SceneSwitcher")

    /// 全局单例
    public static let shared = SceneSwitcher()

    /// 切换器所在 window
    public let window = SceneSwitcherWindow()

    var registeredKeyCommand: Bool = false

    /// FeatureGating
    public var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                registerGlobalKeyCommandIfNeeded()
                Self.logger.info("SceneSwitcher is enabled")
            } else {
                unregisterGlobalKeyCommand()
                Self.logger.info("SceneSwitcher is disabled")
            }
        }
    }

    /// 注册全局快捷键，应该在启动时或 `isEnabled` 值更新时调用
    public func registerGlobalKeyCommandIfNeeded() {
        guard !registeredKeyCommand else { return }
        // register global keycommand
        KeyCommandKit.shared.register(keyBinding: showSwitcherKeyBinding)
        // register press
        KeyPressKit.shared.register(
            pressHandler: autoClosePressHandler
        )
        self.registeredKeyCommand = true
    }

    /// 取消注册全局快捷键
    public func unregisterGlobalKeyCommand() {
        KeyCommandKit.shared.unregister(keyBinding: showSwitcherKeyBinding)
        KeyPressKit.shared.unregister(pressHandler: autoClosePressHandler)
    }

    // MARK: Private
    var showSwitcherKeyBinding = KeyCommandBaseInfo(
        input: UIKeyCommand.inputTab,
        modifierFlags: .control,
        discoverabilityTitle: BundleI18n.LarkSceneManager.Lark_Core_SwitchWindows()
    )
        .binding {
            SceneSwitcher.logger.info("Global keybinding triggered")
            if SceneSwitcher.shared.window.isHidden {
                SceneSwitcher.logger.info("Switcher is isHidden now and will display")
                SceneSwitcher.shared.moveToKeySceneAndDisplay()
            }
        }
    var autoClosePressHandler = PressHandler(
        handleKeys: [.keyboardLeftControl, .keyboardRightControl], status: .ended,
        canHandle: { _ in
            return !SceneSwitcher.shared.window.isHidden
        },
        handle: { _, _ in
            SceneSwitcher.shared.window.vc.switchToSelectedScene()
        }
    )
    func moveToKeySceneAndDisplay() {
        window.windowScene = UIApplication.shared.keyWindow?.windowScene
        Self.logger.info("Switcher moved to keyWindow: \(String(describing: UIApplication.shared.keyWindow))")
        if let activationState = window.windowScene?.activationState, activationState == .foregroundActive {
            window.windowLevel = .alert - 1
            window.isHidden = false
            Self.logger.info("Switcher appeard on keywindow: \(String(describing: UIApplication.shared.keyWindow))")
        }
    }
}

// MARK: Window

@available(iOS 13.4, *)
public final class SceneSwitcherWindow: UIWindow {
    static let logger = Logger.log(SceneSwitcherWindow.self, category: "Module.LarkSceneManager.SceneSwitcher")
    public let vc = SceneSwitcherViewController()
    public override var isHidden: Bool {
        didSet {
            if !isHidden {
                vc.reload()
                makeKey()
                Self.logger.info("Scene Switcher window is visiable")
            } else {
                resignKey()
                Self.logger.info("Scene Switcher window is hidden")
            }
        }
    }

    public init() {
        super.init(frame: .zero)
        rootViewController = vc
        backgroundColor = .clear
        self.windowIdentifier = "LarkSceneManager.SceneSwitcherWindow"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
