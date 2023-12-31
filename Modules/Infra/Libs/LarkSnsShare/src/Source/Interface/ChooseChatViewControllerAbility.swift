//
//  ChooseChatViewControllerAbility.swift
//  LarkSnsShare
//
//  Created by Supeng on 2022/1/12.
//

import UIKit
import Foundation

// 选择会话
public protocol ChooseChatViewControllerAbility: AnyObject {
    var inputNavigationItem: UINavigationItem? { get set }
    var closeHandler: (() -> Void)? { get set }
}
