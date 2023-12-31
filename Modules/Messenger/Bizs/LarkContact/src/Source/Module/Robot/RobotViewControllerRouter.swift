//
//  RobotViewControllerRouter.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/11.
//

import Foundation
import LarkModel

protocol RobotViewControllerRouter: AnyObject {
    func robotViewController(_ vc: RobotViewController, chatter: Chatter, chatId: String?)
}
