//
//  BubbleViewComponent.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/5/18.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import EEAtomic

public final class BubbleViewComponent<C: Context>: ASComponent<BubbleViewComponent.Props, EmptyState, BubbleView, C> {

    final public class Props: ASComponentProps {
        /// 边框颜色
        private var _strokeColor = Atomic<UIColor>(.clear)
        public var strokeColor: UIColor {
            get { return _strokeColor.wrappedValue ?? .clear }
            set { _strokeColor.wrappedValue = newValue }
        }
        /// 背景颜色
        private var _fillColor = Atomic<UIColor>(.clear)
        public var fillColor: UIColor {
            get { return _fillColor.wrappedValue ?? .clear }
            set { _fillColor.wrappedValue = newValue }
        }
        /// 边框宽度
        public var strokeWidth: CGFloat = 1
        public var changeTopLeftRadius = false
        public var changeBottomLeftRadius = false
        public var changeRaiusReverse = false
    }

    public override func update(view: BubbleView) {
        super.update(view: view)
        if props.strokeColor == UIColor.clear {
            view.updateLayer(strokeColor: props.strokeColor, fillColor: props.fillColor, lineWidth: props.strokeWidth)
        } else {
            view.updateLayer(strokeColor: props.strokeColor, fillColor: props.fillColor,
                             lineWidth: props.strokeWidth, showBoder: true)
        }
        if props.changeRaiusReverse {
            view.update(changeTopRightRadius: props.changeTopLeftRadius, changeBottomRightRadius: props.changeBottomLeftRadius)
        } else {
            view.update(changeTopLeftRadius: props.changeTopLeftRadius, changeBottomLeftRadius: props.changeBottomLeftRadius)
        }
    }
}

public final class HighlightFrontBubbleViewComponent<C: Context>: ASComponent<HighlightFrontBubbleViewComponent.Props, EmptyState, HighlightFrontBubbleView, C> {
    final public class Props: ASComponentProps {
        public var fillColor = UIColor.clear
        public var changeTopLeftRadius = false
        public var changeBottomLeftRadius = false
        public var changeRaiusReverse = false
    }

    public override func update(view: HighlightFrontBubbleView) {
        super.update(view: view)
        view.updateLayer(strokeColor: .clear, fillColor: props.fillColor, lineWidth: 0)
        if props.changeRaiusReverse {
            view.update(changeTopRightRadius: props.changeTopLeftRadius, changeBottomRightRadius: props.changeBottomLeftRadius)
        } else {
            view.update(changeTopLeftRadius: props.changeTopLeftRadius, changeBottomLeftRadius: props.changeBottomLeftRadius)
        }
    }
}
