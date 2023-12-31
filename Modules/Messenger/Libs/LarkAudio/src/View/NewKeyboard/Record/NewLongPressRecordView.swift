//
//  AudioLongPressRecordView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/29.
//

import UIKit
import Foundation
import UniverseDesignToast
import UniverseDesignColor
import LarkSDKInterface
import LKCommonsLogging
import EENavigator
import LarkAlertController
import LarkSendMessage
import LarkContainer
import UniverseDesignIcon

final class NewRecordAudioGestureKeyboard: UIView, UserResolverWrapper {
    fileprivate static let logger = Logger.log(NewRecordAudioGestureKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let viewModel: NewRecordViewModel

    private weak var delegate: RecordAudioGestureKeyboardDelegate?
    private var gesture: UILongPressGestureRecognizer

    private var recordLengthLimit: TimeInterval = 5 * 60

    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()
    private var tipLabel = UILabel()
    private var isInvokeEnd: Bool = false

    private var animationHelper = RecordAnimationHelper()

    fileprivate var readyToCancel: Bool = false {
        didSet {
            if oldValue == readyToCancel { return }
            if readyToCancel {
                self.gestureView.backgroundColor = UDColor.bgBody
                self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.functionInfoContentDefault)
                tipLabel.isHidden = true
            } else {
                self.gestureView.backgroundColor = UDColor.functionInfoContentPressed
                self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                tipLabel.isHidden = false
            }
        }
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: NewRecordViewModel, gesture: UILongPressGestureRecognizer, delegate: RecordAudioGestureKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.gesture = gesture
        self.delegate = delegate
        super.init(frame: .zero)
        viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            self.setupViews()
            self.layoutIfNeeded()
            self.startAudioRecord()
        }
    }

    private func setupViews() {
        self.backgroundColor = UIColor.clear
        guard let view = self.gesture.view else {
            return
        }
        let iconRect = view.convert(view.bounds, to: self)

        delegate?.addLongGestureView(view: gestureView)
        self.gestureView.backgroundColor = UDColor.functionInfoContentPressed
        self.gestureView.layer.cornerRadius = 8
        self.gestureView.layer.masksToBounds = true

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(22)
        }
        self.gesture.addTarget(self, action: #selector(handleGesture(sender:)))
    }

    private func resetKeyboardView() {
        self.removeFromSuperview()
    }

    private func stopAudioRecord() {
        NewRecordAudioGestureKeyboard.logger.info("stop audio record")
        if self.readyToCancel {
            self.viewModel.cancelRecord()
        } else {
            self.viewModel.endRecord()
        }
        self.keyboardFocusBlock?(false)
    }

    private func startAudioRecord() {
        if !(gesture.state == .began || gesture.state == .changed) {
            Self.logger.info("gesture error!!! \(gesture.state)")
            isInvokeEnd = true
        }
        NewRecordAudioGestureKeyboard.logger.info("start audio record")
        self.readyToCancel = false
        self.keyboardFocusBlock?(true)
        NewRecordAudioGestureKeyboard.logger.info("did start audio record")
        self.viewModel.startRecordAudio()
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        NewRecordAudioGestureKeyboard.logger.info(
            "gesture state change",
            additionalData: ["state": AudioTracker.stateDescription(sender.state)]
        )
        switch sender.state {
        case .began:
            break
        case .failed, .cancelled, .ended, .possible:
            self.stopAudioRecord()
        case .changed:
            self.handleGestureMove()
        @unknown default:
            break
        }
    }

    private func handleGestureMove() {
        let point = gesture.location(in: gestureView)
        delegate?.updatePoint(point: point)
        if let displayState = delegate?.animationDisplayState, displayState == .cancel {
            self.readyToCancel = true
        } else {
            readyToCancel = false
        }
    }
}

extension NewRecordAudioGestureKeyboard: AudioRecordViewModelDelegate {

    func audioRecordFinish(_ audioData: AudioDataInfo) {
        self.delegate?.recordAudioGestureKeyboardSendAudio(audioData: audioData)
        self.resetKeyboardView()
    }

    func audioRecordStartFailed(uploadID: String) {
        // 强制结束手势
        self.gesture.isEnabled = false
        self.gesture.isEnabled = true

        if let window = self.window {
            DispatchQueue.main.async {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
                alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                self.userResolver.navigator.present(alertController, from: window)
            }
        }
        self.delegate?.recordAudioGestureKeyboardRecordCancel()
        self.resetKeyboardView()
    }

    func audioRecordFinish(uploadID: String, duration: TimeInterval) {
        self.delegate?.recordAudioGestureKeyboardSendAudio(uploadID: uploadID, duration: duration)
        self.resetKeyboardView()
    }

    func audioRecordWillStart(uploadID: String) {
        self.delegate?.recordAudioGestureKeyboardRecordStart()
    }

    func audioRecordDidStart(uploadID: String) {
        if isInvokeEnd, userResolver.fg.staticFeatureGatingValue(with: "messenger.old.audio.stop.record") {
            Self.logger.error("gesture error!!!")
            stopAudioRecord()
        }
    }

    func audioRecordDidCancel(uploadID: String) {
        self.delegate?.recordAudioGestureKeyboardRecordCancel()
        self.resetKeyboardView()
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.delegate?.recordAudioGestureKeyboardRecordCancel()
        self.resetKeyboardView()
        if let window = self.window {
            UDToast.showTips(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
        }
    }

    func audioRecordUpdateRecordTime(time: TimeInterval) {
        if time >= self.recordLengthLimit {
            self.stopAudioRecord()
        } else if recordLengthLimit - time <= 10 {
            delegate?.updateRecordTime(str: BundleI18n.LarkAudio.Lark_IM_AudioMsg_RecordingEndsInNums_Text(Int(recordLengthLimit - time)))
        } else {
            delegate?.updateRecordTime(str: NewAudioKeyboardHelper.timeString(time: time))
        }
    }

    func audioRecordUpdateRecordVoice(power: Float) {
        delegate?.updateDecible(decible: power)
    }

    func audioRecordUpdateState(state: AudioState) {
        switch state {
        case .prepare:
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(showProgressState), with: nil, afterDelay: 0.1)
        default:
            NSObject.cancelPreviousPerformRequests(withTarget: self)
        }
    }

    @objc
    private func showProgressState() {
        self.animationHelper.floatView?.processing = true
    }
}
