//
//  SimpleRustClient+Sync.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/8/17.
//

import UIKit
import Foundation
import SwiftProtobuf
import RustPB

typealias ResponsePacketWithMetrics<T> = (ResponsePacket<T>, SimpleRustClient.Metrics)
extension SimpleRustClient {
    func sendSyncRequestImpl(
        command: Command,
        serCommand: ServerCommand?,
        _ request: SwiftProtobuf.Message,
        context: RequestContext
    ) -> ResponsePacketWithMetrics<Void> {
        return sendSyncRequest(
            command: command, serCommand: serCommand, request,
            context: context,
            factory: { ((), "\($0.count)") }
        )
    }

    func sendSyncRequestImpl<T: Message>(
        command: Command,
        serCommand: ServerCommand?,
        _ request: SwiftProtobuf.Message,
        context: RequestContext
    ) -> ResponsePacketWithMetrics<T> {
        return sendSyncRequest(
            command: command, serCommand: serCommand, request,
            context: context,
            factory: {
              let v = try T(serializedData: $0, options: .discardUnknownFieldsOption)
              return (v, v.responseJsonString)
            }
        )
    }

    private func sendSyncRequest<T>(
        command: Command,
        serCommand: ServerCommand?,
        _ request: SwiftProtobuf.Message,
        context: RequestContext,
        factory: (Data) throws -> (T, String)
    ) -> ResponsePacketWithMetrics<T> {
        let contextID = context.contextID

        var dur: CFTimeInterval?
        let rcErr: RCError
        let commandInfo = context.label
        do {
            let (response, cmd, duration) = try sync(
                command: command, serCommand: serCommand, request: request, context: context)
            dur = duration
            guard let data = response.payload else {
                throw RCError.invalidEmptyResponse
            }
            switch response.code {
            case 0:
                try verifyUserID(response: response, cmd: cmd, contextID: contextID)
                do {
                    let (message, responseJsonString) = try factory(data)
                    return (ResponsePacket(contextID: contextID, result: .success(message)),
                            Metrics(title: "\(self.identifier) <-- \(commandInfo) Success.",
                                    additional: " \(responseJsonString)", contextID: contextID,
                                    startTime: context.startTime, rustDuration: duration))
                } catch {
                    throw RCError.responseSerializeFailure(error: error)
                }
            case 1:
                throw M.errorFromRust(data: data)
            default:
                throw RCError.sdkError
            }
        } catch let error as RCError {
            rcErr = error
        } catch {
            rcErr = RCError.unknownError(error: error)
        }
        return (ResponsePacket(contextID: contextID, result: .failure(rcErr)),
                Metrics(title: "\(self.identifier) <-- \(commandInfo) Failed.",
                        contextID: contextID, startTime: context.startTime, rustDuration: dur,
                        error: rcErr))
    }

    private func sync(
        command: Command, serCommand: ServerCommand?, request: SwiftProtobuf.Message, context: RequestContext
    ) throws -> (response: LarkInvokeResponseBridge, cmd: CMD, duration: CFTimeInterval) {
        // Send the synchronous request, catch send error
        do {
            if self.disposed { throw RCError.cancel }
            // throws: BinaryEncodingError
            // Print Send Log
            let packet = try makeRequestPacket(
                command: command,
                serCommand: serCommand,
                request: request,
                context: context
                )
            let requestData = try packet.packet.serializedData()
            let rustStart = CACurrentMediaTime()
            let response = RustManager.shared.invokeV2(
                command: RustManager.RawCommand(Command.wrapperWithPacket.rawValue),
                data: requestData)
            // guard dispose once more after invoke rust
            if self.disposed { throw RCError.cancel }
            let duration = CACurrentMediaTime() - rustStart
            return (response, packet.cmd, duration)
        } catch let error as BinaryEncodingError {
            throw RCError.requestSerializeFailure(error: error)
        }
    }
    private func verifyUserID(response: LarkInvokeResponseBridge, cmd: CMD, contextID: String) throws {
        if let meta = response.meta.flatMap({ try? Basic_V1_ResponseMeta(serializedData: $0) }) {
            if meta.verifyUserID {
                let (clientUserID, sdkUserID) = (self.clientUserID, meta.userID)
                if clientUserID != sdkUserID {
                    // 全局的先只上报不拦截
                    let intercepted = meta.verifyUserID && clientUserID != 0
                    SimpleRustClient.hook?.onInvalidUserID(RustClient.OnInvalidUserID(
                        scenario: "invoke",
                        command: cmd.rust?.rawValue, serverCommand: cmd.server?.rawValue,
                        clientUserID: clientUserID, sdkUserID: sdkUserID,
                        contextID: contextID, hasError: response.code != 0,
                        intercepted: intercepted
                        ))
                    if intercepted { throw RCError.inconsistentUserID }
                }
            }
        }
    }
}
