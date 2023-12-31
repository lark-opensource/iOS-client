//
//  SCFGService.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/28.
//

import SwiftyJSON
import LarkContainer
import RxSwift
import LarkSetting

public protocol SCFGService {
    func staticValue(_ key: SCFGKey) -> Bool
    func realtimeValue(_ key: SCFGKey) -> Bool
    func observe(_ key: SCFGKey) -> Observable<Bool>
}

class SCFeatureGatingIMP: SCFGService {
    private let service: FeatureGatingService

    init(resolver: UserResolver) throws {
        self.service = try resolver.resolve(assert: FeatureGatingService.self)
    }
    func staticValue(_ key: SCFGKey) -> Bool {
        service.staticFeatureGatingValue(with: .init(stringLiteral: key.rawValue))
    }
    func realtimeValue(_ key: SCFGKey) -> Bool {
        service.dynamicFeatureGatingValue(with: .init(stringLiteral: key.rawValue))
    }

    func observe(_ key: SCFGKey) -> Observable<Bool> {
        service.observe(key: .init(stringLiteral: key.rawValue))
    }
}
