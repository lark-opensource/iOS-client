//  Created by Songwen on 2018/9/14.

import UIKit
import Kingfisher
import SKFoundation
import SKResource
import SKUIKit
import ByteWebImage

class CollaboratorInviteWidgetHeaderView: UIView {
    var detail: String? {
        get { return self.detailLabel.text }
        set {
            self.detailLabel.text = newValue
            self.updateDetailsIfNeed()
        }
    }
    var url: String? {
        didSet {
            guard let url = self.url, !url.isEmpty else { return }
            self.avatar.image = ImageCache.default.retrieveImageInMemoryCache(forKey: url)
                ?? BundleResources.SKResource.Common.Collaborator.avatar_placeholder
            guard let u = URL(string: url) else { return }
            ImageDownloader.default.downloadImage(with: u, completionHandler: { [weak self] (result) in
                switch result {
                case .success(let value):
                    ImageCache.default.store(value.image, forKey: url)
                    self?.avatar.image = value.image
                case .failure(let error):
                    DocsLogger.info("图片下载失败\(error.localizedDescription)")
                }
            })
        }
    }

    var imageResource: LarkImageResource? {
        didSet {
            guard let imageResource else { return }
            avatar.bt.setLarkImage(with: imageResource,
                                   placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        }
    }
    

    private lazy var avatar: UIImageView = {
        let view = SKAvatar(configuration: .init(backgroundColor: UIColor.ud.N100,
                                          style: .circle,
                                          contentMode: .scaleAspectFill))
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var infoPanelView: SKListCellView = {
        let view = SKListCellView()
        return view
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.ud.N500
        return label
    }()

    private lazy var bottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(avatar)
        self.addSubview(infoPanelView)
        self.addSubview(detailLabel)
        self.addSubview(bottomLineView)

        avatar.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(avatar.snp.height)
        }

        infoPanelView.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar.snp.top).offset(3)
            make.right.lessThanOrEqualToSuperview().offset(-10)
        }
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(infoPanelView)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(avatar.snp.bottom)
        }
        bottomLineView.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.avatar.layer.cornerRadius = self.avatar.bounds.size.width * 0.5
    }

    private func updateDetailsIfNeed() {
        if self.detail == nil || self.detail?.isEmpty == true {
            infoPanelView.snp.remakeConstraints { (make) in
                make.left.equalTo(avatar.snp.right).offset(12)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualToSuperview().offset(-10)
            }
            detailLabel.removeFromSuperview()
        }
    }

    func updateInfo(item: Collaborator) {
        var views: [SKListCellElementType] = [.titleLabel(text: item.name)]
        // 1. 外部或跨租户的文档 2. 套件大B用户
        let externalVisable = (item.isExternal || item.isCrossTenant) && EnvConfig.CanShowExternalTag.value
        if let value = item.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.append(.customTag(text: value, visable: externalVisable))
        } else {
            views.append(.external(visable: externalVisable))
        }
        if item.type == .app {
            views.append(.app(visable: true))
        }
        infoPanelView.update(views: views)
        detail = item.detail
        if item.type == .email {
            avatar.image = BundleResources.SKResource.Common.Collaborator.avatar_person
            
            infoPanelView.snp.updateConstraints { make in
                make.top.equalTo(avatar.snp.top).offset(-3)
            }
            
            detailLabel.snp.updateConstraints { make in
                make.bottom.equalTo(avatar.snp.bottom).offset(3)
            }
            
            detailLabel.numberOfLines = 2
        } else if item.type == .organization || item.type == .ownerLeader {
            // 组织架构类型使用本地的图片
            avatar.image = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
        } else if item.type == .userGroup || item.type == .userGroupAssign {
            // 用户组类型使用本地的图片
            avatar.image = BundleResources.SKResource.Common.Collaborator.icon_usergroup
        } else {
            url = item.avatarURL
            if !item.imageKey.isEmpty {
                imageResource = .avatar(key: item.imageKey, entityID: item.userID)
            }
        }
    }
}
