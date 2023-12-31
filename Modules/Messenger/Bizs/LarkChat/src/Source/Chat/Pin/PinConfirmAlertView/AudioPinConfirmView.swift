//
//  AudioPinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import UIKit
import Foundation
import LarkAudio
import LarkModel
import LarkContainer
import LarkMessengerInterface
import RxSwift
import UniverseDesignColor
import EENavigator

// MARK: - AudioPinConfirmView
final class AudioPinConfirmView: PinConfirmContainerView {
    var audioView: AudioView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        let audioView = AudioView(frame: .zero)
        audioView.colorConfig = AudioView.ColorConfig(
            panColorConfig: AudioView.PanColorConfig(
                background: UIColor.ud.primaryOnPrimaryFill,
                readyBorder: nil,
                playBorder: nil
            ),
            stateColorConfig: AudioView.StateColorConfig(
                background: UIColor.ud.N00 & UIColor.ud.N1000,
                foreground: UIColor.ud.N700 & UIColor.ud.N500
            ),
            background: UIColor.ud.N200 & UIColor.ud.N300,
            lineBackground: UIColor.ud.N700.withAlphaComponent(0.3),
            processLineBackground: UIColor.ud.N700,
            timeLabelText: UIColor.ud.N700,
            invalidTimeLabelText: nil
        )
        self.addSubview(audioView)
        audioView.snp.makeConstraints { (make) in
            make.top.equalTo(BubbleLayout.commonInset.top)
            make.left.equalTo(BubbleLayout.commonInset.left)
            make.width.equalTo(200)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
        }
        self.audioView = audioView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)
        guard let contentVM = contentVM as? AudioPinConfirmViewModel, let content = contentVM.content else { return }

        self.audioView.newSkin = true
        self.audioView.set(
            key: "",
            time: TimeInterval(content.duration / 1000),
            state: .ready,
            text: "",
            style: .dark,
            isAudioRecognizeFinish: true,
            isValid: true
        )
        // 设置播放/暂停按钮事件
        self.audioView.clickStateBtnAction = { [weak self] in
            contentVM.playOrPauseAudio(in: self?.window)
        }
        // 设置手动拖动进度条事件，process：拖动进度
        self.audioView.panAction = { (state, process) in
            let status: AudioPlayMediatorStatus
            let duration = TimeInterval(content.duration)
            if state != .end {
                // 拖动中暂停播放
                status = .pause(AudioProgress(key: content.key, authToken: content.authToken, current: duration * process / 1000, duration: duration / 1000))
            } else {
                // 停止拖动播放
                status = .playing(AudioProgress(key: content.key, authToken: content.authToken, current: duration * process / 1000, duration: duration / 1000))
            }
            contentVM.audioPlayer?.updateStatus(status)
        }
        // 监听播放进度更新，实时更新UI
        contentVM.audioPlayer?.statusSignal.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (_) in
            self?.updateUI()
        }).disposed(by: contentVM.disposeBag)
    }

    private func updateUI() {
        guard let contentVM = self.alertViewModel as? AudioPinConfirmViewModel, let content = contentVM.content, let audioPlayer = contentVM.audioPlayer else { return }

        var state: AudioView.State = .ready
        switch audioPlayer.status {
        case .default:
            break
        case let .pause(progress):
            if progress.key == content.key {
                state = self.audioView.isDraging ? .draging(progress.current) : .pause(progress.current)
            }
        case let .playing(progress):
            if progress.key == content.key {
                state = .playing(progress.current)
            }
        case let .loading(key):
            if key == content.key {
                state = .loading(0)
            }
        @unknown default:
            break
        }

        self.audioView.set(
            key: content.key,
            time: TimeInterval(content.duration) / 1000,
            state: state,
            text: "",
            style: .dark,
            isAudioRecognizeFinish: true,
            isValid: true
        )
    }
}

// MARK: - AudioPinConfirmViewModel
final class AudioPinConfirmViewModel: PinAlertViewModel, UserResolverWrapper {
    let userResolver: UserResolver
    /// 音频内容
    private(set) var content: AudioContent?
    /// 音频播放中间件
    @ScopedInjectedLazy var audioPlayer: AudioPlayMediator?
    let disposeBag = DisposeBag()

    init?(userResolver: UserResolver, audioMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        self.userResolver = userResolver
        super.init(message: audioMessage, getSenderName: getSenderName)

        guard let content = audioMessage.content as? AudioContent else { return nil }

        self.content = content
    }

    /// 播放/暂停音频
    func playOrPauseAudio(in from: NavigatorFrom?) {
        guard let content, let audioPlayer else { return }

        if audioPlayer.isPlaying(key: content.key) {
            audioPlayer.pausePlayingAudio()
        } else {
            audioPlayer.playAudioWith(keys: [.init(content.key, content.authToken)], downloadFileScene: .chat, from: from)
        }
    }
}
