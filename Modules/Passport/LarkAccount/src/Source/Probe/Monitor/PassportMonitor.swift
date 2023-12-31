//
//  PassportMonitor.swift
//  LarkAccount
//
//  Created by au on 2021/10/11.
//

import Foundation
import ECOProbe
import EEAtomic

private struct PassportDelayEvent {
    let code: OPMonitorCodeProtocol
    let eventName: String?
    let categoryValueMap: [String: Any?]?
    let context: UniContextProtocol
    let error: Error?
    let time = Date().timeIntervalSince1970
}

struct PassportMonitorEvent {
    private let opMonitor: OPMonitor

    init(opMonitor: OPMonitor) {
        self.opMonitor = opMonitor
    }

    func flush() {
        self.opMonitor.flush()
    }
}

enum PassportMonitorType {
    case common
    case success
    case failure(Error)
}

final class PassportMonitor {

    static func monitor(_ code: OPMonitorCodeProtocol, type: PassportMonitorType, context: UniContextProtocol, categoryValueMap: [String: Any?]? = nil) -> PassportMonitorEvent {
        let passportMonitorEventName = ProbeConst.monitorEventName
        let monitor = OPMonitor(name: passportMonitorEventName, code: code)
        Self.addCommonParams(monitor: monitor, context: context)
        Self.addContextParams(monitor: monitor, context: context, categoryValueMap: categoryValueMap ?? [:])

        switch type {
        case .common: break
        case .success:
            monitor.setResultTypeSuccess()
        case .failure(let error):
            monitor.setResultTypeFail()
            // 添加错误信息
            monitor.setPassportErrorParams(error: error)
        }

        if let map = categoryValueMap {
            map.forEach {
                monitor.addCategoryValue($0.0, $0.1)
            }
        }

        return PassportMonitorEvent(opMonitor: monitor)
    }

    
    @AtomicObject
    private static var delayEventArray: [PassportDelayEvent] = []
    
    /// 延迟上报OPMonitor Event
    static func delayFlush(_ code: OPMonitorCodeProtocol, eventName: String? = nil, categoryValueMap: [String: Any?]? = nil, context: UniContextProtocol, error: Error? = nil) {
        let event = PassportDelayEvent(code: code, eventName: eventName, categoryValueMap: categoryValueMap, context: context, error: error)
        Self.delayEventArray.append(event)
    }
    
    /// 上报所有延迟event
    public static func flushDelayEvents() {
        
    //可优化:上报时，可能又有新的delayEvent加入，后面直接清空，会导致丢失
        Self.delayEventArray.forEach { event in
            let monitor = Self.monitor(event.code, eventName: event.eventName, categoryValueMap: event.categoryValueMap, context: event.context, error: event.error)
            monitor.setTime(event.time)
            monitor.flush()
        }
        //清空
        Self.delayEventArray = []
    }

    /// 添加通用参数
    private static func addCommonParams(monitor: OPMonitor, context: UniContextProtocol) {
        let helper = PassportProbeHelper.shared

        monitor
            .addCategoryValue(ProbeConst.env, helper.env)
            .addCategoryValue(ProbeConst.deviceID, helper.deviceID)

        monitor.addCategoryValue(ProbeConst.monitorScene, context.from.rawValue)

        // 监控中的 traceID 使用 context 里的
        monitor.addCategoryValue(ProbeConst.traceID, context.trace.traceId)

        // 添加身份信息
        if let cp = helper.contactPoint {
            monitor.addCategoryValue(ProbeConst.contactPoint, cp.encrypted())
        }
        if let userID = helper.userID {
            monitor.addCategoryValue(ProbeConst.userID, userID.encrypted())
            monitor.addCategoryValue(ProbeConst.loginStatus, "login")
        } else {
            monitor.addCategoryValue(ProbeConst.loginStatus, "logout")
        }
        if let tenantID = helper.tenantID {
            monitor.addCategoryValue(ProbeConst.tenantID, tenantID.encrypted())
        }

        // 添加节点信息
        if let step = helper.currentStep {
            monitor.addCategoryValue(ProbeConst.stepName, step)
        }
    }

    /// 添加 context 中包含的参数
    private static func addContextParams(monitor: OPMonitor, context: UniContextProtocol, categoryValueMap: [String: Any?]) {
        guard !context.params.keys.isEmpty else { return }
        context.params.keys.forEach { key in
            if categoryValueMap.keys.contains(where: { $0 == key }) {
                // 自带参数中包含的 key，以自带参数为准，不使用 context 内容
                return
            }
            monitor.addCategoryValue(key, context.params[key])
        }
    }
}

// 旧埋点API，已经废弃，不推荐使用
extension PassportMonitor {
    /// 返回 OPMonitor 对象，需要自行 flush()
    @available(*, deprecated, message: "Will be removed soon, please use new func with 'type'")
    static func monitor(_ code: OPMonitorCodeProtocol, eventName: String? = nil, categoryValueMap: [String: Any?]? = nil, context: UniContextProtocol, error: Error? = nil) -> OPMonitor {
        let monitor = OPMonitor(name: eventName, code: code)
        Self.addCommonParams(monitor: monitor, context: context)
        Self.addContextParams(monitor: monitor, context: context, categoryValueMap: categoryValueMap ?? [:])

        if let error = error {
            _ = monitor.setPassportErrorParams(error: error)
        }

        guard let map = categoryValueMap else {
            return monitor
        }
        map.forEach {
            monitor.addCategoryValue($0.0, $0.1)
        }
        return monitor
    }

    /// 创建 OPMonitor 对象，在组装完成后内部会执行 flush()，请确认上报的 eventName
    @available(*, deprecated, message: "Will be removed soon, please use func monitor with 'type'")
    static func flush(_ code: OPMonitorCodeProtocol, eventName: String? = nil, categoryValueMap: [String: Any?]? = nil, context: UniContextProtocol, error: Error? = nil) {
        let monitor = Self.monitor(code, eventName: eventName, categoryValueMap: categoryValueMap, context: context, error: error)
        monitor.flush()
    }
}

extension OPMonitor {
    @discardableResult
    func setPassportErrorParams(error: Error) -> OPMonitor {
        // 错误信息的默认值
        var code = ProbeConst.commonInternalErrorCode
        var errorMessage = error.localizedDescription
        var bizCode = "-9999"

        var loginError = error
        if let error = error as? EventBusError {
            if case .internalError(let v3loginError) = error {
                loginError = v3loginError
            }
        }

        // 尝试转换成LoginError获取更多信息
        if let error = loginError as? V3LoginError {
            if case .badServerCode(let info) = error {
                code = String(info.rawCode)
                bizCode = String(info.bizCode ?? -9999)
                errorMessage = info.message
            } else {
                code = String(error.errorCode)
                errorMessage = error.errorDescription ?? error.localizedDescription
            }
        }

        self.setErrorCode(code)
        self.addCategoryValue("biz_code", bizCode)
        self.setErrorMessage(errorMessage.desensitizeCredential())

        return self
    }

    @discardableResult
    func setUserOperationError(with error: ProbeUserOperationError) -> OPMonitor {
        self.setErrorCode(error.errorCode)
        self.setErrorMessage(error.errorMsg)

        return self
    }
}
