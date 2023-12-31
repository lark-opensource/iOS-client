//
//  ECONetworkRustClient.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import LarkRustHTTP
import LKCommonsLogging
import LarkContainer

final class ECONetworkRustClient: NSObject, ECONetworkRustHttpClientProtocol {
    typealias TaskIdentifier = Int
    internal static let logger = Logger.oplog(ECONetworkRustClient.self, category: "ECONetworkRustClient")
    @Provider private var dependency: ECONetworkDependency // Global
    
    /// ⚠️ 对外提供的只读接口，内部使用需谨慎，防止造成死锁！
    internal var requestingTasks: [TaskIdentifier: ECONetworkRustTask] {
        let map: [TaskIdentifier: ECONetworkRustTask]
        tasksSemaphore.wait()
        map = inner_requestingTasks
        tasksSemaphore.signal()
        return map
    }
    
    // 为避免线程安全问题，操作此变量需要加锁
    var inner_requestingTasks: [TaskIdentifier: ECONetworkRustTask] = [:]
    
    internal let identifier: String = ECOIdentifier.createIdentifier(key: "ECONetworkClient")
    
    let tasksSemaphore = DispatchSemaphore(value: 1)
    
    var rustSession: RustHTTPSession = RustHTTPSession.shared
    
    init(configuration: RustHTTPSessionConfig, delegateQueue: OperationQueue?) {
        super.init()
        self.rustSession = RustHTTPSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }
    
    func dataTask(with context: ECONetworkContextProtocol, request: URLRequest, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> ECONetworkRustTaskProtocol {
        return ECONetworkRustTask(
            context: context,
            client: self,
            task: rustSession.dataTask(with: request),
            responseDataHandler: ECONetworkDataHandler()
        ) { _, product, response, error in
            guard let data = product as? Data? else {
                assertionFailure("dataTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("dataTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(nil, response, error)
                return
            }
            completionHandler?(data, response, error)
        }
    }
    
    func downloadTask(with context: ECONetworkContextProtocol, request: URLRequest, cleanTempFile: Bool, completionHandler: ((URL?, URLResponse?, Error?) -> Void)?) -> ECONetworkRustTaskProtocol {
        let tempFileURL = getTempFilePath(context: context)
        let task = ECONetworkRustTask(
            context: context,
            client: self,
            task: rustSession.downloadTask(with: request),
            responseDataHandler: ECONetworkFileURLHandler(with: tempFileURL)
        ) { _, product, response, error in
            guard let location = product as? URL? else {
                assertionFailure("downloadTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("downloadTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(nil, response, error)
                return
            }
            completionHandler?(location, response, error)
        }
        task.shouldCleanTempFile = cleanTempFile
        return task
    }
    
    func uploadTask(with context: ECONetworkContextProtocol, request: URLRequest, fromFile fileURL: URL, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> ECONetworkRustTaskProtocol {
        return ECONetworkRustTask(
            context: context,
            client: self,
            task: rustSession.uploadTask(with: request, fromFile: fileURL),
            responseDataHandler: ECONetworkDataHandler()
        ) { _, product, response, error in
            guard let data = product as? Data? else {
                assertionFailure("uploadTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("uploadTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(nil, response, error)
                return
            }
            completionHandler?(data, response, error)
        }
    }
    
    func uploadTask(with context: ECONetworkContextProtocol, request: URLRequest, from bodyData: Data, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> ECONetworkRustTaskProtocol {
        return ECONetworkRustTask(
            context: context,
            client: self,
            task: rustSession.uploadTask(with: request, from: bodyData),
            responseDataHandler: ECONetworkDataHandler()
        ) { _, product, response, error in
            guard let data = product as? Data? else {
                assertionFailure("uploadTask complete with wrong type \(String(describing: product.self))")
                Self.logger.error("uploadTask complete with wrong type\(String(describing: product.self))")
                completionHandler?(nil, response, error)
                return
            }
            completionHandler?(data, response, error)
        }
    }
    
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
    
    func finishTasksAndInvalidate() {
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
        rustSession.finishTasksAndInvalidate()
    }
    
    func invalidateAndCancel() {
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
        rustSession.invalidateAndCancel()
    }
}
