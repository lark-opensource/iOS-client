//
//  TargetPreviewChatNavigationBarModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/23.
//

import Foundation
import UIKit

public final class TargetPreviewChatNavigationBarModule: BaseChatNavigationBarModule {

    private static var normalSubModuleTypes: [BaseNavigationBarRegionModule.Type] = [TargetPreviewChatNavigationBarLeftModule.self,
                                                                                     TargetPreviewChatNavigationBarContentModule.self,
                                                                                     TargetPreviewChatNavigationBarRightModule.self]

    public override var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }

    override class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }
}

////目标预览场景使用
class TargetPreviewChatNavigationBarLeftModule: NavigationBarBaseLeftModule {

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.back, .close]
    }

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class TargetPreviewChatNavigationBarRightModule: NavigationBarBaseRightModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.groupMember]
    }

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class TargetPreviewChatNavigationBarContentModule: NavigationBarBaseContentModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}
