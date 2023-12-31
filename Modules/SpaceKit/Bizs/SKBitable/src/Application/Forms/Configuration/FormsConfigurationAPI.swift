import Foundation
import LarkAccountInterface
import LarkContainer
import LarkOpenAPIModel
import LarkSetting
import LKCommonsLogging
import SKFoundation
import Swinject

// MARK: - FormConfiguration Model
final class FormsConfigurationResult: OpenAPIBaseResult {
    
    static let logger = Logger.formsSDKLog(FormsConfigurationResult.self, category: "FormsConfigurationResult")
    
    override init() {
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        let config = FormsConfiguration.formsAbilityConfig()
        Self.logger.info("biz.bitable.formConfiguration result: \(config)")
        return config
    }
}

final class FormsConfiguration {
    
    static let logger = Logger.formsSDKLog(FormsOpenAbility.self, category: "FormsOpenAbility")
    
    class func checkHostFormsValid(url: URL?) -> Bool {
        guard let host = url?.host else {
            Self.logger.error("host is nil")
            return false
        }
        var settingsArray: [String]?
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let formDomainRegs = settings["form_domain_regs"] {
                if let array = formDomainRegs as? [String] {
                    settingsArray = array
                } else {
                    Self.logger.error("form_domain_regs is not string array")
                }
            } else {
                Self.logger.error("settings has no form_domain_regs")
            }
        } catch {
            Self.logger.error("bitable_config get settings error", error: error)
            return false
        }
        
        guard let arr = settingsArray else {
            Self.logger.error("settingsArray is nil")
            return false
        }
        if arr.contains(where: { reg_doamin in
            do {
                let re = try NSRegularExpression(pattern: reg_doamin)
                let result = re.matches(host)
                return !result.isEmpty
            } catch {
                Self.logger.error("form_domain_regs check host fail, host match reg fail")
                return false
            }
        }) {
            Self.logger.info("form_domain_regs check host pass")
            return true
        } else {
            Self.logger.info("form_domain_regs check host not pass")
            return false
        }
    }
    
    class func checkPathFormsValid(url: URL?) -> Bool {
        guard let path = url?.path else {
            Self.logger.error("path is nil")
            return false
        }
        var settingsArray: [String]?
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let formsPathRegs = settings["forms_router_path_regs"] {
                if let array = formsPathRegs as? [String] {
                    settingsArray = array
                } else {
                    Self.logger.error("forms_router_path_regs is not string array")
                }
            } else {
                Self.logger.error("settings has no forms_router_path_regs")
            }
        } catch {
            Self.logger.error("bitable_config get settings error", error: error)
            return false
        }
        
        guard let arr = settingsArray else {
            Self.logger.error("settingsArray is nil")
            return false
        }
        if arr.contains(where: { reg_doamin in
            do {
                let re = try NSRegularExpression(pattern: reg_doamin)
                let result = re.matches(path)
                return !result.isEmpty
            } catch {
                Self.logger.error("forms_router_path_regs check path fail, path match reg fail")
                return false
            }
        }) {
            Self.logger.info("forms_router_path_regs check host pass")
            return true
        } else {
            Self.logger.info("forms_router_path_regs check host not pass")
            return false
        }
    }
    
    class func formsAbilityConfig() -> [AnyHashable: Any] {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let abilityConfig = settings["ability_config"] {
                if let dictionary = abilityConfig as? [AnyHashable: Any] {
                    Self.logger.info("get bitable form ability config success, \(dictionary)")
                    return dictionary
                } else {
                    Self.logger.error("ability_config is not dictionary")
                    return [AnyHashable: Any]()
                }
            } else {
                Self.logger.error("settings has no ability_config")
                return [AnyHashable: Any]()
            }
        } catch {
            Self.logger.error("bitable_config get settings error", error: error)
            return [AnyHashable: Any]()
        }
    }
    
    class func isFormsSharePath(url: URL) -> Bool {
        let path = url.path
        var reg_path: String?
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let formsPathReg = settings["forms_path_reg"] {
                if let str = formsPathReg as? String {
                    reg_path = str
                } else {
                    Self.logger.error("forms_path_reg is not string")
                }
            } else {
                Self.logger.error("settings has no forms_path_reg")
            }
        } catch {
            Self.logger.error("bitable_config get settings error", error: error)
            return false
        }
        guard let reg_path = reg_path else {
            Self.logger.error("reg_doamin is nil")
            return false
        }
        do {
            let re = try NSRegularExpression(pattern: reg_path)
            let result = re.matches(path)
            return !result.isEmpty
        } catch {
            Self.logger.error("forms_path_reg check path fail, path match reg fail")
            return false
        }
    }
    
    class func formsPreloadURL(userResolver: UserResolver) -> URL? {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let formsPreloadUrl = settings["forms_preload_url"] {
                if let str = formsPreloadUrl as? String {
                    if var component = URLComponents(string: str) {
                        do {
                            let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
                            if let mainDomain = DomainSettingManager.shared.currentSetting[.docsMainDomain]?.first, let tenantDomain = passportUserService.userTenant.tenantDomain {
                                if !mainDomain.isEmpty, !tenantDomain.isEmpty {
                                    component.host = tenantDomain + "." + mainDomain
                                    return component.url
                                } else {
                                    Self.logger.error("tenantDomain or docsMainDomain is empty")
                                    return nil
                                }
                            } else {
                                Self.logger.error("get tenantDomain or docsMainDomain error")
                                return nil
                            }
                        } catch {
                            Self.logger.error("resolve PassportUserService error", error: error)
                            return nil
                        }
                    } else {
                        Self.logger.error("URLComponents(string: str) error")
                        return nil
                    }
                } else {
                    Self.logger.error("forms_preload_url is not string")
                    return nil
                }
            } else {
                Self.logger.error("settings has no forms_preload_url")
                return nil
            }
        } catch {
            Self.logger.error("bitable_config get settings error", error: error)
            return nil
        }
    }
    
    class func preloadFormsBrowserMaxTerminateCount() -> Int {
        let defaultMaxTerminateCount = 5
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let maxTerminateCount = settings["max_terminate_count"] {
                if let number = maxTerminateCount as? Int {
                    Self.logger.info("get max_terminate_count success, \(number)")
                    return number
                } else {
                    Self.logger.error("max_terminate_count is not Int")
                    return defaultMaxTerminateCount
                }
            } else {
                Self.logger.error("settings has no max_terminate_count")
                return defaultMaxTerminateCount
            }
        } catch {
            Self.logger.error("bitable_config get settings error", error: error)
            return defaultMaxTerminateCount
        }
    }
    
}
