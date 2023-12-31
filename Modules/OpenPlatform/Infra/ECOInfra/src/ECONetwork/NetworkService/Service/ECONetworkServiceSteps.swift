//
//  ECONetworkServicePipelineValue.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation
import LKCommonsLogging

private let logger = Logger.oplog(ECONetworkPipelineStep.self, category: "ECONetwork")

final class ECONetworkServiceStepMonitorStart: ECONetworkPipelineStep {
    private let monitorEnd: ECONetworkServiceStepMonitorEnd

    init(monitorEnd: ECONetworkServiceStepMonitorEnd) {
        self.monitorEnd = monitorEnd
    }
    
    func process<ResultType>(task: ECONetworkServiceTask<ResultType>, callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)) {
        monitorEnd.startRequest()

        let maskValue = ECONetworkLogTools.monitorValue(data: task.request.headerFields)
        let log = """
        ECONetwork/request-id/\(task.trace.getRequestID() ?? ""),
        domain=\(task.request.domain ?? ""),
        path=\(task.request.path),
        method=\(task.request.method),
        header=\(maskValue?.total ?? ""),
        data=\(ECONetworkLogTools.monitorValue(data: task.request.bodyFields)?.total ?? ""),
        cookie=\(maskValue?.cookie ?? "")
        """
        task.trace.info(log, tag: ECONetworkLogKey.startRequest)

        OPMonitor(
            name: kEventName_econetwork_request,
            code: ECONetworkMonitorCode.request_will_start
        )
        .addCategoryValue(ECONetworkMonitorKey.source, task.getSourceString())
        .tracing(task.trace)
        .flush()
        callback(.success(task))
    }
}

final class ECONetworkServiceStepMonitorEnd: ECONetworkPipelineStep, ECONetworkPipelineException {
    private var monitor: OPMonitor?

    fileprivate func startRequest() {
        monitor = OPMonitor(
            name: kEventName_econetwork_request,
            code: ECONetworkMonitorCode.request_will_response
        )
        monitor?.timing()
    }

    func process<ResultType>(task: ECONetworkServiceTask<ResultType>, callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)) {
        Self.updateMonitor(monitor: monitor, task: task)
        callback(.success(task))
    }
    
    func exception<ResultType>(task: ECONetworkServiceTask<ResultType>, error: ECONetworkError) {
        Self.updateMonitor(monitor: monitor, task: task, error: error)
    }

    private static func updateMonitor<ResultType>(monitor: OPMonitor?, task: ECONetworkServiceTask<ResultType>, error: ECONetworkError? = nil) {
        guard let monitor = monitor else { return }
        let errorWapper = ECONetworkErrorWapper(error: error)

        var map = [String: Any]()
        map[ECONetworkMonitorKey.source] = task.getSourceString()
        map[ECONetworkMonitorKey.appId] = task.getAppId()
        map[ECONetworkMonitorKey.appType] = task.getAppType()
        map[ECONetworkMonitorKey.requestId] = task.trace.getRequestID()
        map[ECONetworkMonitorKey.domain] = task.request.domain
        map[ECONetworkMonitorKey.path] = task.request.path
        map[ECONetworkMonitorKey.requestType] = task.type.stringValue
        map[ECONetworkMonitorKey.method] = task.request.method.rawValue
        map[ECONetworkMonitorKey.netStatus] = OPNetStatusHelper.netStatusName()
        map[ECONetworkMonitorKey.requestBodyLength] = task.request.bodyData?.count
        map[ECONetworkMonitorKey.responseBodyLength] = task.response?.bodyData?.count
        map[ECONetworkMonitorKey.larkErrorCode] = errorWapper?.larkErrorCode
        map[ECONetworkMonitorKey.larkErrorStatus] = errorWapper?.larkErrorStatus
        map[ECONetworkMonitorKey.httpCode] = task.response?.statusCode

        monitor
            .tracing(task.trace)
            .addCategoryMap(map)
        if let errorWapper = errorWapper {
            monitor
                .setErrorCode("\(errorWapper.errorCode)")
                .setErrorMessage(errorWapper.errorMessage)
        }
        if error == nil {
            monitor.setResultTypeSuccess()
        } else {
            monitor.setResultTypeFail()
        }
        monitor
            .timing()
            .flush()
    }
}

