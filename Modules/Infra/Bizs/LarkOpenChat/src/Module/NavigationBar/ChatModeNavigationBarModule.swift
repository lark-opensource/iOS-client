//
//  ChatModeNavigationBarModule.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2023/11/22.
//

import Foundation

/// 分会场场景，定制导航栏
public final class ChatModeNavigationBarModule: BaseChatNavigationBarModule {

    private static var normalSubModuleTypes: [BaseNavigationBarRegionModule.Type] = [ChatModeNavigationBarLeftModule.self,
                                                                                     ChatModeNavigationBarRightModule.self,
                                                                                     ChatModeNavigationBarContentModule.self]

    public override var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return ChatModeNavigationBarModule.normalSubModuleTypes
    }

    override class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }
}

class ChatModeNavigationBarLeftModule: NavigationBarBaseLeftModule {
    /// 相对于Chat，少了unread，分会场不显示未读数
    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.back, .close, .closeScene, .fullScreen, .scene]
    }

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ChatModeNavigationBarRightModule: NavigationBarBaseRightModule {
    /// 导航右侧目前没有任何按钮
    override var itemsOrder: [ChatNavigationExtendItemType] {
        return []
    }

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ChatModeNavigationBarContentModule: NavigationBarBaseContentModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}
