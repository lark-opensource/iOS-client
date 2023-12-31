//
//  RxSwift+Extension.swift
//  LarkTraceId
//
//  Created by ByteDance on 2022/12/15.
//

import Foundation
import RxSwift


public extension ObservableType {

    func observeOn(scheduler: ImmediateSchedulerType) -> Observable<Element> {
        let traceId = TraceIdService.getTraceId()
        return self.observeOn(scheduler).do(onNext: { _ in
            TraceIdService.setTraceId(traceId)
        }, afterNext: { _ in
            TraceIdService.clearTraceId()
        }, onError: { _ in
            TraceIdService.setTraceId(traceId)
        }, afterError: { _ in
            TraceIdService.clearTraceId()
        }, onCompleted: {
            TraceIdService.setTraceId(traceId)
        }, afterCompleted: {
            TraceIdService.clearTraceId()
        })
    }

    func subscribeOn(scheduler: ImmediateSchedulerType) -> Observable<Self.Element> {
        let schedulerWrapper = ImmediateSchedulerWrapper(scheduler: scheduler)
        return self.subscribeOn(schedulerWrapper)
    }
}

public class ImmediateSchedulerWrapper: ImmediateSchedulerType {

    let scheduler: ImmediateSchedulerType

    init(scheduler: ImmediateSchedulerType) {
        self.scheduler = scheduler
    }

    public func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let traceId = TraceIdService.getTraceId()
        let wrapperAction: (StateType) -> Disposable = {
            let preTraceId = TraceIdService.getTraceId()
            TraceIdService.setTraceId(traceId)
            let res = action($0)
            TraceIdService.setTraceId(preTraceId)
            return res
        }
        return scheduler.schedule(state, action: wrapperAction)
    }

    public func scheduleRecursive<State>(_ state: State, action: @escaping (_ state: State, _ recurse: (State) -> Void) -> Void) -> Disposable {
        let traceId = TraceIdService.getTraceId()
        let wrapperAction: (_ state: State, _ recurse: (State) -> Void) -> Void = {
            let preTraceId = TraceIdService.getTraceId()
            TraceIdService.setTraceId(traceId)
            action($0, $1)
            TraceIdService.setTraceId(preTraceId)
        }
        return scheduler.scheduleRecursive(state, action: wrapperAction)
    }
}