/// 调度中间件, 按数组序执行 processRequest 注入/修改 Request, 并返回处理后的 Request. 前一个的处理结果会作为后一个的入参
final class ECONetworkServiceStepProcessRequest: ECONetworkPipelineStep {
    
    private let middlewares: [ECONetworkMiddleware]

    init(middlewares: [ECONetworkMiddleware]) {
        self.middlewares = middlewares
    }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        var result: Result<ECONetworkRequest, Error> = .success(task.request)
        let middlewareNames = middlewares.map { String(describing: $0.self) }
        // 按数组序执行 middleware, enumerated 目的是拿到序号 Debug 用
        
        result = middlewares.enumerated().reduce(result) { prevResult, nextMiddleware in
            switch prevResult {
            case .success(let request):
                // 成功, 将结果作为下个中间件的入参, 继续执行
                return nextMiddleware.element.processRequest(task: task, request: request)
            case .failure(let error):
                // 失败, 取出失败的 middleware 名字, 打印错误
                // 执行 middleware 过程中出错了, 检查 middleware 的 processRequest 步骤
                let errorName = nextMiddleware.offset > 0 ? middlewareNames[nextMiddleware.offset - 1] : ""
                logger.error("task<\(task.identifier)>: Step-MiddlewareProcessRequest,\(errorName) interrupte pipeline with error:\(error)")
                return (.failure(error))
            }
        }
        
        // 回调, 同时将 middleware 的 result 转为最终需要 result
        callback(
            result.map{ (request: ECONetworkRequest) in
                task.request = request
                return task
            }.mapError { middleError in
                return .middewareError(middleError)
            }
        )
    }
}

/// 调用序列化器, 序列化 Request 数据
final class ECONetworkServiceStepSerializeInputParams<Parameters, Serializer: ECONetworkRequestSerializer>: ECONetworkPipelineStep where Serializer.Parameters == Parameters {

    private let serializer: Serializer
    private let params: Parameters

    init(serializer: Serializer, params: Parameters) {
        self.serializer = serializer
        self.params = params
    }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        do {
            var request = task.request
            request.update(
                withSerializeResult: try serializer.serialize(context: task.context, request: request, params: params)
            )
            task.request = request
            callback(.success(task))
        } catch let error {
            // 序列化 request 过程中出错了, 检查入参和 RequestSerilizer
            logger.error("task<\(task.identifier)>: Step-SerializeInputParams error:\(error)")
            assertionFailure("task<\(task.identifier)>: Step-SerializeInputParams error:\(error)")
            if let error = error as? ECONetworkError {
                callback(.failure(error))
            } else {
                callback(.failure(.serilizeRequestFail(error)))
            }
        }
    }
}

/// 调度中间件, 按数组序执行 WillStartRequest
final class ECONetworkServiceStepWillStartRequest: ECONetworkPipelineStep {

    private let middlewares: [ECONetworkMiddleware]

    init(middlewares: [ECONetworkMiddleware]) { self.middlewares = middlewares }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        var result: Result<Void, Error> = .success(())
        let middlewareNames = middlewares.map { String(describing: $0.self) }
        // 按数组序执行 middleware, enumerated() 目的是拿到序号 Debug 用
        result = middlewares.enumerated().reduce(result) { prevResult, nextMiddleware in
            switch prevResult {
            case .success():
                return nextMiddleware.element.willStartRequest(task: task, request: task.request)
            case .failure(let error):
                // 失败, 取出失败的 middleware 名字, 打印错误
                // Tips: 调用中间件过程抛错, 检查所有 middlewares 的 willStartRequest 步骤
                let errorName = nextMiddleware.offset > 0 ? middlewareNames[nextMiddleware.offset - 1] : ""
                logger.error("task<\(task.identifier)>: Step-MiddlewareWillStartRequest,\(errorName) interrupte pipeline with error:\(error)")
                return (.failure(error))
            }
        }
        
        // 回调, 同时将 middleware 的 result 转为最终需要 result
        callback( result.map { return task }.mapError{ return .middewareError($0) })
    }
}

/// 开始向服务器发起请求
/// 内部调用 NetworkClient , 构造任务,并执行任务
final class ECONetworkServiceStepPerformRequest: ECONetworkPipelineStep {

