//
//  RustDynamicDomainService.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/12.
//

import Foundation
import LarkAppConfig
import RxRelay
import RxSwift
import LKCommonsLogging

class RustDynamicDomainService: DynamicDomainService {

    static let logger = Logger.plog(RustDynamicDomainService.self, category: "SuiteLogin.RustDynamicDomainService")

    private var _result: BehaviorRelay<AsynGetDynamicDomainStatus> = {
        return BehaviorRelay(value: .success)
    }()

    @available(*, deprecated,
    message:"This method does nothing, domains will be pushed by rust. There is no need to triger.")
    var result: Observable<AsynGetDynamicDomainStatus> { _result.asObservable() }

    @available(*, deprecated,
    message:"This method does nothing, domains will be pushed by rust. There is no need to triger.")
    func asyncGetDynamicDomain() {
        Self.logger.info("async get dynamic domain")
        _result.accept(.success)
    }
}
