//
//  PassportHTTPClient.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkContainer

// TODO: .boe 区分使用
import LarkReleaseConfig

class HTTPClient {

    static let logger = Logger.plog(HTTPClient.self, category: "SuiteLogin.PassportHTTPClient")

    @Provider var tokenManager: PassportTokenManager
    @Provider var userManager: UserManager
    @Provider var helper: V3APIHelper

    var suiteSessionKey: String? {
        userManager.foregroundUser?.suiteSessionKey // user:current
    }

    private var middlewares: [MiddlewareType: HTTPMiddlewareProtocol] = [:]
    private var middlewareConfigs: [MiddlewareType: HTTPMiddlewareConfig] = [:]

    init() {
        middlewares = [
            .fetchDeviceId: FetchDeviceIdMiddleWare(helper: helper),
            .captcha: CaptchaTokenMiddleWare(helper: helper),
            .checkNetwork: CheckNetworkMiddleWare(),
            .requestCommonHeader: CommonHeaderMiddleWare(helper: helper),
            .saveToken: UpdateHeaderMiddleWare(helper: helper),
            .costTimeRecord: RequestCostMiddleWare(helper: helper),
            .injectParams: InjectParamsMiddleWare(helper: helper),
            .pwdRetry: PwdRetryMiddleWare(),
            .toastMessage: ToastMessageMiddleWare(helper: helper),
            .crossUnit: CrossUnitMiddleWare(),
            .checkSession: CheckSessionMiddleWare(),
            .updateDomain: UpdateDomainMiddleware(),
            .checkLocalSecEnv: CheckLocalSecEnvMiddleWare(helper: helper),
            .fetchUniDeviceId: FetchUniDidMiddleware(helper: helper)
            
        ]
        middlewareConfigs = middlewares.mapValues { $0.config() }
    }

    func send<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        success: @escaping (ResponseData, ResponseHeader) -> Void,
        failure: @escaping (V3LoginError) -> Void
    ) {
        prepare(request)
        processRequest(request, failure, success: {
            self.innerSend(
                request,
                success: { (data, header) in
                    self.processSuccess(request, data, header, success, failure)
                },
                failure: { error in
                    self.processFailure(request, error, success, failure)
                })
            })
    }

    func send<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>
    ) -> Observable<ResponseData> {
        return Observable.create { (ob) -> Disposable in
            self.send(request, success: { (resp, _) in
                ob.onNext(resp)
                ob.onCompleted()
            }, failure: { error in
                ob.onError(error)
            })
            return Disposables.create()
        }
    }

    private func processRequest<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        _ failure: @escaping (V3LoginError) -> Void,
        success: @escaping () -> Void
    ) {
        executeRequestMiddleWare(
            request,
            complete: {
                if let error = request.context.error {
                    failure(error)
                    return
                }
                success()
            })
    }

    private func processSuccess<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        _ data: ResponseData,
        _ header: ResponseHeader,
        _ success: @escaping (ResponseData, ResponseHeader) -> Void,
        _ failure: @escaping (V3LoginError) -> Void
    ) {
        request.response.header = header
        self.executeResponseMiddleWare(request, complete: {
            if let error = request.context.error {
                failure(error)
                return
            }
            success(data, header)
        })
    }

    private  func processFailure<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        _ error: V3LoginError,
        _ success: @escaping (ResponseData, ResponseHeader) -> Void,
        _ failure: @escaping (V3LoginError) -> Void
    ) {
        request.context.error = error
        self.executeErrorMiddleWare(request, complete: {
            if let error = request.context.error {
                if request.context.needRetry, request.retryTime < request.maxRetryTime {
                    let retryRequest = request.retryRequest()
                    DispatchQueue.global().async {
                        self.send(retryRequest, success: success, failure: failure)
                    }
                } else {
                    failure(error)
                }
            } else {
                failure(error)
            }
        })
    }

    private func innerSend<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        success: @escaping (ResponseData, ResponseHeader) -> Void,
        failure: @escaping (V3LoginError) -> Void
    ) {
        Self.logger.info("n_net_client_send_request", body: "path: \(request.path) flow: \(request.context.uniContext?.from.rawValue ?? "nil")")
        var task: URLSessionTask?
        request.context.state = .running
        task = HTTPToolV3.share.send(request, success: { (resp, header) in
            self.removePendingTask(task)
            request.context.state = .finish
            success(resp, header)
        }, failure: { error in
            self.removePendingTask(task)
            request.context.state = .finish
            failure(error)
        })
        addPendingTask(task)
        request.task = task
    }

    // MARK: middle ware

    private func sortedMiddlewareTypes<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        aspect: HTTPMiddlewareAspect
    ) -> [MiddlewareType] {
        return request.middlewareTypes.union(request.commonMiddlewareTypes)
            .compactMap { (type) -> (type: MiddlewareType, priority: HTTPMiddlewarePriority)? in
                if let priority = middlewareConfigs[type]?[aspect] {
                    return (type: type, priority: priority)
                } else {
                    return nil
                }
            }.sorted { $0.priority > $1.priority }
            .map { $0.type }
    }

    private func executeRequestMiddleWare<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void) {
        let middlewareTypes = sortedMiddlewareTypes(request, aspect: .request)
        executeMiddleWrare(
            request,
            middleWareTypes: middlewareTypes,
            middleWares: middlewares,
            complete: complete
        )
    }

    private func executeResponseMiddleWare<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void) {
        let middlewareTypes = sortedMiddlewareTypes(request, aspect: .response)
        executeMiddleWrare(
            request,
            middleWareTypes: middlewareTypes,
            middleWares: middlewares,
            complete: complete
        )
    }

    private func executeErrorMiddleWare<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void) {
        let middlewareTypes = sortedMiddlewareTypes(request, aspect: .error)
        executeMiddleWrare(
            request,
            middleWareTypes: middlewareTypes,
            middleWares: middlewares,
            complete: complete
        )
    }

    private func executeMiddleWrare<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        middleWareTypes: [MiddlewareType],
        middleWares: [MiddlewareType: HTTPMiddlewareProtocol],
        complete: @escaping () -> Void
    ) {
        innerExecuteMiddleWrare(
            request,
            middleWareTypes: middleWareTypes,
            middleWares: middleWares,
            complete: complete
        )
    }

    private func innerExecuteMiddleWrare<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        index: Int = 0,
        middleWareTypes: [MiddlewareType],
        middleWares: [MiddlewareType: HTTPMiddlewareProtocol],
        complete: @escaping () -> Void
    ) {
        if middleWares.isEmpty || index >= middleWareTypes.count {
            complete()
        } else {
            let middleWareType = middleWareTypes[index]
            if let middleware = middleWares[middleWareType] {
                Self.logger.info("\(request.appId?.rawValue ?? "") excuted middleWareType: \(middleWareType)", method: .local)
                middleware.handle(request: request, complete: {
                    self.innerExecuteMiddleWrare(
                        request,
                        index: index + 1,
                        middleWareTypes: middleWareTypes,
                        middleWares: middleWares,
                        complete: complete
                    )
                })
            } else {
                innerExecuteMiddleWrare(
                    request,
                    index: index + 1,
                    middleWareTypes: middleWareTypes,
                    middleWares: middleWares,
                    complete: complete
                )
            }
        }
    }

    private func prepare<ResponseData: ResponseV3>(_ request: PassportRequest<ResponseData>) {
        request.host = helper.fetchDomain(request.domain)
    }

    // MARK: pending task

    private var pendingDataTasks: [URLSessionTask] = []
    private let pendingTaskLock = DispatchSemaphore(value: 1)
}

