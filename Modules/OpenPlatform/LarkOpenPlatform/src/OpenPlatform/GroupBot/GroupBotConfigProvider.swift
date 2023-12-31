//
//  GroupBotConfigProvider.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/25.
//

import LarkRustClient
import RustPB
import RxSwift
import Swinject
import LKCommonsLogging

/// settings v3配置下发的群机器人相关配置
struct GroupBotConfig: Codable {
    let groupBotHelpURL: String?
}

/// 获取settings v3配置下发的群机器人相关配置
class GroupBotConfigProvider {
    static let logger = Logger.oplog(GroupBotConfigProvider.self, category: GroupBotDefines.groupBotLogCategory)

    private let resolver: Resolver
    private let disposeBag = DisposeBag()

    private var config: GroupBotConfig?

    /// 初始化方法
    /// - Parameters:
    ///   - resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    /// 获取群机器人帮助文档URL
    func fetchGroupBotHelpURL(completion: @escaping ((URL?) -> Void)) {
        fetchGroupBotConfig { config, errorMessage in
            guard let config = config else {
                Self.logger.error("fetch bot help url error: \(String(describing: errorMessage))")
                completion(nil)
                return
            }
            completion(config.groupBotHelpURL?.possibleURL())
        }
    }

    /// 获取群机器人相关配置
    func fetchGroupBotConfig(completion: @escaping ((GroupBotConfig?, String?) -> Void)) {
        if config != nil {
            completion(config, nil)
            return
        }

        let key = "group_bot_config"
        Self.logger.info("fetch bot setting keys start")
        fetchSettingsRequest(fields: [key])?.subscribeForUI(onNext: { [weak self] config in
            Self.logger.info("fetch bot setting keys finish: \(key) result = \(config)")
            if let configString = config[key],
               let configData = configString.data(using: String.Encoding.utf8) {
                do {
                    let config = try JSONDecoder().decode(GroupBotConfig.self, from: configData)
                    self?.config = config
                    Self.logger.info("bot setting info success with result config(\(config))")
                    completion(config, nil)
                } catch {
                    let errorMessage = "bot setting info decodes failed with error(\(error))"
                    Self.logger.error(errorMessage)
                    completion(nil, errorMessage)
                }
            } else {
                let errorMessage = "bot setting info decodes failed with config(\(config))"
                Self.logger.error(errorMessage)
                completion(nil, errorMessage)
            }
        }, onError: { error in
            Self.logger.error("fetch bot setting failed", tag: "", additionalData: nil, error: error)
            completion(nil, "fetch bot setting failed: \(error)")
        }).disposed(by: disposeBag)
    }

    /// 获取V3 Setting配置信息
    private func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]>? {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = fields
        return try? resolver.resolve(assert: RustService.self).sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribeOn(ConcurrentMainScheduler.instance)
    }
}
