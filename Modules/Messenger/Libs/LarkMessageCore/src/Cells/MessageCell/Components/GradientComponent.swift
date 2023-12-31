//
//  GradientComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/14.
//

import UIKit
import Foundation
import AsyncComponent
import LarkUIKit
import EEAtomic

public final class GradientComponent<C: AsyncComponent.Context>: ASComponent<GradientComponent.Props, EmptyState, GradientView, C> {
    public final class Props: ASComponentProps {
        /// 渐变颜色
        private var _colors = Atomic<[UIColor]>([])
        public var colors: [UIColor]? {
            get { return _colors.wrappedValue }
            set { _colors.wrappedValue = newValue }
        }
        /// 渐变的位置（0-1之间）
        public var locations: [CGFloat]?
        /// 渐变方向
        public var direction: GradientView.Direction = .vertical
    }

    public override func update(view: GradientView) {
        super.update(view: view)
        view.colors = props.colors
        view.locations = props.locations
        view.direction = props.direction
    }
}
