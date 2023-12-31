//
//  DocsInfo+Watermark.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/4/4.
//

import SKInfra

extension DocsInfo {
    private var watermarkKey: WatermarkKey {
        return WatermarkKey(objToken: objToken, type: type.rawValue)
    }

    public var shouldShowWatermark: Bool {
        // 在 VCFollow 下，不显示水印，由 VC 端处理。
        if self.isInVideoConference ?? false {
            return false
        }
        // 开了全局水印，则ccm水印不展示
        if OpenAPI.globalWatermarkEnabled {
            return false
        }
        return WatermarkManager.shared.shouldShowWatermarkFor(watermarkKey)
    }

    public var shouldShowWatermarkFromServer: Bool {
        return WatermarkManager.shared.shouldShowWatermarkFor(watermarkKey)
    }

    public func requestWatermarkInfo() {
        WatermarkManager.shared.requestWatermarkInfo(watermarkKey)
    }

    // base@docx 场景下，需要查询 base blokc 的水印信息，而不是 docx 的
    public func shouldShowWatermark(watermarkKey: WatermarkKey) -> Bool {
        // 在 VCFollow 下，不显示水印，由 VC 端处理。
        if self.isInVideoConference ?? false {
            return false
        }
        // 开了全局水印，则ccm水印不展示
        if OpenAPI.globalWatermarkEnabled {
            return false
        }
        return WatermarkManager.shared.shouldShowWatermarkFor(watermarkKey)
    }
}
