//
//  JoinRoomNotFoundView.swift
//  ByteView
//
//  Created by kiri on 2023/7/4.
//

import Foundation

final class JoinRoomNotFoundView: JoinRoomChildView {
    private let noRoomLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: I18n.View_MV_CheckController_Tip, config: .body, textColor: .ud.textCaption)
        return label
    }()

    private(set) lazy var scanAgainButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_ScanAgain_ClickText, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgPriPressed, for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        button.addInteraction(type: .lift)
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        return button
    }()

    override func setupViews() {
        super.setupViews()
        let contentView = UIView()
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 20, bottom: 0, right: 20))
        }

        contentView.addSubview(noRoomLabel)
        contentView.addSubview(scanAgainButton)

        noRoomLabel.numberOfLines = 0
        noRoomLabel.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }

        scanAgainButton.snp.makeConstraints { make in
            make.top.equalTo(noRoomLabel.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(buttonHeight)
        }
    }

    private var buttonHeight: CGFloat {
        style == .popover ? 36 : 48
    }

    override func updateStyle() {
        scanAgainButton.snp.updateConstraints { make in
            make.height.equalTo(buttonHeight)
        }
    }

    override func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        self.noRoomLabel.preferredMaxLayoutWidth = maxWidth - 40
        var h: CGFloat = 4 + 20 + buttonHeight
        h += self.noRoomLabel.sizeThatFits(CGSize(width: noRoomLabel.preferredMaxLayoutWidth, height: .greatestFiniteMagnitude)).height
        return h
    }
}
