//
//  OpenAPILocaitonCommonModel.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import CoreLocation
import LarkOpenAPIModel
import LarkCoreLocation
// MARK: - 坐标类型
/// 坐标类型
public enum OPLocationType: String, OpenAPIEnum {
    case wgs84 = "wgs84"
    case gcj02 = "gcj02"
}

// MARK: - 定位精度
/// 定位精度
public enum OpenAPILocationAccuracy: String, OpenAPIEnum {
    /// 当指定 high 时，期望精度值为100m
    case high
    /// 当指定 best 时期望精度值为20m
    case best
    ///best代表kCLLocationAccuracyBest, high代表kCLLocationAccuracyHundredMeters
    var coreLocationAccuracy: CLLocationAccuracy {
        switch self {
        case .best:
            return 20.0
        case .high:
            return kCLLocationAccuracyHundredMeters
        }
    }
}

/// CoreLocatio -> OpenAPILocationAccuracy
extension LocationFrameType {
    var opLocationType: OPLocationType {
        switch self {
        case .gcj02:
            return OPLocationType.gcj02
        case .wjs84:
            return OPLocationType.wgs84
        @unknown default:
            assertionFailure("locationSystem is not available")
            return OPLocationType.wgs84
        }
    }
}

// 一些关键常量
struct OpenAPILocationConstants {
    /// 经度范围  文档 https://open.feishu.cn/document/uYjL24iN/uQTOz4CN5MjL0kzM
    static let longitudeRange = -180.0...180.0
    /// 纬度范围
    static let latitudeRange = -90.0...90.0
    /// 缩放比例最小值
    static let scaleMin = 5
    /// 缩放比例最大值
    static let scaleMax = 18
    static let scaleRange = scaleMin...scaleMax
}
