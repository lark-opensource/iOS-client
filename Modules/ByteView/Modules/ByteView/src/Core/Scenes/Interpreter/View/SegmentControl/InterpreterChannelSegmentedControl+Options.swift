//
//  InterpreterChannelSegmentControl+Options.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

extension InterpreterChannelSegmentedControl {
    enum Option {
        /* Selected segment */
        case indicatorViewBackgroundColor(UIColor)
        case indicatorViewInset(CGFloat)
        case indicatorViewBorderWidth(CGFloat)
        case indicatorViewBorderColor(UIColor)
        case indicatorViewCornerRadius(CGFloat)
        /* Behavior */
        case alwaysAnnouncesValue(Bool)
        case announcesValueImmediately(Bool)
        case panningDisabled(Bool)
        /* Animation */
        case animationDuration(TimeInterval)
        case animationSpringDamping(CGFloat)
        /* Other */
        case backgroundColor(UIColor)
        case cornerRadius(CGFloat)
        case borderWidth(CGFloat)
        case borderColor(UIColor)
        case segmentPadding(CGFloat)
        case segmentSpacing(CGFloat)
    }
}
