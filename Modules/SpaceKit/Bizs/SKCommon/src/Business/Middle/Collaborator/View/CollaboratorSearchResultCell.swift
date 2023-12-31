//
//  PermissionCell.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/26.
//

import Foundation
import SKUIKit
import SKResource
import Kingfisher
import SKFoundation
import RxSwift
import UniverseDesignCheckBox

// MARK: - Collaborator Cell
class CollaboratorSearchResultCell: UITableViewCell {
    private let disposeBag: DisposeBag = DisposeBag()
    var item: CollaboratorSearchResultCellItem?

    private lazy var seprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N300
        return v
    }()

    private lazy var checkBox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple, config: .init(style: .circle)) { (_) in }
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()
    
    private lazy var infoPanelView: SKListCellView = {
        let view = SKListCellView()
        return view
    }()

    lazy var externalLabel: SKNavigationBarTitle.ExternalLabel = {
        let l = SKNavigationBarTitle.ExternalLabel()
        l.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return l
    }()

    lazy var userCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = UIColor.ud.N900
        l.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return l
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
    }()
    
    public var hideSeperator: Bool = false {
        didSet {
            self.seprateLine.isHidden = hideSeperator
        }
    }


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = UIView()
        contentView.addSubview(checkBox)
        contentView.addSubview(infoPanelView)
        addSubview(seprateLine)
        contentView.addSubview(iconImageView)
        contentView.addSubview(subTitleLabel)
        contentView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.left.equalToSuperview().offset(16)
        }
        iconImageView.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
            make.left.equalTo(50)
        })
        infoPanelView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        subTitleLabel.snp.makeConstraints({ (make) in
            make.bottom.equalTo(-13)
            make.left.equalTo(infoPanelView.snp.left)
            make.right.equalToSuperview().offset(-10)
        })
        seprateLine.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(infoPanelView.snp.left)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: CollaboratorSearchResultCellItem) {
        self.item = item
        checkBox.isEnabled = true
        switch item.selectType {
            case .blue:
                checkBox.isSelected = true
            case .gray:
                checkBox.isSelected = false
            case .disable:
                checkBox.isSelected = false
                checkBox.isEnabled = false
            case .none:
                checkBox.isSelected = false
            case .hasSelected:
                checkBox.isSelected = true
                checkBox.isEnabled = false
        }
        if item.selectType == .none {
            checkBox.snp.updateConstraints { (make) in
                make.width.height.equalTo(0)
            }
            iconImageView.snp.updateConstraints { (make) in
                make.left.equalTo(16)
            }
        } else {
            checkBox.snp.updateConstraints { (make) in
                make.width.height.equalTo(16)
            }
            iconImageView.snp.updateConstraints { (make) in
                make.left.equalTo(50)
            }
        }
        // 不可选或者已经选了状态置为灰色
        let disable = item.selectType == .hasSelected || item.selectType == .disable || (item.isExternal && item.blockExternal)
        let alpha: CGFloat = disable ? 0.3 : 1
        iconImageView.alpha = alpha
        subTitleLabel.alpha = alpha
        subTitleLabel.text = item.detail
        let userCountLabelVisable = shouldShowUserCountLabel(item: item, canShowMemberCount: item.canShowMemberCount)
        let externalLabelVisable = shouldShowExternalLabel(item: item)
        var views: [SKListCellElementType] = [.titleLabel(text: item.title),
                                              .count(number: "(\(item.userCount))", visable: userCountLabelVisable)]
        if let value = item.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.append(.customTag(text: value, visable: externalLabelVisable))
        } else {
            views.append(.external(visable: externalLabelVisable))
        }
        infoPanelView.update(views: views)

        iconImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        if item.roleType == .organization || item.roleType == .ownerLeader {
            // 组织架构类型使用本地的图片
            iconImageView.image = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
            if let url = item.imageURL {
                // 缓存，方便后续取用
                ImageCache.default.store(BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32, forKey: url)
            }
        } else if item.roleType == .userGroup || item.roleType == .userGroupAssign {
            // 用户组类型使用本地的图片
            iconImageView.image = BundleResources.SKResource.Common.Collaborator.icon_usergroup
            if let url = item.imageURL {
                // 缓存，方便后续取用
                ImageCache.default.store(BundleResources.SKResource.Common.Collaborator.icon_usergroup, forKey: url)
            }
        } else if item.roleType == .email {
            iconImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_person
        } else {
            if let url = item.imageURL, let u = URL(string: url) {
                let resource = ImageResource(downloadURL: u, cacheKey: url.hashValue.description)
                iconImageView.kf.setImage(with: resource, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
            } else {
                DocsLogger.error("get url failed!")
                DocsLogger.info("imageKey:\(String(describing: item.imageKey))")
                if let imageKey = item.imageKey, !imageKey.isEmpty {
                    let fixedKey = imageKey.replacingOccurrences(of: "lark.avatar/", with: "")
                        .replacingOccurrences(of: "mosaic-legacy/", with: "")
                    iconImageView.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: item.collaboratorID), placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
                }
            }
        }
        updateDetails(item: item)
    }

    private func shouldShowExternalLabel(item: CollaboratorSearchResultCellItem) -> Bool {
        // 1. 外部或跨租户的文档 2. 套件大B用户
        if (item.isExternal || item.isCrossTenanet) && EnvConfig.CanShowExternalTag.value {
            return true
        } else {
            return false
        }
    }

    //是否显示人数(如群)
    private func shouldShowUserCountLabel(item: CollaboratorSearchResultCellItem, canShowMemberCount: Bool) -> Bool {
        guard canShowMemberCount else { return false }
        return (item.roleType == .group
                    || item.roleType == .permanentMeetingGroup
                    || item.roleType == .temporaryMeetingGroup)
    }

    private func updateDetails(item: CollaboratorSearchResultCellItem) {
        if item.roleType == .email {
            infoPanelView.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(13)
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.lessThanOrEqualToSuperview().offset(-16)
            })
            subTitleLabel.numberOfLines = 2
            subTitleLabel.isHidden = false
            return
        }
        subTitleLabel.numberOfLines = 1
        if item.detail == nil || item.detail?.isEmpty == true {
            infoPanelView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.top.equalToSuperview().offset(16)
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.lessThanOrEqualToSuperview().offset(-16)
            }
            subTitleLabel.isHidden = true
        } else {
            infoPanelView.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(16)
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.lessThanOrEqualToSuperview().offset(-16)
            })
            subTitleLabel.isHidden = false
        }
    }
}
