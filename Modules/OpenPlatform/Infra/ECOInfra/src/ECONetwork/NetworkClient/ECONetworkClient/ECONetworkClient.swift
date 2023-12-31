//
//  NetworkClient.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/14.
//

import Foundation
import LKCommonsLogging
import ECOProbe
import LarkContainer

let ECONetworkTempDirectoryName = "ECONetworkTemp"
let ECONetworkClientTempFileName = "ECONetworkTempFile_"
/// ECONetworkClient
/// 实现网络请求的类, 内部封装 URLSession 完成网络功能
/// 目的在于, 将 URLSession 隐藏于内部, 避免上层直接调用 URLSession 并进行二次封装, 同时提供与 URLSession 相似的接口减少接入成本.
/// 内部主要包含对 URLSession 的处理和埋点,日志逻辑
/// ⚠️ 此类作为 URLSession delegate, URLSession 对 delegate 是强引用的. 所以需要在结束使用时手动调用 invalidate 才能释放
final class ECONetworkClient: NSObject, ECONetworkClientProtocol {
    typealias TaskIdentifier = Int
    internal static let logger = Logger.oplog(ECONetworkClient.self, category: "ECONetwork")
    
    @Provider private var dependency: ECONetworkDependency // Global
    /// 生命周期代理,详见 ECONetworkClientEventDelegate
    public weak var delegate: ECONetworkClientEventDelegate?
    /// 请求配置
    public var configuration: URLSessionConfiguration { session.configuration }
    internal let identifier: String = ECOIdentifier.createIdentifier(key: "ECONetworkClient")
    
    /// ⚠️ 对外提供的只读接口，内部使用需谨慎，防止造成死锁！
    internal var requestingTasks: [TaskIdentifier: ECONetworkTask] {
        let map: [TaskIdentifier: ECONetworkTask]
        tasksSemaphore.wait()
        map = inner_requestingTasks
        tasksSemaphore.signal()
        return map
    }
    
    // 为避免线程安全问题，操作此变量需要加锁
    private var inner_requestingTasks: [TaskIdentifier: ECONetworkTask] = [:]
    
    private let tasksSemaphore = DispatchSemaphore(value: 1)
    private var session = URLSession.shared
    
    public init(configuration: URLSessionConfiguration, delegateQueue: OperationQueue?) {
        super.init()
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }
    
    public func finishTasksAndInvalidate() {
        tasksSemaphore.wait()
        var requestIDS: [String] = []
        var traceIDs: [String] = []
        inner_requestingTasks.forEach {
            requestIDS.append($1.requestID ?? "")
            traceIDs.append($1.trace?.traceId ?? "")
        }
        Self.logger.info(
            "finishTasksAndInvalidate",
            additionalData: [
                "clientID": identifier,
                "taskCount": String(inner_requestingTasks.count),
                "taskIDs": requestIDS.description,
                "taskTraceIDs": traceIDs.description
            ])
        tasksSemaphore.signal()
        session.finishTasksAndInvalidate()
    }

    
    public func invalidateAndCancel() {
        tasksSemaphore.wait()
        var requestIDS: [String] = []
        var traceIDs: [String] = []
        inner_requestingTasks.forEach {
            requestIDS.append($1.requestID ?? "")
            traceIDs.append($1.trace?.traceId ?? "")
        }
        Self.logger.info(
            "invalidateAndCancel",
            additionalData: [
                "clientID": identifier,
                "taskCount": String(inner_requestingTasks.count),
                "taskIDs": requestIDS.description,
                "taskTraceIDs": traceIDs.description
            ])
        tasksSemaphore.signal()
        session.invalidateAndCancel()
    }

