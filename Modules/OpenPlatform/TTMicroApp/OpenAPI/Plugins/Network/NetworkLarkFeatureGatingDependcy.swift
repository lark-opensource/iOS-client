//
//  NetworkLarkFeatureGatingDependcy.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/10/26.
//

import LarkSetting

@objcMembers
public final class NetworkLarkFeatureGatingDependcy: NSObject {
    public static var v1SupportInBackground: Bool {
        FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.api.network_v1.support_in_background")
    }
    
    public static var addSocketCloseInfoEnable: Bool {
        FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.socket.close.info.opt")
    }
}
