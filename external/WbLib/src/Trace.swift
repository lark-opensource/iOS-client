//
//  Trace.swift
//  WbClient
//
//  Created by kef on 2022/11/15.
//

import Foundation

private func cOnWbTraceEventHandler(cEvent: UnsafePointer<CWbTraceEvent>?) {
    if let cValue = cEvent {
        _onTraceEvent(WbTraceEvent(cValue.pointee))
    }
}

public enum WbTraceEventPhase: Int8 {
    case B = 1
    case E
    case X
    case I
    
    public init(_ cValue: C_WB_TRACE_EVENT_PHASE) {
        switch cValue {
        case C_WB_TRACE_EVENT_PHASE_B:
            self = .B
        case C_WB_TRACE_EVENT_PHASE_E:
            self = .E
        case C_WB_TRACE_EVENT_PHASE_X:
            self = .X
        case C_WB_TRACE_EVENT_PHASE_I:
            self = .I
        default:
            self = .I
        }
    }
}

public struct WbTraceEvent {
    public let name: String
    public let category: String?
    public let phase: WbTraceEventPhase
    public let duration: UInt64?
    public let args: String?
    
    public init(_ cValue: CWbTraceEvent) {
        self.name = String.fromCValue(cValue.name)!
        self.category = String.fromCValue(cValue.category)
        self.phase = WbTraceEventPhase(cValue.phase.pointee)
        
        if let duration = cValue.duration {
            self.duration = duration.pointee
        } else {
            self.duration = nil
        }
        
        self.args = String.fromCValue(cValue.args)
    }
}

/// 白板内部 Trace 事件通过此回调回传到业务侧
///
/// # 参数
///  - `event`: Trace 事件
public typealias WbTraceEventHandler = (WbTraceEvent) -> Void

private var _isTracerSet: Bool = false
private var _onTraceEvent: WbTraceEventHandler = onTraceEventDefault

public func onTraceEventDefault(_ event: WbTraceEvent) {
    print("onTraceEventDefault - \(event)")
}

/// 设置 Trace 事件回调
public func setTraceEventHandler(_ handler: @escaping WbTraceEventHandler) {
    _onTraceEvent = handler
    
    if !_isTracerSet {
        wrap { wb_set_trace_callback(cOnWbTraceEventHandler) }
        _isTracerSet = true
    }
}
