//
//  MailAPMHelperExt.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/9.
//

import Foundation
import AppReciableSDK

// MARK: - APMEventKey
private struct APMEventKey {
    internal let apmEventType: Any.Type
    internal let name: String?

    internal init(apmEventType: Any.Type, name: String? = nil) {
        self.apmEventType = apmEventType
        self.name = name
    }
}

// MARK: Hashable
extension APMEventKey: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(apmEventType))
        hasher.combine(name?.hashValue ?? 0)
    }
}

// MARK: Equatable
fileprivate func == (lhs: APMEventKey, rhs: APMEventKey) -> Bool {
    return lhs.apmEventType == rhs.apmEventType
        && lhs.name == rhs.name
}

final class MailAPMEventHolder {
    private var events = ThreadSafeDictionary<APMEventKey, MailAPMMonitorable>()

    func store<Event>(object: Event?) {
        let key = APMEventKey(apmEventType: Event.self)
        guard let monitorable = object as? MailAPMMonitorable else {
            assert(false, "you can only store monitorable obejct")
            return
        }
        if let old = events[key], let property = old as? MailAPMEventPropery {
            if property.status != .isInvalid {
//                assert(false, "r you sure you want to set a new Event. before old event is has been invalided?")
                MailLogger.log(level: .info,
                               message: "MailAPMEventHolder store new object:\(String(describing: object)), but old still available :\(old)")
                MailAPMMonitorService.offTrack(event: monitorable.endKey,
                                               type: .type_repeat_start, message: nil)
            }
        }
        events[key] = monitorable
    }

    func remove<Event>(type: Event.Type) {
        let key = APMEventKey(apmEventType: Event.self)
        events[key] = nil
    }

    func getEvent<Event>(type: Event.Type) -> Event? {
        let key = APMEventKey(apmEventType: Event.self)
        if let monitorable = events[key] {
            if let property = monitorable as? MailAPMEventPropery, property.status == .isInvalid {
                MailLogger.debug("event has been invalid \(self)")
                events.removeValue(forKey: key)
                return nil
            }
            if let event = monitorable as? Event {
                return event
            } else {
                assert(false, "shit! some bad thing happen. please @liutefeng")
            }
        }
        return nil
    }
}

// MARK: MailAPMEventHolder 下标
extension MailAPMEventHolder {
    subscript<Event>(key: Event.Type) -> Event? {
        get {
            return self.getEvent(type: Event.self)
        }
        set(newValue) {
            if let value = newValue {
                self.store(object: value)
            } else {
                self.remove(type: Event.self)
            }
        }
    }
}

// MARK: add holder for all VC
private var kEventHolder: Void?
protocol MailApmHolderAble {
    var apmHolder: MailAPMEventHolder { get }
}

extension MailApmHolderAble {
    var apmHolder: MailAPMEventHolder {
        if let holder = objc_getAssociatedObject(self, &kEventHolder) as? MailAPMEventHolder {
            return holder
        } else {
            let holder = MailAPMEventHolder()
            objc_setAssociatedObject(self, &kEventHolder, holder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return holder
        }
    }
}

extension UIViewController: MailApmHolderAble {}

// MARK: deallock hook for default userLeave
final class EventDeallocator {
    var closure: () -> Void

    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    /// call closure when release
    deinit {
        closure()
    }
}

// MARK: param helper
extension Array where Element == MailAPMEventParamAble {
    mutating func appendError(errorCode: Int?, errorMessage: String?) {
        if let code = errorCode {
            self.append(MailAPMEventConstant.CommonParam.error_code(code))
        }
        if let msg = errorMessage {
            self.append(MailAPMEventConstant.CommonParam.debug_message(msg))
        }
    }

    mutating func appendError(error: Error?) {
        appendError(errorCode: error?.mailErrorCode, errorMessage: "\(error?.debugMessage ?? "")-\(error?.localizedDescription)")
    }
}
