//
//  Navigator.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/4.
//

import Foundation
import UIKit
import LarkSceneManager

protocol From {
    func fromController() -> UIViewController
}

// 默认策略 在主 scene 进行跳转
struct MainStrategy: From {
    func fromController() -> UIViewController {
        /// 找到主 scene, 这里之后还可以添加一些唤醒主 scene 的逻辑
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { (scene) -> Bool in
                return scene.sceneInfo.key == Scene.mainSceneKey
            }) as? UIWindowScene {
                return scene.windows.first!.rootViewController!.topMost()
            }
        } else {
            if let window = UIApplication.shared.delegate?.window?.map({ $0 }) {
                return window.rootViewController!.topMost()
            }
        }
        assertionFailure()
        return UIViewController()
    }
}

extension UIViewController: From {
    func fromController() -> UIViewController {
        return self
    }
}

extension UIViewController {
    func topMost() -> UIViewController {
        if let present = self.presentedViewController {
            return present.topMost()
        }

        if let navi = self as? UINavigationController,
           let top = navi.topViewController {
            return top.topMost()
        }

        return self
    }
}

class Navigator {
    static func push(vc: UIViewController, from: From = MainStrategy()) {
        from.fromController().navigationController?.pushViewController(vc, animated: true)
    }

    static func pop(from: From = MainStrategy()) {
        from.fromController().navigationController?.popViewController(animated: true)
    }

    static func present(vc: UIViewController, from: From = MainStrategy()) {
        from.fromController().present(vc, animated: true, completion: nil)
    }

    static func dismiss(from: From = MainStrategy()) {
        from.fromController().dismiss(animated: true, completion: nil)
    }
}
