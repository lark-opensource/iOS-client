//
//  DownloadViewConfig.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/8/10.
//

import Foundation
import UniverseDesignColor
import UIKit

struct MIMEType {
    static let OctetStream = "application/octet-stream"
}

enum DownloadCons {
    /// 内容视图偏移量
    static var contentOffset: CGFloat { 16 }
    /// 主文本字体
    static var titleFont: UIFont { UIFont.systemFont(ofSize: 17, weight: .medium) }
    /// 主文本行高
    static var titleLineHeight: CGFloat { 24 }
    /// 主文本对齐方式
    static var titleAlignment: NSTextAlignment { .center }
    /// 描述文本字体
    static var descFont: UIFont { UIFont.systemFont(ofSize: 14, weight: .medium) }
    /// 描述文本行高
    static var descLineHeight: CGFloat { 20 }
    /// 描述文本对齐方式
    static var descAlignment: NSTextAlignment { .left }
    /// 主按钮字体
    static var downloadBtnFont: UIFont { UIFont.systemFont(ofSize: 16, weight: .medium) }
    /// 主按钮最小宽度
    static var downloadBtnMinWidth: CGFloat { 96 }
    /// 主按钮高度
    static var downloadBtnHeight: CGFloat { 36 }
    /// 主按钮圆角数值
    static var downloadBtnRadius: CGFloat { 6 }
    /// 提示文本字体
    static var tipsFont: UIFont { UIFont.systemFont(ofSize: 16, weight: .medium) }
    /// 提示文本行高
    static var tipsLineHeight: CGFloat { 22 }
    /// 提示文本对齐方式
    static var tipsAlignment: NSTextAlignment { .center }
    /// 格式图标和主文本间距
    static var formatTitleSpacing: CGFloat { 12 }
    /// 进度条宽度
    static var progressBarWidth: CGFloat { 250 }
    /// 进度条高度
    static var progressBarHeight: CGFloat { 4 }
    /// 进度条与文本间距
    static var progressBarTextSpacing: CGFloat { 14 }
    /// 状态图标宽度
    static var statusIconWidth: CGFloat { 16 }
    /// 状态图标与进度条间距
    static var statusIconBarSpacing: CGFloat { 8 }
    /// 描述文本与进度条间距
    static var progressBarDescSpacing: CGFloat { 8 }
    
    static let titleBaselineOffset = (titleLineHeight - titleFont.lineHeight) / 2.0 / 2.0
    static let titleParagraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = titleLineHeight
        style.maximumLineHeight = titleLineHeight
        style.alignment = titleAlignment
        return style
    }()
    
    static let descBaselineOffset = (descLineHeight - descFont.lineHeight) / 2.0 / 2.0
    static let descParagraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = descLineHeight
        style.maximumLineHeight = descLineHeight
        style.alignment = descAlignment
        return style
    }()
    
    static let tipsBaselineOffset = (tipsLineHeight - tipsFont.lineHeight) / 2.0 / 2.0
    static let tipsParagraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = tipsLineHeight
        style.maximumLineHeight = tipsLineHeight
        style.alignment = tipsAlignment
        return style
    }()
}

enum DownloadColor {
    /// 主文本字体颜色
    static var titleColor: UIColor { UIColor.ud.textTitle }
    /// 描述文本字体颜色
    static var descColor: UIColor { UIColor.ud.functionDangerContentDefault }
    /// 提示文本字体颜色
    static var tipsColor: UIColor { UIColor.ud.textCaption }
    /// 进度条闲置状态颜色
    static var barIdleColor: UIColor { UIColor.ud.udtokenProgressBg }
    /// 进度条下载状态颜色
    static var barDownloadColor: UIColor { UIColor.ud.primaryContentDefault }
    /// 进度条成功状态颜色
    static var barSuccessColor: UIColor { UIColor.ud.functionSuccessContentDefault }
    /// 进度条失败状态颜色
    static var barFailColor: UIColor { UIColor.ud.functionDangerContentDefault }
    /// 主按钮字体颜色
    static var downloadTitleColor: UIColor { UIColor.ud.primaryOnPrimaryFill }
    /// 主按钮背景颜色
    static var downloadBGColor: UIColor { UIColor.ud.primaryContentDefault }
}

enum DownloadIcon {
    /// 状态成功图标
    static var iconSuccessIcon: UIImage { BundleResources.WebBrowser.opweb_icon_succeed_filled }
    /// 状态默认图标
    static var iconDefaultIcon: UIImage { BundleResources.WebBrowser.opweb_icon_close_filled }
}
