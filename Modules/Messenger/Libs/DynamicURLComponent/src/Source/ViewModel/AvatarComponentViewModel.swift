//
//  AvatarComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import ByteWebImage
import TangramComponent
import TangramUIComponent
import LarkMessengerInterface

public final class AvatarComponentViewModel: RenderComponentBaseViewModel {
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
        let avatar = property?.avatar ?? .init()
        let props = buildComponentProps(property: avatar)
        _component = UIImageViewComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        // avatar支持字体缩放
        scale(renderStyle)
        // 对齐PC & Android：头像默认圆形，不支持配置
//        renderStyle.cornerRadius = renderStyle.cornerRadius.auto()
        return renderStyle
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.AvatarProperty) -> UIImageViewComponentProps {
        let props = UIImageViewComponentProps()
        props.isAvatar = true
        props.setImage.update { view, completion in
            view.bt.setLarkImage(
                with: .avatar(key: property.chatterInfo.avatarKey,
                              entityID: property.chatterInfo.chatterID),
                trackStart: {
                    return TrackInfo(scene: .Chat, fromType: .avatar)
                },
                completion: { res in
                    switch res {
                    case .success(let imageRes): completion(imageRes.image, nil)
                    case .failure(let error): completion(nil, error)
                    }
                }
            )
        }
        props.onTap.update { [weak self] in
            guard let targetVC = self?.dependency.targetVC else { return }
            let body = PersonCardBody(chatterId: property.chatterInfo.chatterID,
                                      fromWhere: .chat,
                                      source: .chat)
            self?.userResolver.navigator.push(body: body, from: targetVC)
        }
        return props
    }
}
