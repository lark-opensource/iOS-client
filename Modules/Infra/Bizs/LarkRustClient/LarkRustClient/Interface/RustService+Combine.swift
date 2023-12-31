//
//  RustService+Combine.swift
//  LarkRustClient
//
//  Created by 王元洵 on 2021/1/18.
//

import Foundation
import LarkCombine
import RustPB
import SwiftProtobuf
import ServerPB

// swiftlint:disable missing_docs

/// RustService default implementation and helper wrapper with Combine
public extension RustService {
    // MARK: Synchronous + AnyPublisher
    /// all publisher sync send will call this method
    func syncWithCombine<R: Message>(_ request: RequestPacket) -> Deferred<Future<ResponsePacket<R>, Error>> {
        return Deferred {
            Future { promise in
                let result: ResponsePacket<R> = self.sync(request)
                promise(.success(result))
            }
        }
    }

    func sendSyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> AnyPublisher<R, Error> {
        let publisher: Deferred<Future<ResponsePacket<R>, Error>> = syncWithCombine(RequestPacket(message: request))
        return publisher.tryMap { try $0.result.get() }.eraseToAnyPublisher()
    }
    func sendSyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> AnyPublisher<ContextResponse<R>, Error> {
        let publisher: Deferred<Future<ResponsePacket<R>, Error>> = syncWithCombine(RequestPacket(message: request))
        return publisher.tryMap { try ContextResponse(response: $0) }.eraseToAnyPublisher()
    }

