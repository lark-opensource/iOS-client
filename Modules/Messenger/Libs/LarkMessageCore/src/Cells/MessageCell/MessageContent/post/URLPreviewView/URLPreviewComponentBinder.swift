//
//  URLPreviewComponentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/23.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase

final class URLPreviewComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: URLPreviewContext>: ComponentBinder<C> {
    private var props = URLPreviewComponent<C>.Props()
    private lazy var _component: URLPreviewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private let style = ASComponentStyle()

    public override var component: URLPreviewComponent<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? URLPreviewComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.title = vm.message.urlTitle
        props.iconURL = vm.message.iconURL
        props.iconKey = vm.message.iconKey
        props.content = vm.content
        props.coverImageSet = vm.message.coverImageSet
        props.contentMaxWidth = vm.contentMaxWidth
        props.lineColor = vm.lineColor
        props.titleColor = vm.titleColor
        props.contentColor = vm.contentColor
        props.contentTapHandler = { [weak vm] in
            vm?.tapContent()
        }
        props.videoCoverTapHandler = { [weak vm] imageView in
            vm?.tapVideo(cover: imageView)
        }
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = URLPreviewComponent(props: props, style: style, context: context)
    }
}

final class PinUrlPreviewComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: URLPreviewContext>: ComponentBinder<C> {
    private var props = URLPreviewComponent<C>.Props()
    private lazy var _component: URLPreviewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private let style = ASComponentStyle()

    public override var component: URLPreviewComponent<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? URLPreviewComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.title = vm.message.urlTitle
        props.iconURL = vm.message.iconURL
        props.iconKey = vm.message.iconKey
        props.content = vm.content
        props.coverImageSet = vm.message.coverImageSet
        props.contentMaxWidth = vm.contentMaxWidth
        props.lineColor = vm.lineColor
        props.titleColor = vm.titleColor
        props.contentColor = vm.contentColor
        props.needSeperateLine = false
        props.needVideoPreview = false
        props.hasPaddingLeft = true
        props.contentNumberOfLines = 2
        props.contentTapHandler = { [weak vm] in
            vm?.tapContent()
        }
        props.videoCoverTapHandler = { [weak vm] imageView in
            vm?.tapVideo(cover: imageView)
        }
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        style.paddingBottom = 8
        _component = URLPreviewComponent(props: props, style: style, context: context)
    }
}
