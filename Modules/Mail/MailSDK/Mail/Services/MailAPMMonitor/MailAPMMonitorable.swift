//
//  MailAPMEvent.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/4.
//

import Foundation
import RxSwift

/// the param object of apm event
protocol MailAPMEventParamAble {
    var key: String { get }

    /// 部分key在TEA和Slardar不一致，需要手动映射，默认和key一致
    var reciableKey: String { get }

    var value: Any { get }
}

extension MailAPMEventParamAble {
    var reciableKey: String {
        if key == "sence" {
            return "scene_type"
        } else if key == "status" {
            return "mail_status"
        } else {
            return key
        }
    }
}

extension MailAPMEventParamAble where Self: CaseIterable {
    static func allKeys() -> Set<String> {
        var keySet = Set<String>()
        for param in Self.allCases {
            keySet.insert(param.key)
        }
        return keySet
    }
}

enum MailAPMEventStatus {
    case ready /// not started
    case recording /// has been started
    case suspend /// suspend recording
    case isInvalid /// has been Used
}

protocol MailAPMEventPropery: MailDeallocHookAble {
    var totalCostTime: TimeInterval { get set }
    var recordDate: Date { get set }
    var timer: Observable<Int> { get }
    var timerDisposeBag: DisposeBag { get set }
    /// event status
    var status: MailAPMEventStatus { get set }
    /// delay pose start. ( will pose start and end. when poseEnd called ) default is false
    var isDelayPoseStart: Bool { get set }
}

class MailAPMBaseEvent: MailDeallocHookAble, MailAPMEventPropery {
    // MARK: propery
    static let overtime: Int = 31 // 调整为比rust的久

    var isDelayPoseStart: Bool = false
    var totalCostTime: TimeInterval = 0
    var recordDate: Date = Date()
    var timer: Observable<Int> = Observable<Int>.interval(.seconds(MailAPMBaseEvent.overtime),
                                                          scheduler: MainScheduler.instance)
    var timerDisposeBag: DisposeBag = DisposeBag()
    var status: MailAPMEventStatus = .ready

