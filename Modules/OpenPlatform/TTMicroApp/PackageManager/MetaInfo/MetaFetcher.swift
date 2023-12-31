//
//  MetaFetcher.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/22.
//

import Foundation
import LarkOPInterface
import OPSDK
import LarkRustHTTP
import LKCommonsLogging

/// meta 请求器配置
public struct MetaFetcherConfiguration {

    /// 是否需要复用相同的请求，默认不复用
    let shouldReuseSameRequest: Bool

    /// 请求最大并发数，默认值是CPU活跃核心数*2
    let maxConcurrentOperationCount: Int

    /// 请求超时时间，默认60s
    let timeoutIntervalForRequest: TimeInterval

    /// 初始化 meta 请求器配置
    /// - Parameters:
    ///   - shouldReuseSameRequest: 是否需要复用相同的请求，默认不复用
    ///   - maxConcurrentOperationCount: 请求最大并发数，默认值是CPU活跃核心数*2
    ///   - timeoutIntervalForRequest: 请求超时时间，默认60s
    public init(
        shouldReuseSameRequest: Bool = false,
        maxConcurrentOperationCount: Int = ProcessInfo.processInfo.activeProcessorCount * 2,
        timeoutIntervalForRequest: TimeInterval = 60
    ) {
        self.shouldReuseSameRequest = shouldReuseSameRequest
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
    }
}

public  protocol SessionDataTaskProtocol {
    func cancel()
    func resume()
    var taskIdentifier: Int { get }
}

//空实现，在内部已经有对应实现。这里只是通过编译
extension URLSessionDataTask : SessionDataTaskProtocol{}
//空实现，在内部已经有对应实现。这里只是通过编译
extension RustHTTPSessionDataTask : SessionDataTaskProtocol{}

public protocol URLSessionProtocol {
    func dataTaskBridgeWith(_ request: URLRequest, eventName: String?, requestTracing: OPTrace?) -> SessionDataTaskProtocol
    func finishTasksAndInvalidateInBridge()
}

extension URLSession : URLSessionProtocol {
    public func dataTaskBridgeWith(_ request: URLRequest, eventName: String?, requestTracing: OPTrace?) -> SessionDataTaskProtocol {
        return dataTask(with: request, eventName: eventName, requestTracing: requestTracing) as SessionDataTaskProtocol
    }
    public func finishTasksAndInvalidateInBridge() {
        finishTasksAndInvalidate()
    }
}

/// meta 请求器
public final class MetaFetcher: NSObject {
    fileprivate static let logger = Logger.oplog(RustHTTPSession.self)
    /// meta 请求器发请求使用的 session
    private var session: URLSessionProtocol = URLSession()

    /// meta 请求器配置
    private let metaFetcherConfiguration: MetaFetcherConfiguration

    /// 应用类型
    private let type: BDPType

    /// meta 请求器 正在进行的请求字典 key: taskIdentifier
    private var metaTasks = [Int: MetaTask]()

