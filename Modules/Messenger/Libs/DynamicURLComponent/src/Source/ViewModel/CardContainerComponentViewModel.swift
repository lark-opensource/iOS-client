//
//  CardContainerComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/9/18.
//

import Foundation
import RustPB
import TangramComponent
import TangramUIComponent
import UniverseDesignCardHeader

public final class CardContainerComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: CardContainerComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let cardContainer = property?.cardContainer ?? .init()
        let props = buildComponentProps(property: cardContainer, style: style)
        _component = CardContainerComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.CardContainerProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> CardContainerComponentProps {
        let props = CardContainerComponentProps()
        if let baseColor = style.tcBackgroundColor, let maskColor = property.maskColor.color {
            props.colorHue = UDCardHeaderHue(color: baseColor, maskColor: maskColor)
        }
        return props
    }
}
