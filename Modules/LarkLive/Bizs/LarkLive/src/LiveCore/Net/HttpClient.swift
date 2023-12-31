// swiftlint:disable line_length file_length
//
//  DefaultHttpClient.swift
//  ByteView
//
//  Created by kiri on 2020/9/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import ServerPB
import LarkRustClient
import RxSwift
import RxRelay
import RustPB

typealias MsgInfo = Videoconference_V1_MsgInfo

struct RustHandledError: Error, Equatable {
    var error: RCError
    var msgInfo: MsgInfo
    var content: String

    static func == (lhs: RustHandledError, rhs: RustHandledError) -> Bool {
        switch (lhs.error, rhs.error) {
        case let (.businessFailure(errorInfo: linfo), .businessFailure(errorInfo: rinfo)):
            return linfo.code == rinfo.code
        default:
            return lhs.error.description == rhs.error.description
        }
    }
}

protocol RequestCacheable: Message {
    associatedtype ResponseType: Message
    func toCacheKey() -> String
}

protocol CommonRequestErrorHandler: AnyObject {
    func handlePopupError(with content: String, errCode: Int32?, msgInfo: MsgInfo?) -> Bool
}

class ContextID {
    var contextID: String = ""
}

// MARK: - lifecycle
public final class HttpClient {
    static let logger = Logger.network
    private static let proxy = RustServiceProxy()

    /// user scope disposeBag
    private(set) static var disposeBag = DisposeBag()
    static weak var popupErrorHandler: CommonRequestErrorHandler?

    public static func setup(rustService: RustService) {
        disposeBag = DisposeBag()
        proxy.service = rustService
    }

    static func destroy() {
        disposeBag = DisposeBag()
//        clearCache()
    }
}

// MARK: - completion
extension HttpClient {
    static func async<R: Message>(_ request: Message, _ responseType: R.Type, isHandleError: Bool = true,
                                  completion: ((Result<R, Error>) -> Void)?) {
        let contextID: ContextID = ContextID()
        let contextIdCallback: ((String) -> Void) = { contextID.contextID = $0 }
        async(createRequestPacket(message: request, contextIdCallback: contextIdCallback),
              responseType,
              isHandleError: isHandleError,
              contextID: contextID,
              completion: completion)
    }

    static func async(_ request: Message, isHandleError: Bool = true, completion: ((Bool, Error?) -> Void)?) {
        let contextID: ContextID = ContextID()
        let contextIdCallback: ((String) -> Void) = { contextID.contextID = $0 }
        async(createRequestPacket(message: request, contextIdCallback: contextIdCallback),
              isHandleError: isHandleError,
              contextID: contextID,
              completion: completion)
    }

    // MARK: PassThrough
    static func passThroughAsync<R: Message>(_ request: Message, _ responseType: R.Type, serCommand: ServerPB_Improto_Command,
                                             isHandleError: Bool = true, completion: ((Result<R, Error>) -> Void)?) {
        let contextID: ContextID = ContextID()
        let contextIdCallback: ((String) -> Void) = { contextID.contextID = $0 }
        async(createRequestPacket(message: request, passThroughSerCommand: serCommand, contextIdCallback: contextIdCallback),
              responseType,
              isHandleError: isHandleError,
              contextID: contextID,
              completion: completion)
    }

    static func passThroughAsync(_ request: Message, serCommand: ServerPB_Improto_Command,
                                 isHandleError: Bool = true, completion: ((Bool, Error?) -> Void)?) {
        let contextID: ContextID = ContextID()
        let contextIdCallback: ((String) -> Void) = { contextID.contextID = $0 }
        async(createRequestPacket(message: request, passThroughSerCommand: serCommand, contextIdCallback: contextIdCallback),
              isHandleError: isHandleError,
              contextID: contextID,
              completion: completion)
    }

    static func async<R: Message>(_ packet: RequestPacket, _ responseType: R.Type, isHandleError: Bool = true, contextID: ContextID,
                                  completion: ((Result<R, Error>) -> Void)?) {
        proxy.async(packet, responseType) { (r) in
            switch r {
            case .failure(let error):
                let packetName = packet.serCommand?.rawValue.description ?? type(of: packet.message).protoMessageName
                if isHandleError {
                    handleError(error) {
                        completion?(.failure($0))
                    }
                } else {
                    completion?(.failure(error))
                }
            default:
                completion?(r)
            }
        }
    }

    static func async(_ packet: RequestPacket, isHandleError: Bool = true, contextID: ContextID, completion: ((Bool, Error?) -> Void)?) {
        proxy.async(packet) { (r, error) in
            if let error = error {
                let packetName = packet.serCommand?.rawValue.description ?? type(of: packet.message).protoMessageName
                if isHandleError {
                    handleError(error) {
                        completion?(false, $0)
                    }
                } else {
                    completion?(false, error)
                }
            } else {
                completion?(r, error)
            }
        }
    }

    private static func handleError(_ error: Error, completion: @escaping (Error) -> Void) {
        guard let rcerror = error as? RCError, case let RCError.businessFailure(errorInfo) = rcerror else {
            completion(error)
            return
        }

        let jsonString = errorInfo.displayMessage
        guard !jsonString.isEmpty, let msgInfo = try? MsgInfo(jsonString: jsonString), msgInfo.isShow else {
            completion(error)
            return
        }
        completion(error)
    }
}

