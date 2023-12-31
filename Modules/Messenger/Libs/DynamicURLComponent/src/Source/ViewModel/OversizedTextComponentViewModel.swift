//
//  OversizedTextComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/1/7.
//

import UIKit
import Foundation
import RustPB
import TangramComponent
import TangramUIComponent

public final class OversizedTextComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: UILabelComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let oversizedText = property?.oversizedText ?? .init()
        let props = buildComponentProps(stateID: stateID,
                                        componentID: componentID,
                                        property: oversizedText,
                                        style: style)
        _component = UILabelComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(stateID: String,
                                     componentID: String,
                                     property: Basic_V1_URLPreviewComponent.OversizedTextProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UILabelComponentProps {
        let props = UILabelComponentProps()
        props.text = property.text
        switch property.fontWeight {
        case .regular: props.font = UIFont.systemFont(ofSize: CGFloat(property.fontSize))
        case .semiBold: props.font = UIFont.systemFont(ofSize: CGFloat(property.fontSize), weight: .semibold)
        @unknown default:
            assertionFailure("unknown fontWeight")
        }
        if let textColor = style.tcTextColor {
            props.textColor = textColor
        }
        props.numberOfLines = Int(property.numberOfLines)
        // 使用系统默认
        props.lineSpacing = 0
        return props
    }
}
