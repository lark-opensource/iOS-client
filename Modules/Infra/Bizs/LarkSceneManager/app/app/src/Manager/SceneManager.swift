////
////  SceneManager.swift
////  SceneDemo
////
////  Created by 李晨 on 2021/1/3.
////
//
//import Foundation
//import UIKit
//
/// 一个简单的 scen 数据结构
struct SceneInfo {
    enum Key: String, CaseIterable {
        case normal = "Default"
        case detail = "Detail"
        case create = "Create"
    }

    /// 用于指定 scene 场景
    var key: Key
    /// 用于区分同一场景的不同 页面
    var id: String = ""
    /// 用于携带 scene 相关信息
    var info: [String: Any]
}
//
///// 用于管理 scene
//public struct SceneManager {
//
//    // 判断是否支持多
//    static let supportsMultipleScenes: Bool = {
//        if #available(iOS 13.0, *) {
//            return UIApplication.shared.supportsMultipleScenes &&
//                UIDevice.current.userInterfaceIdiom == .pad &&
//                ssupportsMultipleScenes()
//        } else {
//            return false
//        }
//    }()
//
//    /// 更新方法 下次启动生效
//    static func update(supportsMultipleScenes: Bool) {
//        UserDefaults.standard.set(supportsMultipleScenes, forKey: "supportsMultipleScenes")
//    }
//
//    //// 内部保存是否支持多任务
//    static func ssupportsMultipleScenes() -> Bool {
//        if UserDefaults.standard.object(forKey: "supportsMultipleScenes") == nil {
//            return true
//        }
//        return UserDefaults.standard.bool(forKey: "supportsMultipleScenes")
//    }
//
//    /// 激活 scene
//    static func active(scene: Scene) {
//        if #available(iOS 13.0, *) {
//            /// 寻找已经存在的 scene
//            if let sscene = UIApplication.shared.connectedScenes.first(where: { (sscene) -> Bool in
//                let activityType = sscene.userActivity?.activityType ?? Scene.Key.normal.rawValue
//                let id: String = (sscene.userActivity?.userInfo?["id"] as? String) ?? ""
//                return activityType == scene.key.rawValue && id == scene.id
//            }) {
//                UIApplication.shared.requestSceneSessionActivation(sscene.session, userActivity: nil, options: nil) { (error) in
//                    print("requestSceneSessionActivation active old failed \(error)")
//                }
//            }
//            /// 创建新的 scene
//            else {
//                let activity = NSUserActivity.init(activityType: scene.key.rawValue)
//                var userInfo = scene.info
//                if !scene.id.isEmpty {
//                    userInfo["id"] = scene.id
//                }
//                activity.userInfo = userInfo
//
//                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { (error) in
//                    print("requestSceneSessionActivation create new failed \(error)")
//                }
//            }
//        }
//    }
//
//    // 关闭 scene
//    static func deactive(vc: UIViewController) {
//        if #available(iOS 13.0, *) {
//            guard let scene = vc.view.window?.windowScene else {
//                return
//            }
//            UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil) { (error) in
//                print("requestSceneSessionDestruction failed \(error)")
//            }
//        }
//    }
//
//    @available(iOS 13.0, *)
//    static func connect(
//        scene: UIScene,
//        session: UISceneSession,
//        options connectionOptions: UIScene.ConnectionOptions
//    ) -> UIViewController {
//        /// 读取相关信息
//        var activity: NSUserActivity?
//        connectionOptions.userActivities.forEach { (aactivity) in
//            if Scene.Key.allCases.compactMap({ $0.rawValue }).contains(aactivity.activityType) {
//                activity = aactivity
//            }
//        }
//        scene.userActivity = activity ?? session.stateRestorationActivity
//
//        let activityType = scene.userActivity?.activityType ?? Scene.Key.normal.rawValue
//        let id: String = (scene.userActivity?.userInfo?["id"] as? String) ?? ""
//
//        // 设置 title
//        scene.title = activityType
//
//        /// 如果没有开启多任务 fg，则直接关闭其他多有 scne, 只保留一个
//        if !SceneManager.supportsMultipleScenes {
//            UIApplication.shared.openSessions.forEach { (session) in
//                guard session != scene.session else { return }
//                UIApplication.shared.requestSceneSessionDestruction(session, options: nil, errorHandler: nil)
//            }
//        } else {
//            /// 删除重复的 scene
//            UIApplication.shared.openSessions.forEach { (ssession) in
//                guard ssession != scene.session else { return }
//
//                let aactivityType = ssession.scene?.userActivity?.activityType ?? Scene.Key.normal.rawValue
//                let iid: String = (ssession.scene?.userActivity?.userInfo?["id"] as? String) ?? ""
//
//                /// 场景和id共同决定是否相等，如果相等则销毁上一个 scene
//                if aactivityType == activityType &&
//                    id == iid {
//                    UIApplication.shared.requestSceneSessionDestruction(ssession, options: nil, errorHandler: nil)
//                }
//            }
//        }
//        // 判断当前 scene 是否仍然合法
//        var needDestruction = false
//
//        var vc: UIViewController
//        switch activityType {
//        case Scene.Key.detail.rawValue:
//            if let data = DataStore.fetch().first(where: { (item) -> Bool in
//                return item.id == id
//            }) {
//                vc = DetailViewController(data: data)
//            } else {
//                needDestruction =  true
//                vc = RootViewController()
//            }
//        case Scene.Key.create.rawValue:
//            vc = CreateViewController()
//        default:
//            vc = RootViewController()
//        }
//
//        if needDestruction {
//            UIApplication.shared.requestSceneSessionDestruction(session, options: nil, errorHandler: nil)
//        }
//
//        return UINavigationController(rootViewController: vc)
//    }
//}
