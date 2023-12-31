//
//  GCManager.swift
//  LarkChat
//
//  Created by qihongye on 2020/8/19.
//

import UIKit
import Foundation
import EEAtomic
import ThreadSafeDataStructure
import os.signpost

private var _idx = Int32.min

struct WeakGCunitRef: Hashable {
    private let _hashValue: Int32

    weak var ref: GCUnit?

    init(_ ref: GCUnit) {
        self.ref = ref
        self._hashValue = OSAtomicIncrement32(&_idx)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self._hashValue)
    }

    static func == (lhs: WeakGCunitRef, rhs: WeakGCunitRef) -> Bool {
        return lhs._hashValue == rhs._hashValue
    }
}

private var gcunitSet = Set<WeakGCunitRef>()
private let callback: CFRunLoopObserverCallBack = { (_, _, _) in
    guard let mainRunLoopMode = RunLoop.main.currentMode, mainRunLoopMode != .tracking else {
        return
    }
    var releasedArr: [WeakGCunitRef] = []

    // call gc
    for gcunitRef in gcunitSet {
        if let gcunit = gcunitRef.ref {
            gcunit.gc()
        } else {
            releasedArr.append(gcunitRef)
        }
    }

    // remove released GCUnit
    for ref in releasedArr {
        gcunitSet.remove(ref)
    }
}

public struct GCTraceInfo {
    public let limitWeight: Int64
    public let currentWeight: Int64
    public let gcMSCost: CFTimeInterval

    init(_ gcunit: GCUnit) {
        self.limitWeight = gcunit.limitWeight
        self.currentWeight = gcunit.currentWeight.value
        self.gcMSCost = gcunit.gcMStime
    }
}

public struct GCUnitDelegateCallback {
    private var unit: GCUnit

    init(gcunit: GCUnit) {
        self.unit = gcunit
    }

    public func traceInfo() -> GCTraceInfo {
        return GCTraceInfo(unit)
    }

    public func end(currentWeight: Int64) {
        unit.gcEnd(currentWeight)
    }
}

public protocol GCUnitDelegate: AnyObject {
    func gc(limitWeight: Int64, callback: GCUnitDelegateCallback)
}

public final class GCUnit {
    private static let osLogger = OSLog(subsystem: "GCUnit", category: "TimeLogger")
    private static let onceToken = AtomicOnce()
    private var needGC = AtomicBool(false)
    fileprivate var isInGCState = AtomicBool(false)
    private let initialLimitWeight: Int64
    fileprivate var limitWeight: Int64
    fileprivate var currentWeight = AtomicInt64(0)
    private var gcStartTimestamp: CFTimeInterval = 0
    private let limitGCRoundSecondTime: CFTimeInterval
    private let limitGCMSCost: CFTimeInterval

    public private(set) var gcMStime: CFTimeInterval = 0

    public weak var delegate: GCUnitDelegate?

    /// initialize
    /// - Parameters:
    ///   - limitWeight: Target limit total weight, GC will be called when currentWeight>limitWeight. 目标权重，当currentWeight>limitWeight时会触发GC
    ///   - limitGCRoundSecondTime: Target time-consuming for one round of gc to the next one in seconds. 一轮gc到下一轮gc的耗时，单位s
    ///   - limitGCMSCost:Target time-consuming for one round of gc in million seconds. 一轮gc的耗时限制。
    ///   - delegate: GCUnitDelegate
    public init(limitWeight: Int64, limitGCRoundSecondTime: CFTimeInterval, limitGCMSCost: CFTimeInterval, _ delegate: GCUnitDelegate? = nil) {
        self.initialLimitWeight = limitWeight
        self.limitWeight = limitWeight
        self.limitGCRoundSecondTime = limitGCRoundSecondTime
        self.limitGCMSCost = limitGCMSCost
        self.delegate = delegate
        Self.onceToken.once {
            let observer = CFRunLoopObserverCreate(
                kCFAllocatorDefault,
                CFRunLoopActivity.beforeWaiting.rawValue,
                true,
                0xFFFF,
                callback,
                nil
            )
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .defaultMode)
        }
        if Thread.current.isMainThread {
            gcunitSet.insert(WeakGCunitRef(self))
        } else {
            DispatchQueue.main.async {
                gcunitSet.insert(WeakGCunitRef(self))
            }
        }
    }

    deinit {
        print("GCUnit deinit")
    }

    /// increase current weight
    /// - Parameter weight: int64 weight
    public func increaseWeight(_ weight: Int64) {
        needGC.value = currentWeight.add(weight) + weight > limitWeight
    }

    /// set current weight directly
    /// - Parameter weight: int64 weight
    public func setWeight(_ weight: Int64) {
        needGC.value = weight > limitWeight
        currentWeight.value = weight
    }

    func gc() {
        if isInGCState.value {
            return
        }
        let currentTime = CACurrentMediaTime()
        let roundTime = currentTime - gcStartTimestamp
        if gcStartTimestamp != 0, roundTime > limitGCRoundSecondTime * 2 {
            limitWeight = max(limitWeight / 2, initialLimitWeight)
        }
        guard needGC.value, let delegate = self.delegate else {
            return
        }
        trackStart()
        if gcStartTimestamp != 0, roundTime <= limitGCRoundSecondTime {
            limitWeight *= 2
        }
        gcStartTimestamp = currentTime
        isInGCState.value = true
        delegate.gc(limitWeight: limitWeight, callback: GCUnitDelegateCallback(gcunit: self))
    }

    @inline(__always)
    fileprivate func gcEnd(_ currentWeight: Int64) {
        let endTime = CACurrentMediaTime()
        trackEnd(endTime: endTime)
        gcMStime = (endTime - gcStartTimestamp) * 1000
        if gcMStime > limitGCMSCost {
            limitWeight /= 2
        }
        setWeight(currentWeight)
        isInGCState.value = false
        print("GCUnit GC Time: ", gcMStime)
    }

    @inline(__always)
    private func trackStart() {
        #if DEBUG
        if #available(iOS 12.0, *) {
            let spid = OSSignpostID(log: Self.osLogger, object: self)
            os_signpost(.begin, log: Self.osLogger, name: "GCUnit", signpostID: spid, "Start at %ld", gcStartTimestamp * 1000)
        }
        #endif
    }

    @inline(__always)
    private func trackEnd(endTime: CFTimeInterval) {
        #if DEBUG
        if #available(iOS 12.0, *) {
            let spid = OSSignpostID(log: Self.osLogger, object: self)
            os_signpost(.end, log: Self.osLogger, name: "GCUnit", signpostID: spid, "End at %ld", endTime * 1000)
        }
        #endif
    }
}
