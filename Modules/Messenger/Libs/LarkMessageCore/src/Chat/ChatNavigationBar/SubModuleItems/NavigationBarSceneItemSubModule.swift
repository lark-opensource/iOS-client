//
//  NavigationBarSceneItemSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/8.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkOpenChat
import LarkSceneManager
import UniverseDesignIcon
import LarkSplitViewController

open class NavigationBarSceneItemSubModule: BaseNavigationBarItemSubModule {

    public var chat: Chat?

    var _items: [ChatNavigationExtendItem] = []
    public override var items: [ChatNavigationExtendItem] {
        return _items
    }

    /// 是否应该显示 scene 按钮
    public var needShowScene: Bool = false {
        didSet {
            guard needShowScene != oldValue else { return }
            buildItem()
            self.context.refreshLeftItems()
        }
    }

    private lazy var sceneButton: UIView = {
        let sceneButtonItem = SceneButtonItem(clickCallBack: { [weak self] (_) in
            self?.clickSceneItemClicked(sender: UIButton())
        }, sceneKey: getSceneKey(), sceneId: getSceneId())
        sceneButtonItem.targetVC = context.chatVC()
        sceneButtonItem.snp.makeConstraints { make in
            make.height.width.equalTo(24)
        }
        sceneButtonItem.addDefaultPointer()
        return sceneButtonItem
    }()

    open override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.chat = metaModel.chat
        self.buildItem()
    }

    func buildItem() {
        _items = []
        guard SceneManager.shared.supportsMultipleScenes else {
            return
        }
        if needShowScene {
            _items.append(ChatNavigationExtendItem(type: .scene, view: self.sceneButton))
        }
    }
    /// 获取要创建的 scene的id
    open func getSceneId() -> String {
        return ""
    }
    /// 获取要创建的 scene的key
    open func getSceneKey() -> String {
        return ""
    }

    open override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.chat = model.chat
    }
    open override func viewWillAppear() {
        self.needShowScene = self.needShowSceneButtonItem()
    }

    open override func viewWillRealRenderSubView() {
        self.needShowScene = self.needShowSceneButtonItem()
    }
    /// 是否显示 scene 按钮，用于 iPad scene 场景
    open func needShowSceneButtonItem() -> Bool {
        if Display.phone { return false }
        if #available(iOS 13.0, *) {
            let targetVC = self.context.chatVC()
            if let window = targetVC.currentWindow(),
               let scene = window.windowScene {
                let sceneInfo = scene.sceneInfo
                // 当前 scene 不是本会话 scene
                return sceneInfo.targetContentIdentifier != targetVC.sceneTargetContentIdentifier
            }
        }
        return false
    }

    @objc
    open func clickSceneItemClicked(sender: UIButton) {
    }
}
