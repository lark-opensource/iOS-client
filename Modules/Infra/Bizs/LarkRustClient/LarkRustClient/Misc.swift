//
//  Misc.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/8/17.
//

import Foundation
import SwiftProtobuf
import RustPB
import LKCommonsLogging
import ServerPB
import EEAtomic

// short cut for module function without public name

// alias RustPB struct
// swiftlint:disable missing_docs
public typealias Command = Basic_V1_Command
public typealias ServerCommand = ServerPB_Improto_Command
public typealias LarkError = Basic_V1_LarkError
public typealias InitSDKRequest = Basic_V1_InitSDKRequest
public typealias Packet = Basic_V1_Packet
public typealias ServerPacket = ServerPB.ServerPB_Improto_Packet
public typealias DomainInitConfig = Basic_V1_KaInitConfig
public typealias ClientCert = Basic_V1_NetworkClientCertificate
typealias CancelStreamCallbackRequest = Basic_V1_CancelStreamCallbackRequest
typealias LogLevel = LKCommonsLogging.LogLevel

public enum CMD: CustomDebugStringConvertible, Hashable {
    case rust(Basic_V1_Command)
    case server(ServerPB_Improto_Command)

    public init(_ value: Basic_V1_Command) {
        self = .rust(value)
    }
    public init(_ value: ServerPB_Improto_Command) {
        self = .server(value)
    }

    public var rust: Basic_V1_Command? {
        switch self {
        case .rust(let cmd): return cmd
        default: return nil
        }
    }
    public var server: ServerPB_Improto_Command? {
        switch self {
        case .server(let cmd): return cmd
        default: return nil
        }
    }
    public var debugDescription: String {
        switch self {
        case .rust(let command): return "rust(\(command))"
        case .server(let command): return "server(\(command))"
        }
    }
}

/// 内部使用的全局方法和辅助类型先挂到这个命名空间下
internal enum M { // swiftlint:disable:this type_name
    static var logger: Log { SimpleRustClient.logger }
    static let mainSyncErrorTime: CFTimeInterval = 5.0
    static let queueBlockedWarnTime: CFTimeInterval = 3.0
    static let sendQueueWaitWarnDuration: CFTimeInterval = 1.0
    static let syncExecuteWarnningDuration: CFTimeInterval = 1.0
    static let callbackQueueWaitWarnDuration: CFTimeInterval = 1.0
    static let callbackSerialExecuteWarnDuration: CFTimeInterval = 1.0
    static let disposeRecycleTime: CFTimeInterval = 60 * 3

    static func format(time: CFTimeInterval) -> String {
        if time > 1 {
            return String(format: "%.3fs", time)
        } else {
            return String(format: "%.1fms", time * 1_000)
        }
    }
    static func highPriority(command: Command) -> Bool {
        switch command {
        case
            // ByteView
            .registerClientInfo, .createVideoChat, .updateVideoChat, .pushVideoChatNotice, .pushVideoChatNoticeUpdate,
            // VoIP
            .createE2EeVoiceCall, .updateE2EeVoiceCall, .getE2EeVoiceCalls, .pushE2EeVoiceCall:
            return true
        default:
            return false
        }
    }

    static func qos(command: Command) -> DispatchQoS? {
        return highPriority(command: command) ? .userInitiated : nil
    }

