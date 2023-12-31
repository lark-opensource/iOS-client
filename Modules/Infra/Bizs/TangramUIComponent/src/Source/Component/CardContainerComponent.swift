//
//  CardContainerComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/9/16.
//

import Foundation
import TangramComponent
import UniverseDesignCardHeader

public final class CardContainerComponentProps: Props {
    public var colorHue: UDCardHeaderHue = .neural
    public var layoutType: UDCardHeader.UDCardLayoutType = .normal

    public init() {}

    public func clone() -> CardContainerComponentProps {
        let clone = CardContainerComponentProps()
        clone.colorHue = colorHue
        clone.layoutType = layoutType
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? CardContainerComponentProps else { return false }
        return old.colorHue.color == colorHue.color &&
            old.colorHue.maskColor == colorHue.maskColor &&
            old.layoutType == layoutType
    }
}

public final class CardContainerComponent<C: Context>: RenderComponent<CardContainerComponentProps, UDCardHeader, C> {
    public override func create(_ rect: CGRect) -> UDCardHeader {
        let card = UDCardHeader(colorHue: props.colorHue, layoutType: props.layoutType)
        card.frame = rect
        return card
    }

    public override func update(_ view: UDCardHeader) {
        super.update(view)
        view.layoutType = props.layoutType
        view.colorHue = props.colorHue
    }
}
