//
//  ChatterDSLViewComponent.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/11/29.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor

enum DSLEllipsize {
    case none, start, middle, end
}

final class ChatterDSLViewProps: ASComponentProps {
    init() { }
}

final class ChatterDSLViewComponent: ASComponent<ChatterDSLViewProps, EmptyState, UIView, EmptyContext> {
    override init(props: ChatterDSLViewProps, style: ASComponentStyle, context: EmptyContext? = nil) {
        super.init(props: props, style: style, context: context)
    }
}
