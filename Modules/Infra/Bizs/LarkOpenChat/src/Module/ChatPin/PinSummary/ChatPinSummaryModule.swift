//
//  ChatPinSummaryModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/15.
//

import Foundation
import RustPB
import LarkOpenIM
import LKLoadable
import Swinject

open class ChatPinSummaryModule: Module<ChatPinSummaryContext, ChatPinSummaryMetaModel> {
    override public class var loadableKey: String {
        return "OpenChat"
    }
    
    private static var cellVMTypes: [ChatPinSummaryCellViewModel.Type] = []
    public static func registerCellViewModel(_ type: ChatPinSummaryCellViewModel.Type) {
        #if DEBUG
        if Self.cellVMTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatPinSummaryCellViewModel \(type) has already been registered")
        }
        #endif
        Self.cellVMTypes.append(type)
    }

    private var subModules: [ChatPinSummarySubModule] = []
    private var canHandleSubModules: [ChatPinSummarySubModule] = []

    private static var subModuleTypes: [ChatPinSummarySubModule.Type] = []
    public static func registerSubModule(_ type: ChatPinSummarySubModule.Type) {
        #if DEBUG
        if Self.subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatPinSummarySubModule \(type) has already been registered")
        }
        #endif
        Self.subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatPinSummaryContext) {
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
    public override func handler(model: ChatPinSummaryMetaModel) -> [Module<ChatPinSummaryContext, ChatPinSummaryMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [ChatPinSummarySubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatPinSummaryMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public func setup() {
        self.canHandleSubModules.forEach { $0.setup() }
    }

    public func createCellViewModel(_ metaModel: ChatPinSummaryCellMetaModel) -> ChatPinSummaryCellViewModel? {
        var type: ChatPinSummaryCellViewModel.Type?
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

    public static func parse(pb: RustPB.Im_V1_UniversalChatPin, extras: UniversalChatPinsExtras, context: ChatPinSummaryContext) -> ChatPinPayload? {
        if let type = Self.subModuleTypes.first(where: { $0.type == pb.type }) {
            return type.parse(pindId: pb.id, pb: pb.convert(), extras: extras, context: context)
        }
        if let unknownType =  Self.subModuleTypes.first(where: { $0.type == .unknown }) {
            return unknownType.parse(pindId: pb.id, pb: .unknown(pb.unknownData), extras: extras, context: context)
        }
        return nil
    }
}
