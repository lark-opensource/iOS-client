//
//  ChatNavigationBarItemTintColor.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/28.
//

import Foundation
import UIKit
import UniverseDesignColor

public final class ChatNavigationBarItemTintColor {
    public static func tintColorFor(image: UIImage, style: OpenChatNavigationBarStyle) -> UIImage {
        let color = style.elementTintColor()
        return image.ud.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}
