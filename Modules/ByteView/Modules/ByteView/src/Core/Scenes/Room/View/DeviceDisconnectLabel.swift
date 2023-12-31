//
//  DeviceDisconnectLabel.swift
//  ByteView
//
//  Created by wulv on 2023/10/16.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import RichLabel

final class JoinRoomDisconnectButton: UIButton {
    convenience init() {
        self.init(type: .custom)
        let font = VCFontConfig.r_14_22.font
        self.setAttributedTitle(NSAttributedString(string: I18n.View_MV_Disconnect_Button, attributes: [.font: font, .baselineOffset: -0.5, .foregroundColor: UIColor.ud.functionDangerContentDefault]), for: .normal)
        self.vc.setBackgroundColor(UIColor.clear, for: .normal)
        self.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgDangerPressed, for: .highlighted)
        self.addInteraction(type: .highlight)
        self.adjustsImageWhenHighlighted = false
        self.layer.cornerRadius = 6.0
        self.layer.masksToBounds = true
        self.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
    }
}

final class DeviceDisconnectLabel: UIView {
    private(set) lazy var deviceLabel: AttachmentLabel = {
        let label = AttachmentLabel()
        label.backgroundColor = .clear
        label.contentFont = textStyle.font
        label.preferredMaxLayoutWidth = 320
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private(set) lazy var disconnectButton: JoinRoomDisconnectButton = {
        let button = JoinRoomDisconnectButton()
        button.frame = CGRect(origin: .zero, size: disconnectSize)
        return button
    }()

    private let textStyle: VCFontConfig = .r_14_22
    private var textLabelHeight: CGFloat = 0
    private(set) var contentHeight: CGFloat = 0
    private lazy var disconnectSize = CGSize(width: disconnectWidth, height: 20)
    private lazy var disconnectWidth: CGFloat = 8 + I18n.View_MV_Disconnect_Button.vc.boundingWidth(height: 20, config: .r_14_22)
    private let minHeight: CGFloat

    init(minHeight: CGFloat = 0) {
        self.minHeight = minHeight
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: max(22, minHeight)))
        addSubview(deviceLabel)
        deviceLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets.zero)
            make.height.equalTo(max(22, minHeight))
        }
    }

    func setText(_ text: String, color: UIColor? = nil) {
        deviceLabel.reset()
        var text = text
        text += " "
        let color = color ?? .ud.textCaption
        deviceLabel.addAttributedString(NSAttributedString(string: text, config: textStyle, alignment: .center, textColor: color))
        let size = disconnectSize
        deviceLabel.addArrangedSubview(disconnectButton) {
            $0.margin = .init(top: -2, left: -4, bottom: 0, right: 0)
            $0.size = size
        }
        deviceLabel.reload()
        updateHeightConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var preferredMaxLayoutWidth: CGFloat {
        get { deviceLabel.preferredMaxLayoutWidth }
        set { deviceLabel.preferredMaxLayoutWidth = newValue }
    }

    func updateHeightConstraints() {
        if self.preferredMaxLayoutWidth > 0 {
            let maxHeight: CGFloat = .greatestFiniteMagnitude
            // 会fit出23/45/68之类的高度
            let fitSize = deviceLabel.sizeThatFits(CGSize(width: deviceLabel.preferredMaxLayoutWidth, height: maxHeight))
            let textHeight = max(minHeight, fitSize.height)
            let contentHeight = textHeight > minHeight ? ((round(textHeight / textStyle.lineHeight)) * textStyle.lineHeight) : minHeight
            if textLabelHeight != textHeight || contentHeight != contentHeight {
                textLabelHeight = textHeight
                self.contentHeight = contentHeight
                let offset = contentHeight - textHeight
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: offset, right: 0)
                deviceLabel.snp.updateConstraints { make in
                    make.edges.equalToSuperview().inset(insets)
                    make.height.equalTo(textHeight)
                }
            }
        }
    }
}

final class RoomConnectedView: JoinRoomChildView {

    struct Layout {
        static let IconTop: CGFloat = 12
        static let IconTopPopover: CGFloat = 24
        static var IconSize: CGSize {
            CGSize(width: Display.pad ? 62 : 44, height: Display.pad ? 40 : 52)
        }
        static let IconToLabel: CGFloat = 12
        static let DeviceLabelMinH: CGFloat = 24
        static let DisconnectMinH: CGFloat = 22
        static let LabelToLabel: CGFloat = 40
        static let Left: CGFloat = 12
        static let bottomPopover: CGFloat = 10
    }

