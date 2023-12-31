//
//  JoinRoomConnectView.swift
//  ByteView
//
//  Created by kiri on 2023/6/9.
//

import Foundation

final class JoinRoomConnectView: JoinRoomChildView {
    let roomNameLabel = JoinRoomNameLabel(minHeight: 44)

    private let contentView = UIView()
    private let iconView = UIImageView(image: BundleResources.ByteView.JoinRoom.connect_to_room)
    private lazy var buttonView: UIView = {
        let view = UIView()
        view.addSubview(scanAgainButton)
        view.addSubview(connectButton)
        view.subviews.forEach {
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        return view
    }()

    private(set) lazy var connectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_ConnectToRoom_Button, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgPriPressed, for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        button.addInteraction(type: .lift)
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        return button
    }()
//
//    private(set) lazy var disconnectButton: UIButton = {
//        let button = UIButton(type: .custom)
//        button.setTitle(I18n.View_MV_Disconnect_Button, for: .normal)
//        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
//        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgDangerPressed, for: .highlighted)
//        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
//        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
//        button.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
//        button.addInteraction(type: .lift)
//        button.layer.cornerRadius = 6.0
//        button.layer.borderWidth = 1.0
//        button.layer.masksToBounds = true
//        return button
//    }()

    private(set) lazy var scanAgainButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_ScanAgain_ClickText, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgPriPressed, for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        button.addInteraction(type: .lift)
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        return button
    }()

    private var hideButtonConstraint: NSLayoutConstraint?

    override func setupViews() {
        super.setupViews()
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20))
        }

        contentView.addSubview(iconView)
        contentView.addSubview(roomNameLabel)
        contentView.addSubview(buttonView)

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(4)
            make.width.height.equalTo(36)
        }

        roomNameLabel.textLabel.numberOfLines = 0
        roomNameLabel.preferredMaxLayoutWidth = 335
        roomNameLabel.snp.makeConstraints { make in
            make.right.top.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(14)
        }

        buttonView.snp.makeConstraints { make in
            make.top.equalTo(roomNameLabel.snp.bottom).offset(26)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.medium)
            make.height.equalTo(buttonHeight)
        }

        hideButtonConstraint = roomNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        hideButtonConstraint?.isActive = false
    }

    private var buttonHeight: CGFloat {
        style == .popover ? 36 : 48
    }

    private var state: JoinRoomScanState?
    private var roomName: String?
    override func updateRoomInfo(_ viewModel: JoinRoomTogetherViewModel) {
        guard self.state != viewModel.state || self.roomName != viewModel.roomName else { return }
        self.state = viewModel.state
        self.roomName = viewModel.roomName

        switch state {
        case .roomFound(.roomTaken):
            hideButtonConstraint?.isActive = false
            roomNameLabel.setName(roomName, buttonType: nil, textColor: .ud.functionWarningContentDefault)
            connectButton.isHidden = true
            scanAgainButton.isHidden = false
        case .connected:
            hideButtonConstraint?.isActive = true
            connectButton.isHidden = true
            scanAgainButton.isHidden = true
        default:
            hideButtonConstraint?.isActive = false
            roomNameLabel.setName(roomName, buttonType: nil)
            connectButton.isHidden = false
            scanAgainButton.isHidden = true
        }

        contentView.snp.updateConstraints { make in
            let top: CGFloat = state == .connected ? 16 : 20
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: top, left: 20, bottom: 0, right: 20))
        }
    }

    override func updateStyle() {
        buttonView.snp.updateConstraints { make in
            make.height.equalTo(buttonHeight)
        }
        for case let button as UIButton in buttonView.subviews {
            button.titleLabel?.font = .systemFont(ofSize: style == .popover ? 16 : 17)
        }
    }

    override func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        self.roomNameLabel.preferredMaxLayoutWidth = maxWidth - 90
        self.roomNameLabel.updateHeightConstraints()
        if self.state == .connected {
            return self.roomNameLabel.contentHeight + 16
        } else {
            return self.roomNameLabel.contentHeight + 20 + buttonHeight + 26
        }
    }
}
