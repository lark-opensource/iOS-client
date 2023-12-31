//
//  Session.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2023/4/11.
//

import Foundation
import EEAtomic

// 整体接口参考URLSession。
// 实现结构参考swift corelib。但它也没有实现完善
// 需要根据Rust实际支持功能情况裁剪和完善

// swiftlint:disable missing_docs

/// a http session call rust implementation directly
/// API similar to system URLSession API
///
/// not all URLSession feature works, should use with test.
/// current impl feature list:
///
/// * URLSession Similar API
/// * Cookie Support
/// * Cache Support
/// * Redirect Support
/// * Metrics Support
/// * Responsive Timeout
/// * Progress Update Support and KVO
/// * DataTask
/// * DownloadTask
/// * UploadTask

@objc
public class RustHTTPSession: NSObject {
    /// 这个用于简单场景。最好是通过configuration创建业务自己的Session使用
    @objc static public let shared: RustHTTPSession = RustHTTPSessionShared()
    // MARK: RustHTTPSession property
    // NOTE: 检查内部应该用性能更好的_configuration
    @objc public var configuration: RustHTTPSessionConfig { .init(rawValue: _configuration) } // swiftlint:disable:this all
    let _configuration: RustHTTPSessionConfig.Raw // immutable struct value // swiftlint:disable:this all
    // NOTE: delegate is strong retained, if delegate retain session will retain-cycle until invalidated
    // 另外可能也要提供方便的管理循环引用的方法, 切换用户后应该能被清理干净，同时保证task管理正确..
    // invalid应该能保证正确释放
    @objc public private(set) var delegate: RustHTTPSessionDelegate? // swiftlint:disable:this all
    @objc public let delegateQueue: OperationQueue
    // MARK: RustHTTPSession LifeCycle
    @objc
    public override convenience init() {
        self.init(configuration: RustHTTPSessionConfig.default, delegate: nil, delegateQueue: nil)
    }
    @objc
    public init(configuration: RustHTTPSessionConfig, delegate: RustHTTPSessionDelegate?, delegateQueue: OperationQueue?) {
        self.workQueue = DispatchQueue(label: "RustHTTPSession<\(RustHTTPSession.counter.increment())>")
        self._configuration = configuration.rawValue
        self.delegate = delegate
        if let delegateQueue {
            self.delegateQueue = delegateQueue
        } else {
           self.delegateQueue = OperationQueue()
           self.delegateQueue.maxConcurrentOperationCount = 1
        }
        super.init()
    }

    @inlinable
    func asyncOnDelegateQueue(_ action: @escaping () -> Void) {
        #if DEBUG || ALPHA
        delegateQueue.addOperation {
            Thread.current.threadDictionary["RustHTTPSessionDelegateQueue"] = true
            defer { Thread.current.threadDictionary.removeObject(forKey: "RustHTTPSessionDelegateQueue") }
            action()
        }
        #else
        delegateQueue.addOperation(action)
        #endif
    }
    /// NOTE: 这个只是保证在delegate回调队列上，可以直接调用delegate。但是delegateQueue可能支持并发，并不保证原子性
    @inlinable
    func assertInDelegateQueue() {
        #if DEBUG || ALPHA
        precondition(Thread.current.threadDictionary["RustHTTPSessionDelegateQueue"] as? Bool == true)
        #endif
    }

    private func _invalidate() {
        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(workQueue))
        #endif
        guard !invalidated else { return }
        // 按文档：设置后不允许后续task创建, 会抛出异常..
        self.invalidated = true
        guard delegate != nil else { return }
        let finish = { [weak self] in
            guard let self = self else { return }
            self.asyncOnDelegateQueue {
                self.delegate?.rustHTTPSession?(self, didBecomeInvalidWithError: nil)
                self.delegate = nil
            }
        }
        if taskRegistry.isEmpty {
            finish()
        } else {
            taskRegistry.tasksFinishedCallback = finish
        }
    }
    func checkInvalidated() {
        #if DEBUG || ALPHA // avoid crash in product env
        if self.invalidated {
            fatalError("Session invalidated")
        }
        #endif
    }

    // swift-core-lib看起来省略了好多通知..
    private func _dataTask(with req: URLRequest, behaviour: TaskRegistry.Behaviour) -> RustHTTPSessionDataTask {
        checkInvalidated()
        let task = RustHTTPSessionDataTask(session: self, request: req)
        postCreateTask(task, behaviour: behaviour)
        return task
    }
    // swiftlint:disable:next line_length
    private func _uploadTask(with request: URLRequest, body: RustHTTPSessionTask._Body?, behaviour: TaskRegistry.Behaviour) -> RustHTTPSessionUploadTask {
        checkInvalidated()
        let task = RustHTTPSessionUploadTask(session: self, request: request, body: body)
        postCreateTask(task, behaviour: behaviour)
        return task
    }
    private func _downloadTask(with req: URLRequest, behaviour: TaskRegistry.Behaviour) -> RustHTTPSessionDownloadTask {
        checkInvalidated()
        let task = RustHTTPSessionDownloadTask(session: self, request: req)
        postCreateTask(task, behaviour: behaviour)
        return task
    }
    private func postCreateTask(_ task: RustHTTPSessionTask, behaviour: TaskRegistry.Behaviour) {
        workQueue.async { [self] in
            taskRegistry.add(task, behaviour: behaviour)
        }
        if let delegate = delegate as? RustHTTPSessionTaskDelegate {
            delegate.rustHTTPSession?(self, didCreateTask: task)
        }
    }

    // Private Property
    static var counter = AtomicUIntCell(1)
    let workQueue: DispatchQueue
    /// after invalidated, no new task created
    var invalidated = false
    #if DEBUG || ALPHA
    var taskRegistry: TaskRegistry {
        dispatchPrecondition(condition: .onQueue(workQueue))
        return _tasks
    }
    private var _tasks = TaskRegistry()
    #else
    let taskRegistry = TaskRegistry()
    #endif
}

