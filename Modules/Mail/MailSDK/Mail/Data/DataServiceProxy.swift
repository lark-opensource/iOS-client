//
//  DataService.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/27.
//

import Foundation
import RxSwift
import RustPB
import SwiftProtobuf
import ServerPB

// swiftlint:disable missing_docs
public protocol DataPushHandler {

    /// will be called when receive push notification of registered command
    ///
    /// - Parameter payload: push notification data
    func processMessage(payload: Data)
}

typealias DataPushHandlerFactory = () -> DataPushHandler

/// used by RustService.registerPushHandler
protocol DataPushHandlerProvider {

    /// - Returns: [command: lazy load handler]
    func getPushHandlers() -> [RustPB.Basic_V1_Command: DataPushHandlerFactory]
}

public protocol DataServiceProxy {

    /// Synchronous
    ///
    /// - parameter command: Command for request
    /// - parameter request: Reqeust base on SwiftProtobuf.Message
    /// - parameter transform: A function used to create a new type response
    ///
    /// - returns: Response with type inferred from defined return value
    /// - throws: `RCError`
    func sendSyncRequest(_ request: SwiftProtobuf.Message) throws

    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) throws -> R

    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, serCommand: ServerPB_Improto_Command) -> Observable<R>
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, serCommand: ServerPB_Improto_Command, mailAccountId: String?) -> Observable<R>
    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
        ) throws -> U

    /// Synchronous + Observable
    ///
    /// - parameter request: Reqeust base on SwiftProtobuf.Message
    /// - parameter transform: A function used to create a new type response
    ///
    /// - returns: A generic observable of new type response with transforming the asynchronous response
    /// - throws: `RCError` when client send request failure, and rethrow `transform`'s Error
    func sendSyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R>

    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
        ) -> Observable<U>

    /// Asynchronous + Observable
    ///
    /// - parameter request: Reqeust base on SwiftProtobuf.Message
    /// - parameter transform: A function used to create a new type response
    ///
    /// - returns: A generic observable of synchronous response, Error of `RCError` or `transform`'s Error
    func sendAsyncRequest(_ request: SwiftProtobuf.Message, mailAccountId: String?) -> Observable<Void>

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, mailAccountId: String?) -> Observable<R>

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        mailAccountId: String?,
        transform: @escaping(R) throws -> U
        ) -> Observable<U>

    /// helper to get command
    func extractCommand(fromRequest: SwiftProtobuf.Message) -> RustPB.Basic_V1_Command
}
