//
//  LarkBadgeProtocol.swift
//  LarkBadge
//
//  Created by 朱衡 on 2018/10/9.
//  Copyright © 2018年 朱衡. All rights reserved.
//

import Foundation
import UIKit
import CalendarFoundation
struct BadgeObjectKey {
    static var badge = "badgeKey"
    static var badgeStyle = "BadgeStyle"
}

enum BadgeStyle {
    case none
    case redDot //红点类型，默认大小10*10，对齐右上角
    case new    //new类型，默认使用badgeNew图片，对其右上角
}

enum BadgeStatus {
    case show
    case hidden
}

//用协议以后方便扩展UIBarButtonItem、UITabBarItem的红点
protocol LarkBadgeProtocol {
    var badge: UIImageView? { get set }
    var badgeStyle: BadgeStyle { get set } //默认none，使用时需要先设置style

    func setBadgeSize(_ size: CGSize)        //改变badge大小
    func setBadgeTopRightOffset(_ point: CGPoint) //改变badge相对右上角的位置
    func setRedDotColor(_ color: UIColor)   //改变红点颜色，仅对redDot style有用
    func setBadgeImageName(_ name: String)   //改变newImage，仅对new style有用
    func setBadgeStyle(_ style: BadgeStyle)  //改变style
    func changeStatus(_ status: BadgeStatus) //改变一个红点的状态 隐藏/显示/移除
}
