//
//  ChatNavigationBarModule.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/10/12.
//

import Foundation

public final class ChatNavigationBarModule: BaseChatNavigationBarModule {

    private static var normalSubModuleTypes: [BaseNavigationBarRegionModule.Type] = [ChatNavigationBarLeftModule.self,
                                                                                     ChatNavigationBarRightModule.self,
                                                                                     ChatNavigationBarContentModule.self]

    public override var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return ChatNavigationBarModule.normalSubModuleTypes
    }

    override class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }
}

class ChatNavigationBarLeftModule: NavigationBarBaseLeftModule {

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.closeDetail, .back, .close, .unread, .closeScene, .fullScreen, .scene]
    }

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ChatNavigationBarRightModule: NavigationBarBaseRightModule {

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.myAIChatMode, .oncallMiniProgram, .searchItem, .groupMeetingItem,
                .phoneItem, .addNewMember, .p2pCreateGroup, .shareItem,
                .moreItem, .foldItem, .groupMember, .cancel]
    }

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ChatNavigationBarContentModule: NavigationBarBaseContentModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}
