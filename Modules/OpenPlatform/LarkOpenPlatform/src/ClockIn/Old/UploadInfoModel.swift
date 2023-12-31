//
//  ArriveLocationModel.swift
//  Action
//
//  Created by tujinqiu on 2019/8/9.
//

import Foundation
import CoreLocation

// MARK: - config类型

enum LocationType: String, Codable {
    case circle // 圆
    case polygon // 多边形，目前不支持
}

struct Geofence: Codable {
    let type: LocationType
    let center: CoordInfo?
    let radius: CLLocationDistance?
    let coords: [CoordInfo]? // for polygon
}

struct Location: Codable {
    let status: Bool
    let geofences: [Geofence]?

    private enum CodingKeys: String, CodingKey {
        case status, geofences
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let status = try? container.decode(Int.self, forKey: .status) {
                self.status = status == 1
            } else {
                self.status = false
            }
            self.geofences = try? container.decode([Geofence].self, forKey: .geofences)
        } else {
            self.status = false
            self.geofences = nil
        }
    }
}

struct Wifi: Codable {
    let status: Bool

    private enum CodingKeys: String, CodingKey {
        case status
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let status = try? container.decode(Int.self, forKey: .status) {
                self.status = status == 1
            } else {
                self.status = false
            }
        } else {
            self.status = false
        }
    }
}

struct UploadInfoConfig: Codable {
    let location: Location?
    let wifi: Wifi?
    //  https://bytedance.feishu.cn/docs/doccnSCfu0FBMtPCggcEauj7Vng# 参考文档，埋点使用
    let rule_snapshot_id: String?
}

// MARK: - 上传类型

struct CoordInfo: Codable {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var accuracy: CLLocationAccuracy

    init(clCoord: CLLocationCoordinate2D, acc: CLLocationAccuracy) {
        self.latitude = clCoord.latitude
        self.longitude = clCoord.longitude
        accuracy = acc
    }

    func toCLCoord() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// 使用WGS1984坐标
struct LocationInfo: Codable {
    var coord: CoordInfo
}

struct WIFIInfo: Codable {
    var SSID: String?
    var BSSID: String?
    var lastSSID: String?
    var lastBSSID: String?

    func isEmpty() -> Bool {
        return (SSID == nil) && (BSSID == nil) && (lastSSID == nil) && (lastBSSID == nil)
    }
    var hasWifi: Bool {
        if isNotEmpty(SSID) || isNotEmpty(BSSID) {
            return true
        }
        return false
    }
    var hasLastWifi: Bool {
        if isNotEmpty(lastSSID) || isNotEmpty(lastBSSID) {
            return true
        }
        return false
    }
    func isNotEmpty(_ str: String?) -> Bool {
        guard let str = str else {
            return false
        }
        return !str.isEmpty
    }
}
