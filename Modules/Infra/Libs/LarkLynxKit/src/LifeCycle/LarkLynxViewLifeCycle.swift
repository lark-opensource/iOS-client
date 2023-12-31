//
//  LarkLynxViewLifeCycle.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation
import Lynx
import ECOProbe


final class LynxContainerMonitorCode: OPMonitorCode {

    static let startLoading = LynxContainerMonitorCode(code: 10001, message: "lynx container start load")

    static let loadFinished = LynxContainerMonitorCode(code: 10002, message: "lynx load success")

    static let firstScreenFinished = LynxContainerMonitorCode(code: 10003, message: "lynx first screen render success")

    static let lynxReceiveError = LynxContainerMonitorCode(code: 10004, message: "lynx load failed")

    init(code: Int, level: OPMonitorLevel = OPMonitorLevelNormal, message: String) {
        super.init(domain: LarkLynxDefines.lynxContainerDomain, code: code, level: level, message: message)
    }
}

final class LarkLynxViewLifeCycle: NSObject, LynxViewLifecycle {
    private var context: LynxContainerContext?
    public init(context: LynxContainerContext?) {
        self.context = context
    }
    
    public func lynxViewDidStartLoading(_ view: LynxView?) {
        OPMonitor(name: LarkLynxDefines.containerLifecycleEvent, code: LynxContainerMonitorCode.startLoading)
            .addCategoryValue(LarkLynxDefines.containerType, self.context?.containerType)
            .addCategoryValue(LarkLynxDefines.traceId, self.context?.bizExtra?["trace_id"])
            .flush()
    }
    
    public func lynxView(_ view: LynxView?, didLoadFinishedWithUrl url: String?) {
        OPMonitor(name: LarkLynxDefines.containerLifecycleEvent, code: LynxContainerMonitorCode.loadFinished)
            .addCategoryValue(LarkLynxDefines.containerType, self.context?.containerType)
            .addCategoryValue(LarkLynxDefines.traceId, self.context?.bizExtra?["trace_id"])
            .flush()
    }
    
    public func lynxView(_ lynxView: LynxView?, onSetup info: [AnyHashable : Any]?) {
        OPMonitor(name: LarkLynxDefines.containerLifecycleEvent, code: LynxContainerMonitorCode.firstScreenFinished)
            .addCategoryValue(LarkLynxDefines.containerType, self.context?.containerType)
            .addCategoryValue(LarkLynxDefines.traceId, self.context?.bizExtra?["trace_id"])
            .addCategoryValue(LarkLynxDefines.timingType, 0)
            .addCategoryValue(LarkLynxDefines.timing, info)
            .flush()
    }

    public func lynxView(_ view: LynxView?, didRecieveError error: Error?) {
        OPMonitor(name: LarkLynxDefines.containerLifecycleEvent, code: LynxContainerMonitorCode.firstScreenFinished)
            .addCategoryValue(LarkLynxDefines.containerType, self.context?.containerType)
            .addCategoryValue(LarkLynxDefines.traceId, self.context?.bizExtra?["trace_id"])
            .addCategoryValue(LarkLynxDefines.errorMsg, self.errorMessage(error: error))
            .addCategoryValue(LarkLynxDefines.errorCode, self.errorCode(error: error))
            .flush()
    }
    
    private func errorMessage(error: Error?) -> String? {
        guard let error = error as? NSError, let messageInfo = error.userInfo["message"] else {
            return nil
        }
        return "\(messageInfo)"
    }
    
    private func errorCode(error: Error?) -> Int {
        guard let error = error as? NSError else {
            return -1
        }
        return error.code
    }
}
