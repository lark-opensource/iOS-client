//
//  MenuPluginHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/30.
//

import Foundation

/// 插件的操作句柄
final class MenuPluginHandler {
    /// 句柄的代理，最后交给了菜单面板的操作句柄来实现
    weak var operationDelegate: MenuPluginOperationHandler?
}

extension MenuPluginHandler: MenuPanelAdditionViewOperationHandler {
    func updatePanelHeader(for view: MenuAdditionView?) {
        self.operationDelegate?.updatePanelHeader(for: view)
    }

    func updatePanelFooter(for view: MenuAdditionView?) {
        self.operationDelegate?.updatePanelFooter(for: view)
    }
}

extension MenuPluginHandler: MenuPanelItemModelsOperationHandler {
    func updateItemModels(for models: [MenuItemModelProtocol]) {
        self.operationDelegate?.updateItemModels(for: models)
    }

    func resetItemModels(with models: [MenuItemModelProtocol]) {
        self.operationDelegate?.resetItemModels(with: models)
    }

    func removeItemModels(for modelIDs: [String]) {
        self.operationDelegate?.removeItemModels(for: modelIDs)
    }

    func disableCurrentAllItemModels(with: Bool) {
        self.operationDelegate?.disableCurrentAllItemModels(with: with)
    }
}

extension MenuPluginHandler: MenuPanelVisibleOperationHandler {
    func hide(animation: Bool, complete: (() -> Void)?) {
        self.operationDelegate?.hide(animation: animation, complete: complete)
    }

    func show(from sourceView: MenuPanelSourceViewModel, parentPath: MenuBadgePath, animation: Bool, complete: (() -> Void)?) {
        self.operationDelegate?.show(from: sourceView, parentPath: parentPath, animation: animation, complete: complete)
    }
}
