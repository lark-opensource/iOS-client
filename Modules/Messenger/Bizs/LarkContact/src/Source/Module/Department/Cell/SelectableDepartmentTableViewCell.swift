//
//  SelectableDepartmentTableViewCell.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/2/2.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import LarkListItem
import LarkSearchCore
import Homeric

enum SubordinateButtonStatus {
    case enable /// 可以进入下一级
    case disable /// 禁用
}

protocol SelectableDepartmentCellPropsProtocol {
    var selectChannel: SelectChannel { get }
    var departmentName: String { get }
    var info: String { get }
    var checkStatus: ContactCheckBoxStaus { get }
    var tapHandler: () -> Void { get }
    var buttonStatus: SubordinateButtonStatus { get }
}

struct SelectableDepartmentCellProps: SelectableDepartmentCellPropsProtocol {
    let selectChannel: SelectChannel
    let departmentName: String
    let info: String
    let checkStatus: ContactCheckBoxStaus
    let tapHandler: () -> Void
    let buttonStatus: SubordinateButtonStatus
}

final class SelectableDepartmentTableViewCell: UITableViewCell {
    private lazy var departmentInfoView: ListItem = {
        let departmentInfoView = ListItem()
        departmentInfoView.avatarView.image = Resources.department_picker_default_icon
        departmentInfoView.infoLabel.isHidden = true
        departmentInfoView.nameTag.isHidden = true
        departmentInfoView.additionalIcon.isHidden = true
        departmentInfoView.bottomSeperator.isHidden = true
        departmentInfoView.textContentView.spacing = 4
        departmentInfoView.statusLabel.setUIConfig(StatusLabel.UIConfig(font: UIFont.systemFont(ofSize: 16)))
        departmentInfoView.statusLabel.descriptionView.setContentCompressionResistancePriority(.required, for: .horizontal)
        departmentInfoView.statusLabel.descriptionView.setContentHuggingPriority(.required, for: .horizontal)
        departmentInfoView.statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        departmentInfoView.statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        return departmentInfoView
    }()

    private lazy var subordinateButton: UIButton = {
        let subordinateButton = UIButton()
        subordinateButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_Subdepartment, for: .normal)
        subordinateButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        subordinateButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        subordinateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        subordinateButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        return subordinateButton
    }()

    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.fillHover
        highlightView.layer.cornerRadius = IGLayer.commonHighlightCellRadius
        highlightView.isHidden = true
        return highlightView
    }()

    // 整行置灰蒙层
    private lazy var coverView: UIView = {
        let coverView = UIView()
        coverView.backgroundColor = UIColor.ud.bgBody
        coverView.alpha = 0.5
        return coverView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(1.0)
            make.bottom.equalToSuperview().offset(-1.0)
            make.left.equalToSuperview().offset(8.0)
            make.right.equalToSuperview().offset(-6.0)
        }

        contentView.addSubview(departmentInfoView)
        contentView.addSubview(subordinateButton)

        departmentInfoView.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
            make.right.lessThanOrEqualTo(subordinateButton.snp.left)
        }
        subordinateButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(10)
            make.right.equalToSuperview()
        }
        departmentInfoView.bottomSeperator.snp.remakeConstraints { (make) in
            make.leading.equalTo(departmentInfoView.nameLabel.snp.leading)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.trailing.equalTo(self.snp.trailing)
        }
        departmentInfoView.rightMarginConstraint.update(offset: 0)

        self.contentView.addSubview(self.coverView)
        coverView.snp.makeConstraints { (make) in
            make.left.equalTo(self.departmentInfoView.avatarView.snp.left)
            make.right.equalTo(self.departmentInfoView.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        coverView.isHidden = true
    }

    fileprivate var props: SelectableDepartmentCellPropsProtocol? {
        didSet {
            // 默认情况下没有半透明蒙层
            coverView.isHidden = true
            guard let props = self.props else { return }
            switch props.checkStatus {
            case .invalid:
                departmentInfoView.checkBox.isHidden = true
            case .selected:
                departmentInfoView.checkBox.isHidden = false
                updateCheckBox(selected: true, enabled: true)
            case .unselected:
                departmentInfoView.checkBox.isHidden = false
                updateCheckBox(selected: false, enabled: true)
            case .defaultSelected:
                departmentInfoView.checkBox.isHidden = false
                self.updateCheckBox(selected: true, enabled: false)
                coverView.isHidden = false
            case .disableToSelect:
                departmentInfoView.checkBox.isHidden = false
                self.updateCheckBox(selected: false, enabled: false)
                coverView.isHidden = false
            }

            departmentInfoView.nameLabel.text = props.departmentName
            if props.info.isEmpty {
                departmentInfoView.statusLabel.isHidden = true
            } else {
                departmentInfoView.statusLabel.isHidden = false
                departmentInfoView.statusLabel.set(
                    description: NSAttributedString(string: "(\(props.info))"),
                    descriptionIcon: nil,
                    showIcon: false
                )
            }

            switch props.buttonStatus {
            case .enable:
                subordinateButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            case .disable:
                subordinateButton.setTitleColor(UIColor.ud.N400, for: .normal)
            }
        }
    }

    func setProps(_ props: SelectableDepartmentCellPropsProtocol) {
       self.props = props
    }

    private func updateCheckBox(selected: Bool, enabled: Bool) {
        departmentInfoView.checkBox.isEnabled = enabled
        departmentInfoView.checkBox.isSelected = selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.highlightView.isHidden = !highlighted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapped(_ button: UIButton) {
        self.props?.tapHandler()
        // 组织架构埋点
        guard let props = props else { return }
        switch props.selectChannel {
        case .organization:
            SearchTrackUtil.trackPickerSelectArchitectureClick(clickType: SearchTrackUtil.PickerClickType.nextLevel(target: Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_VIEW))
        case .collaboration:
            SearchTrackUtil.trackPickerSelectAssociatedOrganizationsClick(clickType: .nextLevel(target: Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_VIEW))
        default: break
        }
    }
}