    func sendSyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) -> AnyPublisher<U, Error> {
        let publisher: Deferred<Future<ResponsePacket<R>, Error>> = syncWithCombine(RequestPacket(message: request))
        return publisher.tryMap {
            try M.transform($0.result.get(), for: request, by: transform)
        }.eraseToAnyPublisher()
    }

    func sendSyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> AnyPublisher<U, Error> {
        let publisher: Deferred<Future<ResponsePacket<R>, Error>> = syncWithCombine(RequestPacket(message: request))
        return publisher.tryMap {
            try M.transform(ContextResponse(response: $0), for: request, by: transform)
        }.eraseToAnyPublisher()
    }

    // MARK: Asynchronous + AnyPublisher
    // all publisher async method will call Request version
    func asyncWithCombine(_ request: RequestPacket) -> Deferred<Future<ResponsePacket<Void>, Error>> {
        return Deferred {
            Future { promise in
                self.async(request) { (result: ResponsePacket<Void>) in
                    promise(.success(result))
                }
            }
        }
    }

    func asyncWithCombine<R: Message>(_ request: RequestPacket) -> Deferred<Future<ResponsePacket<R>, Error>> {
        return Deferred {
            Future { promise in
                self.async(request) { (result: ResponsePacket<R>) in
                    promise(.success(result))
                }
            }
        }
    }

    func asyncWithCombine(_ request: RequestPacket) -> AnyPublisher<Void, Error> {
        return asyncWithCombine(request)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
    func asyncWithCombine<R: Message>(_ request: RequestPacket) -> AnyPublisher<R, Error> {
        return asyncWithCombine(request)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
    func asyncWithCombine<R: Message>(message: Message,
                                      parentID: String? = nil,
                                      barrier: Bool = false) -> AnyPublisher<R, Error> {
        var req = RequestPacket(message: message)
        req.parentID = parentID
        req.barrier = barrier
        return asyncWithCombine(req)
    }

    func sendAsyncRequestWithCombine(_ request: SwiftProtobuf.Message) -> AnyPublisher<Void, Error> {
        return self.asyncWithCombine(RequestPacket(message: request))
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine(_ request: Message, spanID: UInt64?) -> AnyPublisher<Void, Error> {
        return self.asyncWithCombine(RequestPacket(message: request, spanID: spanID))
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> AnyPublisher<R, Error> {
        return self.asyncWithCombine(RequestPacket(message: request))
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               spanID: UInt64?) -> AnyPublisher<R, Error> {
        return self.asyncWithCombine(RequestPacket(message: request, spanID: spanID))
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> AnyPublisher<ContextResponse<R>, Error> {
        return self.asyncWithCombine(RequestPacket(message: request))
            .tryMap { try ContextResponse(response: $0) }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                               spanID: UInt64?)
    -> AnyPublisher<ContextResponse<R>, Error> {
        return self.asyncWithCombine(RequestPacket(message: request,
                                        spanID: spanID))
            .tryMap { try ContextResponse(response: $0) }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) -> AnyPublisher<U, Error> {
        return self.asyncWithCombine(RequestPacket(message: request)).tryMap {
            try M.transform($0.result.get(), for: request, by: transform)
        }.eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        spanID: UInt64?,
        transform: @escaping(R) throws -> U
    ) -> AnyPublisher<U, Error> {
        return self.asyncWithCombine(RequestPacket(message: request, spanID: spanID))
            .tryMap { try M.transform($0.result.get(), for: request, by: transform) }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> AnyPublisher<U, Error> {
        return self.asyncWithCombine(RequestPacket(message: request))
            .tryMap { try M.transform(ContextResponse(response: $0), for: request, by: transform) }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        spanID: UInt64?,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> AnyPublisher<U, Error> {
        return self.asyncWithCombine(RequestPacket(message: request, spanID: spanID))
            .tryMap { try M.transform(ContextResponse(response: $0), for: request, by: transform) }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestBarrierWithCombine(_ request: SwiftProtobuf.Message) -> AnyPublisher<Void, Error> {
        var req = RequestPacket(message: request)
        req.barrier = true
        return self.asyncWithCombine(req)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
    func sendAsyncRequestBarrierWithCombine(_ request: SwiftProtobuf.Message,
                                            spanID: UInt64?) -> AnyPublisher<Void, Error> {
        var req = RequestPacket(message: request, spanID: spanID)
        req.barrier = true
        return self.asyncWithCombine(req)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendAsyncRequestBarrierWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> AnyPublisher<ContextResponse<R>, Error> {
        var req = RequestPacket(message: request)
        req.barrier = true
        return self.asyncWithCombine(req)
            .tryMap { try ContextResponse(response: $0) }
            .eraseToAnyPublisher()
    }
    func sendAsyncRequestBarrierWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                                      spanID: UInt64?)
    -> AnyPublisher<ContextResponse<R>, Error> {
        var req = RequestPacket(message: request, spanID: spanID)
        req.barrier = true
        return self.asyncWithCombine(req)
            .tryMap { try ContextResponse(response: $0) }
            .eraseToAnyPublisher()
    }

    func sendPassThroughAsyncRequestWithCombine(_ request: SwiftProtobuf.Message,
                                                serCommand: ServerPB_Improto_Command)
    -> AnyPublisher<Void, Error> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
    func sendPassThroughAsyncRequestWithCombine(_ request: SwiftProtobuf.Message,
                                                serCommand: ServerPB_Improto_Command,
                                                spanID: UInt64?)
    -> AnyPublisher<Void, Error> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendPassThroughAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                                          serCommand: ServerPB_Improto_Command)
    -> AnyPublisher<R, Error> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
    func sendPassThroughAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                                          serCommand: ServerPB_Improto_Command,
                                                                          spanID: UInt64?)
    -> AnyPublisher<R, Error> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }

    func sendPassThroughAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                                          serCommand: ServerPB_Improto_Command)
    -> AnyPublisher<ContextResponse<R>, Error> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try ContextResponse(response: $0) }
            .eraseToAnyPublisher()
    }
    func sendPassThroughAsyncRequestWithCombine<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                                          serCommand: ServerPB_Improto_Command,
                                                                          spanID: UInt64?)
    -> AnyPublisher<ContextResponse<R>, Error> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try ContextResponse(response: $0) }
            .eraseToAnyPublisher()
    }

    func sendPassThroughAsyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        serCommand: ServerPB_Improto_Command,
        transform: @escaping(R) throws -> U
    ) -> AnyPublisher<U, Error> {
        var packet = RequestPacket(message: request)
        packet.serCommand = serCommand
        return self.asyncWithCombine(packet)
            .tryMap { try M.transform($0.result.get(), for: request, by: transform) }
            .eraseToAnyPublisher()
    }
    func sendPassThroughAsyncRequestWithCombine<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        serCommand: ServerPB_Improto_Command,
        transform: @escaping(R) throws -> U,
        spanID: UInt64?
    ) -> AnyPublisher<U, Error> {
        var packet = RequestPacket(message: request, spanID: spanID)
        packet.serCommand = serCommand
        return self.asyncWithCombine(RequestPacket(message: request))
            .tryMap { try M.transform($0.result.get(), for: request, by: transform) }
            .eraseToAnyPublisher()
    }
}
