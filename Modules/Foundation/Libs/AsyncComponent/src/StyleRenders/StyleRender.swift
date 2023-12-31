//
//  StyleRender.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/6/20.
//

import UIKit
import Foundation
import UniverseDesignTheme

public struct BorderEdge {
    public enum BorderStyle: Int {
        case none
        case solid
    }

    public var width: CGFloat
    public var color: UIColor = .black
    public var style: BorderStyle

    public init(width: CGFloat = 0, color: UIColor = .black, style: BorderStyle = .solid) {
        self.width = width
        self.color = color
        self.style = style
    }
}

public struct Border {
    public var top: BorderEdge
    public var right: BorderEdge
    public var bottom: BorderEdge
    public var left: BorderEdge

    public var edges: [BorderEdge] {
        return [top, right, bottom, left]
    }

    public init(_ top: BorderEdge, _ right: BorderEdge? = nil, _ bottom: BorderEdge? = nil, _ left: BorderEdge? = nil) {
        self.top = top
        self.right = right ?? top
        self.bottom = bottom ?? top
        self.left = left ?? top
    }
}

protocol StyleRender {
    static func render(_ view: UIView, style: ASComponentUIStyle)
}

struct StyleRenderManger {
    static var renders: [StyleRender.Type] = [
        BorderStyleRender.self
    ]

    static func render(_ view: UIView, style: ASComponentUIStyle) {
        for render in renders {
            render.render(view, style: style)
        }
    }
}

struct BorderStyleRender: StyleRender {
    static func render(_ view: UIView, style: ASComponentUIStyle) {
        /// TODO: @qhy，如果DarkMode支持判断哪个view是用来做TraitObserver的，下方可以使用 view.asRootView做
        var style = style
        let border = style.border
        if border?.top.style == BorderEdge.BorderStyle.none {
            view.layer.borderWidth = 0
        } else {
            view.layer.borderWidth = border?.top.width ?? 0
            view.layer.borderColor = (border?.top.color ?? UIColor.clear)?.cgColor
        }
    }
}
