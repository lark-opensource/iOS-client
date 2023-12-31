//
//  PreviewReplaceJoinView.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/8/31.
//

import Foundation
import ByteViewCommon
import UniverseDesignCheckBox
import ByteViewUI

protocol PreviewReplaceJoinViewDelegate: AnyObject {
    func replaceJoinCheckboxTapped(_ isSelected: Bool)
}

final class PreviewReplaceJoinView: PreviewChildView {

    struct Layout {
        static let deviceNameMaxWidth: CGFloat = 200
        static let checkboxSize: CGFloat = 18
        static let labelLeftPadding: CGFloat = 12
        static let labelConfig: VCFontConfig = .init(fontSize: 14, lineHeight: 20, fontWeight: .regular)
    }

    var isSelected: Bool {
        get {
            replaceJoinCheckbox.isSelected
        }
        set {
            replaceJoinCheckbox.isSelected = newValue
        }
    }

    private lazy var replaceJoinCheckbox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple, config: .init(selectedBackgroundEnabledColor: UIColor.ud.primaryFillDefault))
        return checkbox
    }()

    private lazy var label = UILabel()

    private lazy var button: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        return button
    }()

    weak var delegate: PreviewReplaceJoinViewDelegate?

    var actualPhoneHeight: CGFloat {
        let inset = PreviewFooterView.Layout.Phone.replaceJoinLeftPadding * 2 + Layout.checkboxSize + Layout.labelLeftPadding
        return label.sizeThatFits(.init(width: VCScene.bounds.width - inset,
                                        height: CGFloat.greatestFiniteMagnitude)).height
    }

    init() {
        super.init(frame: .zero)
        addSubview(replaceJoinCheckbox)
        replaceJoinCheckbox.snp.makeConstraints { make in
            make.size.equalTo(Layout.checkboxSize)
            make.left.equalToSuperview()
            // 保持和第一行居中
            make.top.equalToSuperview().inset((Layout.labelConfig.lineHeight - Layout.checkboxSize) / 2)
        }
        addSubview(label)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.snp.makeConstraints { make in
            make.left.equalTo(replaceJoinCheckbox.snp.right).offset(Layout.labelLeftPadding)
            make.top.bottom.right.equalToSuperview()
        }
        addSubview(button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout(isRegular: Bool) {
        if let superview = self.superview {
            button.snp.remakeConstraints { make in
                make.left.right.equalTo(superview)
                make.top.bottom.equalToSuperview()
            }
        }
    }

    @objc private func toggle() {
        replaceJoinCheckbox.isSelected = !replaceJoinCheckbox.isSelected
        delegate?.replaceJoinCheckboxTapped(replaceJoinCheckbox.isSelected)
    }

    func updateDeviceNames(_ names: [String]) {
        guard !names.isEmpty else {
            return
        }

        let style: VCFontConfig = Layout.labelConfig
        var boldStyle = style
        boldStyle.fontWeight = .medium

        if names.count > 1 {
            let deviceCount = "\(names.count)"
            let components = splitParenthese(I18n.__View_G_KeepTheseManyDevicesInMeeting_Desc)
            if components.isEmpty {
                // 文案错误
                Logger.preview.error("View_G_KeepTheseManyDevicesInMeeting_Desc i18n error")
                return
            }
            let attributedText = NSMutableAttributedString(string: components[0], config: style)
            attributedText.append(.init(string: deviceCount, config: boldStyle))
            attributedText.append(.init(string: components[1], config: style))

            label.numberOfLines = 2
            label.attributedText = attributedText
        } else {
            let deviceName = compressDeviceName(names[0], font: style.font)
            let components = splitParenthese(I18n.__View_G_KeepDeviceInMeeting_Desc)
            if components.isEmpty {
                // 文案错误
                Logger.preview.error("View_G_ThisDeviceStay_Desc i18n error")
                return
            }

            let attributedText = NSMutableAttributedString(string: components[0], config: style)
            attributedText.append(.init(string: deviceName, config: boldStyle))
            attributedText.append(.init(string: components[1], config: style))

            label.numberOfLines = 0
            label.attributedText = attributedText
        }
    }

    // 手动分割包含 "{{"、"}}" 的文案，方便对中间的文字加粗
    private func splitParenthese(_ text: String) -> [String] {
        var components = text.components(separatedBy: "{{")
        if components.count != 2 {
            return []
        }
        let subComponent = components.removeLast().components(separatedBy: "}}")
        if subComponent.count != 2 {
            return []
        }
        components.append(subComponent[1])
        return components
    }

    // 设备名限宽
    private func compressDeviceName(_ originName: String, font: UIFont) -> String {
        var name = originName
        let height = Layout.labelConfig.lineHeight
        var width = name.vc.boundingWidth(height: height, font: font)
        while width > Layout.deviceNameMaxWidth && !name.isEmpty {
            name = name.vc.substring(from: 0, length: name.count - 1)
            width = "\(name)...".vc.boundingWidth(height: height, font: font)
        }
        if name == originName {
            return originName
        }
        return "\(name)..."
    }
}
