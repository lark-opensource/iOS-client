//
//  KeyCommandKit.swift
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2020/2/5.
//

import UIKit
import Foundation

public final class KeyCommandKit: NSObject {
    public static let shared = KeyCommandKit()

    /// 全局快捷键
    var globalKeyCommands: [Int: KeyBinding] = [:]

    /// binging cache
    var keyCommandCache: [Int: KeyBinding] = [:]

    static var hadSwizzledResponderMethod: Bool = false

    @objc
    public static func swizzledIfNeeded() {

        /// 只在 pad 版本生效
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }

        if !KeyCommandKit.hadSwizzledResponderMethod {
            kck_swizzling(
                forClass: UIApplication.self,
                originalSelector: #selector(getter: UIResponder.keyCommands),
                swizzledSelector: #selector(UIApplication.kck_keyCommands)
            )
            KeyCommandKit.hadSwizzledResponderMethod = true
        }

    }
    /// 注册全局快捷键
    public func register(keyBinding: KeyBinding) {
        execInMainThread {
            self.globalKeyCommands[keyBinding.hashValue] = keyBinding
        }
    }
    /// 取消注册全局快捷键
    public func unregister(keyBinding: KeyBinding) {
        execInMainThread {
            self.globalKeyCommands[keyBinding.hashValue] = nil
        }
    }

    /// 响应快捷键
    func handle(keyCommand: UIKeyCommand) {
        if let binding = keyCommandCache[keyCommand.hashValue] {
            binding.handle()
        }
    }

    /// 返回当前所有快捷键
    /// 目前的逻辑是找到 rootWindow 的 rootVC 作为根节点向下查找
    /// 后续需要优化支持多 scene 场景
    public func keyCommands() -> [UIKeyCommand] {
        var bindings: [KeyBinding] = []

        /// 添加全局快捷键
        globalKeyCommands.forEach { (info) in
            bindings.append(info.value)
        }
        /// 获取 能响应key command的 windows
        UIApplication.shared.responstiveKeyCommandWindows.forEach { (window) in
            if let root = window.rootViewController {
                bindings.append(contentsOf:
                    root.keyCommandContainers().flatMap { (container) -> [KeyCommandProvider] in
                        return findSub(provider: container) + [container]
                    }.flatMap { (provider) -> [KeyBindingWraper] in
                        return provider.keyBindings()
                    }.compactMap { (wraper) -> KeyBinding in
                        return wraper.binder
                    }
                )
            }
        }
        /// 过滤不需要显示的快捷键
        bindings = bindings.filter { $0.tryHandle($0) }

        var commands: [UIKeyCommand] = []
        var cache: [Int: KeyBinding] = [:]
        bindings.forEach { (binding) in
            let command = binding.info.keyCommand()
            #if swift(>=5.5)
            if #available(iOS 15, *) {
                command.wantsPriorityOverSystemBehavior = true
            }
            #endif
            commands.append(command)
            cache[command.hashValue] = binding
        }
        self.keyCommandCache = cache
        return commands
    }

    func findSub(provider: KeyCommandProvider) -> [KeyCommandProvider] {
        return provider.subProviders().flatMap { (provider) -> [KeyCommandProvider] in
            return [provider] + findSub(provider: provider)
        }
    }

    private func execInMainThread(block: @escaping () -> Void) {
        if Thread.current.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

extension UIApplication {
    @objc
    func kck_keyCommands() -> [UIKeyCommand] {
        return self.kck_keyCommands() +
            KeyCommandKit.shared.keyCommands()
    }
}

extension UIApplication {
    // key window and floating window can responded
    var responstiveKeyCommandWindows: [UIWindow] {
        var responserArray: [UIWindow] = []
        if #available(iOS 13.0, *) {
            connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .forEach { (scene) in
                    guard let windowScene = scene as? UIWindowScene else {
                        return
                    }
                    let sceneSize = windowScene.coordinateSpace.bounds.size
                    let available = windowScene.windows.filter({ (window) -> Bool in
                        guard !window.isHidden else {
                            return false
                        }
                        return window.isKeyWindow || sceneSize.includedAbsolutely(size: window.bounds.size)
                    })
                    responserArray.append(contentsOf: available)
                }
        } else {
            windows.forEach { (window) in
                guard !window.isHidden else {
                    return
                }
                if window.isKeyWindow {
                    responserArray.append(window)
                } else if let keyW = keyWindow, keyW.bounds.size.includedAbsolutely(size: window.bounds.size) {
                    responserArray.append(window)
                }
            }
        }
        return responserArray
    }
}

extension CGSize {
    func includedAbsolutely(size: CGSize) -> Bool {
        let currentArea: CGFloat = width * height
        let floatingArea: CGFloat = size.width * size.height
        return currentArea > floatingArea * 2
    }
}