    /// meta 请求器 正在进行的请求字典 操作相关的信号量 这个比NSRecursiveLock性能高
    private let metaTasksOperationLock = DispatchSemaphore(value: 1)
    /// meta 请求器回调的批量操作相关的信号量，确保线程安全
    private let taskResponseCallbackLock = DispatchSemaphore(value: 1)
    /// 初始化meta 请求器
    /// - Parameters:
    ///   - config: meta 请求器配置
    ///   - appType: 应用类型
    public init(
        config: MetaFetcherConfiguration,
        appType: BDPType
    ) {
        metaFetcherConfiguration = config
        type = appType
        super.init()
        
        let sessionConfiguration = BDPNetworking.sharedSession().configuration.copy() as! URLSessionConfiguration
        sessionConfiguration.timeoutIntervalForRequest = metaFetcherConfiguration.timeoutIntervalForRequest

        if OPSDKFeatureGating.enableMetaFetcherViaRustHttpAPI() {
            Self.logger.info("enableMetaFetcherViaRustHttpAPI is true, session with RustHTTPSession")
            session = RustHTTPSession(configuration: .default,
                                      delegate: self,
                                      delegateQueue: {
                let queue = OperationQueue()
                queue.maxConcurrentOperationCount = metaFetcherConfiguration.maxConcurrentOperationCount
                return queue
            }())
        } else {
            Self.logger.info("enableMetaFetcherViaRustHttpAPI is false, session with URLSession")
            session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: {
                let queue = OperationQueue()
                queue.maxConcurrentOperationCount = metaFetcherConfiguration.maxConcurrentOperationCount
                return queue
            }())
        }
    }

    /// 发起meta请求
    /// - Parameters:
    ///   - task: meta 请求
    ///   - token: 请求唯一标志符，可配合重用策略合并相同请求
    ///   - identifier: 应用唯一标志符
    ///   - trace: 用于请求的trace，会绑定到返回的DataTask中
    ///   - completionHandler: 回调
    /// - Returns: 请求任务
    public func requestMeta(
        with request: URLRequest,
        token: String,
        uniqueID: BDPUniqueID,
        trace: BDPTracing,
        completionHandler: @escaping (Data?, URLResponse?, OPError?) -> Void
    )  {
        //  如果打开了重用策略，且有相同请求正在进行进行，需要重用
        if metaFetcherConfiguration.shouldReuseSameRequest,
           let sameTask = findSameTask(with: token) {
            taskResponseCallbackLock.wait()
            sameTask.responseBlocks.append(completionHandler)
            // 存在相同任务,将埋点添加到任务的埋点数组中
            if OPSDKFeatureGating.enableReportmetaRequestMergeMonitor() {
                let metaMergeMonitor = metaRequestMergeMonitor(uniqueID: uniqueID, isMergeRequest: true, requestID: trace.getRequestID())
                sameTask.mergeMonitors.append(metaMergeMonitor)
            }
            taskResponseCallbackLock.signal()
            return
        }
        //屏蔽所有meta请求（动态组件、小程序、block），只留一个网页应用
        //如果是审核，则强制不发 getAppMeta请求
        //如果应用在 ODR 列表内，且强制开启必须走ODR，也强制不发 getAppMeta 请求（修正审批线上埋点数据问题）
        let metaRequestForbidden = (uniqueID.appType != .webApp) && (OPSDKFeatureGating.isBoxOff() || (OPSDKFeatureGating.isEnableApplePie() && OPSDKFeatureGating.shouldKeepDataWith(uniqueID)))
        let task = session.dataTaskBridgeWith(request, eventName: nil, requestTracing: trace)
        //resume 之前判断一下，是不是需要发起请求
        if metaRequestForbidden {
            //直接 invoke complete 回调，返回错误
            let error = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_request_error, message: "meta requset is forbidden")
            completionHandler(nil, nil, error)
            return
        }
        //  否则保存住task进行请求
        var metaTask = MetaTask(
            dataTask: task,
            token: token,
            uniqueID: uniqueID,
            responseBlock: completionHandler
        )
        
        // 添加是否有重复meta请求埋点
        if OPSDKFeatureGating.enableReportmetaRequestMergeMonitor() {
            let metaMergeMonitor = metaRequestMergeMonitor(uniqueID: uniqueID, isMergeRequest: false, requestID: trace.getRequestID())
            metaTask.mergeMonitors.append(metaMergeMonitor)
        }
        set(metaTask, for: Int(task.taskIdentifier))
        OPMonitor(kEventName_op_common_meta_request_start)
            .addCategoryValue("request_id", trace.getRequestID())
            .setUniqueID(uniqueID)
            .tracing(trace)
            .flush()
        task.resume()
    }
}

extension RustHTTPSession : URLSessionProtocol {
    
    public func dataTaskBridgeWith(_ request: URLRequest, eventName: String?, requestTracing: OPTrace?) -> SessionDataTaskProtocol {
        return dataTaskWith(request, eventName: eventName, requestTracing: requestTracing)
    }
    public func finishTasksAndInvalidateInBridge() {
        finishTasksAndInvalidate()
    }
    
    func dataTaskWith(_ request: URLRequest, eventName: String?, requestTracing: OPTrace?) -> SessionDataTaskProtocol {
        let safeTracing = safeTrace(requestTracing)
        let requestWithTracing = addReqeustTraceHeader(request: request, trace:  safeTracing)
        let url = requestWithTracing.url?.absoluteString
        BDPLogHelper.logRequestBegin(withEventName: eventName, urlString: url, withTrace: safeTracing.traceId)
        let dataTask = self.dataTask(with: requestWithTracing)
        dataTask.bindTrace(trace: safeTracing)
        return dataTask as SessionDataTaskProtocol
    }

    func safeTrace(_ tracing: OPTrace?) -> OPTrace {
        if let tracing = tracing {
            return  tracing
        }
        let safeTracing = OPTraceService.default().generateTrace()
        MetaFetcher.logger.info("request trace is nil, generate new, traceId=\(safeTracing.traceId)")
        return safeTracing
    }

