//
//  NavigationMenuInterceptionService.swift
//  SKBrowser
//
//  Created by ByteDance on 2023/6/7.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import LarkContainer
import SKResource
import UniverseDesignIcon
import LarkUIKit

class NavigationMenuInterceptionService: BaseJSService {
    
    typealias MenuInfo = NavigationMenuService.MenuInfo
    
    private var menuInfoDict = ThreadSafeDictionary<String, MenuInfo>()
    
    /// 更新现有的[MenuInfo]
    func updateMenuInfo(current: [MenuInfo]) -> [MenuInfo] { //TODO.chensi 更通用的排序方式
        var newMenuInfos = current
        if let index = current.firstIndex(where: { $0.naviBarID == .more || $0.naviBarID == .forward }) {
            let items = self.getAllMenuInfo()
            newMenuInfos.insert(contentsOf: items, at: index + 1)
        }
        return newMenuInfos
    }
}

extension NavigationMenuInterceptionService {
    
    /// 注册MenuInfo
    private func registerMenuInfo(menuInfo: MenuInfo, for id: String) {
        menuInfoDict.updateValue(menuInfo, forKey: id)
    }
    
    /// 移除MenuInfo
    private func removeMenuInfo(for id: String) {
        menuInfoDict.removeValue(forKey: id)
    }
    
    private func getAllMenuInfo() -> [MenuInfo] {
        let values = menuInfoDict.all().map { $1 }
        return values
    }
}

extension NavigationMenuInterceptionService: DocsJSServiceHandler {
    
    var handleServices: [DocsJSService] {
        []
    }
    
    func handle(params: [String: Any], serviceName: String) {
        
    }
}

// MARK: AI 分会话业务

extension NavigationMenuInterceptionService {
    
    func registerAIChatModeMenuInfo(callback: @escaping () -> ()) {
        let info = createAIChatModeMenuInfo(callback: callback)
        self.registerMenuInfo(menuInfo: info, for: info.id)
    }
    
    func removeAIChatModeMenuInfo() {
        self.removeMenuInfo(for: self.aiChatModeMenuId)
    }
    
    private func createAIChatModeMenuInfo(callback: @escaping () -> ()) -> MenuInfo {
        let service = try? Container.shared.resolve(assert: CCMAILaunchBarService.self)
        let image = service?.getQuickLaunchBarAIItemInfo().value ?? UDIcon.myaiColorful
        let udSize = CGSize(width: 24, height: 24) // UDIcon的默认尺寸
        let info = MenuInfo(
            id: self.aiChatModeMenuId,
            iconID: nil,
            naviBarID: .aiChatMode,
            text: nil,
            image: image.getResizeImageBySize(udSize),
            disabled: false,
            selected: nil,
            customColorMapping: nil,
            useOriginImageRendering: true,
            badgeStyle: nil,
            callback: callback
        )
        return info
    }
    
    private var aiChatModeMenuId: String { "AI_CHATMODE" }
}
