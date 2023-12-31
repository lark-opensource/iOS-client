//
//  MenuPrivacyViewStyle.swift
//  OPSDK
//
//  Created by 刘洋 on 2021/2/25.
//

import UIKit
import UniverseDesignColor

/// 权限视图的布局样式
struct MenuPrivacyViewStyle {
    /// 判断是否是IPad
    private let isIPad = BDPDeviceHelper.isPadDevice()

    /// 描述字体字号
    var font: UIFont {
        if isIPad {
            return UIFont.systemFont(ofSize: 16)
        } else {
            return UIFont.systemFont(ofSize: 12)
        }

    }

    /// 描述文本高度
    /// - Parameter mutiLine: 是否多行显示
    /// - Returns: 文本高度
    func labelHeight(mutiLine: Bool) -> CGFloat {
        if self.isIPad {
            return mutiLine ? 44 : 22
        } else {
            return mutiLine ? 36 : 18
        }
    }

    /// 权限视图高度
    /// - Parameter mutiLine: 描述是否多行显示
    /// - Returns: 视图高度
    func viewHeight(mutiLine: Bool) -> CGFloat {
        max(self.labelHeight(mutiLine: mutiLine), self.imageWidthAndHeight)
    }

    /// 描述颜色
    var labelColor: UIColor {
        if isIPad {
            return UIColor.ud.textPlaceholder
        } else {
            return UIColor.ud.textCaption
        }
    }

    /// 头像宽度和高度
    var imageWidthAndHeight: CGFloat {
        if isIPad {
            return 20
        } else {
            return 16
        }
    }

    /// 头像颜色
    var imageColor: UIColor {
        if isIPad {
            return UIColor.ud.textPlaceholder
        } else {
            return UIColor.ud.textCaption
        }
    }

    /// 描述左边距
    var titleLeftSpacing: CGFloat {
        if isIPad {
            return 12
        } else {
            return 4
        }
    }

    /// 头像左边距
    var imageLeftSpacing: CGFloat {
        if isIPad {
            return 0
        } else {
            return 0
        }
    }

    /// 描述又边距
    var titleRightSpacing: CGFloat {
        if isIPad {
            return 0
        } else {
            return 0
        }
    }
}
