//
//  VoiceCommentViewV2.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/8/27.
//  Copyright © 2019 bytedance. All rights reserved.
// swiftlint:disable

import Foundation
import RxSwift
import RxRelay
import SnapKit
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignDialog

class VoiceCommentViewV2: UIView {

    private(set) lazy var selectLanguageButton: UIButton = UIButton()
    private(set) lazy var currentLanauageLabel: UILabel = UILabel()
    private(set) lazy var tipsView: UILabel = UILabel()
    private(set) lazy var voiceImageView: UIImageView = UIImageView()
    private(set) lazy var deleteButton: UIButton = UIButton()
    private(set) lazy var sendButton: UIButton = UIButton()
    private let recordingLottie = AnimationViews.recording!

    // 语音按钮的手势
    private lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressVoiceButton(_:)))
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapVoiceButton(_:)))

    // 用来处理隐藏和展示 发送/删除 按钮的动画
    private lazy var showConstraints: [Constraint] = []
    private lazy var hideConstraints: [Constraint] = []

    // 需要做动画的按钮
    private lazy var animatedButtons: [UIButton] = [deleteButton, sendButton]

    /// 录音按钮是否在选中
    private(set) var isVoiceButtonOn = BehaviorRelay<Bool>(value: false)

    private let disposeBag = DisposeBag()

    // 这里用来做埋点
    weak var atInputTextView: AtInputTextView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupSubviews()
        bind()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectLanguageButtonTitle(_ title: String) {
        updateSelectLanguageButton(title)
    }

    func setCurrentLanguageLabel(_ title: String) {
        currentLanauageLabel.text = title
    }

    func reset() {
        isVoiceButtonOn.accept(false)
        hideRecordingLottie()
        hideDeleteAndSendButton(animated: true)
    }
}

