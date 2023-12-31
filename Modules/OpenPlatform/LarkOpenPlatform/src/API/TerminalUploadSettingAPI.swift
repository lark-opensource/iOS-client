//
//  TerminalUploadSettingAPI.swift
//  LarkOpenPlatform
//
//  Created by tujinqiu on 2019/9/23.
//

import Foundation
import LKCommonsLogging
import LarkContainer

extension OpenPlatformAPI {
    public static func TerminalUploadSettingAPI(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .terminalUploadSettings, resolver: resolver)
            .setMethod(.get)
            .useSession()
            .setScope(.uploadInfo)
    }
}

extension OpenPlatformAPI {
    public static func bindTriggerCodeSettingAPI(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .messageCardBindTriggerCode, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .setScope(.messageCard)
    }
}

final class TerminalUploadSettingAPIResponse: APIResponse {
    private static let logger = Logger.oplog(TerminalUploadSettingAPIResponse.self,
                                           category: "TerminalUploadSettingAPIResponse")
    /// 内部变量
    private var _config: UploadInfoConfig?
    /// 外部懒加载变量，这样可以显式解析
    lazy var config: UploadInfoConfig? = {
        if _config == nil {
            tryParseConfig()
        }
        return _config
    }()

    /// 尝试解析config
    public func tryParseConfig() {
        if let data = rawData,
            let cg = try? JSONDecoder().decode(UploadInfoConfig.self, from: data) {
            _config = cg
        } else {
            TerminalUploadSettingAPIResponse.logger.error("Parse api \(api) Json Wrong, maybe data is nil \(rawData != nil) ")
        }
    }
}
