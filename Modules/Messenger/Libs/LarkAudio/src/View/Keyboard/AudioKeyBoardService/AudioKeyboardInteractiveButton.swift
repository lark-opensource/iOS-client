//
//  AudioKeyboardInteractiveButton.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import Foundation
import UIKit
import LarkExtensions
import UniverseDesignIcon
import UniverseDesignColor
import LarkContainer

final class AudioKeyboardInteractiveButton: UIButton {

    /// 语音识别支持的按钮类型
    enum buttonType {
        /// 取消按钮
        case cancel
        /// 发送按钮
        case sendAll
        /// 只发送语音
        case sendOnlyVoice
        /// 只发文字
        case sendOnlyText
    }

    enum Cons {
        static var labelLines: Int { 2 }
        static var iconSideLength: CGFloat { 24 }
        static var spacing: CGFloat { 8 }
        static var labelWidth: CGFloat { 110 }
        static var labelBaseHeight: CGFloat { 22 }
        static var baselineOffset: CGFloat { (Cons.titleFont.figmaHeight - Cons.titleFont.lineHeight) / 2.0 / 2.0 }
        static var titleFont: UIFont { UIFont.systemFont(ofSize: 14) }
    }

    let type: buttonType
    var buttonHeight: CGFloat = 0
    let userResolver: UserResolver
    let customText: String?

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.setNormalColor()
            } else {
                self.setDisableColor()
            }
        }
    }

    private var handler: (() -> Void)?
    private lazy var paragraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = Cons.titleFont.figmaHeight
        paragraphStyle.maximumLineHeight = Cons.titleFont.figmaHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        return paragraphStyle
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Cons.spacing
        return stackView
    }()

    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = Cons.labelLines
        return label
    }()

    init(type: buttonType, userResolver: UserResolver, customText: String? = nil) {
        self.userResolver = userResolver
        self.type = type
        self.customText = customText
        super.init(frame: .zero)
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.setupSubviews()
        self.setupConstraints()
        self.setupAppearance()
    }

    func setupSubviews() {
        self.addSubview(stackView)
        self.stackView.addArrangedSubview(icon)
        self.stackView.addArrangedSubview(textLabel)
    }

    func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        icon.snp.makeConstraints { make in
            make.size.equalTo(Cons.iconSideLength)
        }

        textLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(Cons.labelBaseHeight)
        }
    }

    func setupAppearance() {
        let (title, image) = getTitleAndIconFromConfig()
        self.setLabelText(with: title)
        self.setIconImage(with: image)
        self.setColorAccordingStatus()
        self.lu.addTapGestureRecognizer(
            action: #selector(handleTap),
            target: self
        )
    }

    func getTitleAndIconFromConfig() -> (String, UIImage) {
        let image: UIImage
        let title: String

        switch type {
        case .cancel:
            image = UDIcon.undoOutlined
            title = customText ?? BundleI18n.LarkAudio.Lark_IM_AudioToTextSelectLangugage_Cancel_Button
        case .sendOnlyVoice:
            image = UDIcon.originalmodeFilled
            if userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.improvements") {
                title = customText ?? BundleI18n.LarkAudio.Lark_IM_AudioMsg_SendAudioOnly_Button
            } else {
                title = BundleI18n.LarkAudio.Lark_Chat_SendAudioOnly
            }
        case .sendOnlyText:
            if userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.improvements") {
                title = customText ?? BundleI18n.LarkAudio.Lark_IM_AudioMsg_SendTextOnly_Button
                image = Resources.new_audio_send_only_text
            } else {
                title = BundleI18n.LarkAudio.Lark_Chat_SendTextOnly_Text
                image = Resources.new_voice_send_only_text
            }
        case .sendAll:
            image = UDIcon.sendFilled
            if userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.improvements") {
                title = customText ?? BundleI18n.LarkAudio.Lark_IM_AudioMsg_SendAudioAndText_Button
            } else {
                title = BundleI18n.LarkAudio.Lark_Legacy_Send
            }
        }
        return (title, image)
    }

    func setLabelText(with text: String) {
        self.textLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .baselineOffset: Cons.baselineOffset,
                .paragraphStyle: self.paragraphStyle,
                .font: Cons.titleFont
            ]
        )
        self.buttonHeight = calculateBtnTotalHeight()
    }

    func setIconImage(with image: UIImage) {
        self.icon.image = image
    }

    func setColorAccordingStatus() {
        if isEnabled {
            self.setNormalColor()
        } else {
            self.setDisableColor()
        }
    }

    func setHandler(_ handler: (() -> Void)?) {
        self.handler = handler
    }

    @objc
    func handleTap() {
        self.handler?()
    }

    func setNormalColor() {
        guard isEnabled else { return }
        if type == .sendAll {
            self.textLabel.textColor = UIColor.ud.textLinkHover
            self.icon.image = self.icon.image?.ud.withTintColor(UIColor.ud.textLinkHover)
        } else {
            self.textLabel.textColor = UIColor.ud.textCaption
            self.icon.image = self.icon.image?.ud.withTintColor(UIColor.ud.iconN1)
        }
    }

    func setDisableColor() {
        guard !isEnabled else { return }
        self.textLabel.textColor = UIColor.ud.textDisabled
        self.icon.image = self.icon.image?.ud.withTintColor(UIColor.ud.iconDisabled)
    }
}

extension AudioKeyboardInteractiveButton {
    func calculateBtnTotalHeight() -> CGFloat {
        let textHeight = getTextHeight()
        return Cons.iconSideLength + Cons.spacing + textHeight
    }

    /// 获取文本的宽高
    private func getTextHeight() -> CGFloat {
        guard let text = textLabel.attributedText?.string else { return 0 }
        let textSize = CGSize(width: Cons.labelWidth, height: CGFloat.infinity)
        let textHeight = (text as NSString).boundingRect(with: textSize,
                                                         options: [.usesLineFragmentOrigin],
                                                         attributes: [
                                                            .font: Cons.titleFont,
                                                            .baselineOffset: Cons.baselineOffset,
                                                            .paragraphStyle: self.paragraphStyle
                                                         ],
                                                         context: nil).height
        if textHeight > Cons.labelBaseHeight {
            return Cons.labelBaseHeight * 2
        } else {
            return Cons.labelBaseHeight
        }
    }
}
