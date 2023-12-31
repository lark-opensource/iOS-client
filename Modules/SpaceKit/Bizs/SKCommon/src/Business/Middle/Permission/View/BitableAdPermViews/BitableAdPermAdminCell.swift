//
//  File.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/18.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignTag
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

class BitableAdPermAdminCell: BitableAdPermBaseCell {
    
    static let defaultReuseID = "BitableAdPermAdminCell"
    
//    var editAction: ((BitableAdPermAdminCell) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.headline
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.text = BundleI18n.SKResource.Bitable_AdvancedPermission_WhoCanManage
        return label
    }()
    
    private let titleIconView: UIImageView = {
        let vi = UIImageView()
        vi.image = UDIcon.lockFilled.ud.withTintColor(UDColor.iconN2)
        return vi
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.sk_setText(BundleI18n.SKResource.Bitable_AdvancedPermission_WhoCanManageDesc)
        return label
    }()

    private let spLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private let editView: ManageCollaboratorView = {
        let view = ManageCollaboratorView()
        view.updateManagedAvailability(false)
        view.updateTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_RoleMember_Mobile)
        return view
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(titleIconView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(spLine)
        contentView.addSubview(editView)
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(editTap(_:)))
//        editView.addGestureRecognizer(tap)

        let paddingH: CGFloat = 16.0
        let paddingV: CGFloat = 15.0

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(paddingH)
            make.top.equalToSuperview().offset(paddingV)
            make.height.equalTo(22)
        }
        
        titleIconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(14)
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.right.lessThanOrEqualToSuperview().inset(paddingH)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(paddingH)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalTo(editView.snp.top).offset(-paddingV)
            make.height.greaterThanOrEqualTo(20)
        }

        spLine.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalTo(editView.snp.top)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        editView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(paddingH)
            make.bottom.equalToSuperview()
            make.height.equalTo(52)
        }
    }
    
    public func update(_ data: BitableAdPermUnitDataAdmin) {
        editView.update(collaborators: data.administrators)
    }

//    @objc
//    fileprivate func editTap(_ sender: UITapGestureRecognizer) {
//        editAction?(self)
//    }
}
