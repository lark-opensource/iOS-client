import ECOInfra
import LarkSetting
import LKCommonsLogging

final public class LarkWebSettings {
    
    public static let shared = LarkWebSettings()
    
    public static let lkwEncryptLogEnabel: Bool = OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.web.lkw.log.url.encrypt") // user:global

    
    private let webSettingsKey = "web_settings"
    
    public var settings: [String: Any]? {
        guard let s = ECOConfig.service().getDictionaryValue(for: webSettingsKey) else {
            logger.error("get web_settings error, get nil from ECOConfig.service().getDictionaryValue(for: webSettingsKey)")
            return nil
        }
        return s
    }
    
    public var settingsModel: WebSettings? {
        guard let s = settings else {
            return nil
        }
        guard JSONSerialization.isValidJSONObject(s) else {
            logger.error("get settingsModel error, settings is not valid JSONObject")
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: s)
            return try JSONDecoder().decode(WebSettings.self, from: data)
        } catch {
            logger.error("get web_settings error", error: error)
            return nil
        }
    }
    
    private init() {}
}

extension LarkWebSettings {
    public var offlineSettings: WebOfflineSettings? {
        settingsModel?.offline
    }
}

public struct WebSettings: Codable {
    public let offline: WebOfflineSettings?
    public let downloads: WebDownloadsSettings?
}

public struct WebOfflineSettings: Codable {
    
    public let fullWindowInterceptAppIDs: [String]
    
    public let ajax_hook: AjaxHookSettings
}

public struct AjaxHookSettings: Codable {
    
    public let inject: AjaxHookInject
    
    public let iframe: AjaxHookIFrame
    
    public let net_framework: AjaxHookNetFramework?
}

public enum AjaxHookInject: String, Codable {
    
    case all
    
    case larkweb
    
    case larkweb_offline
    
    case none
}

public enum AjaxHookIFrame: String, Codable {
    
    case all
    
    case none
}

public enum AjaxHookNetFramework: String, Codable {
    
    case `default`
    
    case system
}

public struct WebDownloadsSettings: Codable {
    public let file_type_list: [String]?
    public let mime_file_type: [String: String]?
    public let inline_preview_type: [String]?
    public let filename_max_length: Int?
}
