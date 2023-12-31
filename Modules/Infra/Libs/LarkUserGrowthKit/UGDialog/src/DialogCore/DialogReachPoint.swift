//
//  DialogReachPoint.swift
//  UGDialog
//
//  Created by liuxianyu on 2021/11/26.
//

import Foundation
import UGContainer
import ServerPB
import LKCommonsLogging

public protocol DialogReachPointDelegate: AnyObject {
    func onShow(dialogReachPoint: DialogReachPoint)
}

public final class DialogReachPoint: BasePBReachPoint {
    static let log = Logger.log(DialogReachPoint.self, category: "UGReach.Dialog")

    public typealias ReachPointModel = ServerPB_Ug_reach_material_DialogMaterial

    public static var reachPointType: ReachPointType = "Dialog"

    public weak var delegate: DialogReachPointDelegate? {
        didSet {
            if delegate != nil {
                self.reportEvent(ReachPointEvent(eventName: .onReady,
                                                 reachPointType: DialogReachPoint.reachPointType,
                                                 reachPointId: reachPointId,
                                                 extra: [:]))
            }
        }
    }

    public let handlerRegistry = DialogHandlerRegistry()
    public var dialogData: UGDialogInfo?

    required public init() {
    }

    public func register(dialogName: String, for handler: UGDialogHandler) {
        handlerRegistry.register(dialogName: dialogName, for: handler)
    }

    public func onUpdateData(data: ReachPointModel) -> Bool {
        self.dialogData = data
        return true
    }

    public func onShow() {
        Self.log.info("Dialog show data is empty: \(self.dialogData == nil)")
        guard let dialogData = self.dialogData else {
            return
        }
        delegate?.onShow(dialogReachPoint: self)
    }

    public func onHide() {
        Self.log.info("Dialog hide data is empty: \(self.dialogData == nil)")
        guard let dialogData = self.dialogData else {
            return
        }
        reportEvent(eventName: .didHide)
    }

    public func reportShow() {
        /// 需要业务主动调用，内部埋点，上报事件
        reportEvent(eventName: .didShow)
    }

    public func reportClosed() {
        reportEvent(eventName: .consume)
    }

    public func reportEvent(eventName: ReachPointEvent.Key) {
        reportEvent(ReachPointEvent(eventName: eventName,
                                    reachPointType: Self.reachPointType,
                                    reachPointId: reachPointId,
                                    materialKey: self.dialogData?.base.key,
                                    materialId: self.dialogData?.base.id,
                                    extra: [:]))
    }
}
