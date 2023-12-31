//
//  CornerRadiusComponent.swift
//  LarkMessageCore
//
//  Created by 姚启灏 on 2019/10/18.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

public final class CornerRadiusComponent<C: Context>: ASComponent<CornerRadiusComponent.Props, EmptyState, CornerRadiusView, C> {

    public final class Props: ASComponentProps {
        /// 展示边框
        public var showBoder = true
        /// 边框宽度
        public var lineWidth: CGFloat = 1
    }

    public override func update(view: CornerRadiusView) {
        super.update(view: view)
        view.updateLayer(strokeColor: UIColor.ud.N300, lineWidth: props.lineWidth, showBoder: props.showBoder)
    }
}
