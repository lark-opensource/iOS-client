//
//  ErrorTracker.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/9/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

enum BizErrorKey: String {
    case invalidVoIPPush = "invalid_voip_push"
    case missingFeatureConfig = "missing_feature_config"
    case gridCellCount = "grid_cell_count"
    case gridReloadTimeout = "grid_reload_timeout"
}

class BizErrorTracker {
    static func trackBizError(key: BizErrorKey, _ message: String) {
        VCTracker.post(name: .vc_biz_error, params: ["error": key.rawValue, "msg": message], platforms: [.slardar])
    }
}