// MARK: pending task

extension HTTPClient {

    func addPendingTask(_ task: URLSessionTask?) {
        if let task = task {
            pendingTaskLock.wait()
            defer { pendingTaskLock.signal() }
            pendingDataTasks.append(task)
        }
    }

    func removePendingTask(_ task: URLSessionTask?) {
        if let task = task {
            pendingTaskLock.wait()
            defer { pendingTaskLock.signal() }
            pendingDataTasks.lf_remove(object: task)
        }
    }

    func cancelAllPendingTask() {
        pendingTaskLock.wait()
        defer { pendingTaskLock.signal() }
        let tasks = pendingDataTasks
        pendingDataTasks = []
        tasks.forEach { (task) in
            task.cancel()
        }
    }

}

extension HTTPToolV3 {
     func send<ResponseData: ResponseV3>(
        _ request: PassportRequest<ResponseData>,
        success: @escaping (ResponseData, ResponseHeader) -> Void,
        failure: @escaping (V3LoginError) -> Void
     ) -> URLSessionTask? {
        switch request.method {
        case .get, .patch:
            return HTTPToolV3.share.urlRequest(
                withURLString: request.url,
                method: request.method.rawValue,
                header: request.getCombinedHeaders(),
                params: request.getCombinedParams(),
                timeout: request.timeout,
                transform: { (dict, data) -> ResponseData in
                    return try request.response.transform(dictionary: dict, data: data)
                },
                success: success,
                failure: failure
            )
        case .post, .delete:
            return HTTPToolV3.share.bodyRequest(
                with: request.url,
                method: request.method.rawValue,
                header: request.getCombinedHeaders(),
                params: request.getCombinedParams(),
                timeout: request.timeout,
                transform: { (dict, data) -> ResponseData in
                    return try request.response.transform(dictionary: dict, data: data)
                },
                success: success,
                failure: failure
            )
        }
    }
}
