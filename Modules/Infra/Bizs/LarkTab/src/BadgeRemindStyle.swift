//
//  BadgeRemindStyle.swift
//  LarkTab
//
//  Created by Supeng on 2020/12/16.
//

import Foundation
public enum BadgeRemindStyle: Equatable {
    case strong
    case weak

    public var description: String {
        switch self {
        case .strong:
            return "strong"
        case .weak:
            return "weak"
        }
    }
}
