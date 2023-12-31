//
//  ClockInAPI.swift
//  LarkOpenPlatform
//
//  Created by zhaojingxin on 2022/3/4.
//

import Foundation
import LarkSetting
import LarkContainer

// MARK: - Model

/// 考勤打卡类型
enum OPClockInEnvType: Int {
    case GPS = 1
    case wifi = 2
    case IP = 3
    case machine = 4
    case bluetooth = 5
}

struct OPClockInGPS: Codable {

    enum CodingKeys: String, CodingKey {
        case id, longitude, latitude, name, range, subsidy, accuracy
        case mapType = "gps_map_type"
    }

    enum MapType: Int, Codable {
        case WGS84 = 1
        case GCJ02 = 2
    }

    let longitude: Double
    let latitude: Double
    let mapType: MapType
    let subsidy: Double?
    let accuracy: Double?

    let id: Int64?
    let name: String?
    let range: Int64?
}

struct OPColockInWifi: Codable {

    enum CodingKeys: String, CodingKey {
        case id, name
        case macAddress = "mac_address"
    }

    let id: Int64?
    let name: String
    let macAddress: String

    init(id: Int64?, name: String, macAddress: String) {
        self.id = id
        self.name = name
        let macComponents = macAddress.split(separator: ":")
        self.macAddress = macComponents.map { $0.count == 1 ? "0\($0)" : $0 }.joined(separator: ":")
    }
}

struct OPClockInRiskInfo: Codable {
    
    enum CodingKeys: String, CodingKey {
        case isCracked = "is_cracked"
        case isEmulator = "is_emulator"
        case isDebug = "is_debug"
        case deviceID = "device_id"
        case deviceOS = "device_os"
        case deviceModel = "device_model"
        case isNewVersion = "is_new_version"
    }

    let isCracked: Bool
    let isEmulator: Bool
    let isDebug: Bool
    let deviceID: String
    let deviceOS: Int = 1
    let deviceModel: String
    let isNewVersion: Bool = true
    
    init(isCracked: Bool, isEmulator: Bool, isDebug: Bool, deviceID: String, deviceModel: String) {
        self.isCracked = isCracked
        self.isEmulator = isEmulator
        self.isDebug = isDebug
        self.deviceID = deviceID
        self.deviceModel = deviceModel
    }
}

struct OPSpeedColckInReq {
    var tenantID: String
    var userID: String
    var gps: OPClockInGPS?
    var wifiMacAdress: String?
    var scanWifiList: [OPColockInWifi]?
    var traceID: String
    var riskInfo: OPClockInRiskInfo?
}

// MARK: - API
extension OpenPlatformAPI {

    static func speedClockInGetConfigAPI(tenantID: String, userID: String, traceID: String, beginTime: TimeInterval, resolver: UserResolver) -> OpenPlatformAPI {
        let clockInConfigAPI = OpenPlatformAPI(path: .getSpeedClockInConfig, resolver: resolver)
            .useSession()
            .setScope(.clockIn)
            .appendParam(key: .mw_tenant_id, value: tenantID)
            .appendParam(key: .mw_user_id, value: userID)
            .appendParam(key: .device_trace_id, value: traceID)
        
        if resolver.fg.dynamicFeatureGatingValue(with: "openplatform.speed.clockin.request.opt") {
            _ = clockInConfigAPI.appendParam(key: .request_timestamp, value: beginTime)
        }
        return clockInConfigAPI
    }

    static func speedClockInAPI(req: OPSpeedColckInReq, resolver: UserResolver) -> OpenPlatformAPI {
        let api = OpenPlatformAPI(path: .speedClockIn, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .setScope(.clockIn)
            .appendParam(key: .mw_tenant_id, value: req.tenantID)
            .appendParam(key: .mw_user_id, value: req.userID)
            .appendParam(key: .device_trace_id, value: req.traceID)
        if let gps = req.gps, let gpsData = try? JSONEncoder().encode(gps), let gpsJSON = try? JSONSerialization.jsonObject(with: gpsData, options: .allowFragments) {
            _ = api.appendParam(key: .gps, value: gpsJSON)
        }
        if let wifi = req.wifiMacAdress {
            _ = api.appendParam(key: .wifi_mac_address, value: wifi)
        }
        if let riskInfo = req.riskInfo, let riskInfoData = try? JSONEncoder().encode(riskInfo), let riskInfoJSON = try? JSONSerialization.jsonObject(with: riskInfoData, options: .allowFragments) {
            _ = api.appendParam(key: .risk_info, value: riskInfoJSON)
        }

        return api
    }
}

// MARK: - Response

class OPSpeedClockInConfigResponse: APIResponse {
    var opended: Bool {
        return json["data"]["is_opened"].bool ?? false
    }
    
    var needClockin: Bool {
        return json["data"]["is_need_speed_clock_in"].bool ?? true
    }

    var refactorEnabled: Bool {
        return json["data"]["is_new_version"].bool ?? false
    }

    var beginTime: Int64 {
        return json["data"]["begin_time"].int64 ?? 0
    }

    var endTime: Int64 {
        return json["data"]["end_time"].int64 ?? 0
    }

    var supportedEnvTypeList: [OPClockInEnvType] {
        if let envList = json["data"]["environment_type_list"].array {
            return envList.compactMap { OPClockInEnvType(rawValue: $0.int ?? 0) }
        }

        return []
    }
    
    var needRiskInfo: Bool {
        return json["data"]["need_risk_info"].bool ?? false
    }
}


class OPSpeedClockInResponse: APIResponse {
    var inValidArea: Bool {
        return json["data"]["is_in_env"].bool ?? false
    }

    var colockInSucceed: Bool {
        return json["data"]["is_clock_in_succeed"].bool ?? false
    }
    
    var clockInFailCode: String? {
        return json["data"]["clock_in_fail_code_name"].stringValue
    }

    var nextTimeInterval4SpeedClockIn: Int32? {
        return json["data"]["top_speed_retry_time_duration"].int32
    }
}
