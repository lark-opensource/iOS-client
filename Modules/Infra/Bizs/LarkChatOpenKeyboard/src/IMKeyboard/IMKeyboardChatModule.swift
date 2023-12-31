//
//  IMKeyboardTestModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/19.
//

import UIKit
import LarkOpenKeyboard
import LarkModel
import LarkKeyboardView
import LarkOpenIM
public class IMKeyboardMetaModel: KeyboardMetaModel {
    public let chat: Chat
    public init(chat: Chat) {
        self.chat = chat
    }
}

public class IMKeyboardModule: BaseKeyboardModule<KeyboardContext, IMKeyboardMetaModel> {}

public class IMKeyboardPanelModule: BaseKeyboardPanelModule<KeyboardContext, IMKeyboardMetaModel> {}

public class IMChatKeyboardModule: IMKeyboardModule {

    private static var normalSubModuleTypes: [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] = [
        IMChatKeyboardPanelModule.self
    ]

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }

    public func setPanelItemsOrderBlock(_ itemsOrderBlock: (() -> [KeyboardItemKey])?) {
        (self.getKeyboardPanelModule() as? IMChatKeyboardPanelModule)?.itemsOrderBlock = itemsOrderBlock
    }

    public func setPanelWhiteListBlock(_ whiteListBlock: (() -> [KeyboardItemKey]?)?) {
        (self.getKeyboardPanelModule() as? IMChatKeyboardPanelModule)?.whiteListBlock = whiteListBlock
    }
}

public class IMChatKeyboardPanelModule: IMKeyboardPanelModule {

    /// 这里其实是可以直接判断的!Display.pad 但是LarkUIKit太杂了
    /// 业务上层会进行传值，不需要关心
    public static var getkeyboardNewStyleEnable: (() -> Bool)?

    var itemsOrderBlock: (() -> [KeyboardItemKey])?

    public override var itemsOrder: [KeyboardItemKey] {
        if let itemsOrderBlock = self.itemsOrderBlock { return itemsOrderBlock() }
        if Self.getkeyboardNewStyleEnable?() == true {
            return [.emotion, .at, .picture, .voice, .canvas, .font, .burnTime, .more]
        } else {
            return [.emotion, .at, .voice, .picture, .canvas, .font, .burnTime, .more]
        }
    }

    var whiteListBlock: (() -> [KeyboardItemKey]?)?

    public override var whiteList: [KeyboardItemKey]? {
        if let whiteListBlock = self.whiteListBlock { return whiteListBlock() }
        return nil
    }

    private static var normalSubModuleTypes: [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] = []

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMCryptoChatKeyboardModule: IMKeyboardModule {
    private static var normalSubModuleTypes: [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] = [
        IMCryptoChatKeyboardPanelModule.self
    ]

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }
    public override class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMCryptoChatKeyboardPanelModule: IMKeyboardPanelModule {

    /// 这里其实是可以直接判断的!Display.pad 但是LarkUIKit太杂了，上层传值吧
    public static var getkeyboardNewStyleEnable: (() -> Bool)?

    public override var itemsOrder: [KeyboardItemKey] {
        if Self.getkeyboardNewStyleEnable?() == true {
            return [.emotion, .at, .picture, .voice, .cryptoBurnTime, .more]
        } else {
            return [.emotion, .at, .voice, .picture, .cryptoBurnTime, .more]
        }
    }

    private static var normalSubModuleTypes: [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] = []

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}


public class IMThreadKeyboardModule: IMKeyboardModule {
    private static var normalSubModuleTypes: [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] = [
        IMThreadKeyboardPanelModule.self
    ]

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }
    public override class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMThreadKeyboardPanelModule: IMKeyboardPanelModule {

    public override var itemsOrder: [KeyboardItemKey] {
        return [.emotion, .at, .voice, .picture, .font, .canvas]
    }

    private static var normalSubModuleTypes: [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] = []

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMMessageThreadKeyboardModule: IMKeyboardModule {
    private static var normalSubModuleTypes: [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] = [
        IMMessageThreadKeyboardPanelModule.self
    ]

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }
    public override class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMMessageThreadKeyboardPanelModule: IMKeyboardPanelModule {
    public override var itemsOrder: [KeyboardItemKey] {
        return [.emotion, .at, .voice, .picture, .font, .canvas]
    }

    private static var normalSubModuleTypes: [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] = []

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<KeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}
