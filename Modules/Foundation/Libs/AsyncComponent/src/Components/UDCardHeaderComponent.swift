//
//  UDCardHeaderComponent.swift
//  AsyncComponent
//
//  Created by zhaojiachen on 2021/9/15.
//

import Foundation
import UniverseDesignCardHeader

public final class UDCardHeaderComponentProps: ASComponentProps {
    public var colorHue: UDCardHeaderHue = UDCardHeaderHue.neural
    public var layoutType: UDCardHeader.UDCardLayoutType = .normal
}

public final class UDCardHeaderComponent<C: Context>: ASComponent<UDCardHeaderComponentProps, EmptyState, UDCardHeader, C> {

    public override func create(_ rect: CGRect) -> UDCardHeader {
        return UDCardHeader(colorHue: props.colorHue, layoutType: props.layoutType)
    }

    public override func update(view: UDCardHeader) {
        super.update(view: view)
        view.colorHue = props.colorHue
        view.layoutType = props.layoutType
    }
}
