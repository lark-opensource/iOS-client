//
//  CollaboratorType.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/29.
//

import Foundation

public enum CollaboratorType: Int, Codable, ModelEnum {
    public static var fallbackValue: CollaboratorType = .unknown

    case user = 0
    case group = 1                                  // Lark群
    case tenant = 2                                  // Lark群
    case common = 3                                 // 公共
    case mobile = 4                                 // 手机号搜索出来的
    case unknown = -999

    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .user
        case 1:
            self = .group
        case 2:
            self = .tenant
        case 3:
            self = .common
        case 4:
            self = .mobile
        default:
            return nil
        }
    }
}
