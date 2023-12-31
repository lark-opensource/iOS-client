//
//  CollaboratorAvatarGroupView.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/9/15.
//

import Foundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignAvatar
import UniverseDesignLoading
import RxSwift
import RxCocoa
import LarkContainer

class CollaboratorAvatarGroupView: UIView {

    private enum Layout {
        // 设计稿是 32，但是算上外边框，实际是 34（1 + 32 + 1）
        static var avatarWidth: CGFloat { 34 }
        static var avatarOverlaySpacing: CGFloat { -10 }
    }

    let maxAvatarCount: Int

    private var containerView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .fill
        return view
    }()

    private var disposeBag = DisposeBag()

    // 避免展示过数据后重复 loading 的问题
    private(set) var hasBeenUpdated = false
    private var isLoading = false

    var isEnabled: Bool = true {
        didSet {
            guard oldValue != isEnabled else { return }
            containerView.alpha = isEnabled ? 1 : 0.3
        }
    }

    init(maxAvatarCount: Int) {
        self.maxAvatarCount = maxAvatarCount
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 展示 loading
    func showLoading() {
        if isLoading { return }
        cleanUp()
        isLoading = true
        let loadingView = AvatarLoadingView()
        containerView.addArrangedSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.avatarWidth)
        }
        loadingView.layer.cornerRadius = Layout.avatarWidth / 2
        loadingView.layer.ud.setBorderColor(UDColor.bgFloat)
    }

    // 清理所有内容
    func cleanUp() {
        isLoading = false
        hasBeenUpdated = false
        containerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        isUserInteractionEnabled = false
        disposeBag = DisposeBag()
    }

    func update(owner: Collaborator, totalCount: Int, clickHandler: (() -> Void)?) {
        cleanUp()
        containerView.spacing = 6
        hasBeenUpdated = true
        isUserInteractionEnabled = true
        let needMoreView = totalCount > 1
        let avatarView = AvatarContainerView()
        containerView.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.avatarWidth)
        }
        avatarView.layer.cornerRadius = Layout.avatarWidth / 2
        avatarView.layer.ud.setBorderColor(UDColor.bgFloat)
        let avatarURL = owner.avatarURL
        if owner.type == .hostDoc {
            avatarView.avatar.di.setDocsImage(iconInfo: owner.iconToken, url: owner.extraInfo?.hostUrl ?? "", userResolver: Container.shared.getCurrentUserResolver())
        } else if avatarURL.hasPrefix("http") {
            avatarView.avatar.kf.setImage(with: URL(string: avatarURL),
                                          placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        } else {
            if avatarURL == "icon_tool_sharefolder" {
                // 文件夹图标需要特化
                avatarView.avatar.image = UDIcon.getIconByKey(.fileSharefolderColorful, size: CGSize(width: 20, height: 20))
                avatarView.avatar.contentMode = .center
                avatarView.backgroundColor = UDColor.W200
            } else {
                avatarView.avatar.image = owner.avatarImage
            }
        }
        avatarView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { clickHandler?() })
            .disposed(by: disposeBag)

        if needMoreView {
            let moreView = MoreAvatarView()
            containerView.addArrangedSubview(moreView)
            moreView.snp.makeConstraints { make in
                make.width.height.equalTo(Layout.avatarWidth)
            }
            moreView.layer.cornerRadius = Layout.avatarWidth / 2
            moreView.layer.ud.setBorderColor(UDColor.bgFloat)
            moreView.update(number: totalCount - 1)
        }
    }

    // 更新头像内容
    func update(collaborators: [Collaborator], totalCount: Int, replaceWikiIconLocally: Bool = true) {
        cleanUp()
        containerView.spacing = Layout.avatarOverlaySpacing
        hasBeenUpdated = true
        let needMoreView = collaborators.count > maxAvatarCount
        let displayCollaborators = needMoreView ? collaborators.prefix(maxAvatarCount - 1) : collaborators.prefix(maxAvatarCount)
        displayCollaborators.forEach { collaborator in
            let avatarView = AvatarContainerView()
            containerView.addArrangedSubview(avatarView)
            avatarView.snp.makeConstraints { make in
                make.width.height.equalTo(Layout.avatarWidth)
            }
            avatarView.layer.cornerRadius = Layout.avatarWidth / 2
            avatarView.layer.ud.setBorderColor(UDColor.bgFloat)
            let avatarURL = collaborator.avatarURL

            if collaborator.type == .hostDoc {
                avatarView.avatar.di.setDocsImage(iconInfo: collaborator.iconToken, url: collaborator.extraInfo?.hostUrl ?? "", userResolver: Container.shared.getCurrentUserResolver())
            } else if replaceWikiIconLocally && (collaborator.type == .wikiUser || collaborator.type == .newWikiAdmin || collaborator.type == .newWikiMember || collaborator.type == .newWikiEditor) {
                //TODO: 这段逻辑等APP版本整体提上去后，通知后端修改下发的资源，去掉本地逻辑
                avatarView.avatar.image = BundleResources.SKResource.Common.Collaborator.avatar_wiki_user
                avatarView.avatar.contentMode = .center
                avatarView.backgroundColor = UDColor.W200
            } else {
                if avatarURL.hasPrefix("http") {
                    avatarView.avatar.kf.setImage(with: URL(string: avatarURL),
                                                  placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
                } else {
                    if avatarURL == "icon_tool_sharefolder" {
                        // 文件夹图标需要特化
                        avatarView.avatar.image = UDIcon.getIconByKey(.fileSharefolderColorful, size: CGSize(width: 20, height: 20))
                        avatarView.avatar.contentMode = .center
                        avatarView.backgroundColor = UDColor.W200
                    } else {
                        avatarView.avatar.image = collaborator.avatarImage ?? BundleResources.SKResource.Common.Collaborator.avatar_placeholder
                    }
                }
            }
        }

        if needMoreView {
            let moreView = MoreAvatarView()
            containerView.addArrangedSubview(moreView)
            moreView.snp.makeConstraints { make in
                make.width.height.equalTo(Layout.avatarWidth)
            }
            moreView.layer.cornerRadius = Layout.avatarWidth / 2
            moreView.layer.ud.setBorderColor(UDColor.bgFloat)
            moreView.update(number: totalCount - maxAvatarCount + 1)
        }
    }
}
