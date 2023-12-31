//
//  ThreadNavigationBarModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/23.
//

import Foundation
import UIKit

public final class ThreadNavigationBarModule: BaseChatNavigationBarModule {

    private static var normalSubModuleTypes: [BaseNavigationBarRegionModule.Type] = [ThreadNavigationBarLeftModule.self,
                                                                                     ThreadNavigationBarContentModule.self,
                                                                                     ThreadNavigationBarRightModule.self]

    public override var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }

    override class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }

}

/// 话题场景
class ThreadNavigationBarLeftModule: NavigationBarBaseLeftModule {

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

class ThreadNavigationBarRightModule: NavigationBarBaseRightModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.shareItem, .moreItem]
    }

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ThreadNavigationBarContentModule: NavigationBarBaseContentModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}
