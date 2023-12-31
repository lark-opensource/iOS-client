//
//  HttpClient.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import SwiftProtobuf
import ByteViewCommon
import ByteViewTracker
import ServerPB

public final class HttpClient {
    private static let logger = Logger.network

    private static var dependency: NetworkDependency?
    private static var errorHandler: NetworkErrorHandler?

    public static func setupDependency(_ dependency: NetworkDependency) {
        self.dependency = dependency
    }

    public static func setupErrorHandler(_ handler: NetworkErrorHandler) {
        self.errorHandler = handler
    }

    public let userId: String
    public init(userId: String) {
        self.userId = userId
    }

    public func send<R: NetworkRequest>(
        _ req: R, options: NetworkRequestOptions = .none,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        _send(req, options: options, transformer: { _ in Void() }, completion: completion)
    }

    public func getResponse<R: NetworkRequestWithResponse>(
        _ req: R, options: NetworkRequestOptions = .none,
        completion: ((Result<R.Response, Error>) -> Void)?
    ) {
        _send(req, options: options, transformer: { try R.Response.init(serializedData: $0) }, completion: completion)
    }

    public func getResponse<R: NetworkRequestWithCustomResponse>(
        _ req: R, context: R.Response.CustomContext, options: NetworkRequestOptions = .none,
        completion: ((Result<R.Response, Error>) -> Void)?
    ) {
        _send(req, options: options, transformer: { try R.Response.init(serializedData: $0, context: context) }, completion: completion)
    }

    private func _send<Req: NetworkRequest, Resp>(
        _ request: Req, options: NetworkRequestOptions,
        transformer: @escaping (Data) throws -> Resp,
        completion: ((Result<Resp, Error>) -> Void)?
    ) {
        guard let dependency = HttpClient.dependency else {
            completion?(.failure(NetworkError.rustNotFound))
            return
        }

        let reqName = Req.protoName
        let command = Req.command
        let contextId = Self.uuidGenerator.generate()
        let logger = Logger.network.withContext(contextId).withTag("[\(reqName)]")
        do {
            var options = options
            if options.isNone, let opt = Req.defaultOptions {
                options = opt
            }
            if options.retryCount > 0, options.retryOwner == nil {
                options.retryOwner = DefaultHttpClientRetryOwner.permanentOwner
            }
            let raw = RawRequest(userId: userId, contextId: contextId, command: command,
                                 data: try request.serializedData(),
                                 keepOrder: options.keepOrder, contextIdCallback: { id in
                logger.info("createRequestPacket, fullContextId = \(id)")
                options.contextIdCallback?(id)
            })
            let retryInfo = options.retryCount > 0 ? ", retryCount \(options.retryCount)" : ""
            logger.info("will send request\(retryInfo): \(command), message = \(request)")
            let startTime = CACurrentMediaTime()
            dependency.sendRequest(request: raw) { response in
                let duration = Util.formatTime(CACurrentMediaTime() - startTime)
                let result = response.result.flatMap { data in Result(catching: { try transformer(data) }) }
                switch result {
                case .success(let obj):
                    let respInfo = options.shouldPrintResponse ? ", response = \(obj)" : ""
                    logger.info("send request success: duration = \(duration)\(respInfo)")
                    completion?(.success(obj))
                case .failure(let error):
                    logger.error("send request failed: duration = \(duration), error = \(error)")
                    var trackParams: [String: Any] = [
                        "context_id": response.contextId,
                        "message": reqName,
                        "command": command.rawValue,
                        "command_type": command.isServerCommand ? "server" : "rust"
                    ]
                    if let bizError = error as? RustBizError {
                        trackParams["code"] = bizError.code
                        trackParams["debug_msg"] = bizError.debugMessage
                        AppreciableTracker.shared.trackError(.vc_perf_http_error, params: trackParams)
                        if options.shouldHandleError {
                            self.handleBizError(bizError, options: options) { e in
                                completion?(.failure(e))
                            }
                        } else {
                            completion?(.failure(bizError))
                        }
                    } else if options.retryOwner != nil, options.retryCount > 0 {
                        /// bizError不重试
                        var retryOptions = options
                        retryOptions.retryCount -= 1
                        self._send(request, options: retryOptions, transformer: transformer, completion: completion)
                    } else {
                        trackParams["code"] = -1
                        trackParams["debug_msg"] = error.localizedDescription
                        AppreciableTracker.shared.trackError(.vc_perf_http_error, params: trackParams)
                        completion?(.failure(error))
                    }
                }
            }
        } catch {
            logger.error("Convert request to protobuf failed. req = \(request), error = \(error)")
            completion?(.failure(error))
        }
    }

    private func handleBizError(_ error: RustBizError, options: NetworkRequestOptions, completion: @escaping (Error) -> Void) {
        preprocessBizError(error) { e in
            var result = e
            if let h = options.preErrorHandler, h.handleBizError(httpClient: self, error: result) {
                result.isHandled = true
            } else if let h = HttpClient.errorHandler, h.handleBizError(httpClient: self, error: result) {
                result.isHandled = true
            }
            completion(result)
        }
    }

    private func preprocessBizError(_ error: RustBizError, completion: @escaping (RustBizError) -> Void) {
        guard let msgInfo = error.msgInfo, msgInfo.isShow else {
            completion(error)
            return
        }
        #if BYTEVIEW_NETWORK_HAS_I18N
        var error = error
        switch msgInfo.type {
        case .toast:
            if msgInfo.isOverride {
                i18n.get(by: msgInfo.msgI18NKey, defaultContent: msgInfo.message) { (content) in
                    error.content = content
                    completion(error)
                }
            } else {
                completion(error)
            }
        case .popup:
            i18n.get(by: msgInfo.msgI18NKey, defaultContent: "") { (content) in
                error.content = content
                completion(error)
            }
        case .alert:
            guard let alert = msgInfo.alert, let footer = alert.footer else {
                completion(error)
                return
            }
            i18n.get([alert.title.i18NKey, alert.body.i18NKey, footer.text.i18NKey]) { result in
                if case .success(let dict) = result {
                    error.i18nValues = dict
                }
                completion(error)
            }
        default:
            completion(error)
        }
        #else
        completion(error)
        #endif
    }

    private static let uuidGenerator = UUIDGenerator(count: 8, strict: false)
}

private class DefaultHttpClientRetryOwner {
    static let permanentOwner = DefaultHttpClientRetryOwner()
}