// MARK: - Rx
extension HttpClient {
    static func createRequestPacket(
        message: Message,
        passThroughSerCommand: ServerPB_Improto_Command? = nil,
        contextIdCallback: ((String) -> Void)? = nil) -> RequestPacket {
        var pkt = RequestPacket(message: message)
        pkt.serCommand = passThroughSerCommand
        pkt.contextIdGenerationCallback = { contextId in
            logger.info("createRequestPacket: \(type(of: message)), contextId = \(contextId)")
            contextIdCallback?(contextId)
        }
        return pkt
    }

    static func async<R: Message>(_ request: Message, _ responseType: R.Type, isHandleError: Bool = true) -> Single<R> {
        let contextID: ContextID = ContextID()
        let contextIdCallback: ((String) -> Void) = { contextID.contextID = $0 }
        return async(createRequestPacket(message: request, contextIdCallback: contextIdCallback),
                     responseType,
                     isHandleError: isHandleError,
                     contextID: contextID)
    }

    static func async(_ request: Message, isHandleError: Bool = true) -> Completable {
        let contextID: ContextID = ContextID()
        let contextIdCallback: ((String) -> Void) = { contextID.contextID = $0 }
        return async(createRequestPacket(message: request, contextIdCallback: contextIdCallback),
                     isHandleError: isHandleError,
                     contextID: contextID)
    }
    static func async<R: Message>(_ packet: RequestPacket, _ responseType: R.Type, isHandleError: Bool = true, contextID: ContextID) -> Single<R> {
        let debugServerCommand: Int = packet.serCommand?.rawValue ?? -1 // https://bytedance.feishu.cn/docs/doccnHNvngF7zW4tK27Z4S
        logger.debug("will send async request: \(packet.message), serverCommand: \(String(describing: debugServerCommand))")
        return proxy.async(packet).map { try $0.result.get() }.catchError { (error) -> Observable<R> in
            logger.error("Send request \(packet.message) to rust service failed error: \(error).")
            let packetName = packet.serCommand?.rawValue.description ?? type(of: packet.message).protoMessageName
            if isHandleError {
                return handleError(error)
            } else {
                return .error(error)
            }
        }.asSingle()
    }

    static func async(_ packet: RequestPacket, isHandleError: Bool = true, contextID: ContextID) -> Completable {
        let debugServerCommand: Int = packet.serCommand?.rawValue ?? -1
        logger.debug("will send async request: \(packet.message), serverCommand: \(String(describing: debugServerCommand))")
        return proxy.async(packet).map { try $0.result.get() }.catchError { (error) -> Observable<Void> in
            logger.error("Send request \(packet.message) to rust service failed error: \(error).")
            let packetName = packet.serCommand?.rawValue.description ?? type(of: packet.message).protoMessageName
            if isHandleError {
                return handleError(error)
            } else {
                return .error(error)
            }
        }.ignoreElements()
    }

    private static func handleError<R>(_ error: Error) -> Observable<R> {
        Observable.create { (ob) -> Disposable in
            handleError(error) {
                ob.onError($0)
            }
            return Disposables.create()
        }
    }
}

// MARK: - Proxy
extension HttpClient {
    private final class RustServiceProxy {
        var service: RustService?
        // MARK: Asynchronous + Completion
        func async(_ packet: RequestPacket, completion: ((Bool, Error?) -> Void)?) {
            guard let service = self.service else {
                Logger.network.error("RustService is nil")
                completion?(false, VCError.unknown)
                return
            }
            let message = packet.message
            let serverCommand = packet.serCommand?.rawValue
            Logger.network.debug("will send async request: \(message), serverCommand: \(serverCommand?.description)")
            service.async(packet) { (resp: ResponsePacket<Void>) in
                switch resp.result {
                case .success:
                    Logger.network.info("send request to rust service success: contextId = \(resp.contextID).")
                    completion?(true, nil)
                case .failure(let error):
                    Logger.network.error("send request to rust service failed: contextId = \(resp.contextID), message = \(message)",
                                         error: error)
                    completion?(false, error)
                }
            }
        }

        func async<R: Message>(_ packet: RequestPacket, _ responseType: R.Type, completion: ((Result<R, Error>) -> Void)?) {
            guard let service = self.service else {
                Logger.network.error("RustService is nil")
                completion?(.failure(VCError.unknown))
                return
            }
            let message = packet.message
            let serverCommand = packet.serCommand?.rawValue
            Logger.network.debug("will send async request: \(message), serverCommand: \(serverCommand?.description)")
            service.async(packet) { (resp: ResponsePacket<R>) in
                switch resp.result {
                case .success(let r):
                    Logger.network.info("send request to rust service success: contextId = \(resp.contextID).")
                    completion?(.success(r))
                case .failure(let error):
                    Logger.network.error("send request to rust service failed: contextId = \(resp.contextID), message = \(message)",
                                         error: error)
                    completion?(.failure(error))
                }
            }
        }

        // MARK: Asynchronous + Observable
        // all observable async method will call Request version
        func async(_ request: RequestPacket) -> Observable<ResponsePacket<Void>> {
            guard let service = self.service else {
                Logger.network.error("RustService is nil")
                return .error(VCError.unknown)
            }
            return service.async(request)
        }

        func async<R: Message>(_ request: RequestPacket) -> Observable<ResponsePacket<R>> {
            guard let service = self.service else {
                Logger.network.error("RustService is nil")
                return .error(VCError.unknown)
            }
            return service.async(request)
        }
    }
}


