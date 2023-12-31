//
//  TappedComponent.swift
//  Moment
//
//  Created by zc09v on 2021/1/14.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessageCore

final class TappedComponentProps: ASComponentProps {
    public var onClicked: (() -> Void)?
}

final class TappedComponent<C: ComponentContext>: ASComponent<TappedComponentProps, EmptyState, TappedView, C> {
    public override func update(view: TappedView) {
        super.update(view: view)
        if let tapped = self.props.onClicked {
            view.initEvent(needLongPress: false)
            view.onTapped = { _ in
                tapped()
            }
        } else {
            view.deinitEvent()
        }
    }
}