    private var client: ECONetworkClientProtocol
    private var clientTask: ECONetworkTaskProtocol?
    private var isRunning: Bool = true
    private let semaphore = DispatchSemaphore(value: 1)
    private var completionHandler: ((Data?, URL?, URLResponse?, Error?) -> Void)?

    init(client: ECONetworkClientProtocol) { self.client = client }

    func process<ResultType>(
        task pipelineTask: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        let serviceRequest = pipelineTask.request
        var clientRequest: URLRequest
        var clientTask: ECONetworkTaskProtocol
        let networkContext = ECONetworkContext(from: pipelineTask, trace: pipelineTask.trace, source: pipelineTask.getSourceString())

        do { clientRequest = try serviceRequest.toURLRequest() }
        catch let error {
            // 生成 Request 错误, 检查 Request 内部是否有异常数据
            assertionFailure("general request fail, error:\(error)")
            logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest general request fial with error: \(error)")
            callback(.failure(.requestError(error))); return
        }

        let maskValue = ECONetworkLogTools.monitorValue(data: clientRequest.allHTTPHeaderFields)
        let log = """
        ECONetwork/request-id/\(pipelineTask.trace.getRequestID() ?? ""),
        domain=\(clientRequest.url?.host ?? ""),
        path=\(clientRequest.url?.path ?? ""),
        method=\(clientRequest.httpMethod ?? ""),
        header=\(maskValue?.total ?? ""),
        data=\(ECONetworkLogTools.monitorValue(data: pipelineTask.request.bodyFields)?.total ?? ""),
        cookie=\(maskValue?.cookie ?? "")
        """
        pipelineTask.trace.info(log, tag: ECONetworkLogKey.sendRequest)

        self.completionHandler = {[weak pipelineTask] data, downloadFileLocation, response, error in
            guard let pipelineTask = pipelineTask else {
                logger.error("PerformRequest miss service task")
                callback(.failure(.stepsError(msg: "PerformRequest miss service task")))
                return
            }
            if let error = error as? ECONetworkError {
                Self.logResponse(trace: pipelineTask.trace, response: response, data: data, error: error)
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest complete with error:\(error)")
                callback(.failure(error))
            } else if let error = error {
                Self.logResponse(trace: pipelineTask.trace, response: response, data: data, error: .networkError(error))
                callback(.failure(.networkError(error)))
            }
            else if let httpResponse = response as? HTTPURLResponse {
                Self.logResponse(trace: pipelineTask.trace, response: httpResponse, data: data, error: nil)

                let response = ECONetworkResponse<ResultType>(
                    statusCode: httpResponse.statusCode,
                    request: clientRequest,
                    response: httpResponse,
                    trace: pipelineTask.trace,
                    data: data,
                    downloadFileLocation: downloadFileLocation
                )
                // context 持有 response, 供后续流程修改
                pipelineTask.response = response
                callback(.success(pipelineTask))
            } else {
                let error = OPError.requestCompleteWithUnexpectResponse(
                    detail: String(describing: response.self)
                )
                Self.logResponse(trace: pipelineTask.trace, response: response, data: data, error: .responseError(error))
                assertionFailure("unexpect response type")
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest unexpect response type error:\(error.description)")
                callback(.failure(.responseError(error)))
            }
        }
        // 根据 task 类型创建对应 task
        switch pipelineTask.type {
        case .dataTask:
            clientTask = client.dataTask(
                with: networkContext,
                request: clientRequest
            ) { [weak self] context, data, response, error in
                self?.completionHandler?(data, nil, response, error)
            }
        case .download:
            clientTask = client.downloadTask(
                with: networkContext,
                request: clientRequest,
                cleanTempFile: false
            ) { [weak self] context, location, response, error in
                self?.completionHandler?( nil, location, response, error)
            }
        case .uploadData:
            guard let bodyData = serviceRequest.bodyData else {
                assertionFailure("Upload bodydata is nil")
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest Upload bodydata is nil")
                self.completionHandler?(
                    nil, nil, nil,
                    ECONetworkError.requestParamsError(detail: "Upload bodydata is nil")
                )
                return
            }
            clientTask = client.uploadTask(
                with: networkContext,
                request: clientRequest,
                from: bodyData
            ) { [weak self] context, data, response, error in
                self?.completionHandler?(data, nil, response, error)
            }
        case .uploadFile:
            guard let file = serviceRequest.uploadFileURL else {
                assertionFailure("Upload fileURL is nil")
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest Upload bodydata is nil")
                self.completionHandler?(
                    nil, nil, nil,
                    ECONetworkError.requestError(OPError.createTaskWithWrongParams(detail: "Upload fileURL is nil"))
                )
                return
            }
            clientTask = client.uploadTask(
                with: networkContext,
                request: clientRequest,
                fromFile: file
            ) { [weak self] context, data, response, error in
                self?.completionHandler?(data, nil, response, error)
            }
        }
        // 将 task 的生命周期交由 step 管理
        self.clientTask = clientTask
        
        logger.info("task<\(pipelineTask.identifier)>: Step-PerformRequest create client task: \(clientTask.taskIdentifier)")

        // 只在开始前拦截任务
        semaphore.wait(); defer {semaphore.signal()}
        if isRunning { clientTask.resume() }
    }

