//
//  BTStatisticEvent.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/8/31.
//

import Foundation

enum BTStatisticNormalPointType: String {
    case init_point // 初始点, 可不上报
    case point // 普通点，默认上报
    case temp_point // 临时点，不上报
    case temp_point_group // 消费所有的 temp_point, 会转换成 point 普通点
    case stage_start // 阶段开始
    case stage_end // 阶段结束
}

final class BTStatisticNormalPoint: Hashable {
    let name: String
    let type: BTStatisticNormalPointType
    let timestamp: Int
    let isUnique: Bool
    var extra: [String: Any] = [:]

    var isTempPoint: Bool {
        return type == .temp_point || type == .temp_point_group
    }

    init(
        name: String,
        type: BTStatisticNormalPointType = .point,
        timestamp: Int = Int(Date().timeIntervalSince1970 * 1000),
        extra: [String: Any]? = nil,
        isUnique: Bool = true
    ) {
        self.name = name
        self.type = type
        self.timestamp = timestamp
        self.isUnique = isUnique
        self.extra.merge(other: extra)
        if self.extra[BTStatisticConstant.time] == nil {
            // extra 中默认添加 time 字段，方便问题排查
            self.extra[BTStatisticConstant.time] = timestamp
        }
    }

    func add(extra: [String: Any]) {
        self.extra.merge(extra, uniquingKeysWith: { _, cKey in cKey })
    }

    func toJson() -> [String: Any] {
        return [String: Any]()
    }

    static func == (lhs: BTStatisticNormalPoint, rhs: BTStatisticNormalPoint) -> Bool {
        guard lhs.name == rhs.name else {
            return false
        }
        guard lhs.type == rhs.type else {
            return false
        }
        guard lhs.timestamp == rhs.timestamp else {
            return false
        }
        return true
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
