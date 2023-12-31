//
//  Style.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/2/8.
//

import UIKit
import Foundation
import EEFlexiable
import Darwin

public enum BoxSizing: Int {
    /// box大小包含borderWidth，boxWidth = contentWidth + borderLeftWidth + borderRightWidth
    /// 如：内容大小10px,borderWidth 2,则实际大小10 + 2 + 2
    case contentBox
    /// box大小不包含borderWidth，boxWidth = contentWidth
    /// 如：内容大小10px,borderWidth 2,则实际大小10
    case borderBox
}

open class ASComponentStyle {
    open var ui: ASComponentUIStyle
    public var border: Border? {
        get {
            return ui.border
        }
        set {
            ui.border = newValue
            if boxSizing == .contentBox {
                borderTopWidth = newValue?.top.width ?? 0
                borderRightWidth = newValue?.right.width ?? 0
                borderBottomWidth = newValue?.bottom.width ?? 0
                borderLeftWidth = newValue?.left.width ?? 0
            } else {
                borderTopWidth = 0
                borderRightWidth = 0
                borderBottomWidth = 0
                borderLeftWidth = 0
            }
        }
    }

    /// same to FlexStyle.h
    public var flexBasis: CSSValue = CSSValueAuto
    public var maxWidth: CSSValue = CSSValueUndefined
    public var minWidth: CSSValue = CSSValueUndefined
    public var width: CSSValue = CSSValueAuto
    public var height: CSSValue = CSSValueAuto
    public var maxHeight: CSSValue = CSSValueUndefined
    public var minHeight: CSSValue = CSSValueUndefined
    public var margin: CSSValue = CSSValueUndefined
    public var marginLeft: CSSValue = CSSValueUndefined
    public var marginTop: CSSValue = CSSValueUndefined
    public var marginRight: CSSValue = CSSValueUndefined
    public var marginBottom: CSSValue = CSSValueUndefined
    public var padding: CSSValue = CSSValueUndefined
    public var paddingLeft: CSSValue = CSSValueUndefined
    public var paddingTop: CSSValue = CSSValueUndefined
    public var paddingRight: CSSValue = CSSValueUndefined
    public var paddingBottom: CSSValue = CSSValueUndefined
    public var left: CSSValue = CSSValueUndefined
    public var top: CSSValue = CSSValueUndefined
    public var right: CSSValue = CSSValueUndefined
    public var bottom: CSSValue = CSSValueUndefined

    public var flexGrow: CGFloat = 0
    public var flexShrink: CGFloat = 1
    public var borderWidth: CGFloat = 0
    public var borderStartWidth: CGFloat = 0
    public var borderEndWidth: CGFloat = 0
    public var borderTopWidth: CGFloat = 0
    public var borderRightWidth: CGFloat = 0
    public var borderBottomWidth: CGFloat = 0
    public var borderLeftWidth: CGFloat = 0
    public var aspectRatio: CGFloat = CGFloat(YGUndefined)

    public var position: CSSPosition = .relative
    public var display: CSSDisplay = .flex
    public var flexDirection: CSSFlexDirection = .row
    public var flexWrap: CSSWrap = .noWrap
    public var justifyContent: CSSJustify = .flexStart
    public var alignContent: CSSAlign = .flexStart
    public var alignItems: CSSAlign = .stretch
    public var alignSelf: CSSAlign = .auto
    public var direction: CSSDirection = .inherit
    public var overflow: CSSOverflow = .hidden

    public var boxSizing: BoxSizing = .contentBox {
        didSet {
            guard boxSizing != oldValue else {
                return
            }
            let border = self.border
            self.border = border
        }
    }

    public init(_ ui: ASComponentUIStyle) {
        self.ui = ui
    }

    public init() {
        self.ui = ASComponentUIStyle()
    }

    func applyToFlexStyle(_ flexStyle: FlexStyle) {
        flexStyle.direction = direction
        flexStyle.flexDirection = flexDirection
        flexStyle.justifyContent = justifyContent
        flexStyle.alignContent = alignContent
        flexStyle.alignItems = alignItems
        flexStyle.alignSelf = alignSelf
        flexStyle.position = position
        flexStyle.flexWrap = flexWrap
        flexStyle.overflow = overflow
        flexStyle.display = display
        flexStyle.flexGrow = flexGrow
        flexStyle.flexShrink = flexShrink
        flexStyle.flexBasis = flexBasis
        flexStyle.left = left
        flexStyle.top = top
        flexStyle.right = right
        flexStyle.bottom = bottom
        flexStyle.marginLeft = marginLeft
        flexStyle.marginTop = marginTop
        flexStyle.marginRight = marginRight
        flexStyle.marginBottom = marginBottom
        flexStyle.margin = margin
        flexStyle.paddingLeft = paddingLeft
        flexStyle.paddingTop = paddingTop
        flexStyle.paddingRight = paddingRight
        flexStyle.paddingBottom = paddingBottom
        flexStyle.padding = padding
        flexStyle.borderLeftWidth = borderLeftWidth
        flexStyle.borderTopWidth = borderTopWidth
        flexStyle.borderRightWidth = borderRightWidth
        flexStyle.borderBottomWidth = borderBottomWidth
        flexStyle.borderWidth = borderWidth
        flexStyle.width = width
        flexStyle.height = height
        flexStyle.minWidth = minWidth
        flexStyle.maxWidth = maxWidth
        flexStyle.minHeight = minHeight
        flexStyle.maxHeight = maxHeight
        flexStyle.aspectRatio = aspectRatio
    }

