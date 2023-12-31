//
//  SimpleRustClient+Async.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/8/17.
//

import UIKit
import Foundation
import SwiftProtobuf
import RustPB
import ServerPB
import RustSDK

// MARK: - Asynchronous

extension SimpleRustClient {

    private struct AsyncRequestContext<R> {
        let context: RequestContext
        var priority: DispatchQoS?
        let factory: (Data) throws -> (R, String)
        let callback: (ResponsePacket<R>) -> Void
        var rustDuration: CFTimeInterval?
    }
    func sendAsyncRequestImpl<R: Message>(
        command: Command = .unknownCommand,
        _ request: SwiftProtobuf.Message,
        context: RequestContext,
        serCommand: ServerPB_Improto_Command?,
        callback: @escaping (ResponsePacket<R>) -> Void
    ) {
        sendAsyncRequestImpl(
            command: command,
            request,
            context: context,
            serCommand: serCommand,
            factory: {
                let v = try R(serializedData: $0, options: .discardUnknownFieldsOption)
                return (v, v.responseJsonString)
            },
            callback: callback
        )
    }
    func sendAsyncRequestImpl(
        command: Command = .unknownCommand,
        _ request: SwiftProtobuf.Message,
        context: RequestContext,
        serCommand: ServerPB_Improto_Command?,
        callback: @escaping (ResponsePacket<Void>) -> Void
    ) {
        sendAsyncRequestImpl(
            command: command,
            request,
            context: context,
            serCommand: serCommand,
            factory: { ((), "\($0.count)") },
            callback: callback
        )
    }

    /// Call RustSDK Asynchronous Private API
    private func sendAsyncRequestImpl<R>(
        command: Command = .unknownCommand,
        _ request: SwiftProtobuf.Message,
        context: RequestContext,
        serCommand: ServerPB_Improto_Command?,
        factory: @escaping (Data) throws -> (R, String),
        callback: @escaping (ResponsePacket<R>) -> Void
    ) {
        let asyncContext = AsyncRequestContext(context: context, factory: factory, callback: callback)
        sendAsyncRequestImpl(
            packer: {
                try self.makeRequestPacket(
                    command: command,
                    serCommand: serCommand,
                    request: request,
                    context: context)
            }, context: asyncContext)
    }

    func sendAsyncRequestImpl(
        command: Command,
        serCommand: ServerPB_Improto_Command?,
        _ payload: Data,
        context: RequestContext,
        callback: @escaping (ResponsePacket<Data>) -> Void
    ) {
        // copy to ensure valid in async callback
        let asyncContext = AsyncRequestContext(
            context: context, factory: { (Data($0), "\($0.count)") },
            callback: callback)
        sendAsyncRequestImpl(
            packer: {
                try self.makeRequestPacket(
                    command: command,
                    serCommand: serCommand,
                    payload: payload,
                    context: context)
            }, context: asyncContext)
    }

    private func sendAsyncRequestImpl<R>(
        packer: () throws -> CommonPacket,
        context: AsyncRequestContext<R>
    ) {
        let err: RCError
        var asyncContext = context
        do {
            // Print Send Request Log
            let packet = try packer()
            let packetData = try packet.packet.serializedData()
            asyncContext.priority = M.qos(command: packet.packet.cmd)
            // send a cancel callback when dispose
            let cancelTask = CancelTask { $0.onInvokeFailure(context: asyncContext, error: .cancel) }
            try self.add(disposeTask: cancelTask)
            let rustStart = CACurrentMediaTime()
            RustManager.shared.invokeAsyncV2(
                command: RustManager.RawCommand(Command.wrapperWithPacket.rawValue),
                data: packetData) { [weak self, cmd = packet.cmd] (data, hasError, verifyUserID, sdkUserID) in
                    // ignore deinit event
                    guard let self = self, !self.disposed, self.remove(disposeTask: cancelTask) != nil else { return }
                    asyncContext.rustDuration = CACurrentMediaTime() - rustStart
                    do {
                        guard let data = data.asData() else { throw RCError.invalidEmptyResponse }
                        guard !hasError else { throw M.errorFromRust(data: data) }
                        try self.verify(sdkUserID: sdkUserID, verifyUserID: verifyUserID,
                                        cmd: cmd, contextID: asyncContext.context.contextID)

                        self.onInvokeSucceeded(context: asyncContext, data: data)
                    } catch let error as RCError {
                        self.onInvokeFailure(context: asyncContext, error: error)
                    } catch {
                        self.onInvokeFailure(context: asyncContext, error: .unknownError(error: error))
                    }
            }
            return // success async call
        } catch let error as BinaryEncodingError {
            err = RCError.requestSerializeFailure(error: error)
        } catch let error as RCError {
            err = error
        } catch {
            err = RCError.unknownError(error: error)
        }
        self.onInvokeFailure(context: asyncContext, error: err)
    }

    func verify(sdkUserID: UInt64, verifyUserID: Bool, cmd: CMD, contextID: String) throws {
        guard verifyUserID else { return }
        let clientUserID = self.clientUserID
        if clientUserID != sdkUserID {
            // 全局的先只上报不拦截
            let intercepted = verifyUserID && clientUserID != 0
            SimpleRustClient.hook?.onInvalidUserID(RustClient.OnInvalidUserID(
                scenario: "invoke_async",
                command: cmd.rust?.rawValue, serverCommand: cmd.server?.rawValue,
                clientUserID: clientUserID, sdkUserID: sdkUserID,
                contextID: contextID, intercepted: intercepted
                ))
            if intercepted { throw RCError.inconsistentUserID }
        }
    }

    private func onInvokeSucceeded<R>(context: AsyncRequestContext<R>, data: Data) {
        do {
            let (result, responseJsonString) = try context.factory(data)
            let commandInfo = "\(context.context.label) Success"
            let contextID = context.context.contextID
            let metrics = Metrics(title: "\(self.identifier) <-- \(commandInfo)",
                                  additional: ", \(responseJsonString)", contextID: contextID,
                                  startTime: context.context.startTime, rustDuration: context.rustDuration)
            let finish = { [callback = context.callback](result) in
                metrics.doCallbackAndFinish() {
                    callback( ResponsePacket(contextID: contextID, result: result))
                }
            }
            if context.context.direct {
                finish(.success(result))
            } else {
                let doCallback = metrics.wrapCallback { [weak self] in
                    // 回调queue真正回调前再判断一下，尽量及时释放. self被释放和disposed为true的情况都取消
                    if self?.disposed == false {
                        finish(.success(result))
                    } else {
                        metrics.additional = " Cancel"
                        finish(.failure(RCError.cancel))
                    }
                }
                self.callback(on: callbackQueue, qos: context.priority ?? .unspecified, execute: doCallback)
            }
        } catch {
            let err = RCError.responseSerializeFailure(error: error)
            self.onInvokeFailure(context: context, error: err)
        }
    }
    private func onInvokeFailure<R>(context: AsyncRequestContext<R>, error: RCError) {
        let commandInfo = "\(context.context.label) Failed"
        let contextID = context.context.contextID
        let metrics = Metrics(title: "\(self.identifier) <-- \(commandInfo)", contextID: contextID,
                              startTime: context.context.startTime, rustDuration: context.rustDuration,
                              error: error)

        let finish = { [callback = context.callback] in
            metrics.doCallbackAndFinish() {
                callback( ResponsePacket(contextID: contextID, result: .failure(error)))
            }
        }
        if context.context.direct {
            finish()
        } else {
            let doCallback = metrics.wrapCallback { finish() }
            self.callback(on: callbackQueue, qos: context.priority ?? .unspecified, execute: doCallback)
        }
    }
}
