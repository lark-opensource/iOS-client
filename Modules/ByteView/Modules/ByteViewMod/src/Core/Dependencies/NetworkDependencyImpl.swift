//
//  NetworkDependencyImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2022/12/14.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import LarkRustClient
import LarkContainer

final class NetworkDependencyImpl: NetworkDependency {
    func sendRequest(request: RawRequest, completion: @escaping (RawResponse) -> Void) {
        guard let rust = rustService(for: request.userId) else {
            completion(RawResponse(contextId: request.contextId, result: .failure(NetworkError.rustNotFound)))
            return
        }

        var packet: RawRequestPacket
        switch request.command {
        case .rust(let cmd):
            packet = RawRequestPacket(command: cmd, message: request.data)
        case .server(let cmd):
            packet = RawRequestPacket(serCommand: cmd, message: request.data)
        }
        if request.keepOrder {
            packet.serialToken = self.serialToken(for: request.command)
        }
        packet.parentID = request.contextId
        if let contextIdCallback = request.contextIdCallback {
            packet.contextIdGenerationCallback = contextIdCallback
        }
        rust.async(packet) { (response: ResponsePacket<Data>) in
            let contextId = response.contextID
            switch response.result {
            case .success(let data):
                completion(RawResponse(contextId: contextId, result: .success(data)))
            case .failure(let error):
                if let rcError = error as? RCError, case let .businessFailure(errorInfo: errorInfo) = rcError {
                    let bizError = RustBizError(code: Int(errorInfo.errorCode), debugMessage: errorInfo.debugMessage,
                                                displayMessage: errorInfo.displayMessage, msgInfo: errorInfo.displayMessage)
                    completion(RawResponse(contextId: contextId, result: .failure(bizError)))
                } else {
                    completion(RawResponse(contextId: contextId, result: .failure(error)))
                }
            }
        }
    }

    private func rustService(for userId: String) -> RustService? {
        guard !userId.isEmpty, let resolver = try? Container.shared.getUserResolver(userID: userId) else {
            assertionFailure("user not found")
            return nil
        }
        return try? resolver.resolve(assert: RustService.self)
    }

    @RwAtomic
    private static var tokenCache: [NetworkCommand: SerialToken] = [:]
    private func serialToken(for command: NetworkCommand) -> SerialToken {
        if let cache = Self.tokenCache[command] {
            return cache
        } else {
            let token = RequestPacket.nextSerialToken()
            Self.tokenCache[command] = token
            return token
        }
    }
}
