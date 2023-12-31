//
//  Scene+Info.swift
//  LarkSceneManager
//
//  Created by 李晨 on 2021/1/17.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
extension UIScene {
    private struct AssociatedKeys {
        static var sceneInfoKey = "scene.info.key.tag"
        static var sceneRefreshKey = "scene.refresh.key.tag"
        static var sceneClickDeleteKey = "scene.click.deleta.tag"
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var sceneTargetContentIdentifier = "scene.target.content.identifier.tag"
    }
}

@available(iOS 13.0, *)
extension UIScene {
    public var sceneInfo: Scene {
        set {
            innerSceneInfo = newValue
        }
        get {
            let sessionName = session.configuration.name ?? ""
            var scene = (sessionName == "Default") ? Scene.mainScene() : Scene.invalidScene()
            /// iPhone Scene name delegate 都为nil
            /// iPad 应该按照name区分
            if !SceneManager.shared.supportsMultipleScenes {
                scene = Scene.mainScene()
            }
            return innerSceneInfo ?? scene
        }
    }

    var innerSceneInfo: Scene? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sceneInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sceneInfoKey) as?
                Scene
        }
    }

    var refreshd: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sceneRefreshKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sceneRefreshKey) as?
                Bool ?? false
        }
    }

    var isClickDelete: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sceneClickDeleteKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sceneClickDeleteKey) as?
                Bool ?? false
        }
    }
}

extension UIViewController {
    public var sceneTargetContentIdentifier: String {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sceneTargetContentIdentifier, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sceneTargetContentIdentifier) as?
                String ?? ""
        }
    }
}
