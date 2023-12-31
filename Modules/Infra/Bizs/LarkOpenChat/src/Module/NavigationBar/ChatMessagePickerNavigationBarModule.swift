//
//  ChatMessagePickerNavigationBarModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/23.
//

import Foundation
import UIKit

public final class ChatMessagePickerNavigationBarModule: BaseChatNavigationBarModule {

    private static var normalSubModuleTypes: [BaseNavigationBarRegionModule.Type] = [ChatMessagePickerNavigationBarLeftModule.self,
                                                                                     ChatMessagePickerNavigationBarContentModule.self,
                                                                                     ChatMessagePickerNavigationBarRightModule.self]

    public override var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }

    override class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return Self.normalSubModuleTypes
    }
}

/// messagePicker场景
class ChatMessagePickerNavigationBarLeftModule: NavigationBarBaseLeftModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override var itemsOrder: [ChatNavigationExtendItemType] {
        return [.back, .close, .closeScene, .fullScreen, .scene]
    }

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ChatMessagePickerNavigationBarRightModule: NavigationBarBaseRightModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}

class ChatMessagePickerNavigationBarContentModule: NavigationBarBaseContentModule {

    private static var normalSubModuleTypes: [BaseNavigationBarSubModule.Type] = []

    override class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return normalSubModuleTypes
    }

    override class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        normalSubModuleTypes.append(type)
    }
}
