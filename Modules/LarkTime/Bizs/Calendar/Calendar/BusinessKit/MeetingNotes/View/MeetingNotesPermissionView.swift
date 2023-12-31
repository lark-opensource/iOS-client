//
//  MeetingNotesPermissionView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/9/22.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import SnapKit

protocol MeetingNotesPermissionViewDelegate: AnyObject {
    func showPermissionSelectView(_ view: MeetingNotesPermissionView, onCompleted: @escaping ((CalendarNotesEventPermission) -> Void))
}

typealias CalendarNotesEventPermission = MeetingNotesModel.EventPermission

class MeetingNotesPermissionView: UIView {

    static let clickColor = UDColor.primaryContentDefault

    private lazy var trailClickableView = TrailClickableView()

    private lazy var downIcon = UDIcon.downBoldOutlined.ud.withTintColor(Self.clickColor)
    private lazy var upIcon = UDIcon.upBoldOutlined.ud.withTintColor(Self.clickColor)

    private lazy var clickIcon: UIImageView = UIImageView(image: downIcon)

    private lazy var clickLabel: UILabel = {
        let label = UILabel()
        label.textColor = Self.clickColor
        return label
    }()

    private lazy var clickView: UIView = {
        let containerView = UIView()
        containerView.addSubview(clickLabel)
        containerView.addSubview(clickIcon)
        clickLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        clickIcon.snp.makeConstraints { make in
            make.size.equalTo(12)
            make.leading.equalTo(clickLabel.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
        }
        return containerView
    }()

    weak var delegate: MeetingNotesPermissionViewDelegate?

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UDColor.bgFloat
        addSubview(trailClickableView)
        trailClickableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func toggleClickIcon() {
        if clickIcon.image == downIcon {
            clickIcon.image = upIcon
        } else {
            clickIcon.image = downIcon
        }
    }

    func updateClickLabel(permission: CalendarNotesEventPermission) {
        let promptConfig = TrailClickableView.UIConfig(
            text: I18n.Calendar_G_EventInviteesCan_Desc,
            style: .init()
                .font(UDFont.body2)
                .color(UDColor.textTitle)
                .lineHeight(.point(22))
                .padding(right: .point(6), left: .point(0))
        )
        clickLabel.text = permission.desc
        clickLabel.font = UDFont.body2
        clickLabel.sizeToFit()

        let trailViewSize = CGSize(
            width: clickLabel.bounds.width + 16,
            height: 20
        )

        trailClickableView.updateContent(
            promptConfig: promptConfig,
            trailView: clickView,
            trailViewSize: trailViewSize
        )
        trailClickableView.clickAction = { [weak self] in
            guard let self = self else { return }
            self.toggleClickIcon()
            self.delegate?.showPermissionSelectView(self) { [weak self] permission in
                self?.updateClickLabel(permission: permission)
                self?.toggleClickIcon()
            }
        }
    }
}
