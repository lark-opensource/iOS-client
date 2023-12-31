//
//  OPMockRustService.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/8.
//

import Foundation
import LarkAssembler
import Swinject
import RustPB

final class OpenPluginRustMockAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Swinject.Container) {
        
        container.register(RustService.self) { resolver -> RustService in
            return OPMockRustService(resolver: resolver)
        }.inObjectScope(.container)
    }
}

final class OpenPluginRustRestoreAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Swinject.Container) {
        
        container.register(RustService.self) { resolver -> RustService in
            return SimpleRustClient()
        }.inObjectScope(.container)
    }
}


import RxSwift
import RustPB
import SwiftProtobuf
import LarkRustClient
import ThreadSafeDataStructure

struct MockRustResponse {
    let response: Any
    let success: Bool
}

final class OPMockRustService: RustService {
    var userID: String?
    
    private let resolver: Resolver

    private var mockResponses: [MockRustResponse] {
        get { _mockResponses.getImmutableCopy() }
        set { _mockResponses.replaceInnerData(by: newValue) }
    }

    private var _mockResponses: SafeArray<MockRustResponse> = [] + .semaphore

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func setResponses(responses: [MockRustResponse]) {
        mockResponses.append(contentsOf: responses)
    }

    func clearResponses() {
        mockResponses.removeAll()
    }

    private func getResponse() -> MockRustResponse? {
        guard let first = mockResponses.first else { return  nil }
        mockResponses.removeFirst()
        return first
    }

    func eventStream<R>(request: Message, config: Basic_V1_RequestPacket.BizConfig?, spanID: UInt64?) -> Observable<R> where R : Message {
        return Observable.create { (observer) -> Disposable in
            var req = RequestPacket(message: request)
            req.bizConfig = config
            return self.startEventStream(req, finishOnError: true) { (response: ResponsePacket<R>?, finish) in
                switch response?.result {
                case .some(.failure(let error)):
                    observer.on(.error(error))
                case .some(.success(let response)):
                    observer.on(.next(response))
                    fallthrough
                default:
                    if finish {
                        observer.on(.completed)
                    }
                }
            }
        }
    }

    func eventStream<R>(request: Message, config: Basic_V1_RequestPacket.BizConfig?) -> Observable<R> where R : Message {
        return Observable.create { (observer) -> Disposable in
            var req = RequestPacket(message: request)
            req.bizConfig = config
            return self.startEventStream(req, finishOnError: true) { (response: ResponsePacket<R>?, finish) in
                switch response?.result {
                case .some(.failure(let error)):
                    observer.on(.error(error))
                case .some(.success(let response)):
                    observer.on(.next(response))
                    fallthrough
                default:
                    if finish {
                        observer.on(.completed)
                    }
                }
            }
        }
    }
    
    func startEventStream<R: Message>(
        _ request: RequestPacket, finishOnError: Bool, event: @escaping (ResponsePacket<R>?, Bool) -> Void
    ) -> Disposable {
        let disposable = SingleAssignmentDisposable()
        return disposable
    }

    func register<R>(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (ServerPushPacket<R>) -> Void) -> Disposable where R : Message {
        let ret = Disposables.create()
        return ret
    }

    func register(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (Data) -> Void) -> Disposable {
        return Disposables.create()
    }

    func register<R>(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (R) -> Void) -> Disposable where R : Message {
        return Disposables.create()
    }

    func register(serverPushCmd cmd: ServerCommand, onCancel: (() -> Void)?, handler: @escaping (ServerPushPacket<Data>) -> Void) -> Disposable {
        return Disposables.create()
    }

    func register<R>(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (RustPushPacket<R>) -> Void) -> Disposable where R : Message {
        return Disposables.create()
    }

    func register(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (Data) -> Void) -> Disposable {
        handler(Data.init())
        return Disposables.create()
    }

    func register<R>(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (R) -> Void) -> Disposable where R : Message {
        return Disposables.create()
    }

    func register(pushCmd cmd: Command, onCancel: (() -> Void)?, handler: @escaping (RustPushPacket<Data>) -> Void) -> Disposable {
        return Disposables.create()
    }

    func eventStream<R>(_ request: RequestPacket, event handler: @escaping (ResponsePacket<R>?, Bool) -> Void) -> Disposable where R : Message {
        return Disposables.create()
    }

    func async<R>(_ request: RequestPacket, callback: @escaping (ResponsePacket<R>) -> Void) where R : Message {
        if let _ = request.message as? RustPB.Openplatform_Api_OpenAPIRequest, let response = getResponse() {
            if response.success {
                callback(ResponsePacket(contextID: "", result: .success(response.response as! R)))
            } else {
                if case let error as RCError = response.response {
                    callback(ResponsePacket(contextID: "", result: .failure(error)))
                } else {
                    callback(ResponsePacket(contextID: "", result: .failure(
                        RCError.unknownError(error: response.response as! Error))))
                }
            }
        } else {
            callback(ResponsePacket(contextID: "", result: .failure(RCError.cancel)))
        }
    }

    func async(_ request: RawRequestPacket, callback: @escaping (ResponsePacket<Data>) -> Void) {
        callback(ResponsePacket(contextID: "", result: .failure(RCError.cancel)))
    }

    func async(_ request: RequestPacket, callback: @escaping (ResponsePacket<Void>) -> Void) {
        callback(ResponsePacket(contextID: "", result: .failure(RCError.cancel)))
    }

    func sync<R>(_ request: RequestPacket) -> ResponsePacket<R> where R : Message {
        return ResponsePacket(contextID: "", result: .failure(RCError.cancel))
    }

    func sync(_ request: RequestPacket) -> ResponsePacket<Void> {
        return ResponsePacket(contextID: "", result: .failure(RCError.cancel))
    }

    func dispose() {
    }

    func barrier(allowRequest: @escaping (RequestPacket) -> Bool, enter: @escaping (@escaping () -> Void) -> Void) {
        enter {
        }
    }

    func wait(callback: @escaping () -> Void) {
        callback()
    }

    func sendAsyncRequest(_ request: SwiftProtobuf.Message) -> Observable<Void> {
        return self.async(RequestPacket(message: request)).map { try $0.result.get() }
    }
    
    func async(_ request: RequestPacket) -> Observable<ResponsePacket<Void>> {
        return Observable.create({ (observer) -> Disposable in
            self.async(request) { (result: ResponsePacket<Void>) in
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
}