    private static func logResponse(trace: OPTrace, response: URLResponse?, data: Data?, error: ECONetworkError?) {
        var errorWrapper: ECONetworkErrorWapper? = nil
        if let error = error {
            errorWrapper = ECONetworkErrorWapper(error: error)
        }
        let httpResponse = response as? HTTPURLResponse
        var header = [String: Any]()
        for item in httpResponse?.allHeaderFields ?? [:] {
            header["\(item.key)"] = item.value
        }

        let maskValue = ECONetworkLogTools.monitorValue(data: header)
        let log = """
        ECONetwork/request-id/\(trace.getRequestID() ?? ""),
        domain=\(httpResponse?.url?.host ?? ""),
        path=\(httpResponse?.url?.path ?? ""),
        header=\(maskValue?.total ?? ""),
        set-cookie=\(maskValue?.cookie ?? ""),
        status_code=\(httpResponse?.statusCode ?? -1),
        err_code=\(errorWrapper?.errorCode ?? -1),
        err_msg=\(errorWrapper?.errorMessage ?? ""),
        lark_error_code=\(errorWrapper?.larkErrorCode ?? -1),
        lark_error_status=\(errorWrapper?.larkErrorStatus ?? -1),
        data_length=\(data?.count ?? -1)
        """
        trace.info(log, tag: ECONetworkLogKey.getResponse)
    }

    func resume() {
        semaphore.wait(); defer {semaphore.signal()}
        guard !isRunning else {
            /// pipeline 线程锁失效, 状态管理异常, 重复执行任务了
            logger.error("Step-PerformRequest resume when step is running, check pipeline")
            assertionFailure("Resume when step is running, check pipeline")
            return
        }
        guard let requestingTask = self.clientTask else {
            logger.error("Step-PerformRequest requesting task is nil")
            assertionFailure("Requesting task is nil")
            return
        }
        logger.info("Step-PerformRequest clientTask<\(requestingTask.taskIdentifier)> resume")
        requestingTask.resume()
        isRunning = true
    }

    func suspend() {
        semaphore.wait(); defer {semaphore.signal()}
        guard isRunning else {
            /// pipeline 线程锁失效, 状态管理异常, 重复暂停任务了
            logger.error("Step-PerformRequest suspend when step is not running, check pipeline")
            assertionFailure("Suspend when step is not running, check pipeline")
            return
        }
        guard let requestingTask = self.clientTask else {
            /// pipeline 线程锁失效, 状态管理异常, 重复执行任务了
            logger.error("Requesting task is nil")
            assertionFailure("Requesting task is nil")
            return
        }
        logger.info("Step-PerformRequest clientTask<\(requestingTask.taskIdentifier)> suspend")
        requestingTask.suspend()
    }

    func cancel() {
        semaphore.wait(); defer {semaphore.signal()}
        guard let requestingTask = self.clientTask else {
            /// pipeline 线程锁失效, 状态管理异常, 重复执行任务了
            logger.error("Step-PerformRequest requesting task is nil")
            assertionFailure("Requesting task is nil")
            return
        }
        logger.info("Step-PerformRequest clientTask<\(requestingTask.taskIdentifier)> cancel")
        requestingTask.cancel()
    }

}

/// 开始向服务器发起请求
final class ECONetworkServiceStepRustPerformRequest: ECONetworkPipelineStep {

