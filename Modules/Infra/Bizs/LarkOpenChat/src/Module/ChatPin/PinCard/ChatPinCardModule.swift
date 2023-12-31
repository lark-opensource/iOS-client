//
//  ChatPinCardModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkOpenIM
import RustPB
import LKLoadable
import Swinject

public final class ChatPinCardModule: Module<ChatPinCardContext, ChatPinCardMetaModel> {
    override public class var loadableKey: String {
        return "OpenChat"
    }

    private static var cellVMTypes: [ChatPinCardCellViewModel.Type] = []
    public static func registerCellViewModel(_ type: ChatPinCardCellViewModel.Type) {
        #if DEBUG
        if Self.cellVMTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatPinCardCellViewModel \(type) has already been registered")
        }
        #endif
        Self.cellVMTypes.append(type)
    }

    private var subModules: [ChatPinCardSubModule] = []
    private var canHandleSubModules: [ChatPinCardSubModule] = []

    private static var subModuleTypes: [ChatPinCardSubModule.Type] = []
    public static func registerSubModule(_ type: ChatPinCardSubModule.Type) {
        #if DEBUG
        if Self.subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatPinCardSubModule \(type) has already been registered")
        }
        #endif
        Self.subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatPinCardContext) {
        launchLoad()
        Self.subModuleTypes.forEach({ $0.onLoad(context: context) })
        Self.cellVMTypes.forEach({ $0.onLoad(context: context) })
    }

    public override func onInitialize() {
        self.subModules = Self.subModuleTypes
            .filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    public override class func registGlobalServices(container: Container) {
        Self.subModuleTypes.forEach({ $0.registGlobalServices(container: container) })
        Self.cellVMTypes.forEach({ $0.registGlobalServices(container: container) })
    }

    @discardableResult
    public override func handler(model: ChatPinCardMetaModel) -> [Module<ChatPinCardContext, ChatPinCardMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [ChatPinCardSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatPinCardMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public func setup() {
        self.canHandleSubModules.forEach { $0.setup() }
    }

    public func handleAfterParse(pins: [ChatPin], extras: UniversalChatPinsExtras) {
        self.canHandleSubModules.forEach { subModule in
            let payloads = pins
                .filter { $0.type == subModule.type }
                .compactMap { $0.payload }
            subModule.handleAfterParse(pinPayloads: payloads, extras: extras)
        }
    }

    public func createCellViewModel(_ metaModel: ChatPinCardCellMetaModel) -> ChatPinCardCellViewModel? {
        var type: ChatPinCardCellViewModel.Type?
        if let cellVMType = Self.cellVMTypes.first(where: { $0.type == metaModel.pin.type }) {
            type = cellVMType
        } else if let unknownType =  Self.cellVMTypes.first(where: { $0.type == .unknown }) {
            type = unknownType
        }
        guard let type = type else { return nil }
        guard type.canInitialize(context: self.context) else { return nil }
        let cellVM = type.init(context: self.context)
        cellVM.modelDidChange(model: metaModel)
        cellVM.registServices(container: self.context.container)
        return cellVM
    }

    public static func parse(pb: RustPB.Im_V1_UniversalChatPin, extras: UniversalChatPinsExtras, context: ChatPinCardContext) -> ChatPinPayload? {
        if let type = Self.subModuleTypes.first(where: { $0.type == pb.type }) {
            return type.parse(pindId: pb.id, pb: pb.convert(), extras: extras, context: context)
        }
        if let unknownType =  Self.subModuleTypes.first(where: { $0.type == .unknown }) {
            return unknownType.parse(pindId: pb.id, pb: .unknown(pb.unknownData), extras: extras, context: context)
        }
        return nil
    }

    public static func getReuseIdentifiers() -> [String] {
        return Self.cellVMTypes.compactMap { ($0 as? any ChatPinCardRenderAbility.Type)?.reuseIdentifier }
    }
}
