//
//  MeetingTagType.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/16.
//

import Foundation

enum MeetingTagType: Equatable {
    case none
    /// 外部
    case external
    /// 互通
    case cross
    /// 关联租户
    case partner(String)

    var text: String? {
        switch self {
        case .external:
            return I18n.View_G_ExternalLabel
        case .cross:
            return I18n.View_G_ConnectLabel
        case .partner(let relationTag):
            return relationTag
        case .none:
            return nil
        }
    }

    var hasTag: Bool {
        return text != nil
    }
}

extension MeetingTagType: CustomStringConvertible {
    var description: String {
        switch self {
        case .partner:
            return "partner"
        default:
            return text ?? ""
        }
    }
}
