//
//  MeetingRoomCell.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/9.
//

import UniverseDesignIcon
import Foundation
import SnapKit
import UIKit
import UniverseDesignCheckBox

protocol EventMeetingRoomCellDataType {
    var name: String { get }
    // 需要审批（审批类会议室）
    var needsApproval: Bool { get }
    var isAvailable: Bool { get }
    var unAvailableReason: String? { get }
    var capacityDesc: String { get }
    var location: String { get }
    var isSelected: SelectType? { get } // 是否处于选择态
    var pathName: String { get }
}

// 会议室查询界面使用二级样式 （默认）
// 会议室搜索界面使用一级样式  (setFirstLevelStyle)
final class EventMeetingRoomCell: UITableViewCell, ViewDataConvertible {
    var viewData: EventMeetingRoomCellDataType? {
        didSet {
            let meetingRoomIcon: UIImage
            let capacityIcon: UIImage
            let titleColor: UIColor
            let subTitleColor: UIColor
            if let isAvailable = viewData?.isAvailable, isAvailable {
                meetingRoomIcon = UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3)
                capacityIcon = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3)
                titleColor = UIColor.ud.textTitle
                subTitleColor = UIColor.ud.N600
            } else {
                meetingRoomIcon = UDIcon.getIconByKeyNoLimitSize(.roomUnavailableOutlined).renderColor(with: .n4)
                capacityIcon = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n4)
                titleColor = UIColor.ud.textDisabled
                subTitleColor = UIColor.ud.textDisabled
            }
            let infoBtnImage = UDIcon.getIconByKeyNoLimitSize(.infoOutlined).renderColor(with: .n3)
            iconView.image = meetingRoomIcon.withRenderingMode(.alwaysOriginal)
            infoView.titleLabel.textColor = titleColor
            infoView.titleLabel.text = viewData?.name
            infoView.capacityLabel.textColor = subTitleColor
            infoView.capacityLabel.text = viewData?.capacityDesc
            infoView.icon.image = capacityIcon.withRenderingMode(.alwaysOriginal)
            infoView.approveTag.isHidden = !(viewData?.needsApproval ?? false)
            infoView.updateEquipment(text: viewData?.location)
            infoView.equipmentLabel.textColor = subTitleColor
            infoView.updatePathName(text: viewData?.pathName)
            infoView.pathNameLabel.textColor = subTitleColor
            infoBtn.setImage(infoBtnImage, for: .normal)

            infoBtn.imageView?.snp.makeConstraints {
                $0.centerX.centerY.equalToSuperview()
                $0.size.equalTo(CGSize(width: 20, height: 20))
            }

            let (oldSelect, newSelect) = (isRoomSelected, viewData?.isSelected)
            switch (oldSelect, newSelect) {
            case let (nil, newSelect?):
                /// 变成多选态
                containerView.snp.updateConstraints {
                    $0.left.equalTo(86)
                }
                selectIcon.isHidden = false
                selectIcon.isEnabled = newSelect != .disabled
                selectIcon.isSelected = newSelect == .selected || newSelect == .halfSelected
                selectIcon.updateUIConfig(boxType: newSelect.boxType, config: UDCheckBoxUIConfig())
            case let (_, nil):
                /// 还原成单选态
                containerView.snp.updateConstraints {
                    $0.left.equalTo(48)
                }
                selectIcon.isHidden = true
            case let (_, newSelect?):
                /// 更改选择态
                selectIcon.isEnabled = newSelect != .disabled
                selectIcon.isSelected = newSelect == .selected || newSelect == .halfSelected
                selectIcon.updateUIConfig(boxType: newSelect.boxType, config: UDCheckBoxUIConfig())
            }
            self.isRoomSelected = newSelect
        }
    }

    private var iconView: UIImageView = UIImageView()
    private let infoView = MeetingRoomHomeTableViewCell.InfoView()
    private let containerView = UIView()
    var onTapped: (() -> Void)?
    /// 点击多选回调
    var onSelectClick: (() -> Void)?
    var infoBtnOnTapped: (() -> Void)?
    private var infoBtn: UIButton = UIButton()
    private var isRoomSelected: SelectType?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        selectIcon.tapCallBack = { [weak self] _ in
            self?.onSelectClick?()
        }
        contentView.addSubview(selectIcon)
        selectIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(52)
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(48)
            $0.right.top.bottom.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(contentOnClick))
        containerView.addGestureRecognizer(tapGesture)

        containerView.addSubview(iconView)
        containerView.addSubview(infoView)

        infoView.titleLabel.font = UIFont.systemFont(ofSize: 16)
        infoView.titleLabel.textColor = UIColor.ud.textTitle
        infoView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.top.bottom.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualToSuperview()
        }

        iconView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 16, height: 16))
            $0.left.equalToSuperview()
            $0.centerY.equalTo(infoView.titleLabel)
        }

        contentView.addSubview(infoBtn)
        infoBtn.snp.makeConstraints {
            $0.right.top.bottom.equalToSuperview()
            $0.width.equalTo(50)
        }

        infoBtn.addTarget(self, action: #selector(didInfoBtnClick), for: .touchUpInside)
        infoBtn.isHidden = true
    }

    func showInfoButton() {
        infoBtn.isHidden = false

        infoView.snp.updateConstraints {
            $0.trailing.lessThanOrEqualToSuperview().offset(-50)
        }
    }

    func setFirstLevelStyle() {
        containerView.snp.updateConstraints {
            $0.left.equalToSuperview().offset(16)
        }
    }

    @objc func contentOnClick() {
        // 处于多选态时点击当做点击多选按钮
        if let select = isRoomSelected {
            onSelectClick?()
        } else {
            onTapped?()
        }
    }

    @objc
    private func didInfoBtnClick() {
        infoBtnOnTapped?()
    }

    @objc
    private func onSelectedTapped() {
        onSelectClick?()
    }

    private let selectIcon = UDCheckBox()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
