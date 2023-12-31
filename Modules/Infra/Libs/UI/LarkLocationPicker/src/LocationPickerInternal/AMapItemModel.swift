//
//  AMapItemModel.swift
//  LarkLocationPicker
//
//  Created by 姚启灏 on 2020/5/18.
//

import Foundation
import AMapSearchKit
import MapKit

struct AMapItemModel: UILocationData {
    public var name: String
    public var address: String
    public var location: CLLocationCoordinate2D // 国内是GCJ-02坐标系，国外是WGS-84坐标系
    public var rawLocation: CLLocationCoordinate2D // 不做转换的坐标
    public var isInternal: Bool
    public var isSelected: Bool = false
    public var addressComponent: AddressComponent?

    init(poi: AMapPOI, system: CoordinateSystem) {
        let location = CLLocationCoordinate2D(
            latitude: CLLocationDegrees(poi.location.latitude),
            longitude: CLLocationDegrees(poi.location.longitude)
        )
        let isInternal = FeatureUtils.AMapDataAvailableForCoordinate(location)
        // Note: 由于合规问题，这里不能再使用转化算法！之所以不删代码，是为了警示！原地址展示，已告知PM影响！
        // let coordinate = isInternal ? CoordinateConverter.convertGCJ02ToWGS84(coordinate: location) : location
        self.rawLocation = location
        self.name = poi.name.isEmpty ? "" : poi.name
        self.address = poi.address.isEmpty ? "" : poi.address
        self.location = location
        self.isInternal = isInternal
    }

    init(tip: AMapTip, system: CoordinateSystem) {
        if tip.location == nil {
            self.name = tip.name.isEmpty ? "" : tip.name
            self.address = tip.address.isEmpty ? "" : tip.address
            self.location = CLLocationCoordinate2DMake(360.0, 360.0)
            self.rawLocation = CLLocationCoordinate2DMake(360.0, 360.0)
            self.isInternal = true
        } else {
            let location = CLLocationCoordinate2D(
                latitude: CLLocationDegrees(tip.location.latitude),
                longitude: CLLocationDegrees(tip.location.longitude)
            )
            let isInternal = FeatureUtils.AMapDataAvailableForCoordinate(location)
            // Note: 由于合规问题，这里不能再使用转化算法！之所以不删代码，是为了警示！原地址展示，已告知PM影响！
            // let coordinate = isInternal ? CoordinateConverter.convertGCJ02ToWGS84(coordinate: location) : location
            self.rawLocation = location
            self.name = tip.name.isEmpty ? "" : tip.name
            self.address = tip.address.isEmpty ? tip.district : tip.address
            self.location = location
            self.isInternal = isInternal
        }
    }

    init(name: String = "",
         addr: String = "",
         location: CLLocationCoordinate2D,
         isSelected: Bool = false,
         system: CoordinateSystem,
         addressComponent: AddressComponent? = nil) {
        let isInternal = FeatureUtils.AMapDataAvailableForCoordinate(location)
        // Note: 由于合规问题，这里不能再使用转化算法！之所以不删代码，是为了警示！原地址展示，已告知PM影响！
        // let coordinate = isInternal ? CoordinateConverter.convertGCJ02ToWGS84(coordinate: location) : location
        self.name = name
        self.address = addr
        self.rawLocation = location
        self.location = location
        self.isInternal = isInternal
        self.isSelected = isSelected
        self.addressComponent = addressComponent
    }

    // 仅传入主标题，不传入副标题及经纬度。
    init(name: String) {
        self.name = name
        self.address = BundleI18n.LarkLocationPicker.Lark_Chat_MapsSearchCustomLocation
        self.location = CLLocationCoordinate2DMake(360.0, 360.0)
        self.rawLocation = CLLocationCoordinate2DMake(360.0, 360.0)
        self.isInternal = true
    }
}
