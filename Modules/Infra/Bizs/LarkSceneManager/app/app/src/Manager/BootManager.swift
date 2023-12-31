//
//  BootManager.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/3.
//

import Foundation
import UIKit
import LarkSceneManager
import LarkKeyCommandKit

struct ContextKey {
    static let scene = "scene"
    static let window = "window"
    static let session = "session"
    static let options = "options"
}

typealias BootContext = [String: Any]

/// 简化的启动框架
class BootManager {

    static let shared = BootManager()

    /// 是否已经启动过
    var launched: Bool = false

    /// 启动任务
    var tasks: [BootTask] = []

    func register(task: BootTask) {
        tasks.append(task)
    }

    func launch(context: BootContext) {

        tasks.forEach { (task) in
            if launched && task.onlyLaunch {
                // 跳过
            } else {
                task.execute(context: context)
            }
        }
        launched = true
    }

}
protocol BootTask {
    /// 是否只在启动时执行一次
    var onlyLaunch: Bool { get }

    /// 执行任务
    func execute(context: BootContext)
}

extension BootTask {
    var onlyLaunch: Bool { return true }
}

class DataTask: BootTask {
    func execute(context: BootContext) {
        // 初始化数据
        DataStore.setup()
    }
}

class AlertTask: BootTask {
    func execute(context: BootContext) {
        // 初始化 alert
        AlertManager.shared.observeScene()
    }
}

class SceneTask: BootTask {
    var onlyLaunch: Bool {
        return false
    }

    func execute(context: BootContext) {
        /// 初始化 scene
        guard let window = context[ContextKey.window] as? UIWindow else {
            return
        }

        if #available(iOS 13.0, *) {
            if let scene = context[ContextKey.scene] as? UIScene,
               let session = context[ContextKey.session] as? UISceneSession,
               let options = context[ContextKey.options] as? UIScene.ConnectionOptions,
               let window = context[ContextKey.window] as? UIWindow {
                window.rootViewController = SceneManager.shared.sceneViewController(
                    scene: scene, session: session, options: options, window: window)
                return
            }
        }

        let navi = UINavigationController(rootViewController: RootViewController())
        window.rootViewController = navi
    }
}

class RegisterSceneTask: BootTask {
    func execute(context: BootContext) {
        if #available(iOS 13.0, *) {
            SceneManager.shared.registerMain { _ in
                let navi = UINavigationController()
                navi.viewControllers = [RootViewController()]
                return navi
            }
            SceneManager.shared.register(config: DetailSceneConfig.self)
            SceneManager.shared.registerCloseAuxSceneKeyCommand()
        }
    }
    @available(iOS 13.0, *)
    class DetailSceneConfig: SceneConfig {
        static var key: String = SceneInfo.Key.detail.rawValue

        static func icon() -> UIImage {
            Resources.iconChat
        }

        static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
            let data = Item(id: sceneInfo.id, title: sceneInfo.title ?? SceneInfo.Key.detail.rawValue,
                            detail: sceneInfo.userInfo["detail"] ?? "")
            let navi = UINavigationController()
            navi.pushViewController(DetailViewController(data: data), animated: true)
            return navi
        }
    }
}

class SceneSwitcherTask: BootTask {
    func execute(context: BootContext) {
        if #available(iOS 13.4, *) {
            SceneSwitcher.shared.isEnabled = true
            KeyCommandKit.addCloseKeyCommands()
        }
    }
}
