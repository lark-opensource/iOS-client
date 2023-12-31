//
//  ForwardChatCell.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/11/27.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkTag
import RxSwift
import LarkContainer
import LarkMessengerInterface
import LarkAccountInterface
import LarkBizAvatar
import LarkListItem
import LarkFocusInterface
import LKCommonsLogging
import LarkBizTag

final class ForwardChatTableCell: BaseTableViewCell {
    static let logger = Logger.log(ForwardChatTableCell.self, category: "ForwardChatTableCell")

    var disposeBag = DisposeBag()
    let personInfoView = ListItem()
    let countLabel = UILabel()

    var checkbox: LKCheckbox {
        return personInfoView.checkBox
    }

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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBackgroundViews(highlightOn: true)
        self.contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        personInfoView.splitNameLabel(additional: countLabel)
        countLabel.textColor = UIColor.ud.N500
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(model: ForwardItem,
                    currentTenantId: String,
                    isSelected: Bool = false,
                    hideCheckBox: Bool = false,
                    enable: Bool = true,
                    animated: Bool = false,
                    focusService: FocusService? = nil,
                    checkInDoNotDisturb: ((Int64) -> Bool)) {
        disposeBag = DisposeBag()

        checkbox.isHidden = hideCheckBox
        checkbox.isSelected = isSelected
        checkbox.isEnabled = enable
        personInfoView.avatarView.setAvatarByIdentifier(model.id, avatarKey: model.avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
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

        if let customStatus = model.customStatus,
           let tagView = focusService?.generateTagView() {
            tagView.config(with: customStatus)
            personInfoView.setFocusTag(tagView)
        }
        personInfoView.nameLabel.text = model.name
        countLabel.text = model.chatUserCount > 0 ? "(\(model.chatUserCount))" : nil
        /*
         显示部门 + 签名
         但default数据会用最近的联系人，这些数据不需要显示部门信息
         */
        personInfoView.infoLabel.isHidden = model.subtitle.isEmpty
        personInfoView.infoLabel.text = model.subtitle

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

    private func updateTagsView(model: ForwardItem,
                                currentTenantId: String,
                                needDoNotDisturb: Bool,
                                userType: PassportUserType?) {
        if model.type == .chat {
            chatTagBuild.reset(with: [])
                .isPrivateMode(model.isPrivate)
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
    override func prepareForReuse() {
        super.prepareForReuse()
        self.personInfoView.nameTag.clean()
        personInfoView.setFocusIcon(nil)
        personInfoView.nameTag.clean()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
