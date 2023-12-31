//  Created by Songwen Ding on 2018/4/9.

import UIKit
import Kingfisher
import SnapKit
import SKResource
import SKUIKit

struct CollaboratorInvitationCellItemV1 {
    var selectType: SelectType
    var imageURL: String?
    let title: String
    var detail: String?
    var isExternal: Bool
    var isCrossTenanet: Bool
    var roleType: CollaboratorType?
}

class CollaboratorInvitationCellV1: UITableViewCell {

    var item: CollaboratorInvitationCellItemV1?

    private lazy var seprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N300
        return v
    }()

    private lazy var selectedIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var externalLabel: SKNavigationBarTitle.ExternalLabel = {
        let l = SKNavigationBarTitle.ExternalLabel()
        l.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return l
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = SKAvatar(configuration: .init(backgroundColor: UIColor.ud.N100,
                                                      style: .circle,
                                                      contentMode: .scaleAspectFill))
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(selectedIcon)
        contentView.addSubview(externalLabel)
        addSubview(seprateLine)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        selectedIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
            make.left.equalToSuperview().offset(10)
        }
        iconImageView.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
            make.left.equalTo(50)
        })
        titleLabel.snp.makeConstraints({ (make) in
            make.top.equalTo(16)
            make.left.equalTo(iconImageView.snp.right).offset(12)
        })
        subTitleLabel.snp.makeConstraints({ (make) in
            make.bottom.equalTo(-16)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalToSuperview().offset(-10)
        })
        externalLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        seprateLine.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(1)
            make.left.equalTo(titleLabel.snp.left)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: CollaboratorInvitationCellItemV1) {
        self.item = item
        let selectImage: UIImage?
        switch item.selectType {
            case .blue:
                selectImage = BundleResources.SKResource.Common.Collaborator.Selected
            case .gray:
                selectImage = BundleResources.SKResource.Common.Collaborator.Unselected
            case .disable:
                selectImage = BundleResources.SKResource.Common.Collaborator.collaborator_icon_selected_disable
            case .none:
                selectImage = nil
            case .hasSelected:
                selectImage = BundleResources.SKResource.Common.Collaborator.collaborator_icon_selected_disable
        }
        // 不可选状态z灰色
        let alpha: CGFloat = item.selectType == .disable ? 0.3 : 1
        iconImageView.alpha = alpha
        titleLabel.alpha = alpha
        subTitleLabel.alpha = alpha
        // 内容
        selectedIcon.image = selectImage
        titleLabel.text = item.title
        subTitleLabel.text = item.detail
        externalLabel.isHidden = !((item.isExternal || item.isCrossTenanet) && EnvConfig.CanShowExternalTag.value)

        guard let url = item.imageURL else {
            iconImageView.image = nil
            return
        }
        iconImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        guard let u = URL(string: url) else { return }
        let resource = ImageResource(downloadURL: u, cacheKey: url.hashValue.description)
        iconImageView.kf.setImage(with: resource, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        if User.current.info?.isToC == true {
            externalLabel.isHidden = true
        }
        
        externalLabel.text = (externalLabel.isHidden == false) ? BundleI18n.SKResource.Doc_Widget_External : ""
        var offset = 31
        if let text = subTitleLabel.text, text.count > 0 {
            offset = 16
        }
        titleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(offset)
        }
        updateByRoleType(item: item)
    }

    private func updateByRoleType(item: CollaboratorInvitationCellItemV1) {
        guard let roleType = item.roleType else { return }
        // 部门不显示 Details 标签
        if roleType == .organization {
            titleLabel.snp.updateConstraints { (make) in
                make.top.equalTo(31)
            }
            subTitleLabel.isHidden = true
        } else {
            titleLabel.snp.updateConstraints { (make) in
                make.top.equalTo(16)
            }
            subTitleLabel.isHidden = false
        }
    }
}
