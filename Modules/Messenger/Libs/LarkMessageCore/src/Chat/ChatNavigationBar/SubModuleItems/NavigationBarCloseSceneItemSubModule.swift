//
//  NavigationBarCloseSceneItemSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/8.
//

import UIKit
import Foundation
import LarkModel
import LarkOpenChat
import LarkSceneManager
import UniverseDesignIcon
import LarkUIKit

// NavigationBarCloseSceneItemSubModule.Store KV 存储 Key
public enum NavigationBarCloseSceneItemSubModuleStoreKey: String {
    case closeSceneTapped
}

open class NavigationBarCloseSceneItemSubModule: BaseNavigationBarItemSubModule {
    var _items: [ChatNavigationExtendItem] = []

    public override var items: [ChatNavigationExtendItem] {
        return _items
    }

    public var needShowCloseScene: Bool = false {
        didSet {
            guard needShowCloseScene != oldValue else { return }
            self.buildItems()
            self.context.refreshLeftItems()
        }
    }

    private lazy var closeSceneButton: UIButton = {
        let button = UIButton()
        button.addPointerStyle()
        button.addTarget(self, action: #selector(closeSceneButtonClicked(sender:)), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: LarkUIKit.Resources.navigation_close_outlined,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(image, for: .normal)
        return button
    }()

    @objc
    private func closeSceneButtonClicked(sender: UIButton) {
        let vc = self.context.chatVC()
        if #available(iOS 13.0, *) {
           guard let window = vc.view.window,
                 let scene = window.windowScene else {
               assertionFailure()
               return
           }
           let sceneInfo = scene.sceneInfo
           if !sceneInfo.isMainScene() {
               let closeSceneTapped: (() -> Void)? = context.store.getValue(for: NavigationBarCloseSceneItemSubModuleStoreKey.closeSceneTapped.rawValue)
               closeSceneTapped?()
               SceneManager.shared.deactive(scene: sceneInfo)
           }
        } else {
           assertionFailure()
        }
    }

    public override func viewWillAppear() {
        self.needShowCloseScene = self.needShowCloseSceneBarButtonItem()
    }

    public override func viewWillRealRenderSubView() {
        self.needShowCloseScene = self.needShowCloseSceneBarButtonItem()
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.buildItems()
    }

    func buildItems() {
        self._items = []
        if self.needShowCloseScene {
            self._items.append(ChatNavigationExtendItem(type: .closeScene,
                                                        view: self.closeSceneButton))
        }
    }
    /// 是否显示 close 按钮，用于 iPad scene 场景
    func needShowCloseSceneBarButtonItem() -> Bool {
        if Display.phone { return false }
        if #available(iOS 13.0, *) {
            let targetVC = self.context.chatVC()
            if let window = targetVC.currentWindow(),
               let scene = window.windowScene {
                let sceneInfo = scene.sceneInfo
                // 当作为子 scene rootVC 时显示 close
                let isMainScene = sceneInfo.isMainScene()
                let isRootVC = targetVC.navigationController == window.rootViewController &&
                    targetVC.navigationController?.realViewControllers.first == targetVC
                return !isMainScene && isRootVC
            }
        }
        return false
    }
}
