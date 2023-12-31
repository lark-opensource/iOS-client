//
//  LocationContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/23.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import ByteWebImage
import LarkSDKInterface

public final class LocationContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: LocationContentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = ChatLocationViewWrapperComponent<C>.Props()

    lazy var _component: ChatLocationViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? LocationContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        // 对于话题模式，内容的固定宽度为气泡的最大宽度 - contentPadding
        if (vm.context.scene == .newChat || vm.context.scene == .mergeForwardDetail), vm.message.showInThreadModeStyle {
            style.width = CSSValue(cgfloat: vm.contentPreferMaxWidth - 2 * vm.metaModelDependency.contentPadding)
        } else {
            style.width = CSSValue(cgfloat: vm.contentPreferMaxWidth)
        }
        props.name = vm.name
        props.description = vm.description
        props.originSize = vm.originSize
        props.setting = vm.setting
        let image = vm.content.image
        let metrics: [String: String] = [
            "message_id": vm.message.id
        ]
        props.setImageAction = { imageView, completion in
            let imageSet = ImageItemSet.transform(imageSet: image)
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            imageView.bt.setLarkImage(with: .default(key: key),
                                      placeholder: placeholder,
                                      trackStart: {
                                        TrackInfo(biz: .Messenger,
                                                  scene: .Chat,
                                                  fromType: .image,
                                                  metric: metrics)
                                      },
                                      completion: { result in
                                          switch result {
                                          case let .success(imageResult):
                                              completion(imageResult.image, nil)
                                          case let .failure(error):
                                              completion(nil, error)
                                          }
                                      })
        }
        props.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        props.locationTappedCallback = { [weak vm] in
            vm?.viewDidTapped()
        }
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "LocationContent"
        self._component = ChatLocationViewWrapperComponent<C>(props: props, style: style)
    }
}

final class MessageDetailLocationContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: LocationContentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = ChatLocationViewWrapperComponent<C>.Props()

    private lazy var _component: ChatLocationViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? LocationContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        style.width = CSSValue(cgfloat: vm.contentPreferMaxWidth)
        props.name = vm.name
        props.description = vm.description
        props.originSize = vm.originSize
        props.setting = vm.setting
        let image = vm.content.image
        let metrics: [String: String] = [
            "message_id": vm.message.id
        ]
        props.setImageAction = { imageView, completion in
            let imageSet = ImageItemSet.transform(imageSet: image)
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            imageView.bt.setLarkImage(with: .default(key: key),
                                      placeholder: placeholder,
                                      trackStart: {
                                        TrackInfo(biz: .Messenger,
                                                  scene: .Chat,
                                                  fromType: .image,
                                                  metric: metrics)
                                      },
                                      completion: { result in
                                          switch result {
                                          case let .success(imageResult):
                                              completion(imageResult.image, nil)
                                          case let .failure(error):
                                              completion(nil, error)
                                          }
                                      })
        }
        props.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        props.locationTappedCallback = { [weak vm] in
            vm?.viewDidTapped()
        }
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "LocationContent"
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        self._component = ChatLocationViewWrapperComponent<C>(props: props, style: style)
    }
}

final class PinLocationContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: LocationContentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = ChatLocationViewWrapperComponent<C>.Props()

    private lazy var _component: ChatLocationViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? LocationContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        style.width = CSSValue(cgfloat: vm.contentPreferMaxWidth)
        props.name = vm.name
        props.description = vm.description
        props.originSize = vm.originSize
        props.setting = vm.setting
        let image = vm.content.image
        let metrics: [String: String] = [
            "message_id": vm.message.id
        ]
        props.setImageAction = { imageView, completion in
            let imageSet = ImageItemSet.transform(imageSet: image)
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            imageView.bt.setLarkImage(with: .default(key: key),
                                      placeholder: placeholder,
                                      trackStart: {
                                        TrackInfo(biz: .Messenger,
                                                  scene: .Chat,
                                                  fromType: .image,
                                                  metric: metrics)
                                      },
                                      completion: { result in
                                          switch result {
                                          case let .success(imageResult):
                                              completion(imageResult.image, nil)
                                          case let .failure(error):
                                              completion(nil, error)
                                          }
                                      })
        }
        props.locationTappedCallback = { [weak vm] in
            vm?.viewDidTapped()
        }
        props.settingGifLoadConfig = vm.context.userGeneralSettings?.gifLoadConfig
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "LocationContent"
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        self._component = ChatLocationViewWrapperComponent<C>(props: props, style: style)
    }
}
