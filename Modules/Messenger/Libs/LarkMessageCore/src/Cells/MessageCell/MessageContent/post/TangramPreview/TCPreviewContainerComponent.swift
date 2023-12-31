//
//  TCPreviewContainerComponent.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2022/6/29.
//

import UIKit
import Foundation
import AsyncComponent
import TangramComponent

public extension TCPreviewContainerComponent {
    final class Props: ASComponentProps {
        var subComponents: [ComponentWithContext<C>] = []
    }
}

public final class TCPreviewContainerComponent<C: AsyncComponent.Context>: ASComponent<TCPreviewContainerComponent.Props, EmptyState, UIView, C> {
    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        setSubComponents(props.subComponents)
    }

    public override func willReceiveProps(_ old: TCPreviewContainerComponent.Props, _ new: TCPreviewContainerComponent.Props) -> Bool {
        self.style.flexDirection = .column
        setSubComponents(new.subComponents)
        return true
    }
}