    static func uuid() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...9).map { _ in letters.randomElement() ?? letters[letters.startIndex] })
    }

    static func errorFromRust(data: Data) -> RCError {
        do {
            let larkErr = try LarkError(serializedData: data, options: .discardUnknownFieldsOption)
            return RCError.businessFailure(errorInfo: BusinessErrorInfo(larkErr))
        } catch let error as BinaryDecodingError {
            return RCError.sdkErrorSerializeFailure(error: error)
        } catch {
            return RCError.unknownError(error: error)
        }
    }

    @inline(__always)
    static func getCurrentThreadInt64() -> Int64 {
        return getThreadInt64(Thread.current)
    }

    @inline(__always)
    static func getThreadInt64(_ thread: Thread) -> Int64 {
        return Int64(Int(bitPattern: ObjectIdentifier(thread)))
    }

    /// use by func to transform and unify logging error when failed
    static func transform<R, U>(_ value: R, for request: Message, by: (R) throws -> U) throws -> U {
        do {
            return try by(value)
        } catch {
            M.logger.warn("\(request.protoMessageName)'s Response Transform Failed.", error: error)
            throw error
        }
    }
    /// 一个可被取消的，按实例区分的注册基类
    class DisposableID: Hashable {
        deinit { _disposed.deallocate() }

        private var _disposed = AtomicBoolCell()
        var disposed: Bool {
            return _disposed.value
        }
        /// return true when first dispose
        @discardableResult
        func dispose() -> Bool {
            if _disposed.exchange(true) == false {
                onDispose()
                return true
            }
            return false
        }
        func onDispose() {
            #if ALPHA
            fatalError("implement by subclass")
            #endif
        }
        // Hashable
        static func == (lhs: DisposableID, rhs: DisposableID) -> Bool {
            return lhs === rhs
        }
        func hash(into hasher: inout Hasher) {
            ObjectIdentifier(self).hash(into: &hasher)
        }
    }
    @inlinable
    static func assertAlpha(inLock lock: UnfairLockCell) {
        #if DEBUG || ALPHA
        lock.assertOwner()
        #endif
    }
    @inlinable
    static func preconditionAlpha(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
        if !condition() {
            #if ALPHA
            fatalError(message(), file: file, line: line)
            #else
            M.logger.error(message(), file: String(describing: file), line: Int(line))
            #endif
        }
    }
}

extension SimpleRustClient {
    func log(request: SwiftProtobuf.Message, context: RequestContext) {
        let requestJsonString = request.requestJsonString
        if requestJsonString.isEmpty {
            SimpleRustClient.logger.info(logId: "rust_ffi_request", "\(self.identifier) --> \(context.label)",
                                         params: ["contextID": context.contextID])
        } else {
            SimpleRustClient.logger.info(logId: "rust_ffi_request", "\(self.identifier) --> \(context.label), \(requestJsonString)",
                                         params: ["contextID": context.contextID])
        }
    }
    func log(context: RequestContext) {
        SimpleRustClient.logger.info(logId: "rust_ffi_request", "\(self.identifier) --> \(context.label)",
                                     params: ["contextID": context.contextID])
    }

