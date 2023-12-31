//
//  FactorModel.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation

public struct SubjectFactorModel: Codable, Hashable {
    let commonFactorsMap: [String: FactorVal]?
    let groupIDList: [Int64]?
    let userDeptIDPaths: [[Int64]]?
    let userDeptIdsWithParent: [Int64]?

    enum CodingKeys: String, CodingKey {
        case commonFactorsMap
        case groupIDList = "USER_GROUP_IDS"
        case userDeptIDPaths = "USER_DEPT_ID_PATHS"
        case userDeptIdsWithParent = "USER_DEPT_IDS_WITH_PARENT"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.commonFactorsMap = try container.decodeIfPresent([String: FactorVal].self, forKey: .commonFactorsMap)
        self.groupIDList = try container.decodeIfPresent([String].self, forKey: .groupIDList)?.compactMap { Int64($0) }
        self.userDeptIDPaths = try container.decodeIfPresent([[String]].self, forKey: .userDeptIDPaths)?.map { $0.compactMap { Int64($0) } }
        self.userDeptIdsWithParent = try container.decodeIfPresent([String].self, forKey: .userDeptIdsWithParent)?.compactMap { Int64($0) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commonFactorsMap, forKey: .commonFactorsMap)
        try container.encode(groupIDList?.map { String($0) }, forKey: .groupIDList)
        try container.encode(userDeptIDPaths?.map { $0.map { String($0) } }, forKey: .userDeptIDPaths)
        try container.encode(userDeptIdsWithParent?.map { String($0) }, forKey: .userDeptIdsWithParent)
    }

    public func hash(into hasher: inout Hasher) {
        let sortedFactorsdKeys = (commonFactorsMap ?? [:]).keys.sorted()
        let sortedGroupIDList = (groupIDList?.compactMap { String($0) } ?? []).sorted()
        // [[Int64]] 转换成 [[String]], 并将子数组做合并之后排序
        let sortedUserDeptIDPaths = (userDeptIDPaths?.compactMap { $0.compactMap { String($0) } } ?? [[]]).sorted {
            $0.joined() < $1.joined()
        }
        let sortedUserDeptIdsWithParent = (userDeptIdsWithParent?.compactMap { String($0) } ?? []).sorted()
        
        for key in sortedFactorsdKeys {
            if let value = commonFactorsMap?[key] {
                hasher.combine(key)
                hasher.combine(value)
            }
        }
        
        for groupID in sortedGroupIDList {
            hasher.combine(groupID)
        }
        
        for userDeptIDPath in sortedUserDeptIDPaths {
            hasher.combine(userDeptIDPath.joined())
        }
        
        for userDeptId in sortedUserDeptIdsWithParent {
            hasher.combine(userDeptId)
        }
    }
}

public struct FactorVal: Codable, Hashable {
    let val: String
    let type: FactorType
}

public enum FactorType: String, Codable {
    case UNKNOWN
    case STRING
    case INT
    case FLOAT
    case BOOL

    public init(from decoder: Decoder) throws {
        self = try FactorType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .UNKNOWN
    }
}

enum FactorKey: String {
    case userID = "USER_ID"
    case groupID = "USER_GROUP_IDS"
    case deptIDPaths = "USER_DEPT_ID_PATHS"
    case deptID = "USER_DEPT_IDS_WITH_PARENT"
    case sourceIP = "SOURCE_IP"
    case sourceIPV4 = "SOURCE_IP_V4"
}

public struct IPFactorModel: Codable, Equatable {
    let sourceIP: String
    let sourceIPV4: Int64
    
    enum CodingKeys: String, CodingKey {
        case sourceIP = "SOURCE_IP"
        case sourceIPV4 = "SOURCE_IP_V4"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceIP = try container.decode(String.self, forKey: .sourceIP)
        let sourceIPV4String = try container.decode(String.self, forKey: .sourceIPV4)
        guard let sourceIPV4 = Int64(sourceIPV4String) else {
            throw DecodingError.dataCorruptedError(forKey: .sourceIPV4, in: container, debugDescription: "Invalid sourceIPV4 value")
        }
        self.sourceIPV4 = sourceIPV4
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sourceIP, forKey: .sourceIP)
        try container.encode(String(sourceIPV4), forKey: .sourceIPV4)
    }
}

extension FactorVal {
    func valueConvert() throws -> Any {
        switch type {
        case .BOOL:
            switch val.lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: throw CustomStringError("Can not convert value: \(val) to \(type.rawValue) type.")
            }
        case .FLOAT:
            guard let floatValue = Float(val) else {
                throw CustomStringError("Can not convert value: \(val) to \(type.rawValue) type.")
            }
            return floatValue
        case .INT:
            guard let intValue = Int(val) else {
                throw CustomStringError("Can not convert value: \(val) to \(type.rawValue) type.")
            }
            return intValue
        case .STRING: return val
        case .UNKNOWN: throw CustomStringError("Can not convert value: \(val) to \(type.rawValue) type.")
        }
    }
}
