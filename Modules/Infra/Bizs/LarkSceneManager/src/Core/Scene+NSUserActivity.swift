//
//  Scene+NSUserActivity.swift
//  LarkSceneManager
//
//  Created by 李晨 on 2021/1/17.
//

import Foundation

/// scene 转化工具
public final class SceneTransformer {
    static let userInfoKey: String = "scene_info"

    /// scene to NSUserActivity
    public static func transform(scene: Scene) -> NSUserActivity {
        let activity = NSUserActivity(activityType: Scene.sceneActivityType)
        if let jsonInfo = try? JSONEncoder().encode(scene) {
            activity.addUserInfoEntries(from: [userInfoKey: jsonInfo])
        }
        if #available(iOS 13.0, *) {
            activity.targetContentIdentifier = scene.targetContentIdentifier
        }
        return activity
    }

    /// NSUserActivity to scene
    public static func transform(activity: NSUserActivity) -> Scene? {
        guard activity.activityType == Scene.sceneActivityType,
              let jsonInfo = activity.userInfo?[userInfoKey] as? Data else {
            return nil
        }
        guard let scene = try? JSONDecoder().decode(Scene.self, from: jsonInfo) else {
            assertionFailure()
            return nil
        }
        return scene
    }
}
