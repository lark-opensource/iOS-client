//
//  AudioContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/10.
//

import Foundation
import LarkAudio
import AsyncComponent
import LarkMessageBase

public class BaseAudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: NewComponentBinder<M, D, C> {
    let audioViewModel: AudioContentViewModel<M, D, C>?
    let audioActionHandler: AudioContentActionHandler<C>?
    // 是否支持连续播放，消息链接化场景不需要连续播放，audioProvider是个必包，需要捕获context，
    // supportAutoPlay不方便配置在VM上
    let supportAutoPlay: Bool

    public init(
        key: String? = nil,
        context: C? = nil,
        audioViewModel: AudioContentViewModel<M, D, C>?,
        audioActionHandler: AudioContentActionHandler<C>?,
        supportAutoPlay: Bool = true
    ) {
        self.audioViewModel = audioViewModel
        self.audioActionHandler = audioActionHandler
        self.supportAutoPlay = supportAutoPlay
        super.init(key: key, context: context, viewModel: audioViewModel, actionHandler: audioActionHandler)
    }
}

// MARK: - AudioViewActionDelegate
extension BaseAudioContentComponentBinder: AudioViewActionDelegate {
    public func audioViewPanAction(_ audioView: LarkAudio.AudioView, _ state: LarkAudio.AudioView.PanState, _ progress: TimeInterval) {
        guard let vm = self.audioViewModel else { return }
        self.audioActionHandler?.audioViewPanAction(
            audioView: audioView,
            state: state,
            progress: progress,
            duration: vm.duration,
            stateValue: vm.stateValue,
            showStatusView: vm.showStatusView,
            shouldPlayContinuously: vm.shouldPlayContinuously,
            audioProvider: { [weak self] in
                guard let self = self else { return [] }
                if self.supportAutoPlay {
                    return self.audioViewModel?.audioProvider() ?? []
                } else if let vm = self.audioViewModel {
                    return [vm]
                }
                return []
            },
            content: vm.content,
            message: vm.message,
            chat: vm.metaModel.getChat()
        )
    }

    public func audioViewTapAction() {
        guard let vm = self.audioViewModel else { return }
        self.audioActionHandler?.audioViewTapAction(
            message: vm.message,
            chat: vm.metaModel.getChat(),
            showStatusView: vm.showStatusView,
            shouldPlayContinuously: vm.shouldPlayContinuously,
            audioProvider: { [weak self] in
                guard let self = self else { return [] }
                if self.supportAutoPlay {
                    return self.audioViewModel?.audioProvider() ?? []
                } else if let vm = self.audioViewModel {
                    return [vm]
                }
                return []
            }
        )
    }
}

public final class AudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: BaseAudioContentComponentBinder<M, D, C> {
    fileprivate let props = AudioViewWrapperComponentProps()
    fileprivate let style = ASComponentStyle()
    fileprivate lazy var _component: AudioViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: AudioViewWrapperComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.audioViewModel else {
            assertionFailure()
            return
        }
        props.message = vm.message
        props.minLineWidth = vm.audioViewMinwidth
        props.duration = vm.duration
        props.audioWaves = vm.audioWaves
        props.delegate = self
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
        props.boderWidth = vm.boderWidth
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
        props.displayRule = vm.displayRule
        props.translateText = vm.translateText
        props.translateMoreActionTapHandler = { [weak vm] view in
            vm?.translateMoreTapHandler(view)
        }
        props.translateFeedBackTapHandler = { [weak vm] in
            vm?.translateFeedBackTapHandler()
        }
        props.lineColor = vm.lineColor
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "AudioContent"
        _component = AudioViewWrapperComponent(props: props, style: style, context: context)
    }
}

public final class ThreadChatAudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: BaseAudioContentComponentBinder<M, D, C> {
    fileprivate let props = AudioViewWrapperComponentProps()
    fileprivate let style = ASComponentStyle()
    fileprivate lazy var _component: AudioViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: AudioViewWrapperComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.audioViewModel else {
            assertionFailure()
            return
        }
        props.message = vm.message
        props.minLineWidth = vm.audioViewMinwidth
        props.duration = vm.duration
        props.audioWaves = vm.audioWaves
        props.delegate = self
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
        props.displayRule = vm.displayRule
        props.translateText = vm.translateText
        props.translateMoreActionTapHandler = { [weak vm] view in
            vm?.translateMoreTapHandler(view)
        }
        props.translateFeedBackTapHandler = { [weak vm] in
            vm?.translateFeedBackTapHandler()
        }
        props.lineColor = vm.lineColor
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "AudioContent"
        _component = AudioViewWrapperComponent(props: props, style: style, context: context)
    }
}

public final class MessageDetailAudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: BaseAudioContentComponentBinder<M, D, C> {
    fileprivate let props = AudioViewWrapperComponentProps()
    fileprivate let style = ASComponentStyle()
    fileprivate lazy var _component: AudioViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: AudioViewWrapperComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.audioViewModel else {
            assertionFailure()
            return
        }
        props.message = vm.message
        props.minLineWidth = vm.audioViewMinwidth
        props.duration = vm.duration
        props.audioWaves = vm.audioWaves
        props.delegate = self
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
        props.displayRule = vm.displayRule
        props.translateText = vm.translateText
        props.translateMoreActionTapHandler = { [weak vm] view in
            vm?.translateMoreTapHandler(view)
        }
        props.translateFeedBackTapHandler = { [weak vm] in
            vm?.translateFeedBackTapHandler()
        }
        props.lineColor = vm.lineColor
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "AudioContent"
        _component = AudioViewWrapperComponent(props: props, style: style, context: context)
    }
}

public final class PinAudioContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: AudioViewWrapperComponentContext & PageContext>: BaseAudioContentComponentBinder<M, D, C> {
    fileprivate let props = AudioViewWrapperComponentProps()
    fileprivate let style = ASComponentStyle()
    fileprivate lazy var _component: AudioViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: AudioViewWrapperComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.audioViewModel else {
            assertionFailure()
            return
        }
        props.message = vm.message
        props.minLineWidth = vm.audioViewMinwidth
        props.duration = vm.duration
        props.audioWaves = vm.audioWaves
        props.delegate = self
        props.isDotInside = vm.isDotInside
        props.playingState = vm.stateValue
        props.hideVoice2Text = vm.hideVoice2Text
        props.isAudioWithText = vm.isAudioWithText
        props.isMe = vm.isMe
        props.audioToTextEnable = vm.audioToTextEnable
        props.showUnReadDot = false
        props.hasBoder = vm.hasBoder
        props.hasCorner = vm.hasCorner
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.isLoadingFinished = vm.isLoadingFinished
        props.style = .dark
        props.audioViewInset = vm.audioViewInset
        props.disableMarginWhenAudioToText = vm.disableMarginWhenAudioToText
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
        style.cornerRadius = 10
        _component = AudioViewWrapperComponent(props: props, style: style, context: context)
    }
}
