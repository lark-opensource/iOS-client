//
//  LKLabelDelegate.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/12/15.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

public protocol LKLabelDelegate: AnyObject {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL)

    func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String)

    /// 点击到指定tap事件的文本的回调，返回true表明继续冒泡到url、phoneNum的点击事件监测，返回false表明不继续进行事件冒泡
    ///
    /// - Parameters:
    ///   - label: LKLabel
    ///   - text: 被选中的注册的文字
    ///   - range: 被选中的文字的range
    /// - Returns: 是否要继续冒泡事件
    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool

    func shouldShowMore(_ label: LKLabel, isShowMore: Bool)

    func tapShowMore(_ label: LKLabel)

    func showFirstAtRect(_ rect: CGRect)
}

extension LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {

    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {

    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return true
    }

    public func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {

    }

    public func tapShowMore(_ label: LKLabel) {

    }

    public func showFirstAtRect(_ rect: CGRect) {

    }
}
