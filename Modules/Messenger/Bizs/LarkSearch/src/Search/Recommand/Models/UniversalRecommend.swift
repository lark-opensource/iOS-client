//
//  UniversalRecommend.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/24.
//

import Foundation
import LarkSearchCore
import RustPB
import LarkSDKInterface
import EEAtomic
import ServerPB

enum UniversalRecommend {
    enum IconStyle: Equatable {
        case rectangle, circle, noQuery
        static func == (lhs: UniversalRecommend.IconStyle, rhs: UniversalRecommend.IconStyle) -> Bool {
            switch (lhs, rhs) {
            case (.rectangle, .rectangle):
                return true
            case (.circle, .circle):
                return true
            case (.noQuery, .noQuery):
                return true
            default:
                return false
            }
        }
    }
}
