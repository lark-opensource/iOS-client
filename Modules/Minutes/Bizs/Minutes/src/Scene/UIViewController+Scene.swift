//
//  UIViewController+Scene.swift
//  Minutes
//
//  Created by lvdaqian on 2021/8/10.
//

import Foundation
import LarkSceneManager
import LarkUIKit
import LarkSplitViewController
import MinutesFoundation

protocol MinutesMultiSceneController: UIViewController {
    var sceneID: String { get }
    var sceneTitle: String { get }
}

extension MinutesMultiSceneController {

    var sceneTitle: String {
        BundleI18n.Minutes.MMWeb_G_MinutesNameShort
    }

    var sceneInfo: Scene {
        Scene(key: "Minutes", id: sceneID, title: sceneTitle)
    }

    /// could open this view controler in other scene,  if true, you should show the button of open scene.
    var couldOpenInScene: Bool {
        if Display.phone { return false }
        if #available(iOS 13.0, *) {
            if let window = self.currentWindow(),
               let scene = window.windowScene {
                let sceneInfo = scene.sceneInfo
                let isMainScene = sceneInfo.isMainScene()
                let isSecondary: () -> Bool = { self.navigationController?.viewControllers.reduce(false, { $0 || $1.childrenIdentifier.contains(.secondary) }) ?? false }
                let isInDetail = isInSplitDetail || isSecondary()
                return isMainScene && isInDetail
            }
        }
        return false
    }

    /// could close this view controler in other scene,  if true, you should show the button of close scene.
    var couldCloseScene: Bool {
        if Display.phone { return false }
        if #available(iOS 13.0, *) {
            if let window = self.currentWindow(),
               let scene = window.windowScene {
                let sceneInfo = scene.sceneInfo
                // 当作为子 scene rootVC 时显示 close
                let isMainScene = sceneInfo.isMainScene()
                let isRootVC = self.navigationController == window.rootViewController &&
                    self.navigationController?.realViewControllers.first == self
                return !isMainScene && isRootVC
            }
        }
        return false
    }

    var currentSceneInfo: Scene? {
        if #available(iOS 13.0, *) {
            guard let window = self.rootWindow(),
                  let scene = window.windowScene?.sceneInfo else {
                return nil
            }
            return scene
        } else {
            return nil
        }
    }

    /// exit scene, action for close a scene
    func exitScene() {
        guard let sceneInfo = currentSceneInfo else {
            MinutesLogger.list.warn("exit scene when view controller has not window scene")
            return
        }

        if !sceneInfo.isMainScene() {
            MinutesLogger.list.info("exit scene with id: \(sceneInfo.id)")
            SceneManager.shared.deactive(scene: sceneInfo)
        } else {
            MinutesLogger.list.warn("exit scene when view controller is in main scene")
        }
    }

    /// open this view controller in other scene
    /// - Parameters:
    ///   - localContext: if it is not nil, and it is an UIViewController,  othe scene will open this UIViewController instead of creating a new one.
    ///   - keepLayout: 是否保持原有窗口布局，默认为 false
    ///   - callback: 回调函数，用于返回 scene 或者报错
    func openInScene(localContext: AnyObject? = nil,
                     keepLayout: Bool = false,
                     callback: ((UIWindow?, Error?) -> Void)? = nil) {
        let scene = sceneInfo
        MinutesLogger.list.info("open in scene with id: \(scene.id)")
        SceneManager.shared.active(scene: scene, from: self, localContext: localContext, keepLayout: keepLayout, callback: callback)
    }

    var couldZoomInOut: Bool {
        if Display.phone { return false }
        return isInSplitDetail
    }

    var isInSplitDetail: Bool {
        if Display.phone || larkSplitViewController == nil { return false }
        return larkSplitViewController?.secondaryNavigation == navigationController
    }

    var isSecondary: Bool {
        var identifier = self.childrenIdentifier
        if identifier == .init(identifier: [.undefined]),
           let viewControllers = self.navigationController?.viewControllers,
           let index = viewControllers.lastIndex(of: self) {
            for idx in index...0 {
                let vc = viewControllers[idx]
                if vc.childrenIdentifier != .init(identifier: [.undefined]) {
                    identifier = vc.childrenIdentifier
                    break
                }
            }
        }
        return identifier.contains(.secondary)
    }

}
