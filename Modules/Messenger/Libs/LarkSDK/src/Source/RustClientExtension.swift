//
//  RustClientExtension.swift
//  LarkSDK
//
//  Created by Yaoguoguo on 2023/4/26.
//

import Foundation
import LarkRustClient
import LarkContainer
import LarkFoundation
import LarkSecurityComplianceInterface
import LarkSDKInterface
import RxSwift
import SwiftProtobuf
import LarkAccountInterface

private func handleSecurityError(error: Error, userID: String?) -> Bool {
    guard let error = error.underlyingError as? APIError, error.errorCode == 7005
    else { return false }
    do {
        let resolver: UserResolver
        switch userID {
        case let userID?: resolver = try Container.shared.getUserResolver(userID: userID)
        default: resolver = Container.shared.getCurrentUserResolver() // foregroundUser
        }

        let service = try resolver.resolve(assert: SecurityPolicyService.self)
        let action = DefaultSecurityAction(rawActions: error.extraString)
        service.handleSecurityAction(securityAction: action)

        return true
    } catch {
        return false
    }
}

public extension RustService {
    func sendAsyncSecurityRequest(_ request: SwiftProtobuf.Message) -> Observable<Void> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest(_ request: Message, spanID: UInt64?) -> Observable<Void> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, spanID: spanID).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in

                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest(_ request: Message, mailAccountId: String?) -> Observable<Void> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, mailAccountId: mailAccountId).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                            spanID: UInt64?) -> Observable<R> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, spanID: spanID).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> Observable<ContextResponse<R>> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                            spanID: UInt64?) -> Observable<ContextResponse<R>> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, spanID: spanID).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                            mailAccountId: String?) -> Observable<ContextResponse<R>> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, mailAccountId: mailAccountId).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) -> Observable<U> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, transform: transform).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        spanID: UInt64?,
        transform: @escaping(R) throws -> U
    ) -> Observable<U> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, spanID: spanID, transform: transform).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, transform: transform).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        spanID: UInt64?,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, spanID: spanID, transform: transform).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        mailAccountId: String?,
        transform: @escaping(ContextResponse<R>) throws -> U
    ) -> Observable<U> {
        return Observable.create { observer in
            _ = self.sendAsyncRequest(request, mailAccountId: mailAccountId, transform: transform).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequestBarrier(_ request: SwiftProtobuf.Message) -> Observable<Void> {
        return Observable.create { observer in
            _ = self.sendAsyncRequestBarrier(request).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequestBarrier(_ request: SwiftProtobuf.Message,
                                         spanID: UInt64?) -> Observable<Void> {
        return Observable.create { observer in
            _ = self.sendAsyncRequestBarrier(request, spanID: spanID).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequestBarrier<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message)
    -> Observable<ContextResponse<R>> {
        return Observable.create { observer in
            _ = self.sendAsyncRequestBarrier(request).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }

    func sendAsyncSecurityRequestBarrier<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message,
                                                                   spanID: UInt64?)
    -> Observable<ContextResponse<R>> {
        return Observable.create { observer in
            _ = self.sendAsyncRequestBarrier(request, spanID: spanID).subscribe(
                onNext: { response in
                    observer.onNext(response)
                    observer.onCompleted()
                },
                onError: { error in
                    if handleSecurityError(error: error, userID: userID) {
                    } else {
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
    }
}
