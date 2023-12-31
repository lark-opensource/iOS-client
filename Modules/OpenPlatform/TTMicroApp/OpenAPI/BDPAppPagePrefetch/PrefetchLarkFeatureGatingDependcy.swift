//
//  PrefetchLarkFeatureGatingDependcy.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/11/2.
//

import LarkSetting

@objcMembers
public final class PrefetchLarkFeatureGatingDependcy: NSObject {
    private static var kUseNewRequestAPI = "useNewRequestAPI"

    @RealTimeFeatureGating(key: "bdp_startpage_prefetch.enable")
    public static var prefetchEnable: Bool

    @RealTimeFeatureGating(key: "openplatform.api.network.prefetch_disable_remove_slash")
    public static var prefetchDisableRemoveSlash: Bool
    
    @RealTimeFeatureGating(key: "openplatform.prefetch.crash.fix.opt")
    public static var prefetchCrashOpt: Bool

    private static var prefetchRequestV2FG: Bool {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.api.request.prefetch.align")
    }

    public static func prefetchRequestV2(uniqueID: BDPUniqueID?) -> Bool {
        guard let uniqueID = uniqueID else {
            return false
        }
        let useNewRequestAPI = BDPJSRuntimeSettings.getNetworkAPISettings(with: uniqueID)[kUseNewRequestAPI] as? Bool
        return prefetchRequestV2FG && (useNewRequestAPI == true)
    }
}
