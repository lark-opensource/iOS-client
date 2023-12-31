//
//  JoinedDeviceView.swift
//  ByteViewTab
//
//  Created by Tobb Huang on 2023/9/14.
//

import Foundation
import ByteViewCommon
import UniverseDesignIcon

class JoinedDeviceView: UIView {

    struct Layout {
        static let deviceNameCompactMaxWidth: CGFloat = 120
    }

    private var names: [String] = []
    private var isRegular: Bool = false

    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.multideviceOutlined, iconColor: .ud.textCaption, size: CGSize(width: 14, height: 14))
        return iconView
    }()

    private lazy var label = UILabel()

    init(isRegular: Bool) {
        super.init(frame: .zero)
        addSubview(iconView)
        addSubview(label)
        updateLayout(isRegular: isRegular)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout(isRegular: Bool) {
        self.isRegular = isRegular
        if isRegular {
            iconView.isHidden = false
            iconView.snp.remakeConstraints { make in
                make.size.equalTo(14)
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            label.snp.remakeConstraints { make in
                make.left.equalTo(iconView.snp.right).offset(6)
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        } else {
            iconView.isHidden = true
            label.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.top.bottom.right.equalToSuperview()
            }
        }
        updateDeviceNames(names)
    }

    func updateDeviceNames(_ names: [String]) {
        self.names = names
        guard !names.isEmpty else {
            return
        }

        if isRegular {
            let text: String
            if names.count > 1 {
                text = I18n.View_G_JoinedonOtherDevices_Desc(names.count)
            } else {
                text = I18n.View_G_AlreadyJoinedOnThisTypeOfDevice_Desc(names[0])
            }
            label.textColor = .ud.textCaption
            label.numberOfLines = 1
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.attributedText = NSAttributedString(string: text, config: .tinyAssist, lineBreakMode: .byTruncatingTail)
        } else {
            label.textColor = .ud.textPlaceholder
            let style: VCFontConfig = .init(fontSize: 14, lineHeight: 22, fontWeight: .regular)
            if names.count > 1 {
                label.numberOfLines = 2
                label.attributedText = NSAttributedString(string: I18n.View_G_JoinedonOtherDevices_Desc(names.count),
                                                          config: style,
                                                          lineBreakMode: .byTruncatingTail)
            } else {
                let deviceName = compressDeviceName(names[0], font: style.font)
                label.numberOfLines = 0
                label.setContentCompressionResistancePriority(.required, for: .horizontal)
                label.attributedText = NSAttributedString(string: I18n.View_G_AlreadyJoinedOnThisTypeOfDevice_Desc(deviceName),
                                                          config: style,
                                                          lineBreakMode: .byTruncatingTail)
            }
        }
    }

    // 设备名限宽
    private func compressDeviceName(_ originName: String, font: UIFont) -> String {
        var name = originName
        var width = name.vc.boundingWidth(height: 22, font: font)
        while width > Layout.deviceNameCompactMaxWidth && !name.isEmpty {
            name = name.substring(from: 0, length: name.count - 1) ?? ""
            width = "\(name)...".vc.boundingWidth(height: 22, font: font)
        }
        if name == originName {
            return originName
        }
        return "\(name)..."
    }
}
