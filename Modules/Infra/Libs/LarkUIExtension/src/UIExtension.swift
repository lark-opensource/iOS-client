//
//  UIExtension.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/13.
//

import Foundation

public struct UIExtension {
    public static var animationDuration: TimeInterval = 0.25

    public static let UIWillUpdate = NSNotification.Name("ui.extension.will.change.notification")

    public static let UIDidUpdate = NSNotification.Name("ui.extension.did.change.notification")
}
