//
//  WPTimeoutSettingMiddleware.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/8.
//

import Foundation
import ECOInfra
import LarkOPInterface
import LKCommonsLogging
import LarkSetting

struct WPTimeoutSettingMiddleware: ECONetworkMiddleware {
    private static let logger = Logger.log(WPTimeoutSettingMiddleware.self)

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        let context = task.context as? WPNetworkContext
        var request = request

        // resolve configService 失败不影响请求继续
        // timeout 使用配置默认值
        guard let configService = try? context?.userResolver?.resolve(assert: WPConfigService.self) else {
            Self.logger.error("resolve config service failed")
            request.setting.timeout = NetworkTimeoutConfig.defaultValue.timeout
            return .success(request)
        }

        let config = configService.settingValue(NetworkTimeoutConfig.self)
        request.setting.timeout = config.timeout

        Self.logger.info("setup timeout", additionalData: ["time": "\(config.timeout)"])
        return .success(request)
    }
}
