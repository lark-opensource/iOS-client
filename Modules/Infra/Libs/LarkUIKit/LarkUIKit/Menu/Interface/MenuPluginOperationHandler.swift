//
//  MenuPluginOperationHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/30.
//

import Foundation

// 插件的操作句柄，它具有附加视图和数据模型操作能力
public typealias MenuPluginOperationHandler = MenuPanelItemModelsOperationHandler & MenuPanelAdditionViewOperationHandler & MenuPanelVisibleOperationHandler
