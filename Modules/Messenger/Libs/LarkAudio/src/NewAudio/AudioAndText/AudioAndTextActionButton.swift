//
//  AudioAndTextActionButton.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/15.
//

import Foundation
import UniverseDesignIcon

// 语音加文字场景的四个按钮组
final class AudioAndTextActionButton: UIView {
    private enum Cons {
        static let buttonHeight: CGFloat = 54
        static let stackSpacing: CGFloat = 8
    }
    let cancelButton = AudioActionButton(config: .init(
        name: BundleI18n.LarkAudio.Lark_IM_AudioToTextSelectLangugage_Cancel_Button,
        icon: UDIcon.undoOutlined, iconColor: UIColor.ud.iconN1,
        textColor: UIColor.ud.textCaption, loadingColor: UIColor.ud.iconN1))
    let sendAudioButton = AudioActionButton(config: .init(
        name: BundleI18n.LarkAudio.Lark_IM_AudioMsg_SendAudioOnly_Button,
        icon: UDIcon.originalmodeFilled, iconColor: UIColor.ud.iconN1,
        textColor: UIColor.ud.textCaption, loadingColor: UIColor.ud.iconN1))
    let sendTextButton = AudioActionButton(config: .init(
        name: BundleI18n.LarkAudio.Lark_IM_AudioMsg_SendTextOnly_Button,
        icon: Resources.new_audio_send_only_text, iconColor: UIColor.ud.iconN1,
        textColor: UIColor.ud.textCaption, loadingColor: UIColor.ud.iconN1))
    let sendAllButton = AudioActionButton(config: .init(
        name: BundleI18n.LarkAudio.Lark_IM_AudioMsg_SendAudioAndText_Button,
        icon: UDIcon.sendFilled, iconColor: UIColor.ud.textLinkHover,
        textColor: UIColor.ud.textLinkHover, loadingColor: UIColor.ud.colorfulBlue))
    private let cancelView = UIView()
    private let sendAudioView = UIView()
    private let sendTextView = UIView()
    private let sendAllView = UIView()
    private let centerView = UIView()
    private let stackView = UIStackView()

    override var isHidden: Bool {
        didSet {
            guard isHidden != oldValue else { return }
            if !isHidden {
                setInCenter()
                self.layoutIfNeeded()
                setAverage()
                UIView.animate(withDuration: 0.25) {
                    self.layoutIfNeeded()
                }
            }
        }
    }

    var isEnabled: Bool = true {
        didSet {
            sendTextButton.isEnabled = isEnabled
            sendAllButton.isEnabled = isEnabled
        }
    }

    init() {
        super.init(frame: .zero)

        stackView.axis = .horizontal
        self.addSubview(stackView)

        stackView.addArrangedSubview(cancelView)
        stackView.addArrangedSubview(sendAudioView)
        stackView.addArrangedSubview(sendTextView)
        stackView.addArrangedSubview(sendAllView)
        self.addSubview(centerView)

        self.addSubview(cancelButton)
        self.addSubview(sendAudioButton)
        self.addSubview(sendTextButton)
        self.addSubview(sendAllButton)

        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(Cons.stackSpacing)
            make.bottom.equalToSuperview().offset(-Cons.stackSpacing)
        }
        cancelView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Cons.buttonHeight)
        }
        sendAudioView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Cons.buttonHeight)
            make.width.equalTo(cancelView)
        }
        sendTextView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Cons.buttonHeight)
            make.width.equalTo(cancelView)
        }
        sendAllView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Cons.buttonHeight)
            make.width.equalTo(cancelView)
        }
        centerView.snp.makeConstraints { make in
            make.center.equalTo(stackView)
            make.width.height.equalTo(54)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadingHandler(show: Bool) {
        sendTextButton.loadingHandler(show: show)
        sendAllButton.loadingHandler(show: show)
    }

    private func setInCenter() {
        cancelButton.snp.remakeConstraints { make in
            make.edges.equalTo(centerView)
        }
        sendAudioButton.snp.remakeConstraints { make in
            make.edges.equalTo(centerView)
        }
        sendTextButton.snp.remakeConstraints { make in
            make.edges.equalTo(centerView)
        }
        sendAllButton.snp.remakeConstraints { make in
            make.edges.equalTo(centerView)
        }
    }

    private func setAverage() {
        cancelButton.snp.remakeConstraints { make in
            make.edges.equalTo(cancelView)
        }
        sendAudioButton.snp.remakeConstraints { make in
            make.edges.equalTo(sendAudioView)
        }
        sendTextButton.snp.remakeConstraints { make in
            make.edges.equalTo(sendTextView)
        }
        sendAllButton.snp.remakeConstraints { make in
            make.edges.equalTo(sendAllView)
        }
    }
}
