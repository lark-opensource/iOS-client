//
//  NativeDynamicDomain.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/12.
//

import Foundation
import RxSwift
import LKCommonsLogging

class NativeDynamicDomainService: DynamicDomainService {

    static let logger = Logger.plog(NativeDynamicDomainService.self, category: "SuiteLogin.NativeDynamicDomainService")

    var result: Observable<AsynGetDynamicDomainStatus> {
        Self.logger.errorWithAssertion("not impl dynamic domain impl, result fallback to success")
        return .just(.success)
    }

    func asyncGetDynamicDomain() {
        Self.logger.errorWithAssertion("not impl async dynamic domain")
    }
}
