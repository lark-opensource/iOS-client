//
//  IMComposeKeyboardModule.swift
//  LarkChatOpenKeyboard
//
//  Created by liluobin on 2023/4/20.
//

import LarkOpenKeyboard
import LarkModel
import LarkKeyboardView

public class IMComposeKeyboardModule: BaseKeyboardModule<IMComposeKeyboardContext, IMKeyboardMetaModel> {}
public class IMComposeKeyboardPanelModule: BaseKeyboardPanelModule<IMComposeKeyboardContext, IMKeyboardMetaModel> {}

public class IMChatComposeKeyboardModule: IMComposeKeyboardModule {
    private static var normalSubModuleTypes: [BaseKeyboardPlugInModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] = [
        IMChatComposeKeyboardPanelModule.self
    ]

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }
    public override class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMChatComposeKeyboardPanelModule: IMComposeKeyboardPanelModule {

    deinit {
        print("IMChatComposeKeyboardPanelModule deinit")
    }

    public override var itemsOrder: [KeyboardItemKey] {
        return [.emotion, .at, .picture, .canvas, .font, .burnTime]
    }

    private static var normalSubModuleTypes: [BaseKeyboardSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] = []

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMTopicComposeKeyboardModule: IMComposeKeyboardModule {

    private static var normalSubModuleTypes: [BaseKeyboardPlugInModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] = [
        IMTopicComposeKeyboardPanelModule.self
    ]

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }
    public override class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}

public class IMTopicComposeKeyboardPanelModule: IMComposeKeyboardPanelModule {

    public override var itemsOrder: [KeyboardItemKey] {
        return [.emotion, .at, .picture, .canvas, .font, .burnTime]
    }

    private static var normalSubModuleTypes: [BaseKeyboardSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] = []

    public override class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type] {
        return normalSubModuleTypes
    }

    public override class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>.Type) {
        normalSubModuleTypes.append(type)
    }
}
