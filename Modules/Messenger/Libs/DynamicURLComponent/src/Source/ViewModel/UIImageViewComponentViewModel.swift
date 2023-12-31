//
//  UIImageViewComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import ByteWebImage
import TangramService
import TangramComponent
import LKCommonsLogging
import TangramUIComponent

public final class UIImageViewComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(UIImageViewComponentViewModel.self, category: "DynamicURLComponent.UIImageViewComponentViewModel")

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
        let image = property?.image ?? .init()
        let props = buildComponentProps(property: image, style: style)
        _component = UIImageViewComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.ImageProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UIImageViewComponentProps {
        let props = UIImageViewComponentProps()
        props.contentMode = .scaleAspectFill
        let imageKey = ImageItemSet.transform(imageSet: property.image).getThumbKey()
        // 优先级：UDIcon > ImageSet
        if property.hasUdIcon, let image = property.udIcon.unicodeImage ?? property.udIcon.udImage {
            props.setImage.update { view, completion in
                view.image = image
                completion(image, nil)
            }
        } else if property.hasImage, !imageKey.isEmpty {
            props.setImage.update { [weak self] view, completion in
                view.bt.setLarkImage(with: .default(key: imageKey), trackStart: {
                    return TrackInfo(scene: .Chat, fromType: .urlPreview)
                }, completion: { [weak view, weak self] res in
                    guard let self = self else { return }
                    switch res {
                    case .success(let imageRes):
                        if let color = style.tcTextColor, let image = imageRes.image {
                            view?.setImage(image, tintColor: color, completion: { completion($0, nil) })
                        } else {
                            completion(imageRes.image, nil)
                        }
                    case .failure(let error):
                        completion(nil, error)
                        Self.logger.error("setImage error: \(self.entity.previewID) -> \(imageKey)")
                    }
                })
            }
        } else if property.hasImageURL, !property.imageURL.isEmpty {
            props.setImage.update { [weak self] view, completion in
                view.bt.setLarkImage(with: .default(key: property.imageURL), trackStart: {
                    return TrackInfo(scene: .Chat, fromType: .urlPreview)
                }, completion: { [weak view, weak self] res in
                    guard let self = self else { return }
                    switch res {
                    case .success(let imageRes):
                        if let color = style.tcTextColor, let image = imageRes.image {
                            view?.setImage(image, tintColor: color, completion: { completion($0, nil) })
                        } else {
                            completion(imageRes.image, nil)
                        }
                    case .failure(let error):
                        completion(nil, error)
                        Self.logger.error("setImage error: \(self.entity.previewID) -> \(property.imageURL)")
                    }
                })
            }
        }
        return props
    }
}
