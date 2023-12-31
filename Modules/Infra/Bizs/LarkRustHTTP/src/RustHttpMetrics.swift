//
//  RustHttpMetrics.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2019/3/31.
//
import Foundation
import RustPB

@objc
public final class RustHttpMetrics: NSObject {
    // state
    @objc public let request: NSURLRequest
    @objc public internal(set) var response: URLResponse?
    /// nonnull if error occur and fail
    @objc public internal(set) var error: Error?
    public internal(set) var resourceFetchType: ResourceFetchType = .unknown
    public internal(set) var networkProtocol: RustHttpNetworkProtocol = .unknown

    // -- Date & Cost
    @objc public internal(set) var fetchStartDate: Date?
    /// 0 represent not set
    @objc public internal(set) var dnsCost: TimeInterval = 0
    @objc public internal(set) var connectionCost: TimeInterval = 0
    @objc public internal(set) var tlsCost: TimeInterval = 0
    @objc public var totalCost: TimeInterval {
        // load from local cache shouldn't set end. the total cost means network cost.
        guard let start = fetchStartDate, let end = fetchEndDate else { return 0 }
        return end.timeIntervalSince(start)
    }
    /// date when receive header response.
    /// NOTE: if use cache, this field is nil
    @objc public internal(set) var receiveHeaderDate: Date?
    @objc public internal(set) var fetchEndDate: Date?

    init(request: URLRequest) {
        self.request = request as NSURLRequest
    }

    func fill(from durations: OnFetchResponse.StageCost) {
        if case let cost = durations.dnsCost, cost > 0 { self.dnsCost = TimeInterval(cost) / 1_000 }
        if case let cost = durations.tcpConnectCost, cost > 0 { self.connectionCost = TimeInterval(cost) / 1_000 }
        if case let cost = durations.tlsCost, cost > 0 { self.tlsCost = TimeInterval(cost) / 1_000 }
    }
    public override var debugDescription: String {
        return """
        RustHttpMetrics(\( Unmanaged.passUnretained(self).toOpaque() )):
            - request: \(request)
            - response: \(String(reflecting: response))
            - error: \(String(reflecting: error))
            - type: \(resourceFetchType)
            - fetchStart: \(String(describing: fetchStartDate))
            - fetchEnd: \(String(describing: fetchEndDate))
            - cost: [
                - dns: \(dnsCost)
                - connection: \(connectionCost)
                - tls: \(tlsCost)
                - total: \(totalCost)]
            - header: \(String(describing: receiveHeaderDate))

        """
    }
}
// swiftlint:disable missing_docs

public typealias RustHttpNetworkProtocol = OnFetchResponse.OnHeaderResponse.ProtocolEnum
public enum ResourceFetchType: Int {
    case unknown, networkLoad, localCache
}

// swiftlint:enable missing_docs

extension URLSessionTask {
    /// 获取当前task对应的rust metrics
    @objc public var rustMetrics: [RustHttpMetrics] {
        let lock = URLSessionTask.lock
        lock.wait(); defer { lock.signal() }
        return (_rustMetrics as? [RustHttpMetrics]) ?? []
    }
    internal static let lock = DispatchSemaphore(value: 1)
    private var _rustMetrics: NSMutableArray? {
        // 理论上只会在网络线程上写，但可能多线程读
        // array理论上应该写完前不会读
        // 现在通过外部使用接口加锁来保证线程安全
        get {
            let key = unsafeBitCast(RustHttpMetrics.self, to: UnsafeRawPointer.self)
            if let v = objc_getAssociatedObject(self, key) as? NSMutableArray {
                return v
            }

            // if no associated object, try get from session with same taskIdentifier.
            // this occur when change task type, eg: dataTask -> becomeDownload task
            if let v = self.session?.rustTaskMetrics.object(forKey: self.taskIdentifier as NSNumber) {
                objc_setAssociatedObject(self, key, v, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return v
            }
            return nil
        }
        set {
            let key = unsafeBitCast(RustHttpMetrics.self, to: UnsafeRawPointer.self)
            objc_setAssociatedObject(self, key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            session?.rustTaskMetrics.setObject(newValue, forKey: self.taskIdentifier as NSNumber)
        }
    }
    // 添加新的metrics, 目前实现是先添加metrics占位，再修改的方式.
    // metrics各属性也只会设置一次值。且读取应该是在结束的时候，时间是错开的。应该不会遇到并发读写的问题。
    internal func add(metric: RustHttpMetrics) {
        let lock = URLSessionTask.lock
        lock.wait(); defer { lock.signal() }

        if let v = _rustMetrics {
            v.add(metric)
            return
        }
        // 没有时默认设置一个
        let v = NSMutableArray(object: metric)
        _rustMetrics = v
    }
    @nonobjc internal var session: URLSession? {
        return self.perform(NSSelectorFromString("session"))?.takeUnretainedValue() as? URLSession
    }
}

extension URLSession {
    // 线程不安全，现在通过外部使用接口加锁来保证线程安全
    final fileprivate var rustTaskMetrics: NSMapTable<NSNumber, NSMutableArray> {
        let key = unsafeBitCast(RustHttpMetrics.self, to: UnsafeRawPointer.self)
        if let map = objc_getAssociatedObject(self, key) as? NSMapTable<NSNumber, NSMutableArray> {
            return map
        }
        // value is store on task. here just a reference
        let map = NSMapTable<NSNumber, NSMutableArray>.strongToWeakObjects()
        objc_setAssociatedObject(self, key, map, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return map
    }
    #if DEBUG
    var leftRustMetricsCount: Int {
        return rustTaskMetrics.objectEnumerator()?.allObjects.count ?? 0
    }
    #endif
}
