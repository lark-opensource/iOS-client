//
//  OPLocaionOCBridge.swift
//  OPFoundation
//
//  Created by baojianjun on 2023/5/29.
//

import Foundation
import LarkLocationPicker

@objc public final class OPLocaionOCBridge: NSObject {
    
    /// 是否可以使用GCJ-02，
    @objc public static func canConvertToGCJ02() -> Bool {
        FeatureUtils.isAMap()
    }
    
    /**
     * 转换目标经纬度为GCJ02坐标系
     * @param location 需要转换的GPS坐标
     * @return 转换后的gps坐标
     */
    @objc public static func bdp_convertLocation(toGCJ02 location: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        FeatureUtils.convertWGS84ToGCJ02(coordinate: location)
    }
    
    @objc public static func convertGCJ02(toWGS84 location: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CoordinateConverter.convertGCJ02ToWGS84(coordinate: location)
    }
}




