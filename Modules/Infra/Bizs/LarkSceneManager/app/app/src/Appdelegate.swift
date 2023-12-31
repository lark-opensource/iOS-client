//
//  AppDelegate.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/2.
//

import Foundation
import UIKit
import LKLoadable

/*
 本 demo 共有三个页面

 RootViewController 用于展示数据  done
 DetailViewController 用于展示某一条数据 详情  done
 CreateViewController 用于创建一条新的的数据   done

 其中会涉及 scene 的创建/更新/激活/删除 等等操作  done

 对应新增以及旧有生命周期会发出对应日志 done

 只在某一 scene 展示的 alert  done

 会涉及灰度开关选项  done

 会涉及一些简化的启动流程 done

 简单的 路由适配  done

 会涉及 openURL TODO

 会涉及 通知响应  TODO

 其他废弃 API 的使用
 */

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        print("applicationWillFinishLaunchingWithOptions")

        // 注入启动任务
        BootManager.shared.register(task: DataTask())
        BootManager.shared.register(task: AlertTask())
        BootManager.shared.register(task: RegisterSceneTask())
        BootManager.shared.register(task: SceneTask())
        BootManager.shared.register(task: SceneSwitcherTask())

        LKLoadableManager.run(LoadableState(rawValue: 0))
        LKLoadableManager.run(LoadableState(rawValue: 1))
        LKLoadableManager.run(LoadableState(rawValue: 2))
        LKLoadableManager.run(didFinishLaunch)

        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("applicationDidFinishLaunchingWithOptions")

        var supportsMultipleScenes: Bool = false

        if #available(iOS 13.0, *) {
            supportsMultipleScenes = UIApplication.shared.supportsMultipleScenes
        }

        if !supportsMultipleScenes {
            let window = UIWindow()
            window.makeKeyAndVisible()
            self.window = window
            BootManager.shared.launch(context: [ContextKey.window: window])
        }

        return true
    }


    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default", sessionRole: .windowApplication)
        config.delegateClass = SceneDelegate.self
        return config
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("applicationDidDiscardSceneSessions")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
    }
}
