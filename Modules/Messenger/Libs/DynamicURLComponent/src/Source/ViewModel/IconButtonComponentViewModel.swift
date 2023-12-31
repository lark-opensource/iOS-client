//
//  IconButtonComponentViewModel.swift
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

public final class IconButtonComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(IconButtonComponentViewModel.self, category: "DynamicURLComponent.IconButtonComponentViewModel")

    private lazy var _component: UIImageViewComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let iconButton = property?.iconButton ?? .init()
        let props = buildComponentProps(stateID: stateID, componentID: componentID, property: iconButton, style: style)
        _component = UIImageViewComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        scale(renderStyle)
        return renderStyle
    }

    private func buildComponentProps(stateID: String,
                                     componentID: String,
                                     property: Basic_V1_URLPreviewComponent.IconButtonProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UIImageViewComponentProps {
        let props = UIImageViewComponentProps()
        // 优先级：UDIcon > ImageSet
        if property.hasUdIcon, let image = property.udIcon.unicodeImage ?? property.udIcon.udImage {
            props.setImage.update { view, completion in
                view.image = image
                completion(image, nil)
            }
        } else {
            props.setImage.update { view, completion in
                let key = ImageItemSet.transform(imageSet: property.icon).generateImageMessageKey(forceOrigin: false)
                view.bt.setLarkImage(
                    with: .default(key: key),
                    trackStart: {
                        return TrackInfo(scene: .Chat, fromType: .urlPreview)
                    },
                    completion: { [weak self, weak view] res in
                        guard let self = self else { return }
                        switch res {
                        case .success(let imageRes):
                            if let iconColor = style.tcTextColor, let image = imageRes.image {
                                view?.setImage(image, tintColor: iconColor, completion: { completion($0, nil) })
                            } else {
                                completion(imageRes.image, nil)
                            }
                        case .failure(let error):
                            completion(nil, error)
                            Self.logger.error("setImage error: \(self.entity.previewID) -> \(key)")
                        }
                    }
                )
            }
        }
        let actions = self.entity.previewBody?.states[stateID]?.actions ?? [:]
        if let action = actions[property.actionID] {
            props.onTap.update { [weak self] in
                guard let self = self else { return }
                ComponentActionRegistry.handleAction(entity: self.entity,
                                                     action: action,
                                                     actionID: property.actionID,
                                                     dependency: self.dependency)
                URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .button, componentID: componentID)
            }
        } else {
            props.onTap.value = nil
        }
        return props
    }
}