    open func applyToView(_ view: UIView) {
        assert(Thread.isMainThread)
        ui.applyToView(view)
    }

    public func clone() -> ASComponentStyle {
        let clone = ASComponentStyle()
//        let srcPtr = withUnsafeBytes(of: self, { $0 })

//        return withUnsafeMutablePointer(to: &clone) { (clonePointer: UnsafeMutablePointer<ASComponentStyle>) -> ASComponentStyle in
//            memcpy(
//                UnsafeMutableRawPointer(clonePointer),
//                srcPtr.baseAddress!,
//                MemoryLayout<ASComponentStyle>.size
//            )
//            return clonePointer.pointee
//        }
        clone.alignContent = alignContent
        clone.alignItems = alignItems
        clone.alignSelf = alignSelf
        clone.aspectRatio = aspectRatio

        clone.backgroundColor = backgroundColor?.copy() as? UIColor
        clone.borderBottomWidth = borderBottomWidth
        clone.borderEndWidth = borderEndWidth
        clone.borderLeftWidth = borderLeftWidth
        clone.borderRightWidth = borderRightWidth
        clone.borderStartWidth = borderStartWidth
        clone.borderTopWidth = borderTopWidth
        clone.borderWidth = borderWidth
        clone.border = border
        clone.boxSizing = boxSizing

        clone.cornerRadius = cornerRadius

        clone.direction = direction
        clone.display = display

        clone.flexBasis = flexBasis
        clone.flexDirection = flexDirection
        clone.flexGrow = flexGrow
        clone.flexWrap = flexWrap
        clone.flexShrink = flexShrink

        clone.height = height
        clone.maxHeight = maxHeight
        clone.minHeight = minHeight
        clone.width = width
        clone.maxWidth = maxWidth
        clone.minWidth = minWidth

        clone.justifyContent = justifyContent

        clone.left = left
        clone.right = right
        clone.top = top
        clone.bottom = bottom

        clone.margin = margin
        clone.marginTop = marginTop
        clone.marginBottom = marginBottom
        clone.marginLeft = marginLeft
        clone.marginRight = marginRight

        clone.overflow = overflow

        clone.padding = padding
        clone.paddingBottom = paddingBottom
        clone.paddingTop = paddingTop
        clone.paddingLeft = paddingLeft
        clone.paddingRight = paddingRight
        clone.position = position

        return clone
    }
}

public extension ASComponentStyle {
    var backgroundColor: UIColor? {
        get {
            return ui.backgroundColor
        }
        set {
            ui.backgroundColor = newValue
        }
    }

    var cornerRadius: CGFloat? {
        get { return ui.cornerRadius }
        set { ui.cornerRadius = newValue }
    }
}

public final class ASComponentUIStyle {
    fileprivate var rwlock = pthread_rwlock_t()

    private var _border: Border?
    public var border: Border? {
        get {
            pthread_rwlock_rdlock(&rwlock)
            defer {
                pthread_rwlock_unlock(&rwlock)
            }
            return _border
        }
        set {
            pthread_rwlock_wrlock(&rwlock)
            defer {
                pthread_rwlock_unlock(&rwlock)
            }
            _border = newValue
        }
    }
    public var borderRadius: BorderRadius?
    private var _backgroundColor: UIColor?
    public var backgroundColor: UIColor? {
        get {
            pthread_rwlock_rdlock(&rwlock)
            defer {
                pthread_rwlock_unlock(&rwlock)
            }
            return _backgroundColor
        }
        set {
            pthread_rwlock_wrlock(&rwlock)
            defer {
                pthread_rwlock_unlock(&rwlock)
            }
            _backgroundColor = newValue
        }
    }
    public var cornerRadius: CGFloat?
    public var masksToBounds: Bool = false

    public init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    public func applyToView(_ view: UIView) {
        view.backgroundColor = backgroundColor
        if let cornerRadiusView = view as? CornerRadiusView {
            if let borderRadius = borderRadius {
                cornerRadiusView.updateConfig(borderRadius)
            }
            cornerRadiusView.masksToBounds = masksToBounds
        } else if let cornerRadius = cornerRadius {
            view.layer.cornerRadius = cornerRadius
            view.layer.masksToBounds = cornerRadius > 0 || masksToBounds
        } else { // reset
            view.layer.cornerRadius = 0
            view.layer.masksToBounds = false
        }

        StyleRenderManger.render(view, style: self)
    }
}