    /// 用于延迟打印所有的耗时信息..
    /// 如果被block住，需要监听打印block信息.
    ///
    /// 只有sendQueue wait日志： 卡在sendQueue了
    /// 有send Rust日志，没有<--返回日志:  卡在rust了
    /// 有callback waiting日志，没有后续日志: 卡在callbackQueue了
    /// 有callbacking执行日志，没有后续日志: 卡在业务回调了
    /// 有结束的成功调用日志: 调用正常结束
    class Metrics {
        var title: String
        var additional: String = ""
        var contextID: String
        var info: [String: String]
        var error: Error?
        var startTime: CFTimeInterval?
        var hasBlock: Bool = false
        init(title: String, contextID: String, info: [String: String] = [:]) {
            self.title = title
            self.contextID = contextID
            self.info = info
        }
        convenience init(title: String, additional: String = "", contextID: String,
                         startTime: CFTimeInterval? = nil, rustDuration: CFTimeInterval? = nil,
                         error: Error? = nil) {
            self.init(title: title, contextID: contextID)
            if let rustDuration = rustDuration {
                self.info["Rust-Time"] = M.format(time: rustDuration)
            }
            self.startTime = startTime
            self.additional = additional
            self.error = error
        }
        func finish() {
            var info = self.info
            info["contextID"] = self.contextID
            if let startTime = startTime {
                // NOTE: 这里Execution-Time相对以前含义有一定变化，包含了callback调度和执行时间
                info["Execution-Time"] = M.format(time: CACurrentMediaTime() - startTime)
            }
            if let error {
                SimpleRustClient.logger.warn(title + additional, additionalData: info, error: error)
            } else {
                SimpleRustClient.logger.info(title + additional, additionalData: info)
            }
        }
        /// record waiting time and log if no call in long time
        func wrapCallback(action: @escaping () -> Void) -> () -> Void {
            let timer = makeCallbackQueueTimer()
            return {
                self.finishCallbackQueueTimer(timer: timer)
                action()
            }
        }
        func wrapCallback<T>(action: @escaping (T) -> Void) -> (T) -> Void {
            let timer = makeCallbackQueueTimer()
            return { param in
                self.finishCallbackQueueTimer(timer: timer)
                action(param)
            }
        }
        func makeCallbackQueueTimer() -> BlockedTimer {
            return BlockedTimer(timeout: M.queueBlockedWarnTime) { [self] in
                SimpleRustClient.logger.warn(title + " Waiting...", additionalData: ["contextID": self.contextID])
            }
        }
        func finishCallbackQueueTimer(timer: BlockedTimer) {
            let duration = timer.finish()
            if duration > M.callbackSerialExecuteWarnDuration {
                // callbackqueue-time
                self.info["CBQ-Time"] = M.format(time: duration)
                self.hasBlock = true
            }
        }
        func doCallback(action: () -> Void) {
            let timer = BlockedTimer(timeout: M.queueBlockedWarnTime) { [self] in
                SimpleRustClient.logger.warn(title + " Callbacking...", additionalData: ["contextID": self.contextID])
            }
            defer {
                let duration = timer.finish()
                if duration > M.callbackSerialExecuteWarnDuration {
                    self.info["Callback-Time"] = M.format(time: duration)
                    self.hasBlock = true
                }
            }
            action()
        }
        /// record callback time and log if no call in long time
        func doCallbackAndFinish(action: () -> Void) {
            doCallback(action: action)
            finish()
        }

        class BlockedTimer {
            let finished = AtomicBoolCell(false)
            var action: (() -> Void)?
            let start: CFTimeInterval
            var elapsed: CFTimeInterval { CACurrentMediaTime() - start }
            deinit {
                finished.deallocate()
            }
            init(timeout: TimeInterval, action: @escaping () -> Void) {
                self.action = action
                start = CACurrentMediaTime()
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                    if let self, self.finished.exchange(true) == false, let action = self.action {
                        self.action = nil
                        action()
                    }
                }
            }
            @discardableResult
            func finish() -> CFTimeInterval {
                if self.finished.exchange(true) == false {
                    self.action = nil
                }
                return elapsed
            }
        }
    }
    class HoldTask {
        var tasks: [() -> Void] = []
        func flush() {
            let tasks = self.tasks
            self.tasks = []
            for action in tasks {
                action()
            }
        }
    }
}

extension SwiftProtobuf.Message {
    @inlinable var protoMessageName: String { return type(of: self).protoMessageName }
    var requestJsonString: String {
        if SimpleRustClient.showLogDetails {
            let rustJsonResponse: String
            #if DEBUG || ALPHA
            do {
                rustJsonResponse = try self.jsonString()
            } catch {
                rustJsonResponse = "Could not searialized request data to json format. O.O...."
            }
            #else
                rustJsonResponse = ""
            #endif
            return "[Request Json data: \(rustJsonResponse)]"
        } else {
            return ""
        }
    }
    var responseJsonString: String {
        if SimpleRustClient.showLogDetails {
            let rustJsonResponse: String
            #if DEBUG || ALPHA
            do {
                rustJsonResponse = try self.jsonString()
            } catch {
                rustJsonResponse = "Could not searialized response data to json format. O.O...."
            }
            #else
                rustJsonResponse = ""
            #endif
            return "[Response Json data: \(rustJsonResponse)]"
        } else {
            return ""
        }
    }
}

extension MessageRequest {
    @inlinable var protoMessageCmd: Command { return type(of: self).protoMessageCmd }
}

extension BinaryDecodingOptions {
    static var discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}
