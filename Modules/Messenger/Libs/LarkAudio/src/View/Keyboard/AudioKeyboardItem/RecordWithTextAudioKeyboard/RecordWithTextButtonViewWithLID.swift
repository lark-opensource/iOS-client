//
//  RecordWithTextButtonViewWithLID.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import Foundation
import UIKit
import LarkFeatureGating
import LarkContainer

/// 对 按钮组进行包装，增加了 loading 等逻辑相关的 UI
final class RecordWithTextButtonViewWithLID: BaseRecordWithTextButtonView, UserResolverWrapper {
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?
    var actionButton: BaseRecordWithTextActionView?
    private var tipView: RecordWithTextTipView?
    // 发送按钮上的loading按钮
    let sendAllLoadingView: LoadingView = {
        let loadingView = LoadingView(frame: .zero)
        loadingView.backgroundColor = UIColor.ud.bgBodyOverlay
        loadingView.fillColor = UIColor.ud.bgBodyOverlay
        loadingView.strokeColor = UIColor.ud.colorfulBlue
        loadingView.radius = 10
        return loadingView
    }()
    let sendTextLoadingView: LoadingView = {
        let loadingView = LoadingView(frame: .zero)
        loadingView.backgroundColor = UIColor.ud.bgBodyOverlay
        loadingView.fillColor = .clear
        loadingView.strokeColor = UIColor.ud.iconN1
        loadingView.radius = 10
        return loadingView
    }()
    weak var delegate: RecordWithTextButtonViewDelegate?
    weak var textView: UITextView?
    weak var stackView: UIStackView?
    let sessionId: String
    private lazy var netErrorOptimizeEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "ai.asr.opt.no_network")
    let userResolver: UserResolver
    init(userResolver: UserResolver, delegate: RecordWithTextButtonViewDelegate, textView: UITextView, sessionId: String) {
        self.userResolver = userResolver
        self.delegate = delegate
        self.textView = textView
        self.sessionId = sessionId
    }

    @objc
    private func clickCancelBtn() {
        // ASR识别完成之后选择了取消的埋点上报
        audioTracker?.asrFinishThenCancel(sessionId: sessionId)
        AudioTracker.imChatVoiceMsgClick(click: .empty, viewType: RecognizeLanguageManager.shared.recognitionType)
        if self.textView?.isFirstResponder ?? false {
            self.textView?.endEditing(true)
            DispatchQueue.main.async {
                self.delegate?.recordWithTextButtonViewClickCancel(buttonView: self)
            }
        } else {
            self.delegate?.recordWithTextButtonViewClickCancel(buttonView: self)
        }
    }

    @objc
    private func clickSendBtn() {
        AudioTracker.imChatVoiceMsgClick(click: .send, viewType: RecognizeLanguageManager.shared.recognitionType)
        if self.textView?.isFirstResponder ?? false {
            self.textView?.endEditing(true)
            DispatchQueue.main.async {
                self.delegate?.recordWithTextButtonViewClickSendAll(buttonView: self)
            }
        } else {
            self.delegate?.recordWithTextButtonViewClickSendAll(buttonView: self)
        }
    }

    @objc
    private func clickOnlySendAudioBtn() {
        AudioTracker.imChatVoiceMsgClick(click: .onlyVoice, viewType: RecognizeLanguageManager.shared.recognitionType)
        if self.textView?.isFirstResponder ?? false {
            self.textView?.endEditing(true)
            DispatchQueue.main.async {
                self.delegate?.recordWithTextButtonViewClickSendAudio(buttonView: self)
            }
        } else {
            self.delegate?.recordWithTextButtonViewClickSendAudio(buttonView: self)
        }
    }

    @objc
    private func clickOnlySendTextBtn() {
        AudioTracker.imChatVoiceMsgClick(click: .onlyText, viewType: RecognizeLanguageManager.shared.recognitionType)
        if self.textView?.isFirstResponder ?? false {
            self.textView?.endEditing(true)
            DispatchQueue.main.async {
                self.delegate?.recordWithTextButtonViewClickSendText(buttonView: self)
            }
        } else {
            self.delegate?.recordWithTextButtonViewClickSendText(buttonView: self)
        }
    }

    func showActionsIfNeeded(
        stackInfo: StackViewInfo,
        animation: Bool = true,
        alpha: Bool = false,
        sendEnabled: Bool = true,
        showTipView: Bool = false) {
            guard let stackView = stackInfo.stackView else {
                assertionFailure()
                return
            }
            var location = stackInfo.location
            if netErrorOptimizeEnabled {
                if tipView == nil {
                    let tipView = createTipView()
                    self.tipView = tipView
                    stackView.insertArrangedSubview(tipView, at: location)
                    tipView.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.height.equalTo(18)
                    }
                    location += 1
                }
                tipView?.isHidden = !showTipView
            }

            if self.actionButton == nil {
                self.stackView = stackView
                let actionButton = self.createActionButton(sendAllEnabled: sendEnabled)
                self.actionButton = actionButton
                stackView.insertArrangedSubview(actionButton, at: location)
                actionButton.snp.makeConstraints { (maker) in
                    maker.left.right.equalToSuperview()
                    maker.height.equalTo(actionButton.getActionViewActualHeight())
                }
            }
            actionButton?.sendAllButton.isEnabled = sendEnabled
            actionButton?.sendTextButton.isEnabled = sendEnabled
            if animation {
                self.actionButton?.setButtomInCenter()
                stackView.layoutIfNeeded()
                self.actionButton?.setButtonAverage()
            } else {
                self.actionButton?.setButtonAverage()
                stackView.layoutIfNeeded()
            }

            self.actionButton?.alpha = alpha ? 1 : 0
            UIView.animate(withDuration: 0.25) {
                self.actionButton?.alpha = 1
                if animation {
                    stackView.layoutIfNeeded()
                }
            }
        }

    func showSendAllButtonLoading() {
        guard let actionButton = actionButton else { return }
        actionButton.sendAllButton.isEnabled = false
        actionButton.sendAllButton.addSubview(sendAllLoadingView)
        actionButton.sendTextButton.isEnabled = false
        actionButton.sendTextButton.addSubview(sendTextLoadingView)
        sendAllLoadingView.snp.makeConstraints { (make) in
            make.size.equalTo(24)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        sendTextLoadingView.snp.makeConstraints { (make) in
            make.size.equalTo(24)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    func hideSendAllButtonLoading() {
        sendAllLoadingView.removeFromSuperview()
        sendTextLoadingView.removeFromSuperview()
    }

    private func createActionButton(sendAllEnabled: Bool = true) -> RecordWithTextActionViewWithLID {
        let actionButton = RecordWithTextActionViewWithLID(userResolver: userResolver)
        (actionButton.cancelButton as? AudioKeyboardInteractiveButton)?.setHandler(clickCancelBtn)
        (actionButton.sendAudioButton as? AudioKeyboardInteractiveButton)?.setHandler(clickOnlySendAudioBtn)
        (actionButton.sendAllButton as? AudioKeyboardInteractiveButton)?.setHandler(clickSendBtn)
        (actionButton.sendTextButton as? AudioKeyboardInteractiveButton)?.setHandler(clickOnlySendTextBtn)
        if netErrorOptimizeEnabled {
            actionButton.sendAllButton.isEnabled = sendAllEnabled
            actionButton.sendTextButton.isEnabled = sendAllEnabled
        }
        return actionButton
    }

    private func createTipView() -> RecordWithTextTipView {
        let tipView = RecordWithTextTipView()
        tipView.isHidden = true
        return tipView
    }
}
