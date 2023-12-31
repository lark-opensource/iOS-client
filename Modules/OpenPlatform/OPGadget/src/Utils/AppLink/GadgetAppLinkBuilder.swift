//
//  GadgetAppLinkswift
//  OPGadget
//
//  Created by yinyuan on 2021/3/16.
//

import Foundation
import LarkFeatureGating
import OPSDK
import LarkSetting
import OPFoundation
import LKCommonsLogging

/// 新版本小程序 AppLinkBuilder，从 EMAAppLinkModel 迁移
@objcMembers public final class GadgetAppLinkBuilder: NSObject {
    
    private let log = Logger.log(GadgetAppLinkBuilder.self, category: "GadgetAppLinkBuilder")

    private var urlComponents: URLComponents = URLComponents()
    
    public required init(uniqueID: OPAppUniqueID) {
        super.init()
        
        urlComponents.scheme = "https"
        
        // 服务端为ka配置了不同的applink的domain，但实际不支持自定义domain的applink, 具体现象可以参见ka的这个bughttps://jira.bytedance.com/browse/SUITE-667387
        // 此处添加一个fg，使用线上applink配置domain的，走自定义applink的domain，
        // 否则参照Android和pc的做法，写死分享的applink domain
        // fg是为了方便后续按需从服务端配置上进行修改后，支持自定义applink domain，目前fg为关，需要自定义的时候打开即可，https://fg.bytedance.net/?ticket=ST-1566530582-ruFPGrnGFluKUM5fPQAM7XNO3xaEagIU#/key/detail/microapp.applink.custom.domain
        let featureGatingKeyMicroAppAppLinkCustomDomain = "microapp.applink.custom.domain";
        if LarkFeatureGating.shared.getFeatureBoolValue(for: featureGatingKeyMicroAppAppLinkCustomDomain) {
            urlComponents.host = OPApplicationService.current.domainConfig.appLinkDomain
        } else {
            if let domain = DomainSettingManager.shared.currentSetting["applink"]  {
                // 有打包兜底
                if let settingHost = domain.first {
                    urlComponents.host = settingHost
                }
            } else {
                // 理论上不会出现这个情况，这里是纯语法上的兜底写法，留下日志即可
                log.error("invald applink domain settings.")
                assert(false, "invald applink domain settings.")
            }
            
        }

        urlComponents.path = "/client/mini_program/open"
        
        _ = setUniqueID(uniqueID: uniqueID)
    }
    
    /// 该方法暂未验证稳定性，暂不对外提供，如果需要对外提供，请先验证稳定性
    private func addQuery(paramName: String, value: String?) -> GadgetAppLinkBuilder {
        var queryItems = urlComponents.queryItems ?? []
        queryItems.removeAll(where: { (item) -> Bool in
            item.name == paramName
        })
        queryItems.append(URLQueryItem(name: paramName, value: value))
        urlComponents.queryItems = queryItems
        return self
    }
    
    public func buildURL() -> URL? {
        return urlComponents.url
    }
}

extension GadgetAppLinkBuilder {
    
    private func setUniqueID(uniqueID: OPAppUniqueID) -> GadgetAppLinkBuilder {
        return addQuery(paramName: "appId", value: uniqueID.appID)
    }
}