    public func dataTask(with context: ECONetworkContextProtocol, request: URLRequest, completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?) -> ECONetworkTaskProtocol {
        return ECONetworkTask(
            context: context,
            client: self,
            task: session.dataTask(with: request),
            responseDataHandler: ECONetworkDataHandler()
        ) { context, product, response, error in
            guard let data = product as? Data? else {
                assertionFailure("dataTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("dataTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(context, nil, response, error)
                return
            }
            completionHandler?(context, data, response, error)
        }
    }
    
    public func downloadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        cleanTempFile: Bool = true,
        completionHandler: ((AnyObject?, URL?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkTaskProtocol {
        let tempFileURL = getTempFilePath(context: context)
        let task = ECONetworkTask(
            context: context,
            client: self,
            task: session.downloadTask(with: request),
            responseDataHandler: ECONetworkFileURLHandler(with: tempFileURL)
        ) { context, product, response, error in
            guard let location = product as? URL? else {
                assertionFailure("downloadTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("downloadTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(context, nil, response, error)
                return
            }
            completionHandler?(context, location, response, error)
        }
        task.shouldCleanTempFile = cleanTempFile
        return task
    }
    
    
    public func uploadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        fromFile fileURL: URL,
        completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkTaskProtocol {
        return ECONetworkTask(
            context: context,
            client: self,
            task: session.uploadTask(with: request, fromFile: fileURL),
            responseDataHandler: ECONetworkDataHandler()
        ) { context, product, response, error in
            guard let data = product as? Data? else {
                assertionFailure("uploadTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("uploadTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(context, nil, response, error)
                return
            }
            completionHandler?(context, data, response, error)
        }
    }

    public func uploadTask(with context: ECONetworkContextProtocol, request: URLRequest, from bodyData: Data, completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?) -> ECONetworkTaskProtocol {
        return ECONetworkTask(
            context: context,
            client: self,
            task: session.uploadTask(with: request, from: bodyData),
            responseDataHandler: ECONetworkDataHandler()
        ) { context, product, response, error in
            guard let data = product as? Data? else {
                assertionFailure("uploadTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("uploadTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(context, nil, response, error)
                return
            }
            completionHandler?(context, data, response, error)
        }
    }
    
    deinit { Self.logger.info("client deinit") }
}

extension ECONetworkClient {
    private func getTempFilePath(context: ECONetworkContextProtocol) -> URL {
        var directoryURL: URL
        // 判断外界是否指定了有效路径, 如果没有,返回 temp
        if let url = dependency.networkTempDirectory() {
            directoryURL = url
        } else {
            assertionFailure("dependency.tempDirectory() is nil, setup ECONetwork env first")
            Self.logger.error("dependency.tempDirectory() is nil, setup ECONetwork env first")
            // lint:disable:next lark_storage_check
            directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
        // 使用外界路径的子级目录
        directoryURL = directoryURL.appendingPathComponent(ECONetworkTempDirectoryName)
        
        // 判断是否已有文件夹, 如果没有, 创建一个
        if !FileManager.default.fileExists(atPath: directoryURL.absoluteString) {
            do {
                // lint:disable:next lark_storage_check
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                Self.logger.error("create network temp directory fail error:\(error)")
                // lint:disable:next lark_storage_check
                directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            }
        }
        
        let fileID = context.trace.getRequestID() ?? UUID().uuidString
        directoryURL.appendPathComponent(ECONetworkClientTempFileName + fileID + ".tmp")
        return directoryURL
    }
}

//MARK: - Task
extension ECONetworkClient: ECONetworkTaskClient {
    func taskResuming(task: ECONetworkTask) {
        tasksSemaphore.wait()
        // 外界重复调用属于正常现象
        guard task.state == .suspended else {
            tasksSemaphore.signal()
            return
        }
        Self.logger.info(
            "TaskControl - taskResuming",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
                "timeout": String(session.configuration.timeoutIntervalForRequest)
            ]
        )
        // 准备 Response 的数据接收器
        if let error = task.responseDataHandler.ready() {
            // 数据接收对象准备失败, 失败直接结束任务
            Self.logger.error("taskID: \(task.taskIdentifier) task resume error \(error)")
            task.error = error
            tasksSemaphore.signal()
            task.complete()
        } else {
            // 数据接收对象构造成功, 开始请求
            inner_requestingTasks[task.taskIdentifier] = task
            task.state = .running
            task.internalTask.resume()
            tasksSemaphore.signal()
            // 埋请求开始点
            monitorRequestStart(task: task)
        }
    }
    
    func taskPausing(task: ECONetworkTask) {
        tasksSemaphore.wait(); defer { tasksSemaphore.signal() }
        // 外界重复调用属于正常现象
        guard task.state == .running else { return }
        Self.logger.info(
            "TaskControl - taskPausing",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
            ]
        )
        task.state = .suspended
        task.internalTask.suspend()
        
        inner_requestingTasks.removeValue(forKey: task.taskIdentifier)
    }
    
    func taskCanceling(task: ECONetworkTask) {
        tasksSemaphore.wait(); defer { tasksSemaphore.signal()}
        // 外界重复调用属于正常现象
        guard task.state == .suspended || task.state == .running else { return }
        task.state = .canceling
        task.internalTask.cancel()
        inner_requestingTasks.removeValue(forKey: task.taskIdentifier)
        Self.logger.info(
            "TaskControl - taskCanceling",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
                "prevState": task.state.description()
            ]
        )
    }
    
    internal func taskCompleting(task: ECONetworkTask) {
        tasksSemaphore.wait()
        // 外界重复调用属于正常现象
        guard task.state != .completed else {
            Self.logger.error("taskID: \(task.taskIdentifier) complted")
            assertionFailure("taskID: \(task.taskIdentifier) complted")
            tasksSemaphore.signal()
            return
        }
        Self.logger.info(
            "TaskControl - taskCompleting",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
                "error": task.error?.localizedDescription ?? "",
                "prevState": task.state.description()
            ]
        )
        inner_requestingTasks.removeValue(forKey: task.taskIdentifier)
        task.state = .completed
        tasksSemaphore.signal()
        
        // 执行回调
        task.completionHandler?(
            task.context,
            task.error == nil ? task.responseDataHandler.product() :  nil,
            task.response,
            task.error
        )
        // 埋请求结束点
        monitorRequestEnd(task: task, isCancel: false)
        if task.shouldCleanTempFile, let error = task.responseDataHandler.clean() {
            Self.logger.error("taskID: \(identifier) task clean temp file error:\(error)")
        }
    }
}


