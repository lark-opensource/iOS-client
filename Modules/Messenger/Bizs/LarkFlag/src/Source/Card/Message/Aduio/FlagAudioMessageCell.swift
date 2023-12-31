//
//  FlagAudioMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import RxSwift
import LarkCore
import SnapKit
import LarkAudio
import LarkMessengerInterface
import LarkFeatureGating
import UniverseDesignColor

// favorite audio 新版本 UI

final class FlagAudioMessageCell: FlagMessageCell {

    override class var identifier: String {
        return FlagAudioMessageViewModel.defaultIdentifier
    }

    private(set) var statusDisposeBag = DisposeBag()

    private(set) var wrapperView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var audioLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 5
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var audioView: AudioView = {
        let view = AudioView(frame: .zero)
        view.colorConfig = AudioView.ColorConfig(
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
        view.processViewBlock = { [weak self] key, callback in
            if let audioViewModel = self?.audioViewModel,
                let audioContent = audioViewModel.messageContent,
                key == audioContent.key,
                let waves = audioViewModel.audioWaves,
                !waves.isEmpty {
                let processView = AudioProcessView(duration: TimeInterval(audioContent.duration / 1000), waves: waves)
                callback(processView)
            }
        }

        view.clickStateBtnAction = { [weak self] in
            self?.audioViewModel?.playOrPauseAudio(in: self?.window)
        }
        view.panAction = { [weak self] (state, process) in
            if state == .start { /*ChatTracker.trackAudioPlayDrag()*/ }
            guard let contentVM = self?.audioViewModel,
                let content = contentVM.messageContent else {
                    return
            }
            var status: AudioPlayMediatorStatus
            if state != .end {
                // 拖动中暂停播放
                status = .pause(AudioProgress(
                    key: content.key,
                    authToken: content.authToken,
                    current: TimeInterval(content.duration) * process / 1000,
                    duration: TimeInterval(content.duration) / 1000)
                )
            } else {
                // 停止拖动播放
                status = .playing(AudioProgress(
                    key: content.key,
                    authToken: content.authToken,
                    current: TimeInterval(content.duration) * process / 1000,
                    duration: TimeInterval(content.duration) / 1000)
                )
            }
            contentVM.updateStatus(status)
        }
        return view
    }()

    var state: FlagAudioStatus = .ready {
        didSet {
            self.updateUI()
        }
    }

    var audioViewModel: FlagAudioMessageViewModel? {
        return self.viewModel as? FlagAudioMessageViewModel
    }

    private weak var rightConstraint: SnapKit.Constraint?

    override public func setupUI() {
        super.setupUI()
        self.contentWraper.addSubview(self.wrapperView)
        self.wrapperView.addSubview(self.audioView)
        self.wrapperView.addSubview(self.audioLabel)
        self.wrapperView.snp.makeConstraints { (maker) in
            maker.top.equalTo(nameLabel.snp.bottom).offset(4)
            maker.left.bottom.equalToSuperview()
            self.rightConstraint = maker.right.greaterThanOrEqualToSuperview().constraint
            maker.right.lessThanOrEqualToSuperview()
        }
        self.audioView.snp.makeConstraints { (maker) in
            maker.left.bottom.equalToSuperview()
            maker.right.equalToSuperview()
            maker.top.equalTo(self.audioLabel.snp.bottom)
        }
        self.audioLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(12)
            maker.left.equalToSuperview().offset(12)
            maker.right.equalToSuperview().offset(-12)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let audioViewModel = self.audioViewModel else { return }

        statusDisposeBag = DisposeBag()
        audioViewModel.audioPlayStatusSignal()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (status) in
                self?.state = status
            })
            .disposed(by: statusDisposeBag)

        self.state = audioViewModel.audioPlayStatus()
    }

    func updateUI() {
        guard let audioViewModel = self.audioViewModel,
            let audioContent = audioViewModel.messageContent else { return }

        var state: AudioView.State = .ready
        switch self.state {
        case .ready:
            break
        case .playing(let current):
            state = .playing(current)
        case .pause(let current):
            if self.audioView.isDraging {
                state = .draging(current)
            } else {
                state = .pause(current)
            }
        }

        let time = TimeInterval(audioContent.duration) / 1000
        let audioLevel = AudioLevel.level(time: time)
        let audioText = audioContent.showVoiceText
        self.audioLabel.text = audioText
        if audioText.isEmpty {
            self.audioLabel.isHidden = true
            self.audioView.snp.remakeConstraints { (maker) in
                maker.left.bottom.equalToSuperview()
                maker.right.equalToSuperview()
                maker.top.equalToSuperview()
            }
        } else {
            self.audioLabel.isHidden = false
            self.audioView.snp.remakeConstraints { (maker) in
                maker.left.bottom.equalToSuperview()
                maker.right.equalToSuperview()
                maker.top.equalTo(self.audioLabel.snp.bottom)
            }
        }
        self.wrapperView.backgroundColor = self.audioView.backgroundColor
        self.audioView.set(
            key: audioContent.key,
            time: TimeInterval(audioContent.duration) / 1000,
            state: state,
            text: "",
            style: .dark,
            isAudioRecognizeFinish: true,
            isValid: true)
        self.rightConstraint?.update(offset: -20 * (AudioLevel.levelCount() - audioLevel.levelValue()))
    }

    override func willDisplay() {
        super.willDisplay()
        self.audioViewModel?.downloadAudioIfNeeded()
    }
}
