//
//  RustService+Rx.swift
//  LarkRustClient
//
//  Created by 王元洵 on 2021/1/18.
//

import Foundation
import RxSwift
import RustPB
import SwiftProtobuf
import ServerPB

// swiftlint:disable missing_docs

/// RustService default implementation and helper wrapper with RxSwift
public extension RustService {
    // MARK: Synchronous + Observable
    /// all observable sync send will call this method
    func sync<R: Message>(_ request: RequestPacket) -> Observable<ResponsePacket<R>> {
        return Observable.create({ (observer) -> Disposable in
            let result: ResponsePacket<R> = self.sync(request)
            observer.onNext(result)
            observer.onCompleted()
            return Disposables.create()
        })
    }

    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R> {
        let observable: Observable<ResponsePacket<R>> = sync(RequestPacket(message: request))
        return observable.map { try $0.result.get() }
    }
    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<ContextResponse<R>> {
        let observable: Observable<ResponsePacket<R>> = sync(RequestPacket(message: request))
        return observable.map { try ContextResponse(response: $0) }
    }

    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) -> Observable<U> {
        let observable: Observable<ResponsePacket<R>> = sync(RequestPacket(message: request))
        return observable.map {
            try M.transform($0.result.get(), for: request, by: transform)
        }
    }

    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        let observable: Observable<ResponsePacket<R>> = sync(RequestPacket(message: request))
        return observable.map {
            try M.transform(ContextResponse(response: $0), for: request, by: transform)
        }
    }

    // MARK: Asynchronous + Observable
    // all observable async method will call Request version
    func async(_ request: RequestPacket) -> Observable<ResponsePacket<Void>> {
        return Observable.create({ (observer) -> Disposable in
            self.async(request) { (result: ResponsePacket<Void>) in
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create()
        }).do(onNext: { (result: ResponsePacket<Void>) in
            let traceId = TraceIdUtil.parseContextId(result.contextID)
            TraceIdUtil.setTraceId(traceId)
        }, afterNext: { _ in
            TraceIdUtil.clearTraceId()
        })
    }

    func async<R: Message>(_ request: RequestPacket) -> Observable<ResponsePacket<R>> {
        return Observable.create({ (observer) -> Disposable in
            self.async(request) { (result: ResponsePacket<R>) in
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create()
        }).do(onNext: { (result: ResponsePacket<R>) in
            let traceId = TraceIdUtil.parseContextId(result.contextID)
            TraceIdUtil.setTraceId(traceId)
        }, afterNext: { _ in
            TraceIdUtil.clearTraceId()
        })
    }

    func async(_ request: RequestPacket) -> Observable<Void> {
        return async(request).map { try $0.result.get() }
    }
    func async<R: Message>(_ request: RequestPacket) -> Observable<R> {
        return async(request).map { try $0.result.get() }
    }
    func async<R: Message>(message: Message, parentID: String? = nil, barrier: Bool = false) -> Observable<R> {
        var req = RequestPacket(message: message)
        req.parentID = parentID
        req.barrier = barrier
        return async(req)
    }

    func sendAsyncRequest(_ request: SwiftProtobuf.Message) -> Observable<Void> {
        return self.async(RequestPacket(message: request)).map { try $0.result.get() }
    }

    func sendAsyncRequest(_ request: Message, spanID: UInt64?) -> Observable<Void> {
        return self.async(RequestPacket(message: request, spanID: spanID)).map { try $0.result.get() }
    }

    func sendAsyncRequest(_ request: Message, mailAccountId: String?) -> Observable<Void> {
        return self.async(RequestPacket(message: request, mailAccountId: mailAccountId)).map { try $0.result.get() }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R> {
        return self.async(RequestPacket(message: request)).map { try $0.result.get() }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                    spanID: UInt64?) -> Observable<R> {
        return self.async(RequestPacket(message: request, spanID: spanID)).map { try $0.result.get() }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> Observable<ContextResponse<R>> {
        return self.async(RequestPacket(message: request)).map { try ContextResponse(response: $0) }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                    spanID: UInt64?) -> Observable<ContextResponse<R>> {
        return self.async(RequestPacket(message: request,
                                        spanID: spanID)).map { try ContextResponse(response: $0) }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                    mailAccountId: String?) -> Observable<ContextResponse<R>> {
        return self.async(RequestPacket(message: request,
                                        mailAccountId: mailAccountId)).map { try ContextResponse(response: $0) }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) -> Observable<U> {
        return self.async(RequestPacket(message: request)).map {
            try M.transform($0.result.get(), for: request, by: transform)
        }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        spanID: UInt64?,
        transform: @escaping(R) throws -> U
    ) -> Observable<U> {
        return self.async(RequestPacket(message: request, spanID: spanID)).map {
            try M.transform($0.result.get(), for: request, by: transform)
        }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        return self.async(RequestPacket(message: request)).map {
            try M.transform(ContextResponse(response: $0), for: request, by: transform)
        }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        spanID: UInt64?,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        return self.async(RequestPacket(message: request, spanID: spanID)).map {
            try M.transform(ContextResponse(response: $0), for: request, by: transform)
        }
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        mailAccountId: String?,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        return self.async(RequestPacket(message: request, mailAccountId: mailAccountId)).map {
            try M.transform(ContextResponse(response: $0), for: request, by: transform)
        }
    }

    func sendAsyncRequestBarrier(_ request: SwiftProtobuf.Message) -> Observable<Void> {
        var req = RequestPacket(message: request)
        req.barrier = true
        return self.async(req).map { try $0.result.get() }
    }
    func sendAsyncRequestBarrier(_ request: SwiftProtobuf.Message,
                                 spanID: UInt64?) -> Observable<Void> {
        var req = RequestPacket(message: request, spanID: spanID)
        req.barrier = true
        return self.async(req).map { try $0.result.get() }
    }

    func sendAsyncRequestBarrier<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> Observable<ContextResponse<R>> {
        var req = RequestPacket(message: request)
        req.barrier = true
        return self.async(req).map { try ContextResponse(response: $0) }
    }
    func sendAsyncRequestBarrier<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                           spanID: UInt64?)
    -> Observable<ContextResponse<R>> {
        var req = RequestPacket(message: request, spanID: spanID)
        req.barrier = true
        return self.async(req).map { try ContextResponse(response: $0) }
    }

    // MARK: Event Stream
    func eventStream<R: Message>(_ request: RequestPacket) -> Observable<ResponsePacket<R>> {
        return Observable.create { (observer) -> Disposable in
            return self.eventStream(request) { (result: ResponsePacket<R>?, finish) in
                if let result = result {
                    observer.on(.next(result))
                }
                if finish {
                    observer.on(.completed)
                }
            }
        }
    }
    func eventStream<R>(request: Message, parentID: String? = nil, config: Basic_V1_RequestPacket.BizConfig? = nil)
    -> Observable<ResponsePacket<R>> where R: Message {
        var req = RequestPacket(message: request)
        req.parentID = parentID
        req.bizConfig = config
        return eventStream(req)
    }

    func eventStream<R>(request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?)
    -> Observable<EventStreamContextResponse<R>> where R: SwiftProtobuf.Message {
        var req = RequestPacket(message: request)
        req.bizConfig = config
        return eventStream(req).map { EventStreamContextResponse(response: $0) }
    }
    func eventStream<R>(request: SwiftProtobuf.Message,
                        config: Basic_V1_RequestPacket.BizConfig?,
                        spanID: UInt64?)
    -> Observable<EventStreamContextResponse<R>> where R: SwiftProtobuf.Message {
        var req = RequestPacket(message: request, spanID: spanID)
        req.bizConfig = config
        return eventStream(req).map { EventStreamContextResponse(response: $0) }
    }

    func eventStream<R: SwiftProtobuf.Message>(request: SwiftProtobuf.Message) -> Observable<R> {
        return eventStream(request: request, config: nil)
    }
    func eventStream<R: SwiftProtobuf.Message>(request: SwiftProtobuf.Message)
    -> Observable<EventStreamContextResponse<R>> {
        return eventStream(request: request, config: nil)
    }

    func sendPassThroughAsyncRequest(_ request: SwiftProtobuf.Message,
                                     serCommand: ServerPB_Improto_Command) -> Observable<Void> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.async(packet).map { try $0.result.get() }
    }
    func sendPassThroughAsyncRequest(_ request: SwiftProtobuf.Message,
                                     serCommand: ServerPB_Improto_Command,
                                     spanID: UInt64?) -> Observable<Void> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.async(packet).map { try $0.result.get() }
    }

    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               serCommand: ServerPB_Improto_Command) -> Observable<R> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.async(packet).map { try $0.result.get() }
    }
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               serCommand: ServerPB_Improto_Command,
                                                               spanID: UInt64?) -> Observable<R> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.async(packet).map { try $0.result.get() }
    }

    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               serCommand: ServerPB_Improto_Command)
    -> Observable<ContextResponse<R>> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.async(packet).map { try ContextResponse(response: $0) }
    }
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               serCommand: ServerPB_Improto_Command,
                                                               mailAccountId: String?)
    -> Observable<ContextResponse<R>> {
        var packet = RequestPacket(message: request, mailAccountId: mailAccountId)
        packet.serCommand = serCommand
        return self.async(packet).map { try ContextResponse(response: $0) }
    }
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               serCommand: ServerPB_Improto_Command,
                                                               spanID: UInt64?)
    -> Observable<ContextResponse<R>> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.async(packet).map { try ContextResponse(response: $0) }
    }

    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        serCommand: ServerPB_Improto_Command,
        transform: @escaping(R) throws -> U
    ) -> Observable<U> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.async(packet).map {
            try M.transform($0.result.get(), for: request, by: transform)
        }
    }
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        serCommand: ServerPB_Improto_Command,
        transform: @escaping(R) throws -> U,
        spanID: UInt64?
    ) -> Observable<U> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.async(RequestPacket(message: request)).map {
            try M.transform($0.result.get(), for: request, by: transform)
        }
    }
}