    private let semaphore = DispatchSemaphore(value: 1)
    private var rustClient: ECONetworkRustHttpClientProtocol
    private var rustClientTask: ECONetworkRustTaskProtocol?
    private var isRunning: Bool = true
    private var completionHandler: ((Data?, URL?, URLResponse?, Error?) -> Void)?

    init(client: ECONetworkRustHttpClientProtocol) { self.rustClient = client }
    
    func process<ResultType>(
        task pipelineTask: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        let serviceRequest = pipelineTask.request
        var clientRequest: URLRequest
        var rustClientTask: ECONetworkRustTaskProtocol
        let networkContext = ECONetworkContext(from: pipelineTask, trace: pipelineTask.trace, source: pipelineTask.getSourceString())

        do { clientRequest = try serviceRequest.toURLRequest() }
        catch let error {
            // 生成 Request 错误, 检查 Request 内部是否有异常数据
            assertionFailure("general request fail, error:\(error)")
            logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest general request fial with error: \(error)")
            callback(.failure(.requestError(error))); return
        }

        let maskValue = ECONetworkLogTools.monitorValue(data: clientRequest.allHTTPHeaderFields)
        let log = """
        ECONetwork/request-id/\(pipelineTask.trace.getRequestID() ?? ""),
        domain=\(clientRequest.url?.host ?? ""),
        path=\(clientRequest.url?.path ?? ""),
        method=\(clientRequest.httpMethod ?? ""),
        header=\(maskValue?.total ?? ""),
        data=\(ECONetworkLogTools.monitorValue(data: pipelineTask.request.bodyFields)?.total ?? ""),
        cookie=\(maskValue?.cookie ?? "")
        """
        pipelineTask.trace.info(log, tag: ECONetworkLogKey.sendRequest)

        self.completionHandler = {[weak pipelineTask] data, downloadFileLocation, response, error in
            guard let pipelineTask = pipelineTask else {
                logger.error("PerformRequest miss service task")
                callback(.failure(.stepsError(msg: "PerformRequest miss service task")))
                return
            }
            if let error = error as? ECONetworkError {
                Self.logResponse(trace: pipelineTask.trace, response: response, data: data, error: error)
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest complete with error:\(error)")
                callback(.failure(error))
            } else if let error = error {
                Self.logResponse(trace: pipelineTask.trace, response: response, data: data, error: .networkError(error))
                callback(.failure(.networkError(error)))
            }
            else if let httpResponse = response as? HTTPURLResponse {
                Self.logResponse(trace: pipelineTask.trace, response: httpResponse, data: data, error: nil)

                let response = ECONetworkResponse<ResultType>(
                    statusCode: httpResponse.statusCode,
                    request: clientRequest,
                    response: httpResponse,
                    trace: pipelineTask.trace,
                    data: data,
                    downloadFileLocation: downloadFileLocation
                )
                // context 持有 response, 供后续流程修改
                pipelineTask.response = response
                callback(.success(pipelineTask))
            } else {
                let error = OPError.requestCompleteWithUnexpectResponse(
                    detail: String(describing: response.self)
                )
                Self.logResponse(trace: pipelineTask.trace, response: response, data: data, error: .responseError(error))
                assertionFailure("unexpect response type")
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest unexpect response type error:\(error.description)")
                callback(.failure(.responseError(error)))
            }
        }
        // 根据 task 类型创建对应 task
        switch pipelineTask.type {
        case .dataTask:
            rustClientTask = rustClient.dataTask(
                with: networkContext,
                request: clientRequest
            ) { [weak self] data, response, error in
                self?.completionHandler?(data, nil, response, error)
            }
        case .download:
            rustClientTask = rustClient.downloadTask(
                with: networkContext,
                request: clientRequest,
                cleanTempFile: false
            ) { [weak self] location, response, error in
                self?.completionHandler?( nil, location, response, error)
            }
        case .uploadData:
            guard let bodyData = serviceRequest.bodyData else {
                assertionFailure("Upload bodydata is nil")
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest Upload bodydata is nil")
                self.completionHandler?(
                    nil, nil, nil,
                    ECONetworkError.requestParamsError(detail: "Upload bodydata is nil")
                )
                return
            }
            rustClientTask = rustClient.uploadTask(
                with: networkContext,
                request: clientRequest,
                from: bodyData
            ) { [weak self] data, response, error in
                self?.completionHandler?(data, nil, response, error)
            }
        case .uploadFile:
            guard let file = serviceRequest.uploadFileURL else {
                assertionFailure("Upload fileURL is nil")
                logger.error("task<\(pipelineTask.identifier)>: Step-PerformRequest Upload bodydata is nil")
                self.completionHandler?(
                    nil, nil, nil,
                    ECONetworkError.requestError(OPError.createTaskWithWrongParams(detail: "Upload fileURL is nil"))
                )
                return
            }
            rustClientTask = rustClient.uploadTask(
                with: networkContext,
                request: clientRequest,
                fromFile: file
            ) { [weak self] data, response, error in
                self?.completionHandler?(data, nil, response, error)
            }
        }
        // 将 task 的生命周期交由 step 管理
        self.rustClientTask = rustClientTask
        
        logger.info("task<\(pipelineTask.identifier)>: Step-PerformRequest create client task: \(rustClientTask.taskIdentifier)")

        // 只在开始前拦截任务
        semaphore.wait(); defer {semaphore.signal()}
        if isRunning { rustClientTask.resume() }
    }
    
