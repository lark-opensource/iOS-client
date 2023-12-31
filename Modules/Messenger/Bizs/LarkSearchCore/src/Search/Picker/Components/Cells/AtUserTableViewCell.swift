//
//  AtUserTableViewCell.swift
//  LarkSearchCore
//
//  Created by Jiang Chun on 2022/4/14.
//

import Foundation
import LarkUIKit
import LarkCore
import LarkTag
import RxSwift
import LarkMessengerInterface
import LarkAccountInterface
import LarkBizAvatar
import LarkListItem
import LarkFocusInterface
import LarkContainer
import UIKit
import UniverseDesignIcon
import EENavigator
import LarkBizTag

final class AtUserTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    let personInfoView = ListItem()
    let countLabel = UILabel()
    let personCardButton = UIButton()
    var chatterID: String?
    weak var fromVC: UIViewController?

    lazy var chatTagBuild: ChatTagViewBuilder = ChatTagViewBuilder()
    lazy var chatTagView: TagWrapperView = {
        let tagView = chatTagBuild.build()
        tagView.isHidden = true
        return tagView
    }()

    lazy var chatterTagBuild: ChatterTagViewBuilder = ChatterTagViewBuilder()
    lazy var chatterTagView: TagWrapperView = {
        let tagView = chatterTagBuild.build()
        tagView.isHidden = true
        return tagView
    }()

    var checkbox: LKCheckbox {
        return personInfoView.checkBox
    }

    private var focusService: FocusService?
    public var navigator: Navigatable?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBackgroundViews(highlightOn: true)
        self.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(personInfoView)
        contentView.addSubview(personCardButton)

        personInfoView.avatarView.avatar.ud.setMaskView()
        personInfoView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(personCardButton.snp.left).offset(20)
        }
        personInfoView.splitNameLabel(additional: countLabel)

        personCardButton.setImage(UDIcon.getIconByKey(.groupCardOutlined).withRenderingMode(.alwaysTemplate), for: .normal)
        personCardButton.tintColor = UIColor.ud.iconN3
        personCardButton.addTarget(self, action: #selector(personCardButtonDidClick), for: .touchUpInside)
        personCardButton.setContentHuggingPriority(.required, for: .horizontal)
        personCardButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        personCardButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        countLabel.textColor = UIColor.ud.textPlaceholder
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        personInfoView.avatarView.image = nil
        personInfoView.setFocusIcon(nil)
        personInfoView.nameTag.clean()
    }
    // nolint: duplicated_code 不同cell的渲染代码类似,但是逻辑不同
    func setContent(resolver: LarkContainer.UserResolver,
                    model: ForwardItem,
                    currentTenantId: String,
                    isSelected: Bool = false,
                    hideCheckBox: Bool = false,
                    enable: Bool = true,
                    animated: Bool = false,
                    fromVC: UIViewController?,
                    checkInDoNotDisturb: ((Int64) -> Bool)) {
        focusService = try? resolver.resolve(assert: FocusService.self)
        navigator = resolver.navigator
        disposeBag = DisposeBag()
        chatterID = model.id
        self.fromVC = fromVC

        checkbox.isHidden = hideCheckBox
        checkbox.isSelected = isSelected
        checkbox.isEnabled = enable
        personInfoView.bottomSeperator.isHidden = true
        personInfoView.avatarView.snp.remakeConstraints({ make in
            make.size.equalTo(CGSize(width: 48, height: 48))
        })
        personInfoView.contentView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(16)
        }
        personInfoView.avatarView.setAvatarByIdentifier(model.id, avatarKey: model.avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(48)))
        personInfoView.avatarView.setMiniIcon(nil)
        if model.enableThreadMiniIcon {
            if model.isThread {
                personInfoView.avatarView.setMiniIcon(MiniIconProps(.thread))
            }
            if model.type == .threadMessage {
                personInfoView.avatarView.setMiniIcon(MiniIconProps(.topic))
            }
        } else {
            if model.type == .threadMessage {
                personInfoView.avatarView.setMiniIcon(MiniIconProps(.dynamicIcon(
                    LarkCore.Resources.thread_topic
                )))
            }
        }

        if let attributedTitle = model.attributedTitle {
            personInfoView.nameLabel.attributedText = attributedTitle
        } else {
            personInfoView.nameLabel.text = model.name
        }
        if let customStatus = model.customStatus, let focusService {
            let tagView = focusService.generateTagView()
            tagView.config(with: customStatus)
            personInfoView.setFocusTag(tagView)
        }
        countLabel.text = model.chatUserCount > 0 ? "(\(model.chatUserCount))" : nil

        // 部门
        personInfoView.infoLabel.isHidden = model.subtitle.isEmpty
        personInfoView.infoLabel.lineBreakMode = .byTruncatingHead
        if let attributedSubtitle = model.attributedSubtitle {
            personInfoView.infoLabel.attributedText = attributedSubtitle
        } else {
            personInfoView.infoLabel.text = model.subtitle
        }

        // 签名
        let statusText = model.description
        if statusText.isEmpty {
            personInfoView.statusLabel.isHidden = true
        } else {
            personInfoView.statusLabel.isHidden = false
            personInfoView.setDescription(NSAttributedString(string: statusText),
                                          descriptionType: ListItem.DescriptionType(rawValue: model.descriptionType.rawValue))
        }

        let needDoNotDisturb = checkInDoNotDisturb(model.doNotDisturbEndTime)
        if let userTypeObservable = model.userTypeObservable {
            userTypeObservable.subscribe(onNext: { [weak self] (userType) in
                self?.updateTagsView(model: model,
                                     currentTenantId: currentTenantId,
                                     needDoNotDisturb: needDoNotDisturb,
                                     userType: userType)
            })
            .disposed(by: disposeBag)
        } else {
            updateTagsView(model: model,
                           currentTenantId: currentTenantId,
                           needDoNotDisturb: needDoNotDisturb,
                           userType: nil)
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    // enable-lint: duplicated_code

    // nolint: duplicated_code 设置tag的方式略有不同,后续该cell会替换成统一的
    private func updateTagsView(model: ForwardItem,
                                currentTenantId: String,
                                needDoNotDisturb: Bool,
                                userType: PassportUserType?) {
        if model.type == .chat {
            chatTagBuild.reset(with: [])
                .isOfficial(model.isOfficialOncall || model.tags.contains(.official))
                .isConnect(model.isCrossWithKa && (userType != nil || !isCustomer(tenantId: currentTenantId)))
                .isPublic(model.tags.contains(.public))
                .addTags(with: model.tagData?.transform() ?? [])
                .refresh()
            chatTagView.isHidden = chatTagBuild.isDisplayedEmpty()
            personInfoView.setNameTag(chatTagView)
        } else {
            chatterTagBuild.reset(with: [])
                .isDoNotDisturb(model.type == .user && needDoNotDisturb)
                .addTags(with: model.tagData?.transform() ?? [])
                .refresh()
            chatterTagView.isHidden = chatterTagBuild.isDisplayedEmpty()
            personInfoView.setNameTag(chatterTagView)
        }
    }
    // enable-lint: duplicated_code

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }

    @objc
    private func personCardButtonDidClick() {
        guard let vc = self.fromVC else { return }
        guard let id = self.chatterID else { return }
        gotoPersonCardWith(chatterID: id, fromVC: vc)
    }

    func gotoPersonCardWith(chatterID: String, fromVC: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID, fromWhere: .search)
        if Display.phone {
            navigator?.present(
                body: body,
                wrap: LkNavigationController.self, from: fromVC,
                prepare: { vc in
                    vc.modalPresentationStyle = .pageSheet
                })
        } else {
            navigator?.present(
                body: body,
                wrap: LkNavigationController.self, from: fromVC,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }
}
