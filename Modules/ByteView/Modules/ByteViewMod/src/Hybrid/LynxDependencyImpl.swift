//
//  LynxDependencyImpl.swift
//  ByteViewHybrid
//
//  Created by Tobb Huang on 2022/11/2.
//

import Foundation
import ByteViewCommon
import ByteViewHybrid
import OfflineResourceManager
import LarkContainer
import LarkEnv
import LarkAccountInterface

final class LynxDependencyImpl: NSObject, LynxDependency {

    private static let logger = Logger.getLogger("lynx")

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
    }

    private var hasRegisteredGecko = false
    private lazy var geckoConfig: LynxGeckoConfig = {
        do {
            let passport = try userResolver.resolve(assert: PassportService.self)
            return passport.isFeishuBrand ? .feishu : .lark
        } catch {
            return .feishu
        }
    }()

    func syncResource() {
        initGecko()
        OfflineResourceManager.fetchResource(byId: self.geckoConfig.channel, complete: { (success, state) in
            Self.logger.info("syncResource, success = \(success), state = \(state)")
        })
    }

    func loadTemplate(path: String, callback: ((Data?, Error?) -> Void)?) {
        let channel = geckoConfig.channel
        Self.logger.info("loadTemplate \(path) channel \(channel)")
        let data = loadTemplateSync(templateName: path, channel: channel)
        callback?(data, nil)
    }

    var globalProps: [String: Any] {
        ["env": EnvManager.env.type.domainKey]
    }

    private func initGecko() {
        // 每个账号，gecko只需要注册一次
        guard !hasRegisteredGecko else { return }
        hasRegisteredGecko = true
        let identities: [LynxGeckoConfig] = [self.geckoConfig]
        identities.forEach { identity in
            let accessKey = identity.accessKey
            let config = OfflineResourceBizConfig(bizID: identity.channel,
                                                  bizKey: accessKey,
                                                  subBizKey: identity.channel,
                                                  bizType: .dynamic)
            OfflineResourceManager.registerBiz(configs: [config])
        }
    }

    /// 从Gecko加载模板
    private func loadTemplateSync(templateName: String, channel: String) -> Data? {
        Self.logger.info("loadTemplateSync \(templateName) channel \(channel)")
        guard OfflineResourceManager.fileExists(id: channel, path: templateName) else {
            Self.logger.error("loadTemplateSync failed, file not exists")
            return nil
        }
        let data = OfflineResourceManager.data(forId: channel, path: templateName)
        Self.logger.info("loadTemplateSync \(templateName) from gecko, data:\(String(describing: data))")
        return data
    }
}
