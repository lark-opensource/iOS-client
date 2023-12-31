//
//  Scene+CT.swift
//  SKUIKit
//
//  Created by 邱沛 on 2021/1/24.
//

import LarkSceneManager
import SKFoundation
import UniverseDesignToast
import SKResource
import SpaceInterface
import SKInfra

public protocol SceneProvider {
    var objToken: String { get }
    var objType: DocsType { get }
    var docsTitle: String? { get }
    var isSupportedShowNewScene: Bool { get }
    var userInfo: [String: String] { get }
    // 兼容bitable分享表单，需要原始url链接
    var currentURL: URL? { get }
    // 文档版本
    var version: String? { get }
}
extension Scene: DocsExtensionCompatible {}

extension DocsExtension where BaseType: Scene {
    static var key: String { "Docs" }

    public enum CreateWay: String {
        case sys
        case windowClick = "window_click"
        case menuClick = "menu_click"
        case drag
    }

    public static var kCCMSceneInfoTokenKey: String { "kCCMSceneInfoTokenKey" } 

    public static func scene(_ url: String,
                             title: String?,
                             sceneSourceID: String?,
                             objToken: FileListDefine.ObjToken,
                             docsType: DocsType,
                             createWay: CreateWay,
                             userInfo: [String: String] = [:]) -> Scene {
        var sceneInfo = userInfo
        sceneInfo[kCCMSceneInfoTokenKey] = objToken
        return Scene(key: key,
                     id: url,
                     title: title,
                     userInfo: sceneInfo,
                     sceneSourceID: sceneSourceID,
                     windowType: docsType.name,
                     createWay: createWay.rawValue)
    }

    public static func contextualIcon(for scene: Scene) -> UIImage? {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else { return nil }

        guard let objToken = scene.userInfo[kCCMSceneInfoTokenKey] else {
            DocsLogger.error("scene.docs --- failed to get contextual icon, token not found in userInfo")
            return nil
        }
        guard let entry = dataCenterAPI.spaceEntry(objToken: objToken) else {
            DocsLogger.error("scene.docs --- failed to get contextual icon, entry not found")
            return nil
        }
        return entry.colorfulIcon
    }

    public var activity: NSUserActivity {
        SceneTransformer.transform(scene: self.base)
    }
}

extension UIViewController {
    public func prepareNewSceneDragItem(with scene: Scene) -> [UIDragItem] {
        let activity = SceneTransformer.transform(scene: scene)
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(activity, visibility: .all)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    public func openNewScene(with scene: Scene, shouldCheckTopVC: Bool = true) {
        let toastDisplayView: UIView = self.view.window ?? self.view
        SceneManager.shared.active(scene: scene, from: self) { (_, error) in
            if let error = error {
                DocsLogger.error("newScene error: \(error)")
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_iPad_SplitScreenNotSupported_Toast,
                                       on: toastDisplayView)
            }
        }
    }
}
