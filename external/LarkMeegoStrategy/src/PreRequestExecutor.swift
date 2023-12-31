//
//  PreRequestExecutor.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/9.
//

import Foundation
import LarkMeegoStorage
import LarkMeegoLogger
import LarkMeegoNetClient
import ThreadSafeDataStructure
import LarkContainer
import RxSwift

public struct PreRequestResponse: MeegoResponseType {
    public let dataValue: Any

    public static func build(from data: Data) -> Result<PreRequestResponse, LarkMeegoNetClient.APIError> {
        do {
            let response = try JSONDecoder().decode(Response<String>.self, from: data)
            if response.isValid {
                let responseJson = try JSONSerialization.jsonObject(with: data)
                if let dataValue = (responseJson as? [String: Any])?["data"] as? Any {
                    let preRequestResponse = PreRequestResponse(dataValue: dataValue)
                    return .success(preRequestResponse)
                }
            }
            return .failure(APIErrorFactory.responseNotExpectedError)
        } catch {
            var apiError = APIError(httpStatusCode: MeegoNetClientErrorCode.jsonTransformToModelFailed)
            apiError.errorMsg = "jsonTransformToModelFailed"
            return .failure(apiError)
        }
    }

    public var cacheValue: String? {
        if let data = try? JSONSerialization.data(withJSONObject: dataValue, options: .fragmentsAllowed) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

public extension Response {
    public var isValid: Bool {
        return code == 0 && msg.isEmpty
    }
}

public enum ControlMode {
    case serial
    case concurrent(Int)
}

public protocol Cacheable {
    var cacheKey: String { get }
}

public typealias PreRequest = LarkMeegoNetClient.Request & Cacheable

public protocol PreRequestAPI {
    associatedtype T: PreRequest where T.ResponseType == PreRequestResponse

    func shouldTriggle(with url: URL) -> Bool

    func create(by url: URL, context: T.ResponseType?) -> T?

    func check(with response: T.ResponseType) -> Bool
}

let globalPreRequestFlying = SafeSet<String>()

extension PreRequestAPI {
    func wrap(
        with netClient: MeegoNetClient,
        url: URL,
        context: PreRequestResponse?,
        isConcurrent: Bool
    ) -> Observable<(any PreRequest, PreRequestResponse)> {
        guard let request = create(by: url, context: context) else {
            return .error(APIErrorFactory.urlParseError)
        }
        if isConcurrent {
            globalPreRequestFlying.insert(request.cacheKey)
        }
        return Observable.create { ob in
            netClient.sendRequest(request) { result in
                switch result {
                case .success(let response):
                    if check(with: response) {
                        ob.onNext((request, response))
                    } else {
                        ob.onError(APIErrorFactory.responseNotExpectedError)
                    }
                case .failure(let error):
                    ob.onError(error)
                }
                if isConcurrent {
                    globalPreRequestFlying.remove(request.cacheKey)
                }
                ob.onCompleted()
            }
            return Disposables.create()
        }
    }

    public func shouldTriggle(with url: URL) -> Bool {
        return true
    }

    func create(by url: URL) -> (any PreRequest)? {
        return create(by: url, context: nil)
    }

    public func check(with response: T.ResponseType) -> Bool {
        return true
    }
}

open class PreRequestExecutor: Executor {
    public let type: ExecutorType = .preRequest
    public let scope: MeegoScene
    public let userKvStorage: UserSharedKvStorage
    public let userResolver: UserResolver

    public var preRequestAPIs: [any PreRequestAPI] = []

    // NOTE: 在 concurrent 模式下，高优业务可以适当调高并发数以获得预请求的优先级
    public var controlMode: ControlMode = .concurrent(5)

    public init(
        userResolver: UserResolver,
        userKvStorage: UserSharedKvStorage,
        scope: MeegoScene
    ) {
        self.userResolver = userResolver
        self.userKvStorage = userKvStorage
        self.scope = scope
    }

    public func execute(with context: ExecutorContext) {
        guard let netClient = try? Container.shared.getCurrentUserResolver().resolve(type: MeegoNetClient.self),
              !preRequestAPIs.isEmpty else {
            return
        }
        switch controlMode {
        case .serial:
            var pipeOb: Observable<(any PreRequest, PreRequestResponse)>?
            var cacheKey2Resp: [String: PreRequestResponse] = [:]

            for api in preRequestAPIs where api.shouldTriggle(with: context.url) {
                if let old = pipeOb {
                    pipeOb = old.flatMap({ lastContext in
                        cacheKey2Resp[lastContext.0.cacheKey] = lastContext.1
                        return api.wrap(with: netClient, url: context.url, context: lastContext.1, isConcurrent: false)
                    })
                } else {
                    pipeOb = api.wrap(with: netClient, url: context.url, context: nil, isConcurrent: false)
                }
            }
            guard let pipeOb = pipeOb else { return }

            _ = pipeOb.subscribe(onNext: { [weak self] lastContext in
                guard let `self` = self else { return }
                MeegoLogger.info("serial preRequest pipeline success, scope = \(self.scope.rawValue)", customPrefix: loggerPrefix)

                cacheKey2Resp[lastContext.0.cacheKey] = lastContext.1

                for (key, resp) in cacheKey2Resp {
                    if let expiredSeconds = context.strategy.preRequestConfigs[self.scope]?.expiredSeconds,
                       let cacheValue = resp.cacheValue {
                        _ = self.userKvStorage.setStringAsync(key: key, with: cacheValue, expiredMillis: Int64(expiredSeconds * 1000)).subscribe()
                    }
                }
            }, onError: { [weak self] error in
                if let error = error as? APIError {
                    MeegoLogger.error("serial preRequest pipeline failed, scope = \(self?.scope.rawValue ?? ""), error = \(error.errorMsg ?? "unknown")", customPrefix: loggerPrefix)
                }
            })
        case .concurrent(let maxCount):
            let realAPIs = preRequestAPIs.filter {
                guard $0.shouldTriggle(with: context.url) else {
                    return false
                }
                if let request = $0.create(by: context.url) {
                    // 1. 先检查本地是否有可复用的缓存
                    if let localCache = try? self.userKvStorage.getString(with: request.cacheKey), !localCache.isEmpty {
                        StrategyTracker.signpost(
                            larkScene: context.larkScene,
                            meegoScene: context.meegoScene,
                            action: .preRequestUseCache,
                            url: context.url.absoluteString
                        )
                        MeegoLogger.debug("\(request.cacheKey) already exist in local cache", customPrefix: loggerPrefix)
                        return false
                    }
                    // 2. 再检查是否存在正在运行的等价请求
                    if globalPreRequestFlying.contains(request.cacheKey) {
                        StrategyTracker.signpost(
                            larkScene: context.larkScene,
                            meegoScene: context.meegoScene,
                            action: .preRequestUsePool,
                            url: context.url.absoluteString
                        )
                        MeegoLogger.debug("\(request.cacheKey) already exist in flying", customPrefix: loggerPrefix)
                        return false
                    }
                    return true
                }
                return false
            }
            if realAPIs.isEmpty || globalPreRequestFlying.count + realAPIs.count > maxCount {
                return
            }
            let startTime = Int(Date().timeIntervalSince1970 * 1000)
            let requestContextObs = realAPIs.map { api in
                return api.wrap(with: netClient, url: context.url, context: nil, isConcurrent: true).do(onNext: { _ in
                    StrategyTracker.signpost(
                        larkScene: context.larkScene,
                        meegoScene: context.meegoScene,
                        action: .preRequestSuccess,
                        url: context.url.absoluteString,
                        latency: Int(Date().timeIntervalSince1970 * 1000) - startTime
                    )
                }, onError: { error in
                    StrategyTracker.signpost(
                        larkScene: context.larkScene,
                        meegoScene: context.meegoScene,
                        action: .preRequestFailed,
                        url: context.url.absoluteString,
                        errorMsg: error.localizedDescription
                    )
                }, onSubscribed: {
                    StrategyTracker.signpost(
                        larkScene: context.larkScene,
                        meegoScene: context.meegoScene,
                        action: .preRequest,
                        url: context.url.absoluteString
                    )
                })
            }
            _ = Observable.zip(requestContextObs).subscribe(onNext: { [weak self] apiContexts in
                guard let `self` = self else { return }
                MeegoLogger.info("concurrent preRequest pipeline success, scope = \(self.scope.rawValue)", customPrefix: loggerPrefix)
                for ctx in apiContexts {
                    if let expiredSeconds = context.strategy.preRequestConfigs[self.scope]?.expiredSeconds,
                       let cacheValue = ctx.1.cacheValue {
                        _ = self.userKvStorage.setStringAsync(key: ctx.0.cacheKey, with: cacheValue, expiredMillis: Int64(expiredSeconds * 1000)).subscribe()
                    }
                }
            }, onError: { [weak self] error in
                if let error = error as? APIError {
                    MeegoLogger.error("concurrent preRequest pipeline failed, scope = \(self?.scope.rawValue ?? ""), error = \(error.errorMsg ?? "unknown")", customPrefix: loggerPrefix)
                }
            })
        @unknown default: return
        }
    }
}