    private static func logResponse(trace: OPTrace, response: URLResponse?, data: Data?, error: ECONetworkError?) {
        var errorWrapper: ECONetworkErrorWapper? = nil
        if let error = error {
            errorWrapper = ECONetworkErrorWapper(error: error)
        }
        let httpResponse = response as? HTTPURLResponse
        var header = [String: Any]()
        for item in httpResponse?.allHeaderFields ?? [:] {
            header["\(item.key)"] = item.value
        }

        let maskValue = ECONetworkLogTools.monitorValue(data: header)
        let log = """
        ECONetwork/request-id/\(trace.getRequestID() ?? ""),
        domain=\(httpResponse?.url?.host ?? ""),
        path=\(httpResponse?.url?.path ?? ""),
        header=\(maskValue?.total ?? ""),
        set-cookie=\(maskValue?.cookie ?? ""),
        status_code=\(httpResponse?.statusCode ?? -1),
        err_code=\(errorWrapper?.errorCode ?? -1),
        err_msg=\(errorWrapper?.errorMessage ?? ""),
        lark_error_code=\(errorWrapper?.larkErrorCode ?? -1),
        lark_error_status=\(errorWrapper?.larkErrorStatus ?? -1),
        data_length=\(data?.count ?? -1)
        """
        trace.info(log, tag: ECONetworkLogKey.getResponse)
    }
    
    func resume() {
        semaphore.wait(); defer {semaphore.signal()}
        guard !isRunning else {
            /// pipeline 线程锁失效, 状态管理异常, 重复执行任务了
            logger.error("Step-PerformRequest resume when step is running, check pipeline")
            assertionFailure("Resume when step is running, check pipeline")
            return
        }
        guard let requestingTask = self.rustClientTask else {
            logger.error("Step-PerformRequest requesting task is nil")
            assertionFailure("Requesting task is nil")
            return
        }
        logger.info("Step-PerformRequest clientTask<\(requestingTask.taskIdentifier)> resume")
        requestingTask.resume()
        isRunning = true
    }

    func suspend() {
        semaphore.wait(); defer {semaphore.signal()}
        guard isRunning else {
            /// pipeline 线程锁失效, 状态管理异常, 重复暂停任务了
            logger.error("Step-PerformRequest suspend when step is not running, check pipeline")
            assertionFailure("Suspend when step is not running, check pipeline")
            return
        }
        guard let requestingTask = self.rustClientTask else {
            /// pipeline 线程锁失效, 状态管理异常, 重复执行任务了
            logger.error("Requesting task is nil")
            assertionFailure("Requesting task is nil")
            return
        }
        logger.info("Step-PerformRequest clientTask<\(requestingTask.taskIdentifier)> suspend")
        requestingTask.suspend()
    }

    func cancel() {
        semaphore.wait(); defer {semaphore.signal()}
        guard let requestingTask = self.rustClientTask else {
            /// pipeline 线程锁失效, 状态管理异常, 重复执行任务了
            logger.error("Step-PerformRequest requesting task is nil")
            assertionFailure("Requesting task is nil")
            return
        }
        logger.info("Step-PerformRequest clientTask<\(requestingTask.taskIdentifier)> cancel")
        requestingTask.cancel()
    }

}

