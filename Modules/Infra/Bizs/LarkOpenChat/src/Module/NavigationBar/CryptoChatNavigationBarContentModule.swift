//
//  CryptoChatNavigationBarContentModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/23.
//

import Foundation
import UIKit

public final class CryptoChatNavigationBarModule: BaseChatNavigationBarModule {

    private static var normalSubModuleTypes: [BaseNavigationBarRegionModule.Type] = [CryptoChatNavigationBarLeftModule.self,
                                                                                     CryptoChatNavigationBarContentModule.self,
                                                                                     CryptoChatNavigationBarRightModule.self]

    public override var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }

    override class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }
}

/// 密聊场景
class CryptoChatNavigationBarLeftModule: NavigationBarBaseLeftModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.back, .close, .unread, .closeScene, .fullScreen, .scene]
    }

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class CryptoChatNavigationBarRightModule: NavigationBarBaseRightModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.groupMeetingItem, .phoneItem, .videoItem, .p2pCreateGroup, .addNewMember, .moreItem, .cancel]
    }

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class CryptoChatNavigationBarContentModule: NavigationBarBaseContentModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}
