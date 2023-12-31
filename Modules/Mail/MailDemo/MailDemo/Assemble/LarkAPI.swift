//
//  LarkAPI.swift
//  LarkSDK
//
//  Created by liuwanlin on 2018/8/13.
//

import Foundation
import LarkSDKInterface
import LarkAccountInterface
import LarkFoundation
import RxSwift
import SwiftProtobuf
import LarkRustClient
import RustPB

// swiftlint:disable line_length

extension ObservableType {
    func subscribeOn(_ scheduler: ImmediateSchedulerType? = nil) -> Observable<Self.Element> {
        if let scheduler = scheduler {
            return self.subscribeOn(scheduler)
        }
        return self.asObservable()
    }
}

class LarkAPI {
    var client: SDKRustService
    var scheduler: ImmediateSchedulerType?

    init(client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.client = client
        self.scheduler = onScheduler
    }
}

private func transform<R>(response: ResponsePacket<R>) -> ResponsePacket<R> {
    if case let .failure(error) = response.result {
        var res = response
        res.result = .failure(error.transformToAPIError())
        return res
    }
    return response
}

/// this extension delegate message to client, and convert RCErrro to APIError
struct SDKClient: SDKRustService {
    func wait(callback: @escaping () -> Void) {
        self.client.wait(callback: callback)
    }
    
    func register<R>(serverPushCmd cmd: LarkRustClient.ServerCommand, onCancel: (() -> Void)?, handler: @escaping (LarkRustClient.ServerPushPacket<R>) -> Void) -> RxSwift.Disposable where R: SwiftProtobuf.Message {
        self.client.register(serverPushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register(serverPushCmd cmd: LarkRustClient.ServerCommand, onCancel: (() -> Void)?, handler: @escaping (Data) -> Void) -> RxSwift.Disposable {
        self.client.register(serverPushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register<R>(serverPushCmd cmd: LarkRustClient.ServerCommand, onCancel: (() -> Void)?, handler: @escaping (R) -> Void) -> RxSwift.Disposable where R: SwiftProtobuf.Message {
        self.client.register(serverPushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register(serverPushCmd cmd: LarkRustClient.ServerCommand, onCancel: (() -> Void)?, handler: @escaping (LarkRustClient.ServerPushPacket<Data>) -> Void) -> RxSwift.Disposable {
        self.client.register(serverPushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register<R>(pushCmd cmd: LarkRustClient.Command, onCancel: (() -> Void)?, handler: @escaping (LarkRustClient.RustPushPacket<R>) -> Void) -> RxSwift.Disposable where R: SwiftProtobuf.Message {
        self.client.register(pushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register(pushCmd cmd: LarkRustClient.Command, onCancel: (() -> Void)?, handler: @escaping (Data) -> Void) -> RxSwift.Disposable {
        self.client.register(pushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register<R>(pushCmd cmd: LarkRustClient.Command, onCancel: (() -> Void)?, handler: @escaping (R) -> Void) -> RxSwift.Disposable where R: SwiftProtobuf.Message {
        self.client.register(pushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    func register(pushCmd cmd: LarkRustClient.Command, onCancel: (() -> Void)?, handler: @escaping (LarkRustClient.RustPushPacket<Data>) -> Void) -> RxSwift.Disposable {
        self.client.register(pushCmd: cmd, onCancel: onCancel, handler: handler)
    }

    var wrapped: RustService { client }
    private let client: RustService

    init(client: RustService) {
        self.client = client
    }

    func async<R>(_ request: RequestPacket, callback: @escaping (ResponsePacket<R>) -> Void) where R: Message {
        client.async(request) { (response) in
            callback(transform(response: response))
        }
    }

    func async(_ request: RequestPacket, callback: @escaping (ResponsePacket<Void>) -> Void) {
        client.async(request) { (response) in
            callback(transform(response: response))
        }
    }

    func async(_ request: RawRequestPacket, callback: @escaping (ResponsePacket<Data>) -> Void) {
        client.async(request) { (response) in
            callback(transform(response: response))
        }
    }

    func sync<R>(_ request: RequestPacket) -> ResponsePacket<R> where R: Message {
        return transform(response: client.sync(request))
    }

    func sync(_ request: RequestPacket) -> ResponsePacket<Void> {
        return transform(response: client.sync(request))
    }

    // MARK: - Event Stream
    func eventStream<R>(_ request: RequestPacket, event handler: @escaping (ResponsePacket<R>?, Bool) -> Void) -> Disposable where R: Message {
        return client.eventStream(request) { (response: ResponsePacket<R>?, finish) in
            if let response = response {
                handler(transform(response: response), finish)
            } else {
                handler(nil, finish)
            }
        }
    }

    func eventStream<R>(request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?)
        -> Observable<R>
        where R: SwiftProtobuf.Message {
            return self.client.eventStream(request: request, config: config)
                .catchError { throw $0.transformToAPIError() }
    }

    func eventStream<R>(request: SwiftProtobuf.Message,
                        config: Basic_V1_RequestPacket.BizConfig?,
                        spanID: UInt64?) -> Observable<R> where R: SwiftProtobuf.Message {
        return self.client.eventStream(request: request, config: config, spanID: spanID)
            .catchError { throw $0.transformToAPIError() }
    }

    func eventStream<R>(request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?)
        -> Observable<EventStreamContextResponse<R>>
        where R: SwiftProtobuf.Message {
            return self.client.eventStream(request: request, config: config)
                .map { (response: EventStreamContextResponse<R>) -> EventStreamContextResponse<R> in
                    if case .failure(let error) = response.response {
                        return EventStreamContextResponse(contextID: response.contextID,
                                                          response: .failure(error.transformToAPIError()))
                    }
                    return response
                }
    }

    func barrier(allowRequest: @escaping (RequestPacket) -> Bool, enter: @escaping (@escaping () -> Void) -> Void) {
        client.barrier(allowRequest: allowRequest, enter: enter)
    }

    func dispose() {
        client.dispose()
    }
}

