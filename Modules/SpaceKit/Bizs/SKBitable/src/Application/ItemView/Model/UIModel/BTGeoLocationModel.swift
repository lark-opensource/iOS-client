//
//  BTLocationModel.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/5/1.
//  


import Foundation
import HandyJSON

struct BTGeoLocationModel: HandyJSON, Equatable {
    typealias Location = (longitude: Double, latitude: Double)
    var location: Location?
    var pname: String? // 广东省
    var cityname: String? // 深圳市
    var adname: String? // 南山区
    var name: String? // 深圳湾创新科技中心
    var address: String?// 科苑南路与高新南九道交叉口东南约160米
    var fullAddress: String?// 广东省深圳市南山区科苑南路与高新南九道交叉口东南约160米
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.location <-- TransformOf<Location, String>(fromJSON: { (rawString) -> Location? in
                if let values = rawString?.split(separator: ",").map(Double.init),
                   values.count == 2, let longitude = values[0], let latitude = values[1] {
                    return (longitude, latitude)
                }
                return nil
            }, toJSON: { (location) -> String? in
                if let location = location {
                    return "\(location.longitude),\(location.latitude)"
                }
                return nil
            })
    }
    static func == (lhs: BTGeoLocationModel, rhs: BTGeoLocationModel) -> Bool {
        return lhs.location?.longitude == rhs.location?.longitude
        && lhs.location?.latitude == rhs.location?.latitude
        && lhs.name == rhs.name
        && lhs.address == rhs.address
    }
    var isEmpty: Bool {
        return location == nil
    }
    var isLocationValid: Bool {
        guard let location = location else {
            return false
        }
        return location.latitude >= -90.0 &&
        location.latitude <= 90.0 &&
        location.longitude >= -180.0 &&
        location.longitude <= 180.0
    }
}