    override init() {
        super.init()
        // 因为进入后台所有的数据会有失真，所以对于进入过后台会直接抛弃这个埋点。
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc
    func handleEnterBackground() {
        self.status = .isInvalid
        self.timerDisposeBag = DisposeBag()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol MailAPMMonitorable: AnyObject {
    var startKey: MailAPMEventConstant.StartKey { get }

    /// this will be added to start & end
    var commonParams: [MailAPMEventParamAble] { get set }

    var startParams: [MailAPMEventParamAble] { get set }

    /// the params that start event should upload
    var requireStartParamsKey: Set<String> { get }

    var endKey: MailAPMEventConstant.EndKey { get }

    var endParams: [MailAPMEventParamAble] { get set }

    // MARK: appReciable Event
    var reciableConfig: MailAPMReciableConfig? { get }

    /// the params that end event should upload
    var requireEndParamsKey: Set<String> { get }

    /// need 31s to time out. default is true
    var enableTimeoutCheck: Bool { get }

    func markPostStart()

    /// suspend costime recorder
    func suspend()

    /// resume costime recoder
    func resume()

    /// post end
    /// - Parameter async: true, post async on APMMonitor queue; false, post directly on current queue
    func postEnd(async: Bool)

    /// abandon this event. no start & end will be posed. only avaliable base on isDelayPoseStart is true.
    func abandon()
}

extension MailAPMMonitorable {

    /// 新的可感知埋点不分起始和结束，默认只打结束
    var startKey: MailAPMEventConstant.StartKey {
        return .unknown
    }

    /// 普遍不关心起始埋点
    var requireStartParamsKey: Set<String> {
        return []
    }

    var enableTimeoutCheck: Bool {
        return true
    }
}

extension Array where Element == MailAPMEventParamAble {
    func apmEventParams() -> (tea: [String: Any], reciableEvent: [String: Any])  {
        var params: [String: Any] = [:]
        var reciableParams: [String: Any] = [:]
        // 已经插入过非timeout的status状态
        var status: MailAPMEventParamAble? = nil
        for item in self {
            // 因为超时计时不想放到主线程，这里可能有多线程重复值的情况。允许这种情况发生。做排重即可。
            // 超时的优先级最低。
            if item.key == MailAPMEventConstant.CommonParam.status_timeout.key {
                if let value = item.value as? String,
                   let timeoutValue = MailAPMEventConstant.CommonParam.status_timeout.value as? String,
                   timeoutValue != value {
                    status = item
                }
            }
            if params[item.key] != nil || reciableParams[item.reciableKey] != nil {
//               assert(false, "have same key in a params list: \(item.key)")
            }
            params[item.key] = item.value
            reciableParams[item.reciableKey] = item.value
            // 因为metrics平台不允许空格 新增debug_message_for_metrics用于提供给metrics服务
            if item.key == MailAPMEventConstant.CommonParam.debug_message("").key {
                if let value = item.value as? String {
                   let replaced = value.replacingOccurrences(of: " ", with: "_")
                   params["debug_message_for_metrics"] = replaced
                   reciableParams["debug_message_for_metrics"] = replaced
                }
            }
        }
        if let status = status {
            params[status.key] = status.value
            reciableParams[status.reciableKey] = status.value
        }
        return (params, reciableParams)
    }
}

private var commonParamsKey: Void?
private var startParamsKey: Void?
private var endParamsKey: Void?
private var deallocHooker: Void?

extension MailAPMMonitorable where Self: MailAPMEventPropery {
    var commonParams: [MailAPMEventParamAble] {
        get {
            if let params = objc_getAssociatedObject(self, &commonParamsKey) as? [MailAPMEventParamAble] {
                return params
            } else {
                let holder: [MailAPMEventParamAble] = []
                objc_setAssociatedObject(self, &commonParamsKey, holder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return holder
            }
        }
        set {
            objc_setAssociatedObject(self, &commonParamsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var startParams: [MailAPMEventParamAble] {
        get {
            if let params = objc_getAssociatedObject(self, &startParamsKey) as? [MailAPMEventParamAble] {
                return params
            } else {
                let holder: [MailAPMEventParamAble] = []
                objc_setAssociatedObject(self, &startParamsKey, holder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return holder
            }
        }
        set {
            objc_setAssociatedObject(self, &startParamsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var endParams: [MailAPMEventParamAble] {
        get {
            if let params = objc_getAssociatedObject(self, &endParamsKey) as? [MailAPMEventParamAble] {
                return params
            } else {
                let holder: [MailAPMEventParamAble] = []
                objc_setAssociatedObject(self, &endParamsKey, holder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return holder
            }
        }
        set {
            objc_setAssociatedObject(self, &endParamsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: action
    func markPostStart() {
        self.markPostStart(startDate: Date())
    }
    func markPostStart(startDate: Date) {
        recordDate = startDate
        MailAPMMonitorService.postStart(event: self)
        status = .recording
        // overtime
        if enableTimeoutCheck {
            self.timer.subscribe(onNext: { [weak self] (count) in
                // post over time & invalid self
                guard let self = self, self.status == .recording else {
                    return
                }
                self.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
                self.postEnd()
            }, onError: { (eror) in

            }).disposed(by: timerDisposeBag)
        }
        if Thread.isMainThread { // instance method swizzling not thread safe
            // user leave
            resetDeallocHooker()
        }
    }

    func suspend() {
        guard status != .suspend else {
            return
        }
        let now = Date()
        totalCostTime = totalCostTime + now.timeIntervalSince(recordDate)
        status = .suspend
    }

    func resume() {
        recordDate = Date()
        status = .recording
    }

    func postEnd(async: Bool = true) {
        guard self.status != .ready else {
            assert(false, "event not start")
            return
        }
        guard self.status != .isInvalid else {
            return
        }
        if self.status == .recording {
            let now = Date()
            totalCostTime = totalCostTime + now.timeIntervalSince(recordDate)
        }
        if isDelayPoseStart {
            MailAPMMonitorService.postStart(event: self)
        }
        if async {
            MailAPMMonitorService.postEnd(event: self)
        } else {
            MailAPMMonitorService.postEndImmediately(event: self)
        }
        status = .isInvalid
        timerDisposeBag = DisposeBag()
    }

    func abandon() {
        status = .isInvalid
        timerDisposeBag = DisposeBag()
    }
}

extension MailAPMMonitorable where Self: MailAPMEventPropery {
    // because deallockHooker deinit will call AFTER event deinit. show we should copy a temp for clourse
    func resetDeallocHooker() {
        self.lk_deallocAction = { (object) in
            guard let property = object as? MailAPMEventPropery else {
                return
            }
            guard let event = object as? MailAPMMonitorable else {
                return
            }
            guard property.status == .recording || property.status == .suspend else {
                return
            }
            event.endParams.append(MailAPMEventConstant.CommonParam.status_user_leave)
            // called in dealloc.
            event.postEnd(async: false)
        }
    }
}

// MARK: hook
extension MailAPMMonitorable {
    var deallockHooker: EventDeallocator? {
        get {
            return objc_getAssociatedObject(self, &deallocHooker) as? EventDeallocator
        }
        set {
            if let old = deallockHooker {
                old.closure = {}
            }
            objc_setAssociatedObject(self, &deallocHooker, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension Array where Element == MailAPMEventParamAble {
    /// 插入新event，若对应的event key已在队列中，更新对应event的value为新值
    mutating func appendOrUpdate(_ newElement: MailAPMEventParamAble) {
        if let eventIdx = firstIndex(where: { $0.key == newElement.key }) {
            self[eventIdx] = newElement
        } else {
            append(newElement)
        }
    }
}