    func addReqeustTraceHeader(request: URLRequest, trace: OPTrace?) -> URLRequest {
        if !BDPIsEmptyString(request.allHTTPHeaderFields?[OP_REQUEST_TRACE_HEADER]) {
            MetaFetcher.logger.info("trace is exist, trace=\(request.allHTTPHeaderFields?[OP_REQUEST_TRACE_HEADER]), needLinkTrace=\(trace?.traceId)")
            return request
        }
        let safeTrace = safeTrace(trace)
        if BDPIsEmptyString(safeTrace.getRequestID()) {
            safeTrace.genRequestID(OP_REQUEST_ENGINE_SOURCE)
        }
        var modifyRequest = request
        var header = modifyRequest.allHTTPHeaderFields
        header?[OP_REQUEST_TRACE_HEADER] = safeTrace.traceId
        if BDPIsEmptyString(header?[OP_REQUEST_ID_HEADER]) {
            header?[OP_REQUEST_ID_HEADER] = safeTrace.getRequestID()
        }
        if BDPIsEmptyString(header?[OP_REQUEST_LOGID_HEADER]) {
            header?[OP_REQUEST_LOGID_HEADER] = safeTrace.getRequestID()
        }
        modifyRequest.allHTTPHeaderFields = header
        return modifyRequest
    }
}



private var RustURLSessionTaskBDPTraceKey : Void?
extension RustHTTPSessionTask {
    public var trace: OPTrace? {
        get {
            return objc_getAssociatedObject(self, &RustURLSessionTaskBDPTraceKey) as? OPTrace
        }
        set(newValue) {
            objc_setAssociatedObject(self, &RustURLSessionTaskBDPTraceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func bindTrace(trace: OPTrace?)  {
        guard let trace = trace else {
            assert(false, "trace is null")
            return
        }
        guard self.trace == nil else {
            assert(false, "bind trace repeat")
            return
        }
        self.trace = trace
    }
}

extension MetaFetcher: RustHTTPSessionDataDelegate, RustHTTPSessionTaskDelegate {

    /// data task has received some of the expected data
    /// - Parameters:
    ///   - session: meta 请求器发请求使用的 session
    ///   - dataTask: meta数据请求任务
    ///   - data: 回调的部分数据
    public func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, didReceive data: Data) {
        guard let metaTask = metaTask(for: dataTask.taskIdentifier) else {
            return
        }
        metaTask
            .data
            .append(data)
    }

    /// the task finished transferring data.
    /// - Parameters:
    ///   - session: meta 请求器发请求使用的 session
    ///   - task: meta数据请求任务
    ///   - error: 回调的部分数据
    public func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didCompleteWithError error: Error?) {
        let opError = configOPError(error, monitorCode: CommonMonitorCodeMeta.meta_request_error)
        guard let metaTask = metaTask(for: task.taskIdentifier) else {
            return
        }
        taskResponseCallbackLock.wait()
        metaTask.responseBlocks.forEach { (responseBlock) in
            responseBlock(metaTask.data,task.response, opError)
        }
        
        if OPSDKFeatureGating.enableReportmetaRequestMergeMonitor() {
            // meta合并埋点上报
            let success = (error == nil)
            metaTask.mergeMonitors.forEach { monitor in
                monitor.timing()
                if success {
                    monitor.setResultTypeSuccess()
                } else {
                    monitor.setError(error)
                    monitor.setResultTypeFail()
                }
                monitor.flush()
            }
        }
        taskResponseCallbackLock.signal()
        //  埋点数据
        let statusCode: Int? = (task.response as? HTTPURLResponse)?.statusCode
        //  打一波点
        let metaRequestResultEvent = OPMonitor(kEventName_op_common_meta_request_result)
            .addMetricValue("dns", metaTask.bdpMetrics?.dns)
            .addMetricValue("tcp", metaTask.bdpMetrics?.tcp)
            .addMetricValue("ssl", metaTask.bdpMetrics?.ssl)
            .addMetricValue("send", metaTask.bdpMetrics?.send)
            .addMetricValue("wait", metaTask.bdpMetrics?.wait)
            .addMetricValue("recv", metaTask.bdpMetrics?.receive)
            .addCategoryValue("reuseType", metaTask.bdpMetrics?.reuseConnect)
            .addCategoryValue("host", task.response?.url?.host)
            .addCategoryValue("http_code", statusCode)
            .addCategoryValue("request_id", task.trace?.getRequestID())
            .tracing(task.trace)
            .setUniqueID(metaTask.uniqueID)
            .setError(opError)
            .setDuration(TimeInterval(metaTask.bdpMetrics?.requestTime ?? 0))
        if opError != nil {
            metaRequestResultEvent
                .setResultTypeFail()
        } else {
            metaRequestResultEvent
                .setResultTypeSuccess()
                .setMonitorCode(CommonMonitorCodeMeta.meta_request_success)
        }
        metaRequestResultEvent
            .flush()
        set(nil, for: task.taskIdentifier)
    }

    /// the session finished collecting metrics for the task.
    /// - Parameters:
    ///   - session: meta 请求器发请求使用的 session
    ///   - task: meta数据请求任务
    ///   - metrics: An object encapsulating the metrics for a session task.
    ///
    public func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didFinishCollecting metrics: RustHTTPSessionTaskMetrics) {
        guard let metaTask = metaTask(for: task.taskIdentifier) else {
            return
        }
//        metaTask.bdpMetrics = BDPRequestMetrics(from: metrics.transactionMetrics.first)
    }

}

