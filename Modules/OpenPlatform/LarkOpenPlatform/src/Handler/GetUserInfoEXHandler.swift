//
//  GetUserInfoEXHandler.swift
//  LarkOpenPlatform
//
//  Created by tujinqiu on 2019/10/28.
//

import UIKit
import Swinject
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer

class GetUserInfoEXHandler {
    static let logger = Logger.log(GetUserInfoEXHandler.self, category: "GetUserInfoEXHandler")
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func getUserInfoEx(onSuccess: @escaping ([String: Any]) -> Void, onFail: @escaping (Error) -> Void) {
        if let service = try? resolver.resolve(assert: KaLoginService.self), let config = service.getKaConfig() {
            service.getExtraIdentity(onSuccess: { extra in
                let merged = config.merging(extra) { (current, _) in  current }
                GetUserInfoEXHandler.logger.info("get userInfoEx success config: \(config.keys.count)")
                onSuccess(merged)
            }, onError: { error in
                GetUserInfoEXHandler.logger.error("\(error)")
                onFail(error)
            })
        } else {
            onFail(KaGetUserInfoExError.invalidKaConfig)
        }
    }

    enum KaGetUserInfoExError: Error {
        case invalidKaConfig
    }
}
