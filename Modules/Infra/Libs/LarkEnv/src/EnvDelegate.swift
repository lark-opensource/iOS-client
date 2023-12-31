//
//  EnvDelegate.swift
//  LarkEnv
//
//  Created by Yiming Qu on 2021/1/24.
//

import Foundation
import RxSwift

// swiftlint:disable missing_docs

public typealias EnvDelegateResult = Result<(Env, [AnyHashable: Any]), Error>

public struct EnvPayloadKey {
    public static let brand = "EnvDelegate.EnvPayloadKey.Brand"
}

public protocol EnvDelegate: AnyObject {
    var name: String { get }
    func config() -> EnvDelegateConfig

    func envWillSwitch(_ futureEnv: Env, payload: [AnyHashable: Any]) -> Observable<Void>
    func envDidSwitch(_ result: EnvDelegateResult)
}

public extension EnvDelegate {
    func envWillSwitch(_ futureEnv: Env, payload: [AnyHashable: Any]) -> Observable<Void> { .just(()) }
    func envDidSwitch(_ result: EnvDelegateResult) { }
}

// swiftlint:enable missing_docs
