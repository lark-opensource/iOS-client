//
//  CloseAuxSceneKeyCommand.swift
//  LarkSceneManager
//
//  Created by Saafo on 2021/4/1.
//

import UIKit
import Foundation
import Homeric
import LarkKeyCommandKit
import LKCommonsTracker

public extension SceneManager {
    /// 注册关闭辅助窗口快捷键
    func registerCloseAuxSceneKeyCommand() {
        /// 是否需要响应关闭辅助窗口
        @available(iOS 13.0, *)
        func needHandleAuxSceneDismiss(_: CloseKeyBinding) -> Bool {
            guard let keyWindow = UIApplication.shared.keyWindow else { return false }
            // 有 presentedViewController 时不响应
            return keyWindow.rootViewController?.presentedViewController == nil &&
                // 主窗口不响应
                !(keyWindow.windowScene?.sceneInfo.isMainScene() ?? true) && {
                    guard let navi = keyWindow.rootViewController as? UINavigationController else { return true }
                    // 仅在辅助窗口首页响应
                    return navi.viewControllers.count == 1
                }()
        }
        /// 关闭辅助窗口
        @available(iOS 13.0, *)
        func handleAuxSceneDismiss() {
            if let uiscene = UIApplication.shared.keyWindow?.windowScene, !uiscene.sceneInfo.isMainScene() {
                SceneManager.shared.deactive(from: uiscene)
                Tracker.post(TeaEvent(Homeric.PUBLIC_SHORTCUT_SCENE_CLOSE))
            }
        }
        if #available(iOS 13.0, *) {
            KeyCommandKit.shared.register(
                cmdwKeyBinding: CloseKeyBinding(
                    tryHandle: needHandleAuxSceneDismiss,
                    handler: handleAuxSceneDismiss
                )
            )
        }
    }
}
