//
//  TopStructureTableViewCell.swift
//  Lark
//
//  Created by zc09v on 2017/7/22.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import EENavigator
import LKCommonsLogging
import LarkContainer
import UniverseDesignTag

final class TopStructureTableViewCell: UITableViewCell {
    private var departmentLabel: UILabel = .init()
    private var separator: UIView = UIView()
    private lazy var arrowIcon: UIImageView = {
        let arrowIcon = UIImageView(image: Resources.dark_right_arrow)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        return arrowIcon
    }()

    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.fillHover
        highlightView.layer.cornerRadius = IGLayer.commonHighlightCellRadius
        highlightView.isHidden = true
        return highlightView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.ud.bgBody
//        contentView.backgroundColor = UIColor.ud.bgBody
        self.selectedBackgroundView = BaseCellSelectView()

        self.selectionStyle = .none

        contentView.addSubview(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(1.0)
            make.bottom.equalToSuperview().offset(-1.0)
            make.left.equalToSuperview().offset(6.0)
            make.right.equalToSuperview().offset(-6.0)
        }

        let prefferImageView = UIImageView()
        prefferImageView.image = Resources.department
        self.contentView.addSubview(prefferImageView)
        prefferImageView.contentMode = .center
        prefferImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(52)
            make.width.height.equalTo(10)
        }

        contentView.addSubview(self.arrowIcon)
        self.arrowIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }

        departmentLabel = UILabel()
        departmentLabel.font = UIFont.systemFont(ofSize: 16)
        departmentLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(departmentLabel)
        departmentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(prefferImageView.snp.right).offset(10)
            make.right.equalTo(arrowIcon.snp.left).offset(-26)
        }

        separator = self.lu.addBottomBorder(leading: prefferImageView.snp.left, color: UIColor.ud.lineDividerDefault)
    }

    func set(departmentName: String, userCount: Int32) {
        //departmentLabel.text = "\(departmentName) (\(userCount))"
        departmentLabel.text = departmentName
    }

    func hideSeparator(isHidden: Bool) {
        separator.isHidden = isHidden
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.highlightView.isHidden = !highlighted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OrganizationTableViewCell: UITableViewCell {
    private lazy var internalTag = {
        let tag = UDTag(withText: BundleI18n.LarkContact.Lark_B2B_Menu_InternalOrg)
        tag.colorScheme = .purple
        tag.sizeClass = .mini
        return tag
    }()

    private lazy var departmentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private var separator: UIView = UIView()
    private lazy var arrowIcon: UIImageView = {
        let arrowIcon = UIImageView(image: Resources.dark_right_arrow)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        return arrowIcon
    }()

    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.fillHover
        highlightView.layer.cornerRadius = IGLayer.commonHighlightCellRadius
        highlightView.isHidden = true
        return highlightView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let isInternal = reuseIdentifier == "InternalCollaborationTableViewCell" ? true : false

        self.backgroundColor = UIColor.ud.bgBody
        self.selectedBackgroundView = BaseCellSelectView()

        self.selectionStyle = .none

        contentView.addSubview(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(1.0)
            make.bottom.equalToSuperview().offset(-1.0)
            make.left.equalToSuperview().offset(6.0)
            make.right.equalToSuperview().offset(-6.0)
        }

        contentView.addSubview(self.arrowIcon)
        self.arrowIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }

        self.contentView.addSubview(departmentLabel)
        departmentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(52)
            if !isInternal {
                make.right.lessThanOrEqualTo(arrowIcon.snp.left).offset(-26)
            }
        }
        if isInternal {
            self.contentView.addSubview(internalTag)
            internalTag.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(departmentLabel.snp.right).offset(10)
                make.right.lessThanOrEqualTo(arrowIcon.snp.left).offset(-26)
            }
        }

        separator = self.lu.addBottomBorder(leading: departmentLabel.snp.left, color: UIColor.ud.lineDividerDefault)
    }

    func set(departmentName: String) {
        departmentLabel.text = departmentName
    }

    func hideSeparator(isHidden: Bool) {
        separator.isHidden = isHidden
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.highlightView.isHidden = !highlighted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TenantItemViewCell: UITableViewCell {
    static private let logger = Logger.log(TenantItemViewCell.self, category: "Contact.TenantItemViwCell")
    private var iconView: UIImageView = UIImageView()
    private var titleLabel: UILabel = UILabel()
    private var adminLabel: UILabel = UILabel()
    var tenantName: String = "" {
        didSet {
            self.titleLabel.text = tenantName
        }
    }
    var iconURL: URL? {
        didSet {
            if let iconURL = iconURL {
                self.iconView.kf.setImage(with: iconURL)
            } else {
                self.iconView.image = Resources.defaultTenantImage
            }
        }
    }

    var adminURL: String = ""
    var navigator: Navigatable?
    var isAdmin: Bool = false {
        didSet {
            layout()
        }
    }

    private func openLink(linkString: String, userInfo: [String: Any]) {
        Tracer.contactOrganizationManagementClick(source: "contact")
        guard let url = URL(string: linkString) else {
            TenantItemViewCell.logger.error("openLink failed, adminURL is nil.")
            return
        }
        guard let topVC = navigator?.mainSceneTopMost else {
            TenantItemViewCell.logger.error("openLink failed, nav is nil.")
            return
        }
        navigator?.push(url, context: userInfo, from: topVC)
    }

    func layout() {
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(32)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalTo(16)
        }
        iconView.layer.masksToBounds = true
        iconView.layer.cornerRadius = iconView.bounds.size.width * 0.5

        // admin
        if self.isAdmin {
            adminLabel.isHidden = false
            let width = adminLabel.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(20))).width
            adminLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(iconView)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(20)
                make.width.equalTo(width)
            }
        } else {
            adminLabel.isHidden = true
            adminLabel.frame = .zero
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconView)
            make.left.equalTo(56)
            if self.isAdmin {
                make.right.equalTo(adminLabel.snp.left).offset(-16)
            } else {
                make.right.equalToSuperview().offset(-16)
            }
        }
        layoutIfNeeded()
    }

    @objc
    private func manageEntry(recognizer: UITapGestureRecognizer) {
        openLink(linkString: self.adminURL, userInfo: [:])
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(adminLabel)
        adminLabel.isHidden = true
        adminLabel.textAlignment = .right
        adminLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        adminLabel.font = UIFont.systemFont(ofSize: 14)
        adminLabel.textColor = UIColor.ud.textLinkNormal
        adminLabel.text = BundleI18n.LarkContact.Lark_Contacts_Manage
        adminLabel.numberOfLines = 1
        adminLabel.isUserInteractionEnabled = true

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(manageEntry(recognizer:)))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        adminLabel.addGestureRecognizer(tapRecognizer)

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1

        contentView.addSubview(iconView)
        iconView.contentMode = .scaleToFill

        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class MoreDepartmentsViewCell: UITableViewCell {
    private var moreDepartmentLabel: UILabel = .init()
    private var separator: UIView = UIView()
    private lazy var arrowIcon: UIImageView = {
        let arrowIcon = UIImageView(image: Resources.dark_right_arrow)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        return arrowIcon
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        contentView.addSubview(self.arrowIcon)
        self.arrowIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }
        moreDepartmentLabel = UILabel()
        moreDepartmentLabel.font = UIFont.systemFont(ofSize: 14)
        moreDepartmentLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(moreDepartmentLabel)
        moreDepartmentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(76)
            make.right.equalTo(arrowIcon.snp.left).offset(-5)
        }
        separator = self.lu.addBottomBorder(leading: moreDepartmentLabel.snp.left, color: UIColor.ud.lineDividerDefault)
    }
    func set(title: String) {
        moreDepartmentLabel.text = title
    }
    func hideSeparator(isHidden: Bool) {
        separator.isHidden = isHidden
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MoreOrganizationViewCell: UITableViewCell {
    private var moreDepartmentLabel: UILabel = .init()
    private var separator: UIView = UIView()
    private lazy var arrowIcon: UIImageView = {
        let arrowIcon = UIImageView(image: Resources.showDetailSize16)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        return arrowIcon
    }()

    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.fillHover
        highlightView.layer.cornerRadius = IGLayer.commonHighlightCellRadius
        highlightView.isHidden = true
        return highlightView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        self.backgroundColor = UIColor.ud.bgBody

        moreDepartmentLabel = UILabel()
        moreDepartmentLabel.font = UIFont.systemFont(ofSize: 16)
        moreDepartmentLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(moreDepartmentLabel)
        moreDepartmentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(76)
            make.right.lessThanOrEqualToSuperview()
        }

        contentView.addSubview(self.arrowIcon)
        self.arrowIcon.snp.makeConstraints { (make) in
            make.left.equalTo(moreDepartmentLabel.snp.right).offset(10)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(highlightView)
        self.highlightView.snp.makeConstraints { (make) in
            make.top.equalTo(moreDepartmentLabel.snp.top).offset(-6.0)
            make.bottom.equalTo(moreDepartmentLabel.snp.bottom).offset(6.0)
            make.left.equalTo(moreDepartmentLabel.snp.left).offset(-6.0)
            make.right.equalTo(arrowIcon.snp.right).offset(6.0)
        }

        separator = self.lu.addBottomBorder(leading: 52, color: UIColor.ud.lineDividerDefault)
    }

    func set(title: String, isInternal: Bool, hideMore: Bool) {
        moreDepartmentLabel.text = title

        if hideMore {
            arrowIcon.setImage(Resources.showDetailSize16, tintColor: nil)
        } else {
            arrowIcon.setImage(Resources.hideMoreSize16, tintColor: nil)
        }

        if isInternal {
            moreDepartmentLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(52)
            }
        } else {
            moreDepartmentLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(76)
            }
        }
    }

    func hideSeparator(isHidden: Bool) {
        separator.isHidden = isHidden
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.highlightView.isHidden = !highlighted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
