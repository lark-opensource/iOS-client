//
//  NativeDisposableLoginConfigAPI.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/2/5.
//

import Foundation
import LKCommonsLogging
import RxSwift
import LarkContainer

class NativeDisposableLoginConfigAPI: DisposableLoginConfigAPI {
    static let logger = Logger.plog(NativeDisposableLoginConfigAPI.self, category: "LarkAccount.NativeDisposableLoginConfigAPI")

    private let disposeBag = DisposeBag()

    init(resolver: UserResolver?) { }

    func getDisposableLoginConfig() -> Observable<[Int: String]> {
        Self.logger.errorWithAssertion("provide implementation for config like RustDisposableLoginConfigAPI")
        let urlMap: [Int: String] = [:]
        return .just(urlMap)
    }
}
