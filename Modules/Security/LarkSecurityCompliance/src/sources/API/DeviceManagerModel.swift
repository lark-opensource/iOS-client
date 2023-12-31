//
//  DeviceManagerModel.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/13.
//

import Foundation

enum Ownership: Int, Decodable {
    case unknown = 0
    case company
    case personal

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        self = Ownership(rawValue: value) ?? .unknown
    }
}

enum DeviceApplyStatus: Int, Decodable {
    case unknown = 0
    case noApply
    case processing
    case pass
    case reject

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        self = DeviceApplyStatus(rawValue: value) ?? .unknown
    }
}

struct BaseResponse<T: Decodable>: Decodable {
    let data: T
    let code: Int
    let msg: String
}

struct PingResp: Decodable {
    let pong: String?
}

struct GetDeviceApplySwitchResp: Decodable {
    let isOpen: Bool

    enum CodingKeys: String, CodingKey {
        case isOpen = "switch"
    }
}

struct GetDeviceApplyStatusResp: Decodable {
    let applyStatus: DeviceApplyStatus

    enum CodingKeys: String, CodingKey {
        case applyStatus = "apply_status"
    }
}

struct BindDeviceResp: Decodable {
    let success: Bool
}

struct CheckDeviceResp: Decodable {
    let exist: Bool
}

struct BindDeviceWebResp: Decodable {
    let success: Bool
}

struct ApplyDeviceResp: Decodable {
    let applyStatus: DeviceApplyStatus
    let ownership: Ownership?

    enum CodingKeys: String, CodingKey {
        case applyStatus = "apply_status"
        case ownership
    }
}

final class GetDeviceInfoResp: NSObject, Decodable {
    let exist: Bool
    let applyStatus: DeviceApplyStatus
    let ownership: Ownership
    let rejectReason: String?

    init(exist: Bool, applyStatus: DeviceApplyStatus, ownership: Ownership, rejectReason: String?) {
        self.exist = exist
        self.applyStatus = applyStatus
        self.ownership = ownership
        self.rejectReason = rejectReason
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case applyStatus = "apply_status"
        case exist
        case ownership
        case rejectReason = "reject_reason"
    }
}
