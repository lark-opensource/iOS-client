//
//  MeetingRoomBuildingCell.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/16.
//  Copyright © 2019 EE. All rights reserved.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UIKit

final class SelectedMeetingRoomView: UIView {
    let titleLabel = UILabel.cd.textLabel()
    let inactivateTag = TagViewProvider.inactivate()
    let needApprovalTag = TagViewProvider.needApproval

    var close: ((CalendarMeetingRoom) -> Void)?
    let closeButton = UIButton.cd.button(type: .system)
    let icon = UIImageView(image: NewEventViewUIStyle.Image.meetingRoomIcon)

    private func layout(icon: UIView, in superView: UIView) {
        superView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.left.equalToSuperview().offset(18)
        }
    }

    private func layout(closeButton: UIView, in superView: UIView) {
        superView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.trailing.equalToSuperview().offset(NewEventViewUIStyle.Margin.rightMargin)
        }
    }

    private func layoutStackView(_ stackView: UIStackView,
                                 nameView: UIView,
                                 inactivateTag: UIView,
                                 needApprovalTag: UIView) {
        nameView.removeFromSuperview()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(icon.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-33)
        }
        stackView.addArrangedSubview(nameView)
        stackView.addArrangedSubview(inactivateTag)
        stackView.addArrangedSubview(needApprovalTag)
    }

    private func layout(line: UIView, in superView: UIView) {
        superView.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.bottom.right.equalToSuperview()
            make.left.equalToSuperview().offset(48)
        }
    }

    init() {
        super.init(frame: .zero)
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        layout(icon: icon, in: self)
        layout(closeButton: closeButton, in: self)
        layoutStackView(
            UIStackView(),
            nameView: titleLabel,
            inactivateTag: inactivateTag,
            needApprovalTag: needApprovalTag
        )
        layout(line: line, in: self)

        closeButton.contentHorizontalAlignment = .right
        closeButton.setImage(NewEventViewUIStyle.Image.littleClose, for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)

        inactivateTag.isHidden = true
        needApprovalTag.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func closeAction() {
        if let meetingRoom = self.model {
            self.close?(meetingRoom)
        }
    }

    private var model: CalendarMeetingRoom? {
        didSet {
            guard let model = model else {
                self.titleLabel.text = nil
                self.inactivateTag.isHidden = true
                self.needApprovalTag.isHidden = true
                return
            }
            self.titleLabel.text = model.fullName
            self.inactivateTag.isHidden = !model.isDisabled
            self.needApprovalTag.isHidden = !(model.needsApproval && !model.isDisabled)
        }
    }

    func setupContent(model: CalendarMeetingRoom, allowDeleteOriginalRooms: Bool) {
        self.model = model
        if allowDeleteOriginalRooms || model.permission == .writable {
            self.closeButton.isHidden = false
        } else {
            self.closeButton.isHidden = true
        }
    }

}
