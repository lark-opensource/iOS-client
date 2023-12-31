//
//  AudioFloatingView.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/3/15.
//

import UIKit
import Foundation
import AVFoundation
import Lottie
import MinutesFoundation
import UniverseDesignColor
import LarkMedia
import LarkContainer

class AudioFloatingView: UIView {
    static let viewSize: CGSize = CGSize(width: 170, height: 50)

    private lazy var effectView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.effect = UIBlurEffect(style: .light)
        return view
    }()

    private lazy var loadingPauseView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: BundleResources.Minutes.minutes_audio_floating_pause)
        imageView.isHidden = true
        return imageView
    }()

    private lazy var loadingPlayView: LOTAnimationView = {
        let view: LOTAnimationView
        if let jsonPath = BundleConfig.MinutesBundle.path(
            forResource: "minutes_audio_floating",
            ofType: "json",
            inDirectory: "lottie") {
            view = LOTAnimationView(filePath: jsonPath)
        } else {
            view = LOTAnimationView()
        }
        view.loopAnimation = true
        view.play()
        view.isHidden = true
        return view
    }()

    private lazy var durationLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = "--:--:--"
        label.numberOfLines = 1
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont(name: "DINAlternate-Bold", size: 17)
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(BundleResources.Minutes.minutes_audio_floating_pause_button, for: .normal)
        button.setImage(BundleResources.Minutes.minutes_audio_floating_play_button, for: .selected)
        button.addTarget(self, action: #selector(onClickActionButton(_:)), for: .touchUpInside)
        return button
    }()

    private var tracker: MinutesTracker?

    var onTapViewBlock: ((UserResolver) -> Void)?

    let userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
        
        MinutesLogger.recordFloat.info("audio floating view init")

        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.ud.bgFloatOverlay

        self.layer.cornerRadius = 12
        self.layer.borderWidth = 0.5
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        self.layer.masksToBounds = true

//        addSubview(effectView)
        addSubview(loadingPauseView)
        addSubview(loadingPlayView)
        addSubview(durationLabel)
        addSubview(actionButton)
        layoutSubviewsManually()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAudioFloatingView(_:)))
        self.addGestureRecognizer(tapGestureRecognizer)

        if let someMinutes = MinutesAudioRecorder.shared.minutes {
            self.tracker = MinutesTracker(minutes: someMinutes)
        }

        resetDuration(MinutesAudioRecorder.shared.recordingTime)
        onAudioRecorderStatusChanged(MinutesAudioRecorder.shared.status)
        
        MinutesAudioRecorder.shared.listeners.addListener(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onAudioRecorderStatusChanged(_ audioRecorderStatus: MinutesAudioRecorderStatus) {
        switch audioRecorderStatus {
        case .recording:
            setPlayStyle()
        case .paused:
            setPauseStyle()
        case .idle:
            setIdle()
        }
    }

    private func onAudioRecorderTimeUpdated(_ timeInterval: TimeInterval) {
        DispatchQueue.main.async {
            self.resetDuration(timeInterval)
        }
    }

    private func layoutSubviewsManually() {
//        effectView.snp.makeConstraints { maker in
//            maker.edges.equalToSuperview()
//        }

        durationLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.width.equalTo(75)
        }

        loadingPlayView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.right.equalTo(durationLabel.snp.left)
            maker.width.height.equalTo(38)
        }

        loadingPauseView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.centerX.equalTo(loadingPlayView.snp.centerX)
            maker.width.equalTo(24)
            maker.height.equalTo(6)
        }

        actionButton.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(durationLabel.snp.right)
            maker.width.height.equalTo(32)
        }
    }

    @objc
    private func onClickActionButton(_ sender: UIButton) {
        if MinutesAudioRecorder.shared.interruptionType == .began { return }

        if actionButton.isSelected {
            self.tracker?.tracker(name: .miniView, params: ["action_name": "pause_recording"])
        } else {
            self.tracker?.tracker(name: .miniView, params: ["action_name": "continue_recording"])
        }
        MinutesLogger.recordFloat.info(actionButton.isSelected ? "float pause record" : "float resume record")

        actionButton.isSelected ? MinutesAudioRecorder.shared.pause() : MinutesAudioRecorder.shared.resume()
    }

    @objc
    private func didTapAudioFloatingView(_ gesture: UITapGestureRecognizer) {
        MinutesLogger.recordFloat.info("did tap audio floating view")

        onTapViewBlock?(userResolver)
        self.tracker?.tracker(name: .miniView, params: ["action_name": "expend_miniview"])

        tracker?.tracker(name: .recordingMiniClick, params: ["click": "expand_miniview", "target": "vc_minutes_recording_view"])
    }

    private func setPlayStyle() {
        actionButton.isSelected = true
        loadingPlayView.isHidden = false
        loadingPauseView.isHidden = true

        tracker?.tracker(name: .recordingMiniClick, params: ["click": "continue_recording", "target": "vc_minutes_recording_mini_view"])
    }

    private func setPauseStyle() {
        actionButton.isSelected = false
        loadingPlayView.isHidden = true
        loadingPauseView.isHidden = false

        tracker?.tracker(name: .recordingMiniClick, params: ["click": "pause_recording", "target": "vc_minutes_recording_mini_view"])
    }

    private func setIdle() {
        AudioSuspendable.removeRecordSuspendable()
    }

    private func resetDuration(_ timeInterval: TimeInterval) {
        var duration = Int(timeInterval)
        let hours: Int = duration / 3600
        let hoursString: String = hours > 9 ? "\(hours)" : "0\(hours)"

        let minutes = duration % 3600 / 60
        let minutesString = minutes > 9 ? "\(minutes)" : "0\(minutes)"

        let seconds = duration % 3600 % 60
        let secondsString = seconds > 9 ? "\(seconds)" : "0\(seconds)"

        durationLabel.text = "\(hoursString):\(minutesString):\(secondsString)"
    }
}

extension AudioFloatingView: MinutesAudioRecorderListener {
    func audioRecorderDidChangeStatus(status: MinutesAudioRecorderStatus) {
        onAudioRecorderStatusChanged(status)
    }

    func audioRecorderOpenRecordingSucceed(isForced: Bool) {
        
    }
    
    func audioRecorderTryMideaLockfailed(error: LarkMedia.MediaMutexError, isResume: Bool) {
        let targetView = userResolver.navigator.mainSceneWindow?.fromViewController?.view
        if case let MediaMutexError.occupiedByOther(context) = error {
            if let msg = context.1 {
                DispatchQueue.main.async {
                    MinutesToast.showFailure(with: msg, targetView: targetView)
                }
            }
        } else {
            DispatchQueue.main.async {
                MinutesToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
            }
        }
    }
    
    func audioRecorderTimeUpdate(time: TimeInterval) {
        onAudioRecorderTimeUpdated(time)
    }
}
