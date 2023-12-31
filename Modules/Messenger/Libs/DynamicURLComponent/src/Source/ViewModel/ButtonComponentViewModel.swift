//
//  ButtonComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import EENavigator
import ByteWebImage
import TangramService
import LKCommonsLogging
import TangramComponent
import TangramUIComponent
import UniverseDesignButton

public final class ButtonComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(ButtonComponentViewModel.self, category: "DynamicURLComponent.ButtonComponentViewModel")

    private lazy var _component: UDButtonComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let button = property?.button ?? .init()
        let props = buildComponentProps(stateID: stateID, componentID: componentID, property: button, style: style)
        _component = UDButtonComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        scale(renderStyle)
        return renderStyle
    }

    private func buildComponentProps(stateID: String,
                                     componentID: String,
                                     property: Basic_V1_URLPreviewComponent.ButtonProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UDButtonComponentProps {
        let props = UDButtonComponentProps()
        props.isEnabled = !property.isDisable
        props.title = property.text
        let actions = self.entity.previewBody?.states[stateID]?.actions ?? [:]
        if let action = actions[property.actionID] {
            props.onTap.update { [weak props, weak self] in
                guard let self = self else { return }
                props?.isLoading = true
                self.ability.updatePreview(component: self.component)
                ComponentActionRegistry.handleAction(
                    entity: self.entity,
                    action: action,
                    actionID: property.actionID,
                    dependency: self.dependency,
                    completion: { [weak self] _ in
                        guard let self = self else { return }
                        props?.isLoading = false
                        self.ability.updatePreview(component: self.component)
                    }
                )
                URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .button, componentID: componentID)
            }
        } else {
            props.onTap.value = nil
            props.isLoading = false
        }
        // 优先级：UDIcon > ImageSet
        if property.hasUdIcon, let image = property.udIcon.unicodeImage ?? property.udIcon.udImage {
            props.setImage.update { button in
                button.setImage(image, for: .normal)
            }
        } else if property.hasIcon {
            props.setImage.update { [weak self] button in
                let item = ImageItemSet.transform(imageSet: property.icon)
                let key = item.generateImageMessageKey(forceOrigin: false)
                let isOrigin = item.isOriginKey(key: key)
                button.bt.setLarkImage(
                    with: .default(key: key),
                    for: .normal,
                    trackStart: {
                        return TrackInfo(scene: .Chat, isOrigin: isOrigin, fromType: .urlPreview)
                    },
                    completion: { [weak self] result in
                        if case .failure = result {
                            Self.logger.error("setImage error: \(self?.entity.previewID) -> \(key)")
                        }
                    }
                )
            }
        }
        var semanticContentAttribute = UISemanticContentAttribute.unspecified
        if property.hasDirection {
            semanticContentAttribute = (property.direction == .ltr ? .forceLeftToRight : .forceRightToLeft)
        }
        let config = UDButtonComponentProps.buttonConfig(font: style.tcFont,
                                                         borderColor: style.tcBorderColor,
                                                         backgroundColor: style.tcBackgroundColor,
                                                         textColor: style.tcTextColor,
                                                         semanticContentAttribute: semanticContentAttribute)
        props.config.value = config
        return props
    }
}

extension UDButtonComponentProps {
    static func buttonConfig(font: UIFont?,
                             borderColor: UIColor?,
                             backgroundColor: UIColor?,
                             textColor: UIColor?,
                             semanticContentAttribute: UISemanticContentAttribute) -> UDButtonUIConifg {
        let font = font ?? UIFont.ud.body2
        let color = UDButtonUIConifg.ThemeColor(borderColor: borderColor ?? UIColor.clear,
                                                backgroundColor: backgroundColor ?? .clear,
                                                textColor: textColor ?? UIColor.ud.N00)
        let middleType = UDButtonUIConifg.ButtonType.middle
        let iconSize = UDButtonComponentProps.defaultIconSize
        let buttonType = UDButtonUIConifg.ButtonType.custom(type: (size: middleType.size(),
                                                                   inset: middleType.edgeInsets(),
                                                                   font: font,
                                                                   iconSize: CGSize(width: iconSize, height: iconSize)))
        let config = UDButtonUIConifg(normalColor: color,
                                      pressedColor: color,
                                      disableColor: color,
                                      loadingColor: color,
                                      loadingIconColor: textColor,
                                      type: buttonType,
                                      radiusStyle: .square,
                                      semanticContentAttribute: semanticContentAttribute)
        return config
    }
}
