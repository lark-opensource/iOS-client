import Foundation
import LarkAssembler
import LKSettingExternal
import LarkSetting
import LKCommonsLogging
import LarkAccountInterface

public class LKSettingExternalAssembly: LarkAssemblyInterface {
    public init() {
        KASettingExternal.shared.settings = KASettingImpl()
    }
}

final class KASettingImpl {
    let logger = Logger.log(KASettingImpl.self, category: "Module.LKSettingExternalAssembly")
}

extension KASettingImpl: KASettingProtocol {
    func getConfig(space: String, key: String) -> [String : Any] {
        let spaceKey = "\(space)_\(key)"
        let dic = (try? SettingManager.shared.setting(with: .make(userKeyLiteral: "ka_delivery_config"))) ?? [:]
        logger.info("settings is: \(dic)")
        guard let config = dic[spaceKey] as? [String: Any] else {
            logger.error("delivery_config not find \(spaceKey)'s value")
            return [:]
        }
        logger.info("config_type: \(config["config_type"])")
        guard let type = config["config_type"] as? Int else {
            logger.error("config_type not find")
            return [:]
        }
        var key = type == 1 ? "general" : AccountServiceAdapter.shared.currentTenant.tenantId
        logger.info("config_key: \(key)")
        guard var ret = config[key] as? [String: Any] else {
            logger.error("emm config not find \(key)'s value, config: \(config)")
            return [:]
        }
        logger.info("return dic: \(ret)")
        return ret
    }
}
