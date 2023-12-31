//
//  ModalKeyCommands.swift
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2021/3/10.
//

import UIKit
import Foundation
import LarkKeyboardKit

final class CloseKeyCommands {
    static var shared = CloseKeyCommands()
    var escKeyCommands: [CloseKeyBinding] = []
    var cmdwKeyCommands: [CloseKeyBinding] = []
    func register(escKeyBinding: CloseKeyBinding) {
        escKeyCommands.append(escKeyBinding)
    }
    func register(cmdwKeyBinding: CloseKeyBinding) {
        cmdwKeyCommands.append(cmdwKeyBinding)
    }
    func unregister(escKeyBinding: CloseKeyBinding) {
        if let index = escKeyCommands.firstIndex(where: { $0 === escKeyBinding }) {
            escKeyCommands.remove(at: index)
        }
    }
    func unregister(cmdwKeyBinding: CloseKeyBinding) {
        if let index = cmdwKeyCommands.firstIndex(where: { $0 === cmdwKeyBinding }) {
            cmdwKeyCommands.remove(at: index)
        }
    }
}

public final class CloseKeyBinding {
    var tryHandle: (CloseKeyBinding) -> Bool
    var handler: () -> Void
    public init(tryHandle: @escaping (CloseKeyBinding) -> Bool = { _ in true },
                handler: @escaping () -> Void) {
        self.tryHandle = tryHandle
        self.handler = handler
    }
}

public extension KeyCommandKit {
    func register(escKeyBinding: CloseKeyBinding) {
        CloseKeyCommands.shared.register(escKeyBinding: escKeyBinding)
    }
    func register(cmdwKeyBinding: CloseKeyBinding) {
        CloseKeyCommands.shared.register(cmdwKeyBinding: cmdwKeyBinding)
    }
    func unregister(escKeyBinding: CloseKeyBinding) {
        CloseKeyCommands.shared.unregister(escKeyBinding: escKeyBinding)
    }
    func unregister(cmdwKeyBinding: CloseKeyBinding) {
        CloseKeyCommands.shared.unregister(cmdwKeyBinding: cmdwKeyBinding)
    }
}

// 全局模态视窗快捷键
extension KeyCommandKit {

    /// 添加模态视窗全局快捷键
    public class func addCloseKeyCommands() {
        /// 注册全局 esc 快捷键
        KeyCommandKit.shared.register(
            keyBinding: KeyCommandBaseInfo(
                input: UIKeyCommand.inputEscape,
                modifierFlags: []
            ).binding(
                tryHandle: { (_) -> Bool in
                    return needHandleResignFirstResponder() ||
                        needHandleModalDismiss() ||
                        handleRegisteredEscKeyBinding()
                }, handler: {
                    if needHandleResignFirstResponder() {
                        handleResignFirstResponder()
                    } else {
                        handleModalDismiss()
                    }
                    CloseKeyCommands.shared.escKeyCommands
                        .filter({ $0.tryHandle($0) })
                        .forEach({ $0.handler() })
                }
            )
        )

        /// 注册全局 cmd + w 快捷键
        KeyCommandKit.shared.register(
            keyBinding: KeyCommandBaseInfo(
                input: "w",
                modifierFlags: [.command]
            ).binding(
                tryHandle: { (_) -> Bool in
                    return needHandleModalDismiss() ||
                        handleRegisteredCmdwKeyBinding()
                }, handler: {
                    handleModalDismiss()
                    CloseKeyCommands.shared.cmdwKeyCommands
                        .filter({ $0.tryHandle($0) })
                        .forEach({ $0.handler() })
                }
            )
        )
    }

    /// 是否需要响应取消第一响应者逻辑
    private class func needHandleResignFirstResponder() -> Bool {
        return KeyboardKit.shared.firstResponder != nil
    }

    /// 是否需要响应关闭模态逻辑
    private class func needHandleModalDismiss() -> Bool {
        return UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil
    }

    /// 响应取消第一响应者逻辑
    private class func handleResignFirstResponder() {
        KeyboardKit.shared.firstResponder?.resignFirstResponder()
    }

    /// 响应取消第一响应者逻辑
    private class func handleModalDismiss() {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            return
        }
        var dismissController = rootVC
        while let presented = dismissController.presentedViewController {
            dismissController = presented
        }
        if let nav = dismissController as? UINavigationController,
           let topvc = nav.topViewController {
            topvc.handleModalDismissKeyCommand()
        } else {
            dismissController.handleModalDismissKeyCommand()
        }
    }

    /// 响应其他注册  esc keybinding 逻辑
    private class func handleRegisteredEscKeyBinding() -> Bool {
        return CloseKeyCommands.shared.escKeyCommands.reduce(false, { $0 || $1.tryHandle($1) })
    }

    /// 响应其他注册 cmd + w keybinding 逻辑
    private class func handleRegisteredCmdwKeyBinding() -> Bool {
        return CloseKeyCommands.shared.cmdwKeyCommands.reduce(false, { $0 || $1.tryHandle($1) })
    }
}

extension UIViewController {
    /// 响应模块视窗退出快捷键，业务模块可以自定义快捷键响应逻辑
    @objc
    open func handleModalDismissKeyCommand() {
        self.dismiss(animated: true, completion: nil)
    }
}