// MARK: Objc API
@objc
extension RustHTTPSession {
    @objc(RustHTTPSessionResponseDisposition)
    public enum ResponseDisposition: Int {
        case allow // currently only this implement
    }
    public func finishTasksAndInvalidate() {
        workQueue.async {
            self._invalidate()
        }
    }
    public func invalidateAndCancel() {
        workQueue.sync { // 同步等待cancel调用
            self._invalidate()
            for (_, task) in taskRegistry.tasks {
                task.cancel()
            }
        }
    }
    public func getAllTasks(completionHandler: @escaping @Sendable ([RustHTTPSessionTask]) -> Void) {
        workQueue.async { [self] in
            let tasks: [RustHTTPSessionTask] = Array(taskRegistry.tasks.values)
            self.asyncOnDelegateQueue {
                completionHandler(tasks)
            }
        }
    }

    // Tasks
    @objc(dataTaskWithRequest:)
    public func dataTask(with request: URLRequest) -> RustHTTPSessionDataTask {
        return _dataTask(with: request, behaviour: .callDelegate)
    }
    @objc(dataTaskWithURL:)
    public func dataTask(with url: URL) -> RustHTTPSessionDataTask {
        return _dataTask(with: URLRequest(url: url), behaviour: .callDelegate)
    }
    /*
     * data task convenience methods.  These methods create tasks that
     * bypass the normal delegate calls for response and data delivery,
     * and provide a simple cancelable asynchronous interface to receiving
     * data.  Errors will be returned in the NSURLErrorDomain,
     * see <Foundation/NSURLError.h>.  The delegate, if any, will still be
     * called for authentication challenges.
     */
    @objc(dataTaskWithRequest:completionHandler:)
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> RustHTTPSessionDataTask {
        return _dataTask(with: request, behaviour: .dataCompletionHandler(completionHandler))
    }

    @objc(dataTaskWithURL:completionHandler:)
    public func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> RustHTTPSessionDataTask {
        return _dataTask(with: URLRequest(url: url), behaviour: .dataCompletionHandler(completionHandler))
    }

    @objc(uploadTaskWithRequest:fromFile:)
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> RustHTTPSessionUploadTask {
        return _uploadTask(with: request, body: .file(fileURL), behaviour: .callDelegate)
    }

    @objc(uploadTaskWithRequest:fromData:)
    public func uploadTask(with request: URLRequest, from bodyData: Data) -> RustHTTPSessionUploadTask {
        return _uploadTask(with: request, body: .data(bodyData), behaviour: .callDelegate)
    }

    @objc(uploadTaskWithStreamedRequest:)
    public func uploadTask(withStreamedRequest request: URLRequest) -> RustHTTPSessionUploadTask {
        return _uploadTask(with: request, body: nil, behaviour: .callDelegate)
    }
    @objc(uploadTaskWithRequest:fromData:completionHandler:)
    public func uploadTask(with request: URLRequest, from bodyData: Data, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> RustHTTPSessionUploadTask {
        return _uploadTask(with: request, body: .data(bodyData), behaviour: .dataCompletionHandler(completionHandler))
    }
    @objc(uploadTaskWithRequest:fromFile:completionHandler:)
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> RustHTTPSessionUploadTask {
        return _uploadTask(with: request, body: .file(fileURL), behaviour: .dataCompletionHandler(completionHandler))
    }
    @objc(downloadTaskWithRequest:)
    public func downloadTask(with request: URLRequest) -> RustHTTPSessionDownloadTask {
        return _downloadTask(with: request, behaviour: .callDelegate)
    }
    @objc(downloadTaskWithURL:)
    public func downloadTask(with url: URL) -> RustHTTPSessionDownloadTask {
        return _downloadTask(with: URLRequest(url: url), behaviour: .callDelegate)
    }
    @objc(downloadTaskWithRequest:completionHandler:)
    public func downloadTask(with request: URLRequest, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> RustHTTPSessionDownloadTask {
        return _downloadTask(with: request, behaviour: .downloadCompletionHandler(completionHandler))
    }
    @objc(downloadTaskWithURL:completionHandler:)
    public func downloadTask(with url: URL, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> RustHTTPSessionDownloadTask {
        return _downloadTask(with: URLRequest(url: url), behaviour: .downloadCompletionHandler(completionHandler))
    }
    // TODO: download resume
}

class RustHTTPSessionShared: RustHTTPSession {
    override func finishTasksAndInvalidate() {
        assertionFailure("shouldn't call on shared instance")
    }
    override func invalidateAndCancel() {
        assertionFailure("shouldn't call on shared instance")
    }
}

// swiftlint:enable missing_docs
