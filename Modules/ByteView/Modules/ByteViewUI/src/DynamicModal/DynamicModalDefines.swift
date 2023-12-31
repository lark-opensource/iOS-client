//
//  DynamicModalDefines.swift
//  ByteViewUI
//
//  Created by Tobb Huang on 2023/4/21.
//

import Foundation
import UniverseDesignTheme
import UniverseDesignColor

public enum DynamicModalPresentationStyle: Int {

    // system style
    case fullScreen = 0
    case pageSheet = 1
    case formSheet = 2
//    case currentContext = 3
//    case custom = 4
    case overFullScreen = 5
//    case overCurrentContext = 6
    case popover = 7
//    case none = -1
//    case automatic = -2

    // custom style
    case pan = 100

    var systemModalStyle: UIModalPresentationStyle {
        if let style = UIModalPresentationStyle(rawValue: self.rawValue) {
            return style
        }
        return .overFullScreen
    }
}

public struct DynamicModalConfig {
    public enum Category {
        case regular
        case compact
        case both
    }

    let presentationStyle: DynamicModalPresentationStyle
    var popoverConfig: DynamicModalPopoverConfig?
    let backgroundColor: UIColor
    let disableSwipeDismiss: Bool
    let needNavigation: Bool
    var contentSize: CGSize?

    public init(presentationStyle: DynamicModalPresentationStyle,
                popoverConfig: DynamicModalPopoverConfig? = nil,
                backgroundColor: UIColor = UIColor.ud.bgMask,
                disableSwipeDismiss: Bool = false,
                needNavigation: Bool = false,
                contentSize: CGSize? = nil) {
        self.presentationStyle = presentationStyle
        self.popoverConfig = popoverConfig
        self.backgroundColor = backgroundColor
        self.disableSwipeDismiss = disableSwipeDismiss
        self.needNavigation = needNavigation
        self.contentSize = contentSize
    }
}

public struct DynamicModalPopoverConfig {
    weak var sourceView: UIView?
    var sourceRect: CGRect
    var backgroundColor: UIColor
    var popoverSize: CGSize?
    var popoverLayoutMargins: UIEdgeInsets
    var hideArrow: Bool
    // 箭头方向，0为无箭头
    var permittedArrowDirections: UIPopoverArrowDirection?

    public init(sourceView: UIView,
                sourceRect: CGRect,
                backgroundColor: UIColor,
                popoverSize: CGSize? = nil,
                popoverLayoutMargins: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
                hideArrow: Bool = false,
                permittedArrowDirections: UIPopoverArrowDirection? = nil) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.backgroundColor = backgroundColor
        self.popoverSize = popoverSize
        self.popoverLayoutMargins = popoverLayoutMargins
        self.hideArrow = hideArrow
        self.permittedArrowDirections = permittedArrowDirections
    }
}

public protocol DynamicModalDelegate: AnyObject {
    func regularCompactStyleDidChange(isRegular: Bool)
    func didAttemptToSwipeDismiss()
}

public extension DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {}
    func didAttemptToSwipeDismiss() {}
}

class CustomPopoverBackgroundView: UIPopoverBackgroundView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.ud.setShadowColor(UIColor.clear)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable unused_setter_value
    override var arrowOffset: CGFloat {
        get {
            return 0
        }
        set {
            setNeedsLayout()
        }
    }

    override var arrowDirection: UIPopoverArrowDirection {
        get {
            return .up
        }
        set {
            setNeedsLayout()
        }
    }
    // swiftlint:enable unused_setter_value

    override class func arrowHeight() -> CGFloat {
        0.0
    }

    override class func arrowBase() -> CGFloat {
        0.0
    }

    override class func contentViewInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
