//
//  ECOSettingsFetchingServiceImp.swift
//  LarkOpenPlatform
//
//  Created by 窦坚 on 2021/6/9.
//

import Foundation
import ECOInfra
import RxSwift
import RustPB
import LarkRustClient
import LarkContainer
import ECOProbe
import LKCommonsLogging

/// ECOSettingsFetchingService 实现，用于rust能力注入
class ECOSettingsFetchingServiceImp: ECOSettingsFetchingService {
    static let logger = Logger.oplog(ECOSettingsFetchingService.self, category: "ECOSettingsFetchingService")

    private let disposeBag = DisposeBag()

    private var client: RustService?
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
        client = try? resolver.resolve(assert: RustService.self)
    }

    func fetchSettingsConfig(withKeys keys: [String], completion handler: @escaping EMASettingsFetchCompletion) {
        Self.logger.info("start fetch settings config", additionalData: ["keys": "\(keys), client is nil:\(client == nil)"])
        let monitor = OPMonitor(EPMClientOpenPlatformCommonConfigCode.fetch_settings_config_result).timing()
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = keys
        client?.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).do(onNext: { (dict) in
            monitor
                .setResultTypeSuccess()
                .addCategoryValue("key_count", dict.count)
                .timing()
                .flush()
            handler(dict, true)
        }, onError: { (error) in
            monitor
                .setResultTypeFail()
                .setError(error)
                .timing()
                .flush()
            handler([:], false)
        })
        .subscribe()
        .disposed(by: disposeBag)

    }
}

