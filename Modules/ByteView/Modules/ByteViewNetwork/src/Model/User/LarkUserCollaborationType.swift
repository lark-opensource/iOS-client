//
//  LarkUserCollaborationType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum LarkUserCollaborationType: Int, Hashable {

    /// 默认拥有协作权限
    case `default` // = 0

    /// 自己主动屏蔽了对方, 无法对他发起视频会议
    case blocked // = 1

    /// 单向联系人关系，且对方还未许可协作权限
    case requestNeeded // = 2

    ///  高管模式
    case executiveMode // = 3

    /// 对方已将你屏蔽, 无法对他发起视频会议
    case beBlocked // = 4
}

extension LarkUserCollaborationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return "default"
        case .blocked:
            return "blocked"
        case .requestNeeded:
            return "requestNeeded"
        case .executiveMode:
            return "executiveMode"
        case .beBlocked:
            return "beBlocked"
        }
    }
}
