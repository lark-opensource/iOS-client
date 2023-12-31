//
//  LinearLayoutComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import UIKit
import Foundation
import RustPB
import TangramComponent
import TangramUIComponent

public final class LinearLayoutComponentViewModel: LayoutComponentBaseViewModel {
    private var _component: LinearLayoutComponent!
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        layoutStyle: LayoutComponentStyle) {
        let linearLayout = property?.linearLayout ?? .init()
        let props = buildComponentProps(property: linearLayout)
        _component = LinearLayoutComponent(children: [], props: props, style: layoutStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.LinearLayoutProperty) -> LinearLayoutComponentProps {
        var props = LinearLayoutComponentProps()
        props.orientation = property.orientation.tcOrientation
        props.spacing = CGFloat(property.spacing)
        props.wrapWidth = CGFloat(property.wrapWidth)
        props.padding = property.tcPadding
        props.justify = property.mainAxisJustify.tcJustify
        props.align = property.crossAxisAlign.tcAlign
        return props
    }
}

extension Basic_V1_URLPreviewComponent.LinearLayoutProperty {
    var tcPadding: Padding {
        if hasSidePadding {
            return .init(top: CGFloat(sidePadding.top),
                         right: CGFloat(sidePadding.right),
                         bottom: CGFloat(sidePadding.bottom),
                         left: CGFloat(sidePadding.left))
        }
        return .init(padding: CGFloat(padding))
    }
}
