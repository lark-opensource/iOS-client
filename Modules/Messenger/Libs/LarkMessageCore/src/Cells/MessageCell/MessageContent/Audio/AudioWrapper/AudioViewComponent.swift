//
//  AudioViewComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/12.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkModel
import LarkAudio

public final class AudioViewComponent<C: AudioViewWrapperComponentContext>: ASComponent<AudioViewWrapperComponentProps, EmptyState, AudioView, C> {

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        // 20: button height, 6: 3top,3bottom
        return CGSize(width: min(props.minLineWidth, props.contentPreferMaxWidth),
                      height: 20 + 6 + props.audioViewInset.top + props.audioViewInset.bottom)
    }

    public override func create(_ rect: CGRect) -> AudioView {
        let view = AudioView(frame: .zero)
        update(view: view)
        return view
    }

    public override func update(view: AudioView) {
        view.newSkin = true
        // AudioView自己会修改背景色，不能调用Super，否则component style会修改背景色
        // super.update(view: view)
        guard let message = props.message, let content = message.content as? AudioContent else { return }
        // 进度条
        view.processViewBlock = { [weak self] _, callback in
            guard let `self` = self else { return }
            if let waves = self.props.audioWaves,
                !waves.isEmpty {
                let processView = AudioProcessView(duration: self.props.duration, waves: waves)
                callback(processView)
            }
        }
        // 点击
        view.clickStateBtnAction = props.delegate?.audioViewTapAction
        // 拖拽
        let audioViewPanAction = props.delegate?.audioViewPanAction
        view.panAction = { [weak view] (state, process) in
            if let audioView = view,
                let audioViewPanAction = audioViewPanAction {
                audioViewPanAction(audioView, state, process)
            }
        }

        var state: AudioView.State = .ready
        if let playingState = props.playingState {
            switch playingState {
            case let .playing(progress):
                state = .playing(progress.current)
            case let .pause(progress):
                state = .pause(progress.current)
            case .loading:
                state = .loading(0)
            case .default:
                break
            }
        }

        view.colorConfig = props.colorConfig

        // 如果判断 audio view 正在拖动中，则不设置状态
        if view.isDraging {
            return
        }
        view.set(
            key: content.key,
            time: props.duration,
            state: state,
            text: "", // 没有传文字，语音转文字自己实现component
            style: props.style,
            edgeInset: props.audioViewInset,
            minLineWidth: props.minLineWidth,
            isAudioRecognizeFinish: true,
            isValid: !props.isFileDeleted)
    }
}