extension MetaFetcher: URLSessionDataDelegate {

    /// data task has received some of the expected data
    /// - Parameters:
    ///   - session: meta 请求器发请求使用的 session
    ///   - dataTask: meta数据请求任务
    ///   - data: 回调的部分数据
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let metaTask = metaTask(for: dataTask.taskIdentifier) else {
            return
        }
        metaTask
            .data
            .append(data)
    }

    /// the task finished transferring data.
    /// - Parameters:
    ///   - session: meta 请求器发请求使用的 session
    ///   - task: meta数据请求任务
    ///   - error: 回调的部分数据
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let opError = configOPError(error, monitorCode: CommonMonitorCodeMeta.meta_request_error)
        guard let metaTask = metaTask(for: task.taskIdentifier) else {
            return
        }
        taskResponseCallbackLock.wait()
        metaTask.responseBlocks.forEach { (responseBlock) in
            responseBlock(metaTask.data,task.response, opError)
        }
        
        if OPSDKFeatureGating.enableReportmetaRequestMergeMonitor() {
            // meta合并埋点上报
            let success = (error == nil)
            metaTask.mergeMonitors.forEach { monitor in
                monitor.timing()
                if success {
                    monitor.setResultTypeSuccess()
                } else {
                    monitor.setError(error)
                    monitor.setResultTypeFail()
                }
                monitor.flush()
            }
        }
        taskResponseCallbackLock.signal()
        //  埋点数据
        let statusCode: Int? = (task.response as? HTTPURLResponse)?.statusCode
        //  打一波点
        let metaRequestResultEvent = OPMonitor(kEventName_op_common_meta_request_result)
            .addMetricValue("dns", metaTask.bdpMetrics?.dns)
            .addMetricValue("tcp", metaTask.bdpMetrics?.tcp)
            .addMetricValue("ssl", metaTask.bdpMetrics?.ssl)
            .addMetricValue("send", metaTask.bdpMetrics?.send)
            .addMetricValue("wait", metaTask.bdpMetrics?.wait)
            .addMetricValue("recv", metaTask.bdpMetrics?.receive)
            .addCategoryValue("reuseType", metaTask.bdpMetrics?.reuseConnect)
            .addCategoryValue("host", task.response?.url?.host)
            .addCategoryValue("http_code", statusCode)
            .addCategoryValue("request_id", task.trace?.getRequestID())
            .tracing(task.trace)
            .setUniqueID(metaTask.uniqueID)
            .setError(opError)
            .setDuration(TimeInterval(metaTask.bdpMetrics?.requestTime ?? 0))
        if opError != nil {
            metaRequestResultEvent
                .setResultTypeFail()
        } else {
            metaRequestResultEvent
                .setResultTypeSuccess()
                .setMonitorCode(CommonMonitorCodeMeta.meta_request_success)
        }
        metaRequestResultEvent
            .flush()
        set(nil, for: task.taskIdentifier)
    }

    /// the session finished collecting metrics for the task.
    /// - Parameters:
    ///   - session: meta 请求器发请求使用的 session
    ///   - task: meta数据请求任务
    ///   - metrics: An object encapsulating the metrics for a session task.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let metaTask = metaTask(for: task.taskIdentifier) else {
            return
        }
        metaTask.bdpMetrics = BDPRequestMetrics(from: metrics.transactionMetrics.first)
    }
    
}

