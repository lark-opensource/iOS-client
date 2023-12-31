//
//  SharePanelConfig.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/17.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon
import LarkEmotion

// disable-lint: magic number

// swiftlint:disable all
enum ShareCons {
    /// 面板标题字体
    static var panelTitleFont: UIFont { UIFont.ud.title3(.fixed) }
    /// 面板取消字体
    static var panelCancelTitleFont: UIFont { UIFont.ud.body0(.fixed) }
    /// 设置区标题字体
    static var configTitleFont: UIFont { UIFont.ud.body0(.fixed) }
    /// 设置区副标题字体
    static var configSubTitleFont: UIFont { UIFont.ud.body2(.fixed) }
    /// 分享区标题字体
    static var shareIconTitleFont: UIFont { UIFont.ud.caption1(.fixed) }

    /// 面板标题行高
    static var panelTitleFontHeight: CGFloat { panelTitleFont.figmaHeight }
    /// 面板取消字体行高
    static var panelCancelTitleFontHeight: CGFloat { panelCancelTitleFont.figmaHeight }
    /// 设置区标题行高
    static var configTitleFontHeight: CGFloat { configTitleFont.figmaHeight }
    /// 设置区副标题行高
    static var configSubTitleFontHeight: CGFloat { configSubTitleFont.figmaHeight }
    /// 分享区标题行高
    static var ShareTitleFontHeight: CGFloat { shareIconTitleFont.figmaHeight }

    /// popover 箭头高度
    static var popoverArrowHeight: CGFloat { 13 }
    /// 通用边距 16px
    static var defaultSpacing: CGFloat { 16 }
    /// 面板标题区域高度
    static var panelHeaderHeight: CGFloat { 48 }
    /// 图片面板标题区域高度
    static var imagePanelHeaderHeight: CGFloat { 58 }
    /// 面板圆角 12px
    static var panelCornerRadius: CGFloat { 12 }
    /// 面板分割线高度 0.5px
    static var panelDivideLineHeight: CGFloat { 0.5 }
    /// 设置区控件间距 12px
    static var configDefaultSpacing: CGFloat { 12 }
    /// 设置区文字到上下边距 13px
    static var configTitleTopAndBottomMargin: CGFloat { 13 }
    /// 设置区左侧图标大小 16px
    static var configLeftIconWidth: CGFloat { 16 }
    /// 设置区右侧业务自定义区宽度 200px
    static var configCustomViewWidth: CGFloat { 200 }
    /// 设置区右侧图标大小 16px
    static var configRightIconWidth: CGFloat { 16 }
    /// 设置区标题副标题间距 4px
    static var configtitleSubtitleSpacing: CGFloat { 4 }
    /// 设置区单行行高
    static var configSingleLineHeight: CGFloat { 48 }
    /// 设置区双行行高
    static var configMultiLineHeight: CGFloat { 72 }
    /// 分享区图标圆角 12px
    static var shareIconCornerRadius: CGFloat { 12 }
    /// 分享区图标宽度 48px
    static var shareIconContainerWidth: CGFloat { 48 }
    /// 分享区图标图片宽度 24px
    static var shareIconImageWidth: CGFloat { 24 }
    /// 分享区图标标题最大宽度 64px
    static var shareTitleMaxWidth: CGFloat { 64 }
    /// 分享区图标-标题间距 8px
    static var shareIconTitleSpacing: CGFloat { 8 }
    /// 分享区标题最大行数 2
    static var shareTitleMaxLineNums: Int { 2 }
    /// 分享区单元格宽高
    static var shareCellItemSize: CGSize { CGSize(width: 48, height: 92) }
    /// 分享区单行图标间距 20px
    static var shareIconDefaultSpacing: CGFloat { 20 }
    /// 分享区图标最小间距
    static var shareIconMinSpacing: CGFloat { 20 }
    /// 分享区页码高度
    static var sharePageIndicatorHeight: CGFloat { 4 }
}

enum ShareColor {
    /// 蒙板颜色
    static var maskColor: UIColor { UIColor.ud.bgMask }
    /// 面板背景色
    static var panelBackgroundColor: UIColor { UIColor.ud.bgFloatBase }
    /// 面板标题色
    static var panelTitleColor: UIColor { UIColor.ud.textTitle }
    /// 面板取消色
    static var panelCancelTitleColor: UIColor { UIColor.ud.textTitle }
    /// 面板关闭图标色
    static var panelCloseIconColor: UIColor { UIColor.ud.iconN1 }
    /// 面板分割线色
    static var panelDivideLineColor: UIColor { UIColor.ud.N800.withAlphaComponent(0.15) }
    /// 设置区背景色
    static var configBackgroundColor: UIColor { UIColor.ud.bgFloat }
    /// 设置区左侧图标色
    static var configLeftIconColor: UIColor { UIColor.ud.iconN1 }
    /// 设置区标题色
    static var configTitleColor: UIColor { UIColor.ud.textTitle }
    /// 设置区副标题色
    static var configSubTitleColor: UIColor { UIColor.ud.textCaption }
    /// 设置区右侧图标色
    static var configRightIconColor: UIColor { UIColor.ud.iconN2 }
    /// 设置区表格按压颜色
    static var configCellPressColor: UIColor { UIColor.ud.fillPressed }
    /// 分享区图标背景色
    static var shareIconBackgroundColor: UIColor { UIColor.ud.bgFloat }
    /// 分享区图标颜色
    static var shareIconColor: UIColor { UIColor.ud.iconN1 }
    /// 分享区标题颜色
    static var shareTitleColor: UIColor { UIColor.ud.textCaption }
    /// 分享区分页选中颜色
    static var shareCurrentPageColor: UIColor { UIColor.ud.primaryContentDefault }
    /// 分享区分页未选中颜色
    static var shareUnselectedPageColor: UIColor { UIColor.ud.iconDisabled }
}