extension VoiceCommentViewV2 {
    private func setupSubviews() {

        backgroundColor = UIColor.ud.N00

        let triangleIcon = UIImage.docs.drawEquilateralTriangle(with: UIColor.ud.N500.cgColor)
        selectLanguageButton.setImage(triangleIcon, for: .normal)
        selectLanguageButton.setImage(triangleIcon, for: .selected)
        selectLanguageButton.setTitleColor(UIColor.ud.N600, for: .normal)
        selectLanguageButton.titleLabel?.font = .systemFont(ofSize: 14)

        currentLanauageLabel.textAlignment = .center
        currentLanauageLabel.font = .systemFont(ofSize: 14)
        currentLanauageLabel.textColor = UIColor.ud.N600
        currentLanauageLabel.isHidden = true

        tipsView.text = BundleI18n.SKResource.LarkCCM_Docs_Comment_HoldtoDictate
        tipsView.textAlignment = .center
        tipsView.textColor = UIColor.ud.N600
        tipsView.font = .systemFont(ofSize: 14)

        let inset: CGFloat = 24.0
        let imageEdgeInsets: UIEdgeInsets = .init(top: inset, left: inset, bottom: inset, right: inset)

        let buttonSize = CGSize(width: 72, height: 72)

        let voicePlayIcon = BundleResources.SKResource.Common.Global.icon_global_voice_nor
            .withRenderingMode(.alwaysTemplate)
            .resizableImage(withCapInsets: imageEdgeInsets)
        let voicePauseIcon = BundleResources.SKResource.Common.Global.icon_global_pause_nor
            .withRenderingMode(.alwaysTemplate)
            .resizableImage(withCapInsets: imageEdgeInsets)
        voiceImageView.contentMode = .center
        voiceImageView.image = voicePlayIcon
        voiceImageView.tintColor = UIColor.ud.N00.nonDynamic
        voiceImageView.backgroundColor = UIColor.ud.colorfulBlue.nonDynamic
        voiceImageView.layer.cornerRadius = buttonSize.width / 2.0

        isVoiceButtonOn
            .skip(1)
            .bind { [weak self] (isOn) in
                if isOn {
                    self?.voiceImageView.image = voicePauseIcon
                } else {
                    self?.voiceImageView.image = voicePlayIcon
                }
            }.disposed(by: disposeBag)
        sendButton.setTitle(BundleI18n.SKResource.Doc_Comment_Send, for: .normal)
        sendButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        sendButton.backgroundColor = UIColor.ud.N200
        sendButton.imageEdgeInsets = imageEdgeInsets
        sendButton.layer.cornerRadius = buttonSize.width / 2.0
        sendButton.tintColor = UIColor.ud.colorfulBlue

        deleteButton.setTitle(BundleI18n.SKResource.Doc_Comment_Clear, for: .normal)
        deleteButton.setTitleColor(UIColor.ud.N900, for: .normal)
        deleteButton.backgroundColor = UIColor.ud.N200
        deleteButton.imageEdgeInsets = imageEdgeInsets
        deleteButton.layer.cornerRadius = buttonSize.width / 2.0
        deleteButton.tintColor = UIColor.ud.N600

        recordingLottie.isHidden = true

        addSubview(currentLanauageLabel)
        addSubview(selectLanguageButton)
        addSubview(tipsView)
        addSubview(deleteButton)
        addSubview(sendButton)
        addSubview(recordingLottie)
        addSubview(voiceImageView)
        bringSubviewToFront(voiceImageView)

        //iPad Highlight
        selectLanguageButton.docs.addHighlight(with: UIEdgeInsets(top: -3, left: 3, bottom: -3, right: 3), radius: 4)
        voiceImageView.docs.addStandardLift()
        deleteButton.docs.addStandardLift()
        sendButton.docs.addStandardLift()

        voiceImageView.snp.makeConstraints { (make) in
            make.size.equalTo(buttonSize)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(42)
        }

        sendButton.snp.makeConstraints { (make) in
            make.size.equalTo(buttonSize)
            make.top.equalTo(voiceImageView)

            hideConstraints.append(make.centerX.equalToSuperview().constraint)
            showConstraints.append(make.right.equalTo(-30).constraint)
        }

        deleteButton.snp.makeConstraints { (make) in
            make.size.equalTo(buttonSize)
            make.top.equalTo(voiceImageView)

            hideConstraints.append(make.centerX.equalToSuperview().constraint)
            showConstraints.append(make.left.equalTo(30).constraint)
        }

        tipsView.snp.makeConstraints { (make) in
            make.width.centerX.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalTo(voiceImageView.snp.top).offset(-18)
        }

        selectLanguageButton.snp.makeConstraints { (make) in
            make.top.equalTo(voiceImageView.snp.bottom).offset(22)
            make.height.equalTo(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
        }

        currentLanauageLabel.snp.makeConstraints { (make) in
            make.top.equalTo(selectLanguageButton.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
        }

        recordingLottie.snp.makeConstraints({ (make) in
            make.width.height.equalTo(128)
            make.center.equalTo(voiceImageView.snp.center)
        })

        updateSelectLanguageButton(BundleI18n.SKResource.Doc_Doc_LanguageChineseMandarin)
        hideDeleteAndSendButton(animated: false)
    }

    private func bind() {

        // 设置语音按钮的长按和点按的手势
        voiceImageView.addGestureRecognizer(longPressGesture)
        // 5.16.0 开始不支持点按
//        voiceImageView.addGestureRecognizer(tapGesture)
        voiceImageView.isUserInteractionEnabled = true

        // 设置点击按钮
        isVoiceButtonOn
            .skip(1)
            .bind { [weak self] (isOn) in
                if isOn {
                    self?.showRecordingLottie()
                    self?.hideDeleteAndSendButton(animated: true)
                    self?.selectLanguageButton.isHidden = true
                    // UI 临时不要这个 label，以后可能用，先留着吧
                    // self?.currentLanauageLabel.isHidden = false
                    self?.tipsView.isHidden = true
                } else {
                    self?.hideRecordingLottie()
                    self?.showDeleteAndSendButton(animated: true)
                    self?.selectLanguageButton.isHidden = false
                    // UI 临时不要这个 label，以后可能用，先留着吧
                    // self?.currentLanauageLabel.isHidden = true
                    self?.tipsView.isHidden = false
                }
            }.disposed(by: disposeBag)
    }

    @objc
    private func longPressVoiceButton(_ gesture: UILongPressGestureRecognizer) {
        let state = gesture.state
        
        if checkIsVCRuning() {
            if state == .began {
                notifyIsVCRuning() // 在视频会议中无法进行语音输入，与IM模块保持一致，弹提示框
            }
            return
        }
        
        switch state {
        case .began:
            isVoiceButtonOn.accept(true)
            track(isTap: false)
        case .changed:
            break
        case .ended:
            isVoiceButtonOn.accept(false)
        default:
            break
        }
    }

    @objc
    private func tapVoiceButton(_ gesture: UITapGestureRecognizer) {
        
        if checkIsVCRuning() {
            notifyIsVCRuning() // 在视频会议中无法进行语音输入，与IM模块保持一致，弹提示框
            return
        }
        
        if isVoiceButtonOn.value == false {
            track(isTap: true)
        }
        isVoiceButtonOn.accept(!isVoiceButtonOn.value)
    }

    private func track(isTap: Bool) {
        if let atInputTextView = atInputTextView {
            let mode = isTap ? "click" : "press"
            CommentTracker.log(.record_audiocomment, atInputTextView: atInputTextView, extraInfo: ["mode": mode])
        }
    }

    func showDeleteAndSendButton(animated: Bool) {
        // 把 delete/send button 弹出去
        hideConstraints.forEach { $0.deactivate() }
        showConstraints.forEach { $0.activate() }

        animatedButtons.forEach { $0.alpha = 1 }

        let duration = animated ? 0.3 : 0
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }

    func hideDeleteAndSendButton(animated: Bool) {
        // 把 delelte/send button 收回来
        showConstraints.forEach { $0.deactivate() }
        hideConstraints.forEach { $0.activate() }

        animatedButtons.forEach { $0.alpha = 0.5 }

        let duration = animated ? 0.3 : 0
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }

    private func showRecordingLottie() {
        recordingLottie.isHidden = false
        recordingLottie.play()
    }

    private func hideRecordingLottie() {
        recordingLottie.isHidden = true
        recordingLottie.stop()
    }

    private func updateSelectLanguageButton(_ title: String) {

        selectLanguageButton.setTitle(title, for: .normal)

        if let imageWidth = selectLanguageButton.imageView?.image?.size.width,
            let titleWidth = selectLanguageButton.titleLabel?.bounds.size.width {

            let titleOffset = imageWidth + 4.0
            let imageOffset = titleWidth + 4.0
            selectLanguageButton.titleEdgeInsets = UIEdgeInsets(top: 0,
                                                                left: -titleOffset,
                                                                bottom: 0,
                                                                right: titleOffset)
            selectLanguageButton.imageEdgeInsets = UIEdgeInsets(top: 0,
                                                                left: imageOffset,
                                                                bottom: 0,
                                                                right: -imageOffset)
        }

    }
    
    /// 是否在视频会议中
    private func checkIsVCRuning() -> Bool {
        let isVCRuning = (HostAppBridge.shared.call(GetVCRuningStatusService()) as? Bool) ?? false
        DocsLogger.info("VideoConference is running == \(isVCRuning)")
        return isVCRuning
    }
    
    /// 弹出提示框：在视频会议中
    private func notifyIsVCRuning() {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_VC_AlreadyInCall_Dialog)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Ok, dismissCheck: { true })
        let selfRootVC = window?.rootViewController
        let topMostVC = UIViewController.docs.topMost(of: selfRootVC)
        topMostVC?.present(dialog, animated: true)
        DocsLogger.info("VideoConference is running now, present alert")
    }
}
