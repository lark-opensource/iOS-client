//
//  ShareContentCodeViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewTracker
import ByteViewMeeting
import UniverseDesignIcon

final class ShareContentCodeViewController: VMViewController<ShareContentCodeViewModel> {
    private let commitButton = LoadableButton(title: I18n.View_G_ConfirmButton)
    private var shareScreenVerifyTextField: ShareScreenVerifyTextField!
    private let descLabel = UILabel()
    private let navBarBottomLine = UIView()
    private let navBar = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()

    // 区分用户是否手动点击关闭按钮，如果是，deinit时就无需处理关闭事件
    // 因为在 iPad 上 fromSheet 弹出时，用户点击背景关闭页面时没有很好的回调，只能将关闭事件写在 deinit 中
    var hasHandledClose = false
    private var isVerifying = false
    private var state: State = .normal
    private let isIPadLayout: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    deinit {
        if !hasHandledClose {
            closeAction(needDismissViewController: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateDynamicModalSize(CGSize(width: 375, height: 170))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LocalShareTracks.trackShareCodeAppear()
        LocalShareTracks.trackShareCodeInputAppear()
        shareScreenVerifyTextField.beginEdit()
    }

    override func setupViews() {
        super.setupViews()
        isNavigationBarHidden = true

        view.addSubview(navBar)

        let closeImage = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))
        closeButton.setImage(closeImage, for: .normal)
        closeButton.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        navBar.addSubview(closeButton)

        titleLabel.text = I18n.View_M_ShareScreenButtonRoom
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        navBar.addSubview(titleLabel)

        descLabel.attributedText = NSAttributedString(string: I18n.View_G_EnterSharingCodeOrMeetingID, config: .bodyAssist)
        descLabel.textColor = UIColor.ud.textCaption
        view.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(navBar.snp.bottom).offset(20)
            make.height.equalTo(20)
        }

