//
//  BitableHomeConstant.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/15.
//

import Foundation
import SKUIKit
import UniverseDesignColor

struct SKBitableConst {
    static let triggerOpenFullscreenNoti = "triggerOpenFullscreenNoti"
}

struct BitableHomeLayoutConfig {
    static let homeHeaderHeight = 56
    //MARK: 列表
    static let multiListContainerHeight: CGFloat = 364.0
    static let multiListContainerCornerRadius: CGFloat = 20
    static let multiListSectionHeaderHeight: CGFloat = 60.0
    
    static func headerGridentColors() -> [UIColor] {
        if UIColor.docs.isCurrentDarkMode {
            return [
                UIColor(hexString: "#26292C"),
                UIColor(hexString: "#1B1B1B")]
        } else {
           return [
            UIColor(hexString: "#E5EBF1"),
            UIColor(hexString: "#EEF2F6")]
        }
    }
    
    static func headerBgColor() -> UIColor {
        return UDColor.rgb("#FFFFFF") & UDColor.rgb("#292929")
    }
    
    static func backgroundColor() -> UIColor {
        return UDColor.rgb("#EEF2F6") & UDColor.rgb("#1B1B1B")
    }
    
    static func multiListContainerBgColor() -> UIColor {
        return UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
    }
    static func multiListContainerBorderColor() -> UIColor {
        return UDColor.rgb("#FFFFFF") & UDColor.rgb("#292929")
    }
    
    //MARK: 仪表盘
    static let chartHeaderHeight: CGFloat = 52.0 + 12.0
    static let chartFooterHeight: CGFloat = 12.0
    static let colloctionViewHorizonMargin : CGFloat = 16.0
    static let chartCardCorner : CGFloat = 20.0
    
    static let chartCardHeightNormal : CGFloat = 198.0
    static let chartCardHeightStatistic : CGFloat = 148.0
}
