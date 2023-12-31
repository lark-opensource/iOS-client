//
//  PreviewConnectRoomButton.swift
//  ByteView
//
//  Created by lutingting on 2023/5/30.
//

import Foundation
import UniverseDesignIcon

class PreviewConnectRoomButton: VisualButton {

    private let iconSize = CGSize(width: 16, height: 16)
    private let edgeInsets: CGFloat = Display.pad ? 8.0 : 6.0
    private let iconKey: UDIconType = Display.pad ? .videoSystemBoldOutlined : .videoSystemOutlined
    private lazy var normalIcon = UDIcon.getIconByKey(iconKey, iconColor: .ud.iconN1, size: iconSize)
    private lazy var connectedIcon = UDIcon.getIconByKey(iconKey, iconColor: .ud.G500, size: iconSize)

    private var isConnected: Bool = false {
        didSet {
            guard isConnected != oldValue else { return }
            updateColor()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        edgeInsetStyle = .left
        space = Display.pad ? 6 : 4
        isNeedExtend = true
        contentEdgeInsets = .init(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
        setTitle(I18n.View_G_ConnectToRoom_Button, for: .normal)
        titleLabel?.font = Display.pad ? .systemFont(ofSize: 16, weight: .medium) : .systemFont(ofSize: 14)
        vc.setBackgroundColor(.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        vc.setBackgroundColor(.ud.udtokenBtnTextBgNeutralHover, for: .selected)
        layer.cornerRadius = 6
        layer.masksToBounds = true
        addInteraction(type: .highlight)
        updateColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateColor() {
        let icon = isConnected ? connectedIcon : normalIcon
        let color = isConnected ? UIColor.ud.G500 : .ud.textTitle
        setImage(icon, for: .normal)
        setImage(icon, for: .highlighted)
        setImage(UDIcon.getIconByKey(iconKey, iconColor: .ud.iconDisabled, size: iconSize), for: .disabled)
        setTitleColor(color, for: .normal)
        setTitleColor(.ud.textDisabled, for: .disabled)
    }

    func updateConnectState(_ isConnected: Bool, roomName: String?) {
        self.isConnected = isConnected
        if let name = roomName, !name.isEmpty, isConnected {
            setTitle(I18n.View_G_IsConnected(name: name), for: .normal)
        } else {
            setTitle(I18n.View_G_ConnectToRoom_Button, for: .normal)
        }
    }
}
