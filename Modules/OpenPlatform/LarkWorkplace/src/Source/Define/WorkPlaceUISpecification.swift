//
//  WorkPlaceUISpecification.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/10/29.
//

import Foundation
import LarkUIKit

enum WPUIConst {
    enum AvatarSize {
        static let large: CGFloat = Display.pad ? 48.0 : 52.0
        static let middle: CGFloat = 48.0
        static let small: CGFloat = 32.0
        static let xs20: CGFloat = 20.0
    }

    enum AvatarRadius {
        static let large: CGFloat = Display.pad ? 12.0 : 14.0
        static let middle: CGFloat = 12.0
        static let small: CGFloat = 8.0
        static let xs6: CGFloat = 6.0
        static let xs5: CGFloat = 5.0
    }

    enum BorderW {
        // swiftlint:disable identifier_name
        static let px1: CGFloat = 1.0 / UIScreen.main.scale
        static let pt1: CGFloat = 1.0
        static let pt0_5: CGFloat = 0.5
        // swiftlint:enable identifier_name
    }

    static let hoverRadius: CGFloat = 6.0
}

/// 工作台通用头像尺寸：https://bytedance.feishu.cn/docs/doccnWiHQ0zbRPXxi739ZTxTQPb#ggt4Ya
/// 大号头像边长
let avatarSideL: CGFloat = 48.0
/// 大号头像圆角
let avatarCornerL: CGFloat = 8.0
/// 中号头像边长
let avatarSideM: CGFloat = 40.0
/// 中号头像圆角
let avatarCornerM: CGFloat = 6.0
/// 小号头像边长
let avatarSideS: CGFloat = 32.0
/// 小号头像圆角
let avatarCornerS: CGFloat = 6.0
/// 超小号头像边长
let avatarSideXS: CGFloat = 20.0
/// 超小号头像圆角
let avatarCornerXS: CGFloat = 4.0

/// 工作台通用键鼠特效值
/// hignlight-corner 高亮圆角值
let highLightCorner: CGFloat = 8.0
/// highLight-width-margin-text(double) 高亮文案宽度拓展
let highLightTextWidthMargin: CGFloat = 20.0
/// highLight-common-text-height 高亮普通文案高度
let highLightCommonTextHeight: CGFloat = 38.0
/// highLight-width-margin-icon(double) 高亮图标宽度拓展（需要适配icon尺寸）
let highLightIconWidthMargin: CGFloat = 24.0
/// highLight-height-margin-icon(double) 高亮图标高度拓展（需要适配icon尺寸）
let highLightIconHeightMargin: CGFloat = 16.0
/// highLight-common-Height-Icon 高亮图标的通用高度
let highLightIconCommonHeight: CGFloat = 44.0
/// highLight-common-width-Icon 高亮图标的通用宽度
let highLightIconCommonWidth: CGFloat = 36.0

/// 预览模式样式
/// 预览模式标题占位圆角
let previewTitleCorner: CGFloat = 2.0