enum ShareIcon {
    /// 微信
    static var shareWechatIcon: UIImage { UDIcon.wechatColorful }
    /// 微博
    static var shareWeiboICon: UIImage { UDIcon.weiboColorful }
    /// QQ
    static var shareQQIcon: UIImage { UDIcon.qqColorful }
    /// 拷贝链接
    static var shareCopyIcon: UIImage { UDIcon.getIconByKey(.linkCopyOutlined,
                                                            iconColor: ShareColor.shareIconColor) }
    /// 更多
    static var shareMoreIcon: UIImage { UDIcon.getIconByKey(.moreOutlined,
                                                            iconColor: ShareColor.shareIconColor) }
    /// 朋友圈
    static var shareTimeLineIcon: UIImage { UDIcon.wechatFriendColorful }
    
    /// 保存图片
    static var shareSaveIcon: UIImage { UDIcon.getIconByKey(.downloadOutlined,
                                                            iconColor: ShareColor.shareIconColor) }
    
    /// 分享到朋友圈的固定白色图标
    static var shareSavePYQIcon: UIImage { UDIcon.getIconByKey(.downloadOutlined,
                                                               iconColor: UIColor.ud.primaryOnPrimaryFill) }
    
    /// 生成图片
    static var shareImageIcon: UIImage{ UDIcon.getIconByKey(.imageOutlined,
                                                              iconColor: ShareColor.shareIconColor) }
}

enum SharePanelTheme: Int, Codable {
    case unspecified = 0
    case light = 1
    case dark = 2
    
    @available(iOS 13.0, *)
    static func convert(from newValue: UIUserInterfaceStyle) -> SharePanelTheme {
        switch newValue {
        case .light: return .light
        case .dark: return .dark
        default: return .unspecified
        }
    }
    
    @available(iOS 13.0, *)
    static func convert(from currentUserInterfaceStyle: SharePanelTheme) -> UIUserInterfaceStyle {
        switch currentUserInterfaceStyle {
        case .light: return .light
        case .dark: return .dark
        default: return .unspecified
        }
    }
}

public let shareOptionMapping: [LarkShareItemType: (icon: UIImage, title: String)] = [
    .wechat: (ShareIcon.shareWechatIcon,
              BundleI18n.LarkSnsShare.Lark_UserGrowth_TitleWechat),
    .weibo: (ShareIcon.shareWeiboICon,
             BundleI18n.LarkSnsShare.Lark_UserGrowth_TitleWeibo),
    .qq: (ShareIcon.shareQQIcon,
          BundleI18n.LarkSnsShare.Lark_UserGrowth_TitleQQ),
    .copy: (ShareIcon.shareCopyIcon,
            BundleI18n.LarkSnsShare.Lark_UD_SharePanelCopyLink),
    .more(.default): (ShareIcon.shareMoreIcon,
                      BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareToMore),
    .timeline: (ShareIcon.shareTimeLineIcon,
                BundleI18n.LarkSnsShare.Lark_Invitation_SharePYQ),
    .save: (ShareIcon.shareSaveIcon,
            BundleI18n.LarkSnsShare.Lark_UD_SharePanelSave),
    .shareImage: (ShareIcon.shareImageIcon,
                  BundleI18n.LarkSnsShare.Lark_UD_SharePanelShareImage)
]

/// 配置区配置项
// 因为此数据结构与UI密切相关，放在ExpansionAbility中
public struct ShareSettingItem {
    var identifier: String
    var icon: UIImage?
    var title: String?
    var subTitle: String?
    var customView: UIView?
    var handler: ((LarkShareActionPanel) -> Void)?

    public init(identifier: String,
                icon: UIImage? = nil,
                title: String? = nil,
                subTitle: String? = nil,
                customView: UIView? = nil,
                handler: ((LarkShareActionPanel) -> Void)? = nil) {
        self.identifier = identifier
        self.icon = icon
        self.title = title
        self.subTitle = subTitle
        self.customView = customView
        self.handler = handler
    }
}

protocol LarkShareItemClickDelegate: AnyObject {
    func shareItemDidClick(itemType: LarkShareItemType)
    func sharePanelDidClosed()
}

protocol PanelHeaderCloseDelegate: AnyObject {
    func dismissCurrentVC(animated: Bool)
}

public protocol LarkSharePanelDelegate: AnyObject {
    func clickShareItem(at shareItemType: LarkShareItemType, in panel: PanelType)
}