/// 调度中间件, 按数组序执行 DidCompleteRequest
final class ECONetworkServiceStepDidCompleteRequest: ECONetworkPipelineStep {

    private let middlewares: [ECONetworkMiddleware]

    init(middlewares: [ECONetworkMiddleware]) { self.middlewares = middlewares }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        // 取出 response,这步操作在请求之后, 理论上不能有无 response 的情况
        guard let response = task.response else {
            assertionFailure("response is nil")
            logger.error("task<\(task.identifier)>: Step: DidCompleteRequest response is nil")
            callback(.failure(.stepsError(msg: "Step: CompleteRequest missing response")))
            return
        }

        var result: Result<Void, Error> = .success(())
        let request: ECONetworkRequest = task.request
        let middlewareNames = middlewares.map { String(describing: $0.self) }
        // 按数组序执行 middleware, enumerated 目的是拿到序号 Debug 用
        result = middlewares.enumerated().reduce(result) { prevResult, nextMiddleware in
            switch prevResult {
            case .success(()):
                // 成功, 将结果作为下个中间件的入参, 继续执行
                return nextMiddleware.element.didCompleteRequest(task: task, request: request, response: response)
            case .failure(let error):
                // 失败, 取出失败的 middleware 名字, 打印错误
                let errorName = nextMiddleware.offset > 0 ? middlewareNames[nextMiddleware.offset - 1] : ""
                logger.error("task<\(task.identifier)>: Step-DidCompleteRequest \(errorName) interrupte pipeline with error:\(error)")
                return (.failure(error))
            }
        }

        // 回调, 同时将 middleware 的 result 转为最终需要 result
        callback( result.map { return task }.mapError{ return .middewareError($0) })
    }
}

/// 调用校验器, 验证 Response 是否符合预期
final class ECONetworkServiceStepValidateResponse: ECONetworkPipelineStep {

    private let validator: ECONetworkResponseValidator

    init(validator: ECONetworkResponseValidator) { self.validator = validator }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        // 取出 response,这步操作在请求之后, 理论上不能有无 response 的情况
        guard let response = task.response else {
            assertionFailure("response is nil")
            logger.error("task<\(task.identifier)>: Step: ValidateResponse response is nil")
            callback(.failure(.stepsError(msg: "Step: ValidateResponse missing response")))
            return
        }
        do {
            // 校验 response 数据
            try validator.validate(context: task.context, response: response)
            callback(.success(task))
        } catch let error {
            logger.error("task<\(task.identifier)>: Step-ValidateResponse fail with error:\(error)")
            if let error = error as? ECONetworkError {
                callback(.failure(error))
            } else {
                callback(.failure(.validateFail(error)))
            }
        }
    }
}

/// 调用序列化器, 反序列化 Response 数据
final class ECONetworkServiceStepSerializeResponse<Serializer: ECONetworkResponseSerializer>: ECONetworkPipelineStep {

    private let serilizer: Serializer

    init(serilizer: Serializer) { self.serilizer = serilizer }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        // 取出 response,这步操作在请求之后, 理论上不能有无 response 的情况
        guard var response = task.response else {
            assertionFailure("response is nil")
            logger.error("task<\(task.identifier)>: Step: SerializeResponse response is nil")
            callback(.failure(.stepsError(msg: "Step: SerializeResponse missing response")))
            return
        }
        do {
            // 序列化 response 数据
            let serializedObject = try serilizer.serialize(context: task.context, response: response)
            guard let result = serializedObject as? ResultType else {
                let errMsg = "Serialize error: expect result type: \(ResultType.self), serialized obj type: \(String(describing: serializedObject.self))"
                let error = ECONetworkError.responseTypeError(detail: errMsg)
                assertionFailure(errMsg)
                logger.error("task<\(task.identifier)>: Step-SerializeResponse error:\(errMsg)")
                callback(.failure(error))
                return
            }
            response.updateResult(result: result)
            task.response = response
            callback(.success(task))
        } catch let error {
            assertionFailure("task<\(task.identifier)>: Step-SerializeResponse fail with error:\(error)")
            logger.error("task<\(task.identifier)>: Step-SerializeResponse fail with error:\(error)")
            if let error = error as? ECONetworkError {
                callback(.failure(error))
            } else {
                callback(.failure(.serilizeResponseFail(error)))
            }
        }
    }
}

