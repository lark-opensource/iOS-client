//
//  Props.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/3/23.
//

import TangramLayoutKit

// 不提供默认实现，都是强依赖业务方实现的方法
public protocol Props {
    /// deep copy a Props and it's variables
    func clone() -> Self
    /// deep compare a Props
    func equalTo(_ old: Props) -> Bool
}

public struct EmptyProps: Props {
    public static var empty: EmptyProps {
        return EmptyProps()
    }

    public init() {}

    public func clone() -> EmptyProps {
        return self
    }

    public func equalTo(_ old: Props) -> Bool {
        return old is EmptyProps
    }
}

// MARK: - Common Props

public enum Direction {
    case ltr // 从左到右
    case rtl // 从右到左

    public var value: TLDirection {
        switch self {
        case .ltr: return TLDirectionLTR
        case .rtl: return TLDirectionRTL
        @unknown default: return TLDirectionLTR
        }
    }
}

public enum Orientation {
    case row
    case column
    case rowReverse
    case columnReverse

    public var value: TLOrientation {
        switch self {
        case .row: return TLOrientationRow
        case .column: return TLOrientationColumn
        case .rowReverse: return TLOrientationRowReverse
        case .columnReverse: return TLOrientationColumnReverse
        @unknown default: return TLOrientationRow
        }
    }
}

public enum Justify {
    case start
    case center
    case end
    case spaceBetween
    case spaceArround
    case spaceEvenly

    public var value: TLJustify {
        switch self {
        case .start: return TLJustifyStart
        case .center: return TLJustifyCenter
        case .end: return TLJustifyEnd
        case .spaceBetween: return TLJustifySpaceBetween
        case .spaceArround: return TLJustifySpaceArround
        case .spaceEvenly: return TLJustifySpaceEvenly
        @unknown default: return TLJustifyStart
        }
    }
}

public enum Align {
    case undefined
    case top
    case middle
    case bottom
    case stretch
    case baseline

    public var value: TLAlign {
        switch self {
        case .undefined: return TLAlignUndefined
        case .top: return TLAlignTop
        case .middle: return TLAlignMiddle
        case .bottom: return TLAlignBottom
        case .stretch: return TLAlignStretch
        case .baseline: return TLAlignBaseline
        @unknown default: return TLAlignTop
        }
    }
}

public enum FlexWrap {
    case noWrap
    case wrap
    case wrapReverse
    case linearWrap

    public var value: TLFlexWrap {
        switch self {
        case .noWrap: return TLFlexWrapNoWrap
        case .wrap: return TLFlexWrapWrap
        case .wrapReverse: return TLFlexWrapWrapReverse
        case .linearWrap: return TLFlexWrapLinearWrap
        @unknown default: return TLFlexWrapNoWrap
        }
    }
}

public enum Display {
    case display
    case none

    public var value: TLDisplay {
        switch self {
        case .display: return TLDisplayDisplay
        case .none: return TLDisplayNone
        @unknown default: return TLDisplayDisplay
        }
    }
}

public struct Padding: Equatable {
    public static var zero: Padding {
        return .init()
    }

    public var top: CGFloat
    public var right: CGFloat
    public var bottom: CGFloat
    public var left: CGFloat

    public init(top: CGFloat = 0,
                right: CGFloat = 0,
                bottom: CGFloat = 0,
                left: CGFloat = 0) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
    
    public init(padding: CGFloat) {
        self.top = padding
        self.right = padding
        self.bottom = padding
        self.left = padding
    }
}
