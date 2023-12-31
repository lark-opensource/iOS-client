//
//  LarkLocationModel.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/9.
//

import Foundation
import MapKit
import Contacts

public protocol LocationData {
    var name: String { get }        // 名称
    var address: String { get }     // 详细地址
    var location: CLLocationCoordinate2D { get }    // 对应的WGS-84坐标
    var rawLocation: CLLocationCoordinate2D { get } // 原始未转换数据
    var isInternal: Bool { get }
    var addressComponent: AddressComponent? { get }
}

public struct AddressComponent {
    public var country: String         // 国家
    public var province: String        // 省/直辖市
    public var city: String            // 市
    public var district: String        // 区
    public var township: String        // 乡镇街道
    public var neighborhood: String    // 社区
    public var building: String        // 建筑
    public var address: String         // 完整地址
    public var pois: [PoiItemInfo]?     // 兴趣点
    public var aois: [AoiItemInfo]?     // 兴趣区域
    public var streetNumberInfo: StreetNumberInfo?
}

public struct PoiItemInfo {
    public var poiId: String            // POI 的id，即其唯一标识
    public var title: String            // POI的名称
    public var typeCode: String         // 兴趣点类型编码
    public var typeDes: String          // POI 的类型描述
    public var latitude: Double         // 该点纬度
    public var longitude: Double        // 该点经度
    public var snippet: String          // POI的地址
    public var tel: String              // POI的电话号码
    public var distance: Int            // POI 距离中心点的距离
    public var parkingType: String      // POI的停车场类型
    public var businessArea: String     // POI的所在商圈
}

public struct AoiItemInfo {
    public var adCode: String           // AOI的行政区划代码
    public var aoiArea: CGFloat           // AOI覆盖区域面积，单位平方米
    public var latitude: Double         // AOI的中心点该点纬度
    public var longitude: Double        // AOI的中心点该点经度
    public var aioId: String            // AOI的id，即其唯一标识
    public var aoiName: String          // AOI的名称
}

public struct StreetNumberInfo {
    public var direction: String         // 门牌信息中的方向 ，指结果点相对地理坐标点的方向
    public var distance: Int             // 门牌信息中地理坐标点与结果点的垂直距离
    public var latitude: Double          // 门牌信息点纬度
    public var longitude: Double         // 门牌信息点经度
    public var number: String            // 门牌信息中的门牌号码
    public var street: String            // 门牌信息中的街道名称
}


extension CLPlacemark {
    var formattedAddress: String? {
        if #available(iOS 11.0, *) {
            guard let postalAddress = postalAddress else { return nil }
            return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
        } else {
            // Fallback on earlier versions
            return nil
        }
    }
}

public protocol UILocationData: LocationData {
    var isSelected: Bool { get set }
}

/// 苹果地理数据模型
/// Apple geographic data model
public struct MKMapItemModel: UILocationData {
    public var name: String
    public var address: String
    public var location: CLLocationCoordinate2D // 全部是WGS-84坐标，不用转换
    public var rawLocation: CLLocationCoordinate2D
    public var isInternal: Bool
    public var isSelected: Bool = false
    public var addressComponent: AddressComponent?
    init(mapItem: MKMapItem, system: CoordinateSystem) {
        let isInternal = mapItem.placemark.isoCountryCode == "CN"
        // let coordinate = isInternal ? CoordinateConverter.convertGCJ02ToWGS84(coordinate: mapItem.placemark.coordinate) : mapItem.placemark.coordinate
        // Note: 由于合规问题，这里不能再使用转化算法！之所以不删代码，是为了警示！原地址展示，已告知PM影响！
        let coordinate = mapItem.placemark.coordinate
        self.name = mapItem.name ?? ""
        self.address = mapItem.placemark.formattedAddress ?? ""
        self.location = coordinate
        self.rawLocation = mapItem.placemark.coordinate
        self.isInternal = isInternal
    }

    init(
        name: String? = "",
        addr: String? = "",
        location: CLLocationCoordinate2D,
        isInternal: Bool,
        isSelected: Bool = false,
        system: CoordinateSystem,
        addressComponent: AddressComponent? = nil) {
        self.name = name ?? ""
        self.address = addr ?? ""
        // let coordinate = isInternal ? CoordinateConverter.convertGCJ02ToWGS84(coordinate: location) : location
        // Note: 由于合规问题，这里不能再使用转化算法！之所以不删代码，是为了警示！原地址展示，已告知PM影响！
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
