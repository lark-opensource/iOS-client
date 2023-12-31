//
//  BTStatisticTrace.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/1.
//

import Foundation
import SKFoundation
import ThreadSafeDataStructure

enum BTStatisticTraceType {
    case normal
    case fps
}

protocol BTStatisticTrace {
    var type: BTStatisticTraceType { get }
    var parentTraceId: String? { get }
    var traceId: String { get }
    var isStop: Bool { get }

    func addChildren(trace: BTStatisticTrace)

    func stop(includeChildren: Bool)

    func addExtra(extra: [String: Any])
    func getExtra(includeParent: Bool) -> [String: Any]

    func add(consumer: BTStatisticConsumer)
    func remove(consumer: BTStatisticConsumer)
    func removeAllConsumer()
}

class BTStatisticBaseTrace: BTStatisticTrace {
    let type: BTStatisticTraceType
    let parentTraceId: String?
    let traceId: String
    var isStop = false

    weak var traceProvider: BTStatisticTraceInnerProvider?

    var childrens: SafeArray<BTStatisticTrace> = [] + .semaphore

    private var extra: [String: Any] {
        get { _extra.getImmutableCopy() }
        set { _extra.replaceInnerData(by: newValue) }
    }
    private var _extra: SafeDictionary<String, Any> = [:] + .semaphore

    var consumers: SafeArray<BTStatisticConsumer> = [] + .semaphore

    init(
        type: BTStatisticTraceType,
        parentTraceId: String?,
        traceProvider: BTStatisticTraceInnerProvider?
    ) {
        assert(traceProvider != nil)
        self.type = type
        self.parentTraceId = parentTraceId
        self.traceId = traceProvider?.getUUId() ?? BTStatisticUtils.generateTraceId()
        self.traceProvider = traceProvider
        if let parentTraceId = parentTraceId {
            traceProvider?.getTrace(traceId: parentTraceId, includeStop: true)?.addChildren(trace: self)
        }
    }

    func addChildren(trace: BTStatisticTrace) {
        childrens.append(trace)
    }

    func stop() {
        stop(includeChildren: true)
    }

    func stop(includeChildren: Bool = true) {
        isStop = true
        if includeChildren {
            childrens.forEach { child in
                child.stop(includeChildren: includeChildren)
            }
        }
        checkClear()
    }

    func addExtra(extra: [String : Any]) {
        self.extra.merge(extra, uniquingKeysWith: { _, cKey in return cKey })
    }

    func getExtra(includeParent: Bool) -> [String: Any] {
        guard  let parentTraceId = parentTraceId else {
            return extra
        }
        guard let parentExtra = traceProvider?.getTrace(traceId: parentTraceId, includeStop: false)?.getExtra(includeParent: includeParent) else {
            return extra
        }
        return extra.merging(parentExtra) { cur, _ in cur }
    }

    func add(consumer: BTStatisticConsumer) {
        consumers.append(consumer)
    }

    func remove(consumer: BTStatisticConsumer) {
        consumers = consumers.filter { $0 != consumer }
    }

    func removeAllConsumer() {
        consumers.removeAll()
    }

    func checkClear() {
        guard isStop else {
            return
        }
        traceProvider?.removeTrace(traceId: traceId, includeChild: true)
    }
}
