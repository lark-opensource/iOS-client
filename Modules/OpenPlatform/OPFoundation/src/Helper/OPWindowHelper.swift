//
//  OPWindowHelper.swift
//  OPFoundation
//
//  Created by yinyuan on 2021/1/15.
//

import Foundation
import LarkSceneManager

@objcMembers
public final class OPWindowHelper: NSObject {
    
    public static func fincMainSceneWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            if let scene = findMainScene(),
               let delegate = scene.delegate as? UIWindowSceneDelegate,
               let window = delegate.window ?? scene.windows.first
            {
                return window
            }
        }

        return UIApplication.shared.delegate?.window?.map({ $0 }) ?? UIApplication.shared.windows.first
    }

    @available(iOS 13.0, *)
    public static func findMainScene() -> UIWindowScene? {
        if let scene = SceneManager.shared.windowApplicationScenes.first(where: { (scene) -> Bool in
            /// 我们默认 name 为 "Default" 为主 scene
            if scene is UIWindowScene,
               scene.session.configuration.name == "Default" {
                return true
            }
            return false
        }) as? UIWindowScene {
            return scene
        } else if let scene = SceneManager.shared.windowApplicationScenes.first as? UIWindowScene {
            return scene
        }
        return nil
    }

    /// 查找一个给定Scene的主window
    @available(iOS 13.0, *)
    public static func findSceneMainWindow(_ scene: UIWindowScene) -> UIWindow? {
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
           let window = delegate.window {
            return window
        }
        
        if !scene.windows.isEmpty {
            return scene.windows.first
        }
        // 兜底，如果最后没有找的Scene对应的主窗口，则返回整个应用程序的主窗口
        return fincMainSceneWindow()
    }
    
}

