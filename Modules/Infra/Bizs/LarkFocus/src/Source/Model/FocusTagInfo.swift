//
//  FocusTagInfo.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2022/1/4.
//

import UIKit
import Foundation
import RustPB

///
/// ```
/// public struct FocusTagInfo {
///      var isShowTag: Bool          // 个人状态是否展示为 Tag 形式
///      var tagColor: FocusTagColor  // Tag 颜色样式配置
/// }
/// ```
public typealias FocusTagInfo = Basic_V1_TagInfo

///
/// ```
/// public enum FocusTagColor {
///     case blue       = 0
///     case gray       = 1
///     case indigo     = 2
///     case wathet     = 3
///     case green      = 4
///     case turquoise  = 5
///     case yellow     = 6
///     case lime       = 7
///     case red        = 8
///     case orange     = 9
///     case purple     = 10
///     case violet     = 11
///     case carmine    = 12
/// }
/// ```
public typealias FocusTagColor = Basic_V1_TagColor

// 个人状态标签颜色配置写死在客户端
extension FocusTagColor {

    /// 个人状态标签背景颜色
    var backgroundColor: UIColor {
        switch self {
        case .blue:         return UIColor.ud.udtokenTagBgBlue
        case .gray:         return UIColor.ud.udtokenTagNeutralBgNormal
        case .indigo:       return UIColor.ud.udtokenTagBgIndigo
        case .wathet:       return UIColor.ud.udtokenTagBgWathet
        case .green:        return UIColor.ud.udtokenTagBgGreen
        case .turquoise:    return UIColor.ud.udtokenTagBgTurquoise
        case .yellow:       return UIColor.ud.udtokenTagBgYellow
        case .lime:         return UIColor.ud.udtokenTagBgLime
        case .red:          return UIColor.ud.udtokenTagBgRed
        case .orange:       return UIColor.ud.udtokenTagBgOrange
        case .purple:       return UIColor.ud.udtokenTagBgPurple
        case .violet:       return UIColor.ud.udtokenTagBgViolet
        case .carmine:      return UIColor.ud.udtokenTagBgCarmine
        @unknown default:   return UIColor.ud.udtokenTagBgBlue
        }
    }

    /// 个人状态标签文字颜色
    var textColor: UIColor {
        switch self {
        case .blue:         return UIColor.ud.udtokenTagTextSBlue
        case .gray:         return UIColor.ud.udtokenTagNeutralTextNormal
        case .indigo:       return UIColor.ud.udtokenTagTextSIndigo
        case .wathet:       return UIColor.ud.udtokenTagTextSWathet
        case .green:        return UIColor.ud.udtokenTagTextSGreen
        case .turquoise:    return UIColor.ud.udtokenTagTextSTurquoise
        case .yellow:       return UIColor.ud.udtokenTagTextSYellow
        case .lime:         return UIColor.ud.udtokenTagTextSLime
        case .red:          return UIColor.ud.udtokenTagTextSRed
        case .orange:       return UIColor.ud.udtokenTagTextSOrange
        case .purple:       return UIColor.ud.udtokenTagTextSPurple
        case .violet:       return UIColor.ud.udtokenTagTextSViolet
        case .carmine:      return UIColor.ud.udtokenTagTextSCarmine
        @unknown default:   return UIColor.ud.udtokenTagTextSBlue
        }
    }
}
