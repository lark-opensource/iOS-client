//
//  CryptoChatAudioContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/18.
//

import Foundation
import AsyncComponent
import LarkMessageBase

public final class CryptoChatAudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: ComponentBinder<C> {
    fileprivate let props = AudioViewWrapperComponentProps()
    fileprivate let style = ASComponentStyle()
    fileprivate lazy var _component: AudioViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: AudioViewWrapperComponent<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatAudioContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.message = vm.message
        props.minLineWidth = vm.audioViewMinwidth
        props.duration = vm.duration
        props.audioWaves = vm.audioWaves
        props.delegate = vm
        props.isDotInside = vm.isDotInside
        props.playingState = vm.stateValue
        props.originText = vm.originText
        props.text = vm.text
        props.hideVoice2Text = vm.hideVoice2Text
        props.isAudioWithText = vm.isAudioWithText
        props.isMe = vm.isMe
        props.audioToTextEnable = vm.audioToTextEnable
        props.showUnReadDot = vm.hasRedDot
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.isLoadingFinished = vm.isLoadingFinished
        props.style = vm.style
        props.hasBoder = vm.hasBoder
        props.hasCorner = vm.hasCorner
        props.audioViewInset = vm.audioViewInset
        props.disableMarginWhenAudioToText = vm.disableMarginWhenAudioToText
        props.isFileDeleted = vm.isFileDeleted
        props.colorConfig = vm.generateColorConfig()
        props.backgroundColor = vm.background
        props.audioWithTextTextColor = vm.audioWithTextTextColor
        props.audioTextColor = vm.audioTextColor
        props.convertStateColor = vm.convertStateColor
        props.convertStateButtonBackground = vm.convertStateButtonBackground
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "AudioContent"
        _component = AudioViewWrapperComponent(props: props, style: style, context: context)
    }
}

public final class CryptoChatMessageDetailAudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: ComponentBinder<C> {
    fileprivate let props = AudioViewWrapperComponentProps()
    fileprivate let style = ASComponentStyle()
    fileprivate lazy var _component: AudioViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: AudioViewWrapperComponent<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatMessageDetailAudioContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.message = vm.message
        props.minLineWidth = vm.audioViewMinwidth
        props.duration = vm.duration
        props.audioWaves = vm.audioWaves
        props.delegate = vm
        props.isDotInside = vm.isDotInside
        props.playingState = vm.stateValue
        props.originText = vm.originText
        props.text = vm.text
        props.hideVoice2Text = vm.hideVoice2Text
        props.isAudioWithText = vm.isAudioWithText
        props.isMe = vm.isMe
        props.audioToTextEnable = vm.audioToTextEnable
        props.showUnReadDot = vm.hasRedDot
        props.hasBoder = vm.hasBoder
        props.hasCorner = vm.hasCorner
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.isLoadingFinished = vm.isLoadingFinished
        props.style = vm.style
        props.audioViewInset = vm.audioViewInset
        props.disableMarginWhenAudioToText = vm.disableMarginWhenAudioToText
        props.isFileDeleted = vm.isFileDeleted
        props.colorConfig = vm.generateColorConfig()
        props.backgroundColor = vm.background
        props.audioWithTextTextColor = vm.audioWithTextTextColor
        props.audioTextColor = vm.audioTextColor
        props.convertStateColor = vm.convertStateColor
        props.convertStateButtonBackground = vm.convertStateButtonBackground
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "AudioContent"
        _component = AudioViewWrapperComponent(props: props, style: style, context: context)
    }
}
