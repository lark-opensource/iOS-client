//
//  BitableAdvancedPermissionsView.swift
//  Collaborator
//
//  Created by Da Lei on 2018/4/10.
//

import Foundation
import SnapKit
import SKResource
import RxSwift
import UniverseDesignTag
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignCheckBox

class AddCollaboratorView: UIView {
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UDIcon.memberAddOutlined.ud.withTintColor(UDColor.iconN1)
        return imageView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = UDColor.textTitle
        label.text = BundleI18n.SKResource.Bitable_AdvancedPermission_AddCollaborator
        return label
    }()
    private lazy var arrow: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.textPlaceholder)
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAddedAvailability(_ available: Bool) {
        if available {
            iconImageView.image = UDIcon.memberAddOutlined.ud.withTintColor(UDColor.iconN1)
            arrow.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconN2)
            titleLabel.textColor = UDColor.textTitle
        } else {
            iconImageView.image = UDIcon.memberAddOutlined.ud.withTintColor(UDColor.iconDisabled)
            arrow.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconDisabled)
            titleLabel.textColor = UDColor.textDisabled
        }
    }
    
    func updateTitle(_ text: String?) {
        titleLabel.text = text
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(8)
        }

        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
    }
}

class ManageCollaboratorView: UIView {

    private let avatarMaxDisplayCount: Int = 5

    private var totalCollaboratorCount: Int = 0

    private(set) var collaborators: [Collaborator] = []

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UDIcon.groupOutlined.ud.withTintColor(UDColor.iconN1)
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.textColor = UDColor.textTitle
        label.text = BundleI18n.SKResource.Doc_Share_Collaborators
        return label
    }()
    
    private lazy var avatarGroupView: CollaboratorAvatarGroupView = {
        let view = CollaboratorAvatarGroupView(maxAvatarCount: avatarMaxDisplayCount)
        return view
    }()

    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.textPlaceholder)
        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        
        addSubview(arrowImageView)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(avatarGroupView)
        
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.right.lessThanOrEqualTo(avatarGroupView.snp.left).offset(-12)
        }
        
        avatarGroupView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
    }

    func update(collaborators: [Collaborator]) {
        self.collaborators = collaborators
        self.reorderData(&self.collaborators)
        totalCollaboratorCount = collaborators.count
        if totalCollaboratorCount == 0 {
            avatarGroupView.isHidden = true
            arrowImageView.isHidden = false
        } else {
            arrowImageView.isHidden = true
            avatarGroupView.isHidden = false
            avatarGroupView.update(collaborators: collaborators, totalCount: totalCollaboratorCount, replaceWikiIconLocally: false)
        }
    }

    func updateManagedAvailability(_ available: Bool) {
        if available {
            iconImageView.image = UDIcon.groupOutlined.ud.withTintColor(UDColor.iconN1)
            arrowImageView.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconN2)
            titleLabel.textColor = UDColor.textTitle
            avatarGroupView.isEnabled = true
        } else {
            iconImageView.image = UDIcon.groupOutlined.ud.withTintColor(UDColor.iconDisabled)
            arrowImageView.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconDisabled)
            titleLabel.textColor = UDColor.textDisabled
            avatarGroupView.isEnabled = false
        }
    }
    
    func updateTitle(_ text: String?) {
        titleLabel.text = text
    }

    // 数据排序
    private func reorderData(_ list: inout [Collaborator]) {
        moveOwnerToFirst(&list)
    }

    private func moveOwnerToFirst(_ list: inout [Collaborator]) {
        var dstIndex = -1
        for index in 0 ..< list.count where list[index].isOwner {
            dstIndex = index
        }
        if dstIndex >= 0 {
            let data = list[dstIndex]
            list.remove(at: dstIndex)
            list.insert(data, at: 0)
        }
    }
}

// MARK: - Rule VC

class BitableAdvancedPermissionsRuleCell: UICollectionViewCell {
    static let reuseIdentifier = "BitableAdvancedPermissionsRuleCell"
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        label.numberOfLines = 1
        return label
    }()

    private lazy var splitView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UDColor.bgFloat
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(splitView)

        splitView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    public func setModel(_ model: BitableAdvancedPermissionsRuleCellData) {
        titleLabel.text = model.title
        descriptionLabel.text = model.subTitle

        let leftpadding = 16
        let topPadding = 15
        if let subTitle = model.subTitle, !subTitle.isEmpty {
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(leftpadding)
                make.top.equalToSuperview().offset(topPadding)
                make.right.equalToSuperview().offset(-leftpadding)
            }
            descriptionLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(titleLabel.snp.left)
                make.bottom.equalToSuperview().offset(-topPadding)
                make.right.equalToSuperview().offset(-leftpadding)
            }
            descriptionLabel.isHidden = false
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(leftpadding)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-leftpadding)
            }
            descriptionLabel.snp.removeConstraints()
            descriptionLabel.isHidden = true
        }
    }

    static func height(_ model: BitableAdvancedPermissionsRuleCellData) -> CGFloat {
        if let subTitle = model.subTitle, !subTitle.isEmpty {
            return 76
        } else {
            return 52
        }
    }

    public func updateSplitView(hidden: Bool) {
        splitView.isHidden = hidden
    }
}

class BitableAdvancedPermissionsRuleHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "BitableAdvancedPermissionsRuleHeaderView"
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UDColor.textCaption
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.bgFloatBase
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    static func sectionHeaderViewHeight(title: String?) -> CGFloat {
        return title?.isEmpty == false ? 46 : 16
    }
}
