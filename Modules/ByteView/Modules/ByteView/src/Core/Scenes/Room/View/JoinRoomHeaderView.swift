//
//  JoinRoomHeaderView.swift
//  ByteView
//
//  Created by kiri on 2023/6/9.
//

import Foundation

final class JoinRoomHeaderView: JoinRoomChildView {
    private let titleLabel = UILabel()

    private lazy var zeroHeightConstraint = self.heightAnchor.constraint(equalToConstant: 0)

    override func setupViews() {
        super.setupViews()
        addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().priority(.high)
            make.left.right.equalToSuperview().inset(20)
        }
    }

    override func updateRoomInfo(_ viewModel: JoinRoomTogetherViewModel) {
        var title: String
        switch viewModel.state {
        case .roomFound(.roomTaken):
            title = I18n.View_G_RoomInUseFindAnother
        case .roomFound:
            title = I18n.View_G_ConnectToRoom_Suggestion3
            if let resp = viewModel.lastShareCodeInfo, viewModel.isSuggestedRoom {
                title = resp.isRoomInMeeting ? I18n.View_G_ConnectToRoom_Suggestion1 : I18n.View_G_ConnectToRoom_Suggestion2
            }
        case .verifyCode:
            if viewModel.verifyCodeState == .error {
                title = I18n.View_G_IncorrectSharingCode
            } else {
                title = I18n.View_G_EnterTheCodeHere
            }
        case .roomNotFound:
            title = I18n.View_G_NoRoomNearbyShort
        case .idle, .scanning, .connected:
            title = ""
        }
        self.titleLabel.attributedText = NSAttributedString(string: title, config: .h3, textColor: .ud.textTitle)
    }

    override func updateStyle() {
        titleLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(style == .popover ? 18 : 16)
            make.right.equalToSuperview().inset(style == .popover ? 20 : 56)
        }
    }

    override func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        self.titleLabel.preferredMaxLayoutWidth = style == .popover ? maxWidth - 40 : maxWidth - 76
        guard let title = self.titleLabel.text, !title.isEmpty else {
            /// title为空，c 20， r 0
            let height: CGFloat = style == .popover ? 0 : 20
            zeroHeightConstraint.constant = height
            zeroHeightConstraint.isActive = true
            return height
        }
        zeroHeightConstraint.isActive = false
        var h: CGFloat = style == .popover ? 18 : 16
        if self.titleLabel.preferredMaxLayoutWidth > 0 {
            h += self.titleLabel.sizeThatFits(CGSize(width: self.titleLabel.preferredMaxLayoutWidth, height: .greatestFiniteMagnitude)).height
        } else {
            h += 24
        }
        return h
    }
}
