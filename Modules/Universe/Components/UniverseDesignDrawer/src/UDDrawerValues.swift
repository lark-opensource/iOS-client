//
//  UDDrawerValues.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

import UIKit
import Foundation
import UniverseDesignColor

public enum UDDrawerValues {
    public static let maskColor: UIColor = UDColor.bgMask
    // subView默认宽度
    public static let subViewDefaultWidth: CGFloat = 96
    // content默认宽度
    public static var contentDefaultWidth: CGFloat {
        return (UIApplication.shared.delegate?.window??.bounds.width ?? UIScreen.main.bounds.width) * contentDefaultPercent
    }
    // content默认百分比
    public static let contentDefaultPercent: CGFloat = 0.87
    // 动画时间
    public static let transitionDuration: TimeInterval = 0.25
    // content最大宽度
    public static let contentMaxWidth: CGFloat = 375
    static let velocityThreshold: CGFloat = 50
    static let offsetThreshold: CGFloat = 0.3
    static let shadowColor: UIColor = UIColor.ud.shadowDefaultLg
    static let shadowOffset: CGSize = CGSize(width: 2, height: 0)
    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: Float = 1.0
}