/// 调度中间件, 按数组序执行 processResponse 注入/修改 response, 并返回处理后的 response. 前一个的处理结果会作为后一个的入参
final class ECONetworkServiceStepProcessResponse: ECONetworkPipelineStep {

    private let middlewares: [ECONetworkMiddleware]

    init(middlewares: [ECONetworkMiddleware]) { self.middlewares = middlewares }

    func process<ResultType>(
        task: ECONetworkServiceTask<ResultType>,
        callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)
    ) {
        // 取出 response,这步操作在请求之后, 理论上不能有无 response 的情况
        guard let response = task.response else {
            assertionFailure("response is nil")
            logger.error("task<\(task.identifier)>: Step: MiddlewareProcessResponse response is nil")
            callback(.failure(.stepsError(msg: "Step: processResponse missing response")))
            return
        }

        var result: Result<ECONetworkResponse<ResultType>, Error> = .success(response)
        let middlewareNames = middlewares.map { String(describing: $0.self) }
        // 按数组序执行 middleware, enumerated 目的是拿到序号 Debug 用
        result = middlewares.enumerated().reduce(result) { prevResult, nextMiddleware in
            switch prevResult {
            case .success(let response):
                // 成功, 将结果作为下个中间件的入参, 继续执行
                return nextMiddleware.element.processResponse(task: task, request: task.request, response: response)
            case .failure(let error):
                // 失败, 取出失败的 middleware 名字, 打印错误
                // 执行 middleware 过程中出错了, 检查 middleware 的 processResponse 步骤
                let errorName = nextMiddleware.offset > 0 ? middlewareNames[nextMiddleware.offset - 1] : ""
                logger.error("task<\(task.identifier)>: Step-MiddlewareProcessResponse,\(errorName) interrupte pipeline with error:\(error)")

                let log = """
                ECONetwork/request-id/\(task.trace.getRequestID() ?? ""),
                domain=\(task.request.domain ?? ""),
                path=\(task.request.path),
                error_msg=process response fail \(error.localizedDescription)
                """
                task.trace.info(log, tag: ECONetworkLogKey.getResponseEdit)

                return (.failure(error))
            }
        }
        
        // 回调, 同时将 middleware 的 result 转为最终需要 result
        callback(
            result.map { (response: ECONetworkResponse<ResultType>) in
                task.response = response
                return task
            }.mapError { middleError in
                return .middewareError(middleError)
            }
        )
    }
}

/// 调度中间件,  通知中间件请求发生异常, 由中间件自行处理异常
final class ECONetworkServiceStepRequestException: ECONetworkPipelineException {
    private let middlewares: [ECONetworkMiddleware]
    init(middlewares: [ECONetworkMiddleware]) { self.middlewares = middlewares }
    func exception<ResultType>(task: ECONetworkServiceTask<ResultType>, error: ECONetworkError) {
        let middlewareNames = middlewares.map { String(describing: $0.self) }.joined(separator: ",")
        logger.info("task<\(task.identifier)>: Step-RequestException middlewareNames: \(middlewareNames)")
        middlewares.forEach { $0.requestException(task: task, error: error, request: task.request, response: task.response) }
    }
}


/// 清理过程中产生的垃圾文件, 成功失败都会执行
final class ECONetworkServiceStepCleanWorkSpace: ECONetworkPipelineStep, ECONetworkPipelineException {
    /// 清理 pipeline 执行过程产生的临时数据
    private func cleanWorkSpace<ResultType>(task: ECONetworkServiceTask<ResultType>) {
        guard let URL = task.response?.downloadFileLocation else { return }
        // lint:disable:next lark_storage_check
        do { try FileManager.default.removeItem(at: URL) }
        catch let error {
            assertionFailure("removeItem fail with error:\(error)")
            logger.error("removeItem fail with error:\(error)")
        }
    }
    
    func process<ResultType>(task: ECONetworkServiceTask<ResultType>, callback: @escaping ((Result<ECONetworkServiceTask<ResultType>, ECONetworkError>) -> Void)) {
        cleanWorkSpace(task: task)
        // 清理任务不会影响 pipeline 结果
        callback(.success(task))
    }
    
    func exception<ResultType>(task: ECONetworkServiceTask<ResultType>, error: ECONetworkError) {
        cleanWorkSpace(task: task)
    }
}
