//
//  SimpleRustClient+EventStream.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/8/17.
//

import Foundation
import SwiftProtobuf
import RustPB
import RxSwift

// MARK: - Event Stream
extension SimpleRustClient {
    // swiftlint:disable:next function_body_length
    func startEventStreamImpl<R: SwiftProtobuf.Message>(
        request: SwiftProtobuf.Message,
        config: Basic_V1_RequestPacket.BizConfig?,
        context: RequestContext,
        finishOnError: Bool,
        callback: @escaping (ResponsePacket<R>?, _ finish: Bool) -> Void
    ) -> Disposable {
        // NOTE: 需要调用过Rust的初始化代码才会有推送回调。没command map, 其实只在子类支持event stream

        // log and guarantee run on callbackQueue
        let commandInfo = context.label
        let contextID = context.contextID
        var priority: DispatchQoS?
        // event stream需要保证自己的事件是串行的, 所以每一个使用独立子Queue
        let callbackQueue = DispatchQueue(label: "Rust Client Stream-\(contextID)", target: self.callbackQueue)
        let wrapCallback = { (self: SimpleRustClient, result: Result<R, RCError>?, finish: Bool) in
            let metrics: Metrics
            // let label: String
            let response: ResponsePacket<R>?
            if let result = result {
                response = ResponsePacket(contextID: contextID, result: result)
                switch result {
                case .success(let message):
                    let label = "\(commandInfo) \(finish ? "Finish With" : "") Data"
                    metrics = Metrics(title: "\(self.identifier) <-- \(label)",
                                      additional: ", \(message.responseJsonString)",
                                      contextID: contextID)
                case .failure(let error):
                    let label = "\(commandInfo) \(finish ? "Finish With" : "") Error"
                    metrics = Metrics(title: "\(self.identifier) <-- \(label)",
                                      contextID: contextID, error: error)
                }
            } else {
                response = nil
                assert(finish)
                let label = "\(commandInfo) Finish"
                metrics = Metrics(title: "\(self.identifier) <-- \(label)", contextID: contextID)
            }
            let doCallback = metrics.wrapCallback { [weak self] in
                if self?.disposed == false {
                    metrics.doCallbackAndFinish { callback(response, finish) }
                } else {
                    metrics.additional = " Cancel By Disposed"
                    // else分支已经disposed了，所以一定会发finish, 但可能在callback queue里被延迟.
                    // 所以之前的event都忽略，最后直接发一个finish的cancel通知
                    if finish {
                        metrics.doCallbackAndFinish {
                            callback(ResponsePacket(contextID: contextID,
                                                    result: .failure(RCError.cancel)),
                                     true)
                        }
                    } else if metrics.hasBlock {
                        metrics.finish()
                    }
                }
            }
            self.callback(on: callbackQueue, qos: priority ?? .unspecified, execute: doCallback)
        }

        // 需要保证回调只执行一次finish，且finish回调后不会再有普通的回调
        var finishLock = os_unfair_lock()
        var finished = false
        weak var weakSteam: RustManager.Stream?
        let cancelTask = CancelTask { (self) in
            do {
                os_unfair_lock_lock(&finishLock); defer { os_unfair_lock_unlock(&finishLock) }
                if finished { return }
                finished = true
            }
            weakSteam?.cancel()
            wrapCallback(self, .failure(RCError.cancel), true)
        }
        let callback = { (self: SimpleRustClient, result: Result<R, RCError>?, finish: Bool) in
            os_unfair_lock_lock(&finishLock); defer { os_unfair_lock_unlock(&finishLock) }
            if finished { return }
            if finish {
                finished = true
                self.remove(disposeTask: cancelTask)
            }
            wrapCallback(self, result, finish)
        }

        let err: RCError
        do {
            var packet = try self.makeRequestPacket(
                command: .unknownCommand,
                serCommand: nil, // TODO: 支持server command的事件流, 现在事件流用得太少了
                request: request,
                context: context).packet

            if let config = config {
                packet.bizConfig = config
            }

            priority = M.qos(command: packet.cmd)
            try self.add(disposeTask: cancelTask) // 必须在请求前设置，若直接回调可能会finish需要移除
            let stream = try RustManager.shared.eventStream(
                command: RustManager.RawCommand(Command.wrapperWithPacket.rawValue),
                request: packet
            ) { [weak self, cmd = packet.cmd] (stream, packet) in
                // return when deinit, deinit will cancel all stream.
                // this callback will convert payload data to response/error.
                guard let self = self, !self.disposed else { return }
                var finish = false
                switch packet.streamStatus {
                case .finalWithoutPayload:
                    callback(self, nil, true)

                    // dispatch payload
                case .finalWithPayload:
                    finish = true
                    fallthrough
                case .active:
                    let result: Result<R, RCError>
                    do {
                        guard packet.hasPayload else {
                            stream.cancel()
                            finish = true // exception
                            throw RCError.invalidEmptyResponse
                        }
                        if packet.isErr { throw M.errorFromRust(data: packet.payload) }
                        try verify()
                        result = .success(try R(serializedData: packet.payload, options: .discardUnknownFieldsOption))

                        func verify() throws {
                            let (clientUserID, sdkUserID) = (self.clientUserID, UInt64(packet.userID) ?? 0)
                            guard packet.verifyUserID else { return }
                            if clientUserID != sdkUserID {
                                // 全局的先只上报不拦截
                                let intercepted = packet.verifyUserID && clientUserID != 0
                                SimpleRustClient.hook?.onInvalidUserID(RustClient.OnInvalidUserID(
                                    scenario: "event_stream", command: cmd.rawValue, serverCommand: nil,
                                    clientUserID: clientUserID, sdkUserID: sdkUserID,
                                    contextID: contextID, hasError: packet.isErr,
                                    intercepted: intercepted
                                    ))
                                if intercepted {
                                    stream.cancel() // 用户错误是否要取消呢？
                                    finish = true // exception
                                    throw RCError.inconsistentUserID
                                }
                            }
                        }
                    } catch let error as RCError {
                        // 正常业务error, 看情况要不要cancel
                        if finishOnError {
                            stream.cancel()
                            finish = true
                        }
                        result = .failure(error)
                    } catch let error as BinaryEncodingError {
                        stream.cancel()
                        finish = true // exception
                        result = .failure(RCError.responseSerializeFailure(error: error))
                    } catch {
                        assertionFailure("unknownError \(error)")
                        stream.cancel()
                        finish = true // exception
                        result = .failure(RCError.unknownError(error: error))
                    }
                    callback(self, result, finish)
                @unknown default:
                    #if ALPHA
                    fatalError("unknown cases!")
                    #endif
                    stream.cancel()
                    callback(self, .failure(RCError.sdkError), true)
                }
            }
            weakSteam = stream
            return Disposables.create { [weak self] in
                if stream.cancel(), let self = self {
                    SimpleRustClient.logger.info("\(self.identifier) <-- \(commandInfo) Cancel",
                                            additionalData: ["contextID": contextID])
                    self.remove(disposeTask: cancelTask)
                }
            }
        } catch let error as BinaryEncodingError {
            err = .requestSerializeFailure(error: error)
        } catch let error as RCError {
            err = error
        } catch {
            assertionFailure("unknownError \(error)")
            err = .unknownError(error: error)
        }
        callback(self, .failure(err), true)
        return Disposables.create()
    }
}
