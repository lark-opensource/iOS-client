//
//  PushCardConfiguration.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import UIKit
import Foundation
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor

// ignore magic number checking for UI
// disable-lint: magic number

enum Cons {
    /// 容器折叠时距离顶部距离
    static var cardStackedTopMargin: CGFloat { Helper.safeAreaHeight + Cons.cardDefaultTopMargin }
    /// 容器距离 safeArea 的距离
    static var cardDefaultTopMargin: CGFloat { 6 }
    /// 容器内边距
    static var cardContainerPadding: CGFloat { 12 }
    /// 边框宽度
    static var borderWidth: CGFloat { 1 }
    /// 头部总高度
    static var cardHeaderTotalHeight: CGFloat { Cons.cardStackedTopMargin + Cons.cardHeaderHeight }
    /// 尾部总高度
    static var cardBottomTotalHeight: CGFloat { Cons.cardDefaultTopMargin + Cons.cardHeaderBtnHeight }
    /// 头部高度
    static var cardHeaderHeight: CGFloat { 48 }
    /// 头部圆形按钮上外边距
    static var cardHeaderBtnTopMargin: CGFloat { 7 }
    /// 头部圆形按钮下外边距
    static var cardHeaderBtnBottomMargin: CGFloat { 8 }
    /// 头部胶囊按钮宽度
    static var cardHeaderBtnWidth: CGFloat { 82 }
    /// 头部按钮高度
    static var cardHeaderBtnHeight: CGFloat { 38 }
    /// 头部按钮间距
    static var cardHeaderButtonSpacing: CGFloat { 8 }
    /// 头部按钮文本内边距
    static var cardHeaderBtnPadding: CGFloat { 29 }
    /// 圆形按钮 x 图标
    static var closeIcon: UIImage { UDIcon.getIconByKey(.closeOutlined,
                                                        renderingMode: .alwaysOriginal,
                                                        iconColor: UIColor.ud.iconN2,
                                                        size: CGSize(width: 20, height: 20)) }
    /// 卡片展开时间距
    static var spacingBetweenCards: CGFloat { 8 }
    /// 卡片内部元素默认间距
    static var cardDefaultSpacing: CGFloat { 16 }
    /// 卡片图标 / 文字间距
    static var cardBodySpacingBetweenIconAndTitle: CGFloat { 8 }
    /// 卡片图标尺寸
    static var imageSize: CGFloat { 24 }
    /// 卡片标题字体
    static var cardTitleFont: UIFont { UIFont.ud.caption0 }
    /// 卡片标题字体行高
    static var cardTitleFigmaHeight: CGFloat { cardTitleFont.figmaHeight }
    /// 卡片按钮字体
    static var cardBodyBtnFont: UIFont { UIFont.ud.title4 }
    /// 卡片按钮字体行高
    static var cardBodyBtnFontFigmaHeight: CGFloat { cardBodyBtnFont.figmaHeight }
    /// 卡片按钮高度
    static var cardBodyBtnHeight: CGFloat { 36 }
    /// 卡片按钮圆角
    static var cardBodyBtnCornerRadius: CGFloat { 6 }
    /// 卡片圆角
    static var cardBodyCornerRadius: CGFloat { 12 }
    /// 卡片折叠时高的差
    static var stackHeightDiff: CGFloat { 8 }
    /// 卡片折叠时宽的差
    static var stackWidthDiff: CGFloat { 24 }
    /// 卡片默认宽度 eg: ipad 全屏或横屏时的宽度
    static var cardDefaultWidth: CGFloat { 360 }
    /// 卡片默认高度
    static var cardDefaultHeight: CGFloat { 148 }
    /// 卡片在不同设备下的宽度
    static var cardWidth: CGFloat {
        guard Helper.isInCompact, Helper.windowWidth < 500 else {
            return Cons.cardDefaultWidth
        }
        return Helper.windowWidth - cardContainerPadding * 2
    }
}

enum Colors {
    /// 背景颜色
    static var bgColor: UIColor { UIColor.ud.bgFloatPush }
    /// 边框颜色
    static var borderColor: UIColor { UIColor.ud.lineBorderCard }
    /// 卡片标题颜色
    static var cardTitleColor: UIColor { UIColor.ud.textCaption }
    /// 卡片按钮标题颜色 黑色
    static var buttonTitleColor: UIColor { UIColor.ud.textTitle }
}

/// 卡片当前显示状态
enum PushCardState {
    /// 隐藏
    case hidden
    /// 折叠
    case stacked
    /// 展开
    case expanded
}

/// 头部清除按钮状态
enum PushCardsCleanState {
    /// 清除 文字状态
    case clearText
    /// x 图标状态
    case closeIcon
}

struct StaticFunc {

    /// 添加阴影
    static func setShadow(on view: UIView) {
        view.layer.ud.setShadow(type: .s5Down, shouldRasterize: false)
    }

    /// 是否在展开时展示底部折叠按钮
    static func isShowBottomButton(collectionView: UICollectionView) -> Bool {
        return collectionView.contentSize.height > Helper.screenHeight
    }

    /// 主线程执行
    static func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
