//
//  OrganizationCell.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/28.
//

import Foundation
import UIKit
import SKUIKit
import SKResource
import Kingfisher
import UniverseDesignCheckBox

// 下级 View
class SubordinateView: UIControl {

    var didClickedBlock: (() -> Void)?

    private lazy var seperateLine: UIView = {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    private lazy var subordinateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = BundleI18n.SKResource.Doc_Permission_AddUserSubDep
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.colorfulBlue
        return label
    }()

    private lazy var rightArrow: UIImageView = {
        let arrow = UIImageView()
        arrow.image = BundleResources.SKResource.Common.Collaborator.icon_tool_arrow_nor.withRenderingMode(.alwaysTemplate)
        arrow.tintColor = UIColor.ud.colorfulBlue
        return arrow
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addTarget(self, action: #selector(didClicked), for: .touchUpInside)
        addSubview(rightArrow)
        rightArrow.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        addSubview(subordinateLabel)
        subordinateLabel.snp.makeConstraints { (make) in
            make.right.equalTo(rightArrow.snp.left).offset(-2)
            make.centerY.equalToSuperview()
        }
        addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.right.equalTo(subordinateLabel.snp.left).offset(-12.5)
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(17)
            make.height.equalTo(18)
            make.width.equalTo(1)
        }
    }

    func update(isDisabled: Bool) {
        rightArrow.image = BundleResources.SKResource.Common.Collaborator.icon_tool_arrow_nor.withRenderingMode(.alwaysTemplate)
        rightArrow.tintColor = isDisabled ? UIColor.ud.B300 : UIColor.ud.colorfulBlue
        subordinateLabel.textColor = isDisabled ? UIColor.ud.B300 : UIColor.ud.colorfulBlue
    }

    @objc
    private func didClicked() {
        didClickedBlock?()
    }
}

enum OrganizationCellType {
    case department
    case employee
}

// 组织架构元数据，可能是部门，也可能是员工
protocol OrganizationCellItem: Any {
    var id: String { get }
    var name: String { get }
    var avatarURL: String { get }
    var organizationType: OrganizationCellType { get }
    var selectType: SelectType { get set }
    var isExist: Bool { get set }
}

class OrganizationCell: UITableViewCell {

    private var organizationInfoItem: OrganizationCellItem?
    var didClickedBlock: ((_ item: OrganizationCellItem?) -> Void)?

    private lazy var checkbox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple, config: .init(style: .circle)) { (_) in }
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var subordinateView: SubordinateView = {
        let subordinate = SubordinateView()
        subordinate.didClickedBlock = { [weak self] in
            guard let self = self else { return }
            self.didClickedBlock?(self.organizationInfoItem)
        }
        return subordinate
    }()

    private lazy var bottomSeprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N300
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(subordinateView)
        subordinateView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(60)
            make.width.greaterThanOrEqualTo(51)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualTo(contentView.snp.top).offset(14)
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalTo(subordinateView.snp.left).offset(-16)
        }
        contentView.addSubview(bottomSeprateLine)
        bottomSeprateLine.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func update(item: OrganizationCellItem) {
        self.organizationInfoItem = item
        updateselectedIcon(item: item)
        // 不可选状态: 灰色
        let alpha: CGFloat = item.selectType == .disable ? 0.3 : 1
        titleLabel.alpha = alpha
        // 内容
        titleLabel.text = item.name
        // 更新下级View
        subordinateView.update(isDisabled: item.selectType == .blue)
    }

    func updateselectedIcon(item: OrganizationCellItem) {
        checkbox.isHidden = false
        checkbox.isEnabled = true
        switch item.selectType {
            case .blue:
                checkbox.isSelected = true
            case .gray:
                checkbox.isSelected = false
            case .disable:
                checkbox.isSelected = false
            case .none:
                checkbox.isHidden = true
            case .hasSelected:
                checkbox.isSelected = true
                checkbox.isEnabled = false
        }
    }
}

class EmployeeCell: UITableViewCell {

    private var organizationInfoItem: OrganizationCellItem?

    private lazy var checkbox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple, config: .init(style: .circle)) { (_) in }
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = SKAvatar(configuration: .init(backgroundColor: UIColor.ud.N100,
                                               style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var bottomSeprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N300
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(13)
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(48)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualTo(contentView.snp.top).offset(14)
            make.left.equalTo(iconImageView.snp.right).offset(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        contentView.addSubview(bottomSeprateLine)
        bottomSeprateLine.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func update(item: OrganizationCellItem) {
        self.organizationInfoItem = item
        iconImageView.snp.updateConstraints { (make) in
            make.width.equalTo(48)
        }
        if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: item.avatarURL.hashValue.description) {
            iconImageView.image = image
        } else {
            guard let url = URL(string: item.avatarURL) else { return }
            let resource = ImageResource(downloadURL: url, cacheKey: item.avatarURL.hashValue.description)
            iconImageView.kf.setImage(with: resource,
                                      placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        }
        updateselectedIcon(item: item)
        // 不可选状态: 灰色
        let alpha: CGFloat = (item.selectType == .hasSelected || item.selectType == .disable) ? 0.3 : 1
        iconImageView.alpha = alpha
        titleLabel.alpha = alpha
        // 内容
        titleLabel.text = item.name
    }

    func updateselectedIcon(item: OrganizationCellItem) {
        checkbox.isHidden = false
        checkbox.isEnabled = true
        switch item.selectType {
            case .blue:
                checkbox.isSelected = true
            case .gray:
                checkbox.isSelected = false
            case .disable:
                checkbox.isSelected = false
            case .none:
                checkbox.isHidden = true
            case .hasSelected:
                checkbox.isSelected = true
                checkbox.isEnabled = false
        }
    }
}
