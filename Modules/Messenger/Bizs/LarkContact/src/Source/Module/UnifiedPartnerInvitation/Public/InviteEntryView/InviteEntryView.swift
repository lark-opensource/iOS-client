//
//  InviteEntryView.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/11/4.
//

import Foundation
import LarkUIKit
import SnapKit
import UIKit

public class InviteEntryView: UIControl {
    public init(icon: UIImage, title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        layoutPageSubviews()
        iconView.image = icon
        titleLabel.text = title
    }

    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.fillHover
        highlightView.layer.cornerRadius = IGLayer.commonHighlightCellRadius
        highlightView.isHidden = true
        return highlightView
    }()

    public override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.highlightView.isHidden = !self.isHighlighted
            }
        }
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 1
        return label
    }()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.mine_right_arrow
        view.contentMode = .scaleAspectFit
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutPageSubviews() {
        addSubview(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8.0)
            make.bottom.equalToSuperview().offset(-8.0)
            make.left.equalToSuperview().offset(8.0)
            make.right.equalToSuperview().offset(-8.0)
        }
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(arrowView)
        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(16)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(arrowView.snp.left).offset(-16)
        }
        arrowView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(13)
        }
    }
}

public final class ExternalContactInviteEntryView: InviteEntryView {
    private let highlightColor = UIColor.ud.fillHover
    private let normalColor = UIColor.ud.bgBody
    private lazy var highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = normalColor
        view.layer.cornerRadius = 6.0
        return view
    }()

    public init(title: String) {
        super.init(
            icon: Resources.invite_contact_icon,
            title: title
        )
        self.addSubview(highlightView)
        self.sendSubviewToBack(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6.0)
            make.bottom.equalToSuperview().offset(-6.0)
            make.left.equalToSuperview().offset(6.0)
            make.right.equalToSuperview().offset(-6.0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.highlightView.backgroundColor = highlightColor
        super.touchesBegan(touches, with: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.highlightView.backgroundColor = normalColor
        super.touchesEnded(touches, with: event)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.highlightView.backgroundColor = normalColor
        super.touchesCancelled(touches, with: event)
    }
}

public final class MemberInviteEntryView: InviteEntryView {
    public init() {
        super.init(
            icon: Resources.invite_member_icon,
            title: BundleI18n.LarkContact.Lark_Invitation_InviteTeamMembers_TitleBar
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
