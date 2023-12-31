//
//  Extension+Top.swift
//  EENavigator
//
//  Created by 李晨 on 2021/1/8.
//

import UIKit
import Foundation

extension UIApplication {
    @available(iOS 13.0, *)
    public var windowApplicationScenes: [UIScene] {
        return UIApplication.shared.connectedScenes.filter {
            $0.session.role == .windowApplication
        }
    }
}

extension Navigatable {

    @available(iOS 13.0, *)
    public var windowApplicationScenes: [UIScene] {
        return UIApplication.shared.connectedScenes.filter {
            $0.session.role == .windowApplication
        }
    }

    /// 获取 main Scene
    @available(iOS 13.0, *)
    public var mainScene: UIWindowScene? {
        guard globalValid() else { return nil }
        let scene = windowApplicationScenes.first { (scene) -> Bool in
            return scene.session.configuration.name == "Default"
        } ?? windowApplicationScenes.first
        return scene as? UIWindowScene
    }

    /// 获取 main Scene rootWindow
    public var mainSceneWindow: UIWindow? {
        guard globalValid() else { return  nil }
        if #available(iOS 13.0, *) {
            if let windowScene = self.mainScene,
               let delegate = windowScene.delegate as? UIWindowSceneDelegate {
                return delegate.window?.map({ $0 })
            }
        }
        return UIApplication.shared.delegate?.window?.map({ $0 })
    }

    /// 获取 main Scene windows
    public var mainSceneWindows: [UIWindow] {
        guard globalValid() else { return [] }
        if #available(iOS 13.0, *) {
            if let windowScene = self.mainScene {
                return windowScene.windows
            }
        }
        return UIApplication.shared.windows
    }

    /// 获取 main Scene topmost vc
    public var mainSceneTopMost: UIViewController? {
        guard let window = mainSceneWindow,
              let root = window.rootViewController else {
            return nil
        }
        return UIViewController.topMost(of: root, checkSupport: true)
    }

    /// 获取主scene对应的navigationController
    public var navigation: UINavigationController? {
        guard globalValid() else { return nil }
        return Navigator.shared.navigationProvider?()
    }
}