        shareScreenVerifyTextField = ShareScreenVerifyTextField(groupWidth: [3], groupKern: 4.0, confirmCodeBlock: { [weak self] code in
            self?.confirmCode(code)
        }, selectCodeBlock: { [weak self] code in
            self?.handleCode(code)
        })
        view.addSubview(shareScreenVerifyTextField)
        shareScreenVerifyTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(26)
            make.top.equalTo(descLabel.snp.bottom).offset(17)
        }

        commitButton.isEnabled = false

        navBarBottomLine.backgroundColor = UIColor.ud.lineBorderCard
        navBarBottomLine.isHidden = true
        navBar.addSubview(navBarBottomLine)
        navBarBottomLine.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(1)
        }

        isIPadLayout.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isRegular in
                self?.updateConstraintsForIPad(isRegular: isRegular)
            })
            .disposed(by: rx.disposeBag)
    }

    override func bindViewModel() {
        super.bindViewModel()

        commitButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self, let text = self.shareScreenVerifyTextField.text else { return }
            self.confirmCode(text)
        }).disposed(by: rx.disposeBag)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func showLoading() {
        view.endEditing(true)
        setState(.verifying)
    }

    @objc override func doBack() {
        closeAction()
        super.doBack()
    }

    func closeAction(needDismissViewController: Bool = false) {
        hasHandledClose = true
        LocalShareTracks.trackShareCodeClick(click: "close")
    }

    // disable-lint: duplicated code
    private func updateConstraintsForIPad(isRegular: Bool) {
        navBarBottomLine.isHidden = !isRegular
        commitButton.removeFromSuperview()
        if isRegular {
            commitButton.style = .light
            navBar.addSubview(commitButton)
            commitButton.snp.makeConstraints { (make) in
                make.right.equalTo(-16)
                make.centerY.equalToSuperview()
                make.height.equalTo(48)
            }

            navBar.snp.remakeConstraints { (make) in
                make.height.equalTo(60)
                make.top.left.right.equalToSuperview()
            }
            closeButton.snp.remakeConstraints { (make) in
                make.left.equalTo(16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(24)
            }
            titleLabel.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.height.equalTo(24)
            }
        } else {
            commitButton.style = .fill
            view.addSubview(commitButton)
            commitButton.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(Display.iPhoneXSeries ? -8 : -12)
                make.height.equalTo(48)
            }

            navBar.snp.remakeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
            }
            closeButton.snp.remakeConstraints { (make) in
                make.left.equalTo(16)
                make.bottom.equalToSuperview().inset(10)
                make.width.height.equalTo(24)
            }
            titleLabel.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(10)
                make.height.equalTo(24)
            }
        }
        view.layoutIfNeeded()
    }
    // enable-lint: duplicated code

    private func handleCode(_ code: String) {
        guard !isVerifying else { return }

        if !code.isEmpty {
            setState(.normal)
        }
        if shareScreenVerifyTextField.isCharacter {
            commitButton.isEnabled = code.count == ShareScreenVerifyTextField.maxInputChar
        } else {
            commitButton.isEnabled = code.count == ShareScreenVerifyTextField.maxInputNum
        }
    }

    private func confirmCode(_ code: String) {
        guard commitButton.isEnabled else { return }
        let entryCode: ShareContentEntryCodeType = shareScreenVerifyTextField.isCharacter ? .shareCode(code: code) : .meetingNumber(number: code)

        ShareContentCodeViewModel.logger.info("Process share code: \(entryCode)")
        let inMeeting = MeetingManager.shared.hasActiveMeeting.description
        VCTracker.post(name: .vc_share_code_input_click, params: [.click: "confirm", "during_meeting": inMeeting,
                                                            "code_type": shareScreenVerifyTextField.isCharacter ? "share_key" : "conf_id",
                                                            "share_code": code])
        LocalShareTracks.trackShareCodeClick(click: "confirm")

        isVerifying = true
        showLoading()

        viewModel.commitAction(entryCode) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                ShareContentCodeViewModel.logger.info("Verify code \(code) success.")
                self.isVerifying = false
                self.setState(.normal)
            case .failure(let e):
                let error = e.toVCError()
                ShareContentCodeViewModel.logger.error("Verify code \(code) failed with error: \(error).")
                self.isVerifying = false
                switch error {
                case .localShareToCurrentMeeting, .shareScreenInThisMeeting, .localShareCancelled, .shareScreenInWiredShare:
                    self.setState(.normal)
                default:
                    self.trackCommitFailed(error)
                    if error == .meetingLocked || error == .noCastWhiteboard {
                        self.setState(.error(""))
                    } else {
                        self.setState(.error(error.description))
                    }
                }
            }
        }
    }

    private func trackCommitFailed(_ error: VCError) {
        let trackName: String
        switch self.viewModel.source {
        case .groupPlus:
            trackName = "vr_sharescreen"
        case .independTab:
            trackName = "tab_top_share_screen"
        default:
            trackName = ""
        }
        let reason: String
        switch error {
        case .invalidShareCode:
            reason = "invalid_code"
        case .roomShareCode:
            reason = "invalid_room"
        default:
            reason = "unknown"
        }
        VCTracker.post(name: .vc_meeting_attend_fail, params: [.from_source: trackName, "fail_reason": reason])
    }

    private func setState(_ state: State) {
        Util.runInMainThread { [weak self] in
            self?._setState(state)
        }
    }

    private func _setState(_ state: State) {
        guard !self.state.equals(state) else { return }
        self.state = state

        commitButton.isEnabled = false
        descLabel.attributedText = NSAttributedString(string: I18n.View_G_EnterSharingCodeOrMeetingID, config: .bodyAssist)
        descLabel.textColor = UIColor.ud.textCaption
        shareScreenVerifyTextField.bottomLine.backgroundColor = UIColor.ud.textCaption

        switch state {
        case .normal:
            commitButton.stopLoading(success: true)
        case .error(let message):
            descLabel.attributedText = NSAttributedString(string: message, config: .bodyAssist)
            descLabel.textColor = UIColor.ud.functionDangerContentDefault
            shareScreenVerifyTextField.bottomLine.backgroundColor = UIColor.ud.functionDangerContentDefault
            shareScreenVerifyTextField.onError()
            commitButton.stopLoading(success: false)
        case .verifying:
            commitButton.startLoading()
        }
    }

    @objc
    private func keyboardFrameChange(_ notify: Notification) {
        guard commitButton.style == .fill, let userInfo = notify.userInfo, commitButton.superview != nil else { return }

        if notify.name == UIResponder.keyboardWillShowNotification {
            guard let toFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            commitButton.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalTo(-toFrame.height - 12)
                make.height.equalTo(48)
            }
        } else if notify.name == UIResponder.keyboardWillHideNotification {
            commitButton.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(Display.iPhoneXSeries ? -8 : -12)
                make.height.equalTo(48)
            }
        }
    }
}

extension ShareContentCodeViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isIPadLayout.accept(isRegular)
    }
}

private enum State {
    case normal
    case verifying
    case error(String)

    func equals(_ other: State) -> Bool {
        switch (self, other) {
        case (.normal, .normal): return true
        case (.verifying, .verifying): return true
        case (.error, .error): return true
        default: return false
        }
    }
}
