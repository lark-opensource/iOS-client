//
//  DataServiceProvider.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/28.
//

import Foundation
import MailSDK
import LarkRustClient
import RustPB
import SwiftProtobuf
import RxSwift
import ServerPB
import LarkFeatureGating
import Swinject
import LarkContainer

// bridge for Mailsdk. provide network & data service
class DataServiceProvider {
    private let resolver: UserResolver

    var enable: Bool {
        return true
    }

    var client: RustService? {
        if let client = try? resolver.resolve(assert: RustService.self) {
            return client
        } else if let currentResolver = try? resolver.getUserResolver(userID: resolver.userID, compatibleMode: true) {
            /// Fallback 回旧逻辑拿当前用户容器，如果走到这里说明用户登出后，还有地方持有旧的容器
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call previous disposed RustService!")
            return try? currentResolver.resolve(assert: RustService.self)
        } else {
            return nil
        }
    }

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
}

extension DataServiceProvider: DataServiceProxy {
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, serCommand: ServerPB_Improto_Command) -> Observable<R> {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<R>.empty()
        }
        let observable: Observable<ContextResponse<R>> = client.sendPassThroughAsyncRequest(request, serCommand: serCommand)
        return observable.map({ (response) -> R in
            return response.response
        })
    }
    
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, serCommand: ServerPB_Improto_Command, mailAccountId: String?) -> Observable<R> {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<R>.empty()
        }
        let observable: Observable<ContextResponse<R>> = client.sendPassThroughAsyncRequest(request, serCommand: serCommand, mailAccountId: mailAccountId)
        return observable.map({ (response) -> R in
            return response.response
        })
    }

    func sendSyncRequest(_ request: SwiftProtobuf.Message) throws {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return
        }

        do {
            try client.sendSyncRequest(request)
        } catch {
            throw error.transformToAPIError()
        }
    }

    func sendSyncRequest<R>(_ request: SwiftProtobuf.Message) throws -> R where R: SwiftProtobuf.Message {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return R()
        }

        let resonse: ContextResponse<R> = try client.sendSyncRequest(request)
        return resonse.response
    }

    func sendSyncRequest<R, U>(_ request: SwiftProtobuf.Message, transform: @escaping (R) throws -> U) throws -> U where R: SwiftProtobuf.Message {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return try transform(R())
        }

        return try client.sendSyncRequest(request, transform: { (response: ContextResponse<R>) -> U in
            return try transform(response.response)
        })
    }

    func sendSyncRequest<R>(_ request: SwiftProtobuf.Message) -> Observable<R> where R: SwiftProtobuf.Message {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<R>.empty()
        }

        let observable: Observable<ContextResponse<R>> = client.sendSyncRequest(request)
        return observable.map({ (response) -> R in
            return response.response
        })
    }

    func sendSyncRequest<R, U>(_ request: SwiftProtobuf.Message, transform: @escaping (R) throws -> U) -> Observable<U> where R: SwiftProtobuf.Message {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<U>.empty()
        }

        return client.sendSyncRequest(request, transform: { (response: ContextResponse<R>) -> U in
            return try transform(response.response)
        })
    }

    func sendAsyncRequest(_ request: SwiftProtobuf.Message, mailAccountId: String?) -> Observable<Void> {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<Void>.empty()
        }

        return client.sendAsyncRequest(request, mailAccountId: mailAccountId)
    }

    func sendAsyncRequest<R>(_ request: SwiftProtobuf.Message, mailAccountId: String?) -> Observable<R> where R: SwiftProtobuf.Message {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<R>.empty()
        }

        let observable: Observable<ContextResponse<R>> = client.sendAsyncRequest(request, mailAccountId: mailAccountId)
        return observable.map({ (response) -> R in
            return response.response
        })
    }

    func sendAsyncRequest<R, U>(_ request: SwiftProtobuf.Message, mailAccountId: String?, transform: @escaping (R) throws -> U) -> Observable<U> where R: SwiftProtobuf.Message {
        guard enable,
              let client = client
        else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Should not call Rust when user not login!")
            return Observable<U>.empty()
        }

        return client.sendAsyncRequest(request, mailAccountId: mailAccountId, transform: { (response: ContextResponse<R>) -> U in
            return try transform(response.response)
        })
    }

    func extractCommand(fromRequest: Message) -> Basic_V1_Command {
        return RustManager.shared.extractCommand(fromRequest: fromRequest)
    }
}