/// 操作 metaTasks 字典的安全方法
extension MetaFetcher {
    private func configOPError(_ error: Error?, monitorCode: OPMonitorCode) -> OPError? {
        if let _error = error as? NSError {
            var userInfo = _error.userInfo
            userInfo[NSLocalizedDescriptionKey] = "\(_error.localizedDescription), domain: \(_error.domain) code: \(_error.code)"
            return _error.newOPError(monitorCode: monitorCode, userInfo: userInfo)
        }

        return error?.newOPError(monitorCode: monitorCode)
    }

    /// 尝试寻找是否存在正在进行的相同的请求
    /// - Parameter token: 请求唯一标志符
    /// - Returns: 可能存在的相同的任务
    private func findSameTask(with token: String) -> MetaTask? {
        var sameTask: MetaTask?
        metaTasksOperationLock.wait()
        metaTasks
            .flatMap { $0.value }
            .forEach { (taskInRequesting) in
                if taskInRequesting.token == token {
                    sameTask = taskInRequesting
                }
            }
        metaTasksOperationLock.signal()
        return sameTask
    }

    /// 尝试通过 taskIdentifier 获取 MetaTask
    /// - Parameter taskIdentifier: 请求的任务ID
    /// - Returns: MetaFetcher 使用的请求结构
    private func metaTask(for taskIdentifier: Int) -> MetaTask? {
        var mt: MetaTask?
        metaTasksOperationLock.wait()
        mt = metaTasks[taskIdentifier]
        metaTasksOperationLock.signal()
        return mt

    }

    /// 向meta 请求器 正在进行的请求字典对应的id进行修改
    /// - Parameters:
    ///   - metaTask: 需要被设置的task 可以为nil
    ///   - taskIdentifier: 请求的任务ID
    private func set(_ metaTask: MetaTask?, for taskIdentifier: Int) {
        metaTasksOperationLock.wait()
        metaTasks[taskIdentifier] = metaTask
        metaTasksOperationLock.signal()
    }

    /// 清除所有请求
    public func clearAllTasks() {
        metaTasksOperationLock.wait()
        metaTasks.values.forEach {
            $0
                .dataTask
                .cancel()
        }
        metaTasks.removeAll()
        metaTasksOperationLock.signal()
    }

    /// 清除指定请求
    public func clearTask(with token: String) {
        metaTasksOperationLock.wait()
        metaTasks.values.forEach {
            if ($0.token == token) {
                $0.dataTask.cancel()
            }
        }
        metaTasks = metaTasks.filter({ $0.value.token != token })
        metaTasksOperationLock.signal()
    }
    
    //打破 session 和 MetaFetcher 之间的依赖链，避免内存泄漏
    public func invalidateSession() {
        if OPSDKFeatureGating.enableMetaFetcherLeakFix() {
            self.session.finishTasksAndInvalidateInBridge()
        }
    }
    
    private func metaRequestMergeMonitor(uniqueID: BDPUniqueID,
                                         isMergeRequest: Bool,
                                         requestID: String? = "") -> OPMonitor {
        OPMonitor("op_common_meta_request_merge_result")
            .setUniqueID(uniqueID)
            .timing()
            .addMap(["request_id" : BDPSafeString(requestID),
                     "isMergeRequest" : isMergeRequest])
    }
}

/// MetaFetcher 使用的请求结构
private class MetaTask {

    /// meta数据请求任务
    let dataTask: SessionDataTaskProtocol

    /// 请求唯一标志符，可配合重用策略合并相同请求
    let token: String

    let uniqueID: BDPUniqueID

    /// 同一个任务的回调数组
    var responseBlocks: [(Data?, URLResponse?, OPError?) -> Void]
    
    /// 合并meta请求埋点数组
    var mergeMonitors: [OPMonitor] = []

    /// 请求回包数据
    var data = Data()

    /// 请求链路各阶段耗时度量
    var bdpMetrics: BDPRequestMetrics?

    /// MetaFetcher 使用的请求结构初始化
    /// - Parameters:
    ///   - dataTask: meta数据请求任务
    ///   - token: 请求唯一标志符，可配合重用策略合并相同请求
    ///   - responseBlock: 同一个任务的回调数组
    init(
        dataTask: SessionDataTaskProtocol,
        token: String,
        uniqueID: BDPUniqueID,
        responseBlock: @escaping (Data?, URLResponse?, OPError?) -> Void
    ) {
        self.dataTask = dataTask
        self.token = token
        self.uniqueID = uniqueID
        responseBlocks = [responseBlock]
    }
}
