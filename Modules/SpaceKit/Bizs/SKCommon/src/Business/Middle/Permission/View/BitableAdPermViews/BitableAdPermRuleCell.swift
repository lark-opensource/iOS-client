//
//  BitableAdPermRuleCell.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/19.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignTag
import UniverseDesignColor
import UniverseDesignFont

class BitableAdPermRuleCell: BitableAdPermBaseCell {
    
    static let defaultReuseID = "BitableAdPermRuleCell"
    
    var model: BitableAdPermUnitDataRule?
    var addCollaboratorEvent: ((BitableAdPermUnitDataRule) -> Void)?
    var editCollaboratorEvent: ((BitableAdPermUnitDataRule) -> Void)?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.headline
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        UILabel()
    }()

    private lazy var tagView: UDTag = {
        UDTag(withText: "")
    }()

    private lazy var firstSplitView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var addCollaboratorView: AddCollaboratorView = {
        let view = AddCollaboratorView()
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(addCollaboratorViewTap(_:)))
        view.addGestureRecognizer(gestureRecognizer)
        view.updateTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_AddMember)
        return view
    }()

    private lazy var secondSplitView: UIView = {
       let view = UIView()
       view.backgroundColor = UIColor.ud.lineDividerDefault
       return view
    }()

    private lazy var manageCollaboratorView: ManageCollaboratorView = {
        let view = ManageCollaboratorView()

        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(collaboratorViewTap(_:)))
        view.addGestureRecognizer(gestureRecognizer)
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
        contentView.addSubview(tagView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(firstSplitView)
        contentView.addSubview(addCollaboratorView)
        contentView.addSubview(secondSplitView)
        contentView.addSubview(manageCollaboratorView)

        let paddingH: CGFloat = 16.0
        let paddingV: CGFloat = 15.0

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(paddingH)
            make.top.equalToSuperview().offset(paddingV)
            make.height.equalTo(22)
        }

        tagView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.right.lessThanOrEqualToSuperview().offset(-paddingH)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(paddingH)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalTo(addCollaboratorView.snp.top).offset(-paddingV)
        }

        firstSplitView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalTo(addCollaboratorView.snp.top)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        addCollaboratorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(paddingH)
            make.bottom.equalTo(manageCollaboratorView.snp.top)
            make.height.equalTo(52)
        }

        secondSplitView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalTo(addCollaboratorView.snp.bottom)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        manageCollaboratorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(paddingH)
            make.bottom.equalToSuperview()
            make.height.equalTo(52)
        }
    }
    
    public func setModel(_ model: BitableAdPermUnitDataRule) {
        self.model = model
        titleLabel.text = model.title
        
        switch model.tagType {
        case .none:
            tagView.isHidden = true
        case .origin:
            tagView.isHidden = false
            let configure = UDTag.Configuration.text(
                BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultPermission,
                tagSize: .mini,
                colorScheme: UDTag.Configuration.ColorScheme.normal,
                isOpaque: false
            )
            tagView.updateConfiguration(configure)
        case .advance:
            tagView.isHidden = false
            let configure = UDTag.Configuration.text(
                BundleI18n.SKResource.Bitable_AdvancedPermission_PremiumFeatureIncludedTag,
                tagSize: .mini,
                colorScheme: UDTag.Configuration.ColorScheme.orange,
                isOpaque: false
            )
            tagView.updateConfiguration(configure)
        }
        descriptionLabel.sk_setText(model.subTitle)

        addCollaboratorView.updateAddedAvailability(model.addedAvailability.addable)
        manageCollaboratorView.updateManagedAvailability(model.managedAvailability.editable)
        manageCollaboratorView.update(collaborators: model.collaborators)
    }

    @objc
    fileprivate func addCollaboratorViewTap(_ sender: AnyObject?) {
        guard let model = model else { return }
        addCollaboratorEvent?(model)
    }

    @objc
    fileprivate func collaboratorViewTap(_ sender: AnyObject?) {
        guard let model = model else { return }
        editCollaboratorEvent?(model)
    }
}
