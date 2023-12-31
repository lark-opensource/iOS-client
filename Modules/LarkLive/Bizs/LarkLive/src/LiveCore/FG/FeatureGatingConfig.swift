//
//  FeatureGatingConfig.swift
//  LarkLive
//
//  Created by panzaofeng on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkFeatureGating

public final class FeatureGatingConfig {
    // 直播是否支持native
    public static var liveNativeEnabled: Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: "byteview_live_ios_native")
    }
    // 是否支持quic拉流
    public static var liveQuicEnabled: Bool {
        #if DEBUG
        return true
        #else
        LarkFeatureGating.shared.getFeatureBoolValue(for: "byteview.live.mobile.quic")
        #endif
    }
    
    // 是否支持quic内网拉流
    public static var liveQuicIntranetEnabled: Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: "byteview.live.mobile.quic-Intranet")
    }
    
    // 是否使用节点优选
    public static var liveNodeOptimizeEnabled: Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: "byteview_live_ios_native_node_optimize")
    }
}
