//
//  EasyhintBubbleViewPreference.swift
//  LarkUIKit
//
//  Created by sniperj on 2018/12/7.
//

import UIKit
import Foundation
import UniverseDesignColor

public enum ArrowPosition {
    case any
    case top
    case bottom
    case right
    case left

    static let allValues = [top, bottom, right, left]
}

public struct Preferences {
    public struct Drawing {
        public var cornerRadius = CGFloat(5)
        public var arrowHeight = CGFloat(8)
        public var arrowWidth = CGFloat(16)
        public var textColor = UIColor.ud.primaryOnPrimaryFill
        public var backgroundColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.9)
        public var isNeedShadow = true
        public var arrowPosition = ArrowPosition.any
        public var textAlignment = NSTextAlignment.center
        //            后续考虑支持
        //            public var borderWidth         = CGFloat(0)
        //            public var borderColor         = UIColor.clear
        public var font = UIFont.systemFont(ofSize: 14)
    }

    public struct Positioning {
        public var bubbleHInset = CGFloat(1)
        public var bubbleVInset = CGFloat(1)
        public var textHInset = CGFloat(10)
        public var textVInset = CGFloat(10)
        public var maxWidth = CGFloat(200)
        public var railingOffset = CGPoint(x: 0, y: 0)
    }

    public struct Shadow {
        public var shadowOffset = CGSize(width: 0, height: 4)
        public var shadowOpacity = Float(0.4)
        public var shadowColor = UIColor.ud.color(153, 187, 255)
        public var shadowRadius = CGFloat(10)
    }

    public var drawing = Drawing()
    public var positioning = Positioning()
    public var shadow = Shadow()
}