    private var layoutTop: CGFloat { style == .popover ? Layout.IconTopPopover : Layout.IconTop }
    private var layoutBottom: CGFloat { style == .popover ? Layout.bottomPopover : 0 }

    private let deviceIcon = UIImageView(image: Display.pad ? BundleResources.ByteView.JoinRoom.pad_mute : BundleResources.ByteView.JoinRoom.phone_mute)
    private lazy var deviceLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: I18n.View_G_UseRoomMicMuteDevice_Desc(Display.pad ? I18n.View_G_Pad_Desc : I18n.View_G_Phone_Desc), config: .h3, alignment: .center, textColor: .ud.textTitle)
        label.numberOfLines = 0
        return label
    }()

    private let disconnectFont: VCFontConfig = .r_14_22
    private static let buttonText = I18n.View_MV_Disconnect_Button
    private lazy var deviceDisconnectLabel: LKLabel = {
        let label = LKLabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        let text = I18n.View_G_WantToUseDeviceMicThenDisconnect_Desc(Display.pad ? I18n.View_G_Pad_Desc : I18n.View_G_Phone_Desc, " " + Self.buttonText + " ")
        label.attributedText = NSAttributedString(string: text, config: disconnectFont, alignment: .center, textColor: UIColor.ud.textCaption)
        return label
    }()

    func addButtonAction(_ action: @escaping () -> Void) {
        let text = deviceDisconnectLabel.attributedText?.string
        if let text = text, let range = text.range(of: Self.buttonText) {
            let location = text.distance(from: text.startIndex, to: range.lowerBound)
            let length = text.distance(from: range.lowerBound, to: range.upperBound)
            let buttonRange = NSRange(location: location, length: length)
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.functionDangerContentDefault,
                              NSAttributedString.Key.backgroundColor: UIColor.clear,
                              NSAttributedString.Key.font: disconnectFont.font]
            var link = LKTextLink(range: buttonRange,
                                  type: .link,
                                  attributes: attributes,
                                  activeAttributes: attributes)
            link.linkTapBlock = { (_, _) in action() }
            deviceDisconnectLabel.removeLKTextLink()
            deviceDisconnectLabel.addLKTextLink(link: link)
            deviceDisconnectLabel.attributedText = deviceDisconnectLabel.attributedText
        }
    }

    override func setupViews() {
        backgroundColor = .clear
        addSubview(deviceIcon)
        addSubview(deviceLabel)
        addSubview(deviceDisconnectLabel)

        deviceIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(layoutTop)
            make.size.equalTo(Layout.IconSize)
        }

        deviceLabel.snp.makeConstraints { make in
            make.top.equalTo(deviceIcon.snp.bottom).offset(Layout.IconToLabel)
            make.left.right.equalToSuperview().inset(Layout.Left)
            make.height.greaterThanOrEqualTo(Layout.DeviceLabelMinH)
        }

        deviceDisconnectLabel.preferredMaxLayoutWidth = 335
        deviceDisconnectLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.Left)
            make.top.equalTo(deviceLabel.snp.bottom).offset(Layout.LabelToLabel)
            make.height.greaterThanOrEqualTo(Layout.DisconnectMinH)
            make.bottom.equalToSuperview().inset(layoutBottom)
        }
    }

    override func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        let realWidth = maxWidth - Layout.Left * 2
        let string = deviceLabel.attributedText?.string ?? ""
        var titleHeight = string.vc.boundingHeight(width: realWidth, config: .h3)
        titleHeight = max(Layout.DeviceLabelMinH, titleHeight)
        deviceDisconnectLabel.preferredMaxLayoutWidth = realWidth
        let disconnectSize = deviceDisconnectLabel.sizeThatFits(CGSize(width: deviceDisconnectLabel.preferredMaxLayoutWidth, height: Layout.DisconnectMinH))
        let disconnectHeight = max(Layout.DisconnectMinH, disconnectSize.height)
        return layoutTop + Layout.IconSize.height + Layout.IconToLabel + titleHeight + Layout.LabelToLabel + disconnectHeight + layoutBottom
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if deviceDisconnectLabel.preferredMaxLayoutWidth != deviceDisconnectLabel.bounds.size.width {
            deviceDisconnectLabel.preferredMaxLayoutWidth = deviceDisconnectLabel.preferredMaxLayoutWidth
            deviceDisconnectLabel.attributedText = deviceDisconnectLabel.attributedText
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        deviceDisconnectLabel.attributedText = deviceDisconnectLabel.attributedText
    }
}
