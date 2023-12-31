//
//  ForwardChatCell.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/11/27.
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
import LKCommonsLogging
import UIKit
import LarkBizTag

final class ForwardChatTableCell: UITableViewCell {
    static let logger = Logger.log(ForwardChatTableCell.self, category: "ForwardChatTableCell")
    var disposeBag = DisposeBag()
    let personInfoView = ListItem()
    let countLabel = UILabel()
    private lazy var thumbnailAvatarView = BizAvatar()
    public lazy var targetInfo: UIButton = {
        let targetInfo = UIButton(type: .custom)
        targetInfo.setImage(Resources.target_info, for: .normal)
        targetInfo.addTarget(self, action: #selector(handleTargetInfoTap), for: .touchUpInside)
        targetInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return targetInfo
    }()

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
    public var section: Int?
    public var row: Int?
    public weak var delegate: TargetInfoTapDelegate?

    private var focusService: FocusService?

    var isDepartmentInfoTail: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBackgroundViews(highlightOn: true)
        self.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(personInfoView)
        personInfoView.avatarView.avatar.ud.setMaskView()
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        personInfoView.splitNameLabel(additional: countLabel)
        countLabel.textColor = UIColor.ud.textPlaceholder
        self.contentView.addSubview(thumbnailAvatarView)
        thumbnailAvatarView.snp.makeConstraints { make in
            make.right.equalTo(personInfoView.avatarView)
            make.bottom.equalTo(personInfoView.avatarView)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        self.contentView.addSubview(targetInfo)
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

    @objc
    func handleTargetInfoTap() {
        self.delegate?.presentPreviewViewController(section: section, row: row)
    }

    func setContent(resolver: LarkContainer.UserResolver,
                    model: ForwardItem,
                    currentTenantId: String,
                    isSelected: Bool = false,
                    hideCheckBox: Bool = false,
                    enable: Bool = true,
                    animated: Bool = false,
                    checkInDoNotDisturb: ((Int64) -> Bool),
                    targetPreview: Bool = false) {
        focusService = try? resolver.resolve(assert: FocusService.self)
        disposeBag = DisposeBag()

        checkbox.isHidden = hideCheckBox
        checkbox.isSelected = isSelected
        checkbox.isEnabled = enable
        personInfoView.alpha = enable ? 1 : 0.5
        personInfoView.bottomSeperator.isHidden = true
        personInfoView.avatarView.snp.remakeConstraints({ make in
            make.size.equalTo(CGSize(width: 48, height: 48))
        })
        personInfoView.contentView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(16)
        }
        let avatarId = model.avatarId ?? model.id
        let avatarKey = model.avatarKey
        personInfoView.avatarView.setAvatarByIdentifier(avatarId, avatarKey: avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(48))) {
            if case let .failure(error) = $0 {
                Self.logger.error("Forward.Cell: load info avatar {id: \(avatarId), key: \(avatarKey)} \(error)")
            }
        }
        personInfoView.avatarView.setMiniIcon(nil)
        thumbnailAvatarView.isHidden = true
        if model.enableThreadMiniIcon {
            if model.isThread {
                personInfoView.avatarView.setMiniIcon(MiniIconProps(.thread))
            }
            if model.type == .threadMessage {
                personInfoView.avatarView.setMiniIcon(nil)
                thumbnailAvatarView.setAvatarByIdentifier("", avatarKey: "")
                thumbnailAvatarView.image = BundleResources.LarkSearchCore.Picker.thread_topic_middle
                updateThumbnailAvatarSize(false)
            } else if model.type == .replyThreadMessage {
                personInfoView.avatarView.setMiniIcon(nil)
                updateCellPerviewAvatarWith(model: model)
            }
        } else {
            if model.type == .threadMessage {
                thumbnailAvatarView.setAvatarByIdentifier("", avatarKey: "")
                thumbnailAvatarView.image = BundleResources.LarkSearchCore.Picker.thread_topic_middle
                updateThumbnailAvatarSize(false)
            } else if model.type == .replyThreadMessage {
                updateCellPerviewAvatarWith(model: model)
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
        if model.isUserCountVisible == false { // 不能显示群成员个数
            countLabel.text = nil
        }
        setSubtitle(model)
        personInfoView.statusLabel.isHidden = true

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

        if targetPreview {
            targetInfo.isHidden = false
            personInfoView.snp.remakeConstraints { (make) in
                make.leading.top.bottom.equalToSuperview()
                make.trailing.equalToSuperview().offset(-Self.Layout.personInfoMargin)
            }
            targetInfo.snp.makeConstraints { (make) in
                make.leading.equalTo(personInfoView.snp.trailing).offset(8)
                make.trailing.equalToSuperview().offset(-Self.Layout.targetInfoMargin)
                make.centerY.equalToSuperview()
            }
        } else {
            targetInfo.isHidden = true
            personInfoView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }

    private func setSubtitle(_ item: ForwardItem) {
        func addSubtitleAttribute(attr: NSMutableAttributedString, isHead: Bool) {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 6
            paragraph.lineBreakMode = isHead ? .byTruncatingHead : .byTruncatingTail
            let dict = [NSAttributedString.Key.paragraphStyle: paragraph]
            attr.addAttributes(dict, range: NSRange(location: 0, length: attr.length))
        }
        /*
         显示部门 + 签名
         但default数据会用最近的联系人，这些数据不需要显示部门信息
         */
        let isUser = item.type == .user
        personInfoView.infoLabel.isHidden = item.subtitle.isEmpty
        if var attributedSubtitle = item.attributedSubtitle {
            if isDepartmentInfoTail {
                var attr = NSMutableAttributedString(attributedString: attributedSubtitle)
                addSubtitleAttribute(attr: attr, isHead: isUser)
                attributedSubtitle = attr
            }
            personInfoView.infoLabel.attributedText = attributedSubtitle
        } else {
            if isDepartmentInfoTail {
                personInfoView.infoLabel.lineBreakMode = isUser ? .byTruncatingHead : .byTruncatingTail
            }
            personInfoView.infoLabel.text = item.subtitle
        }
    }
    // nolint: duplicated_code 设置tag的方式略有不同,后续该cell会替换成统一的
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
    // enable-lint: duplicated_code

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }

    func updateCellPerviewAvatarWith(model: ForwardItem) {
        /// 防止cell的复用 清空一下数据
        personInfoView.avatarView.setAvatarByIdentifier("", avatarKey: "")
        personInfoView.avatarView.image = BundleResources.LarkSearchCore.Picker.thread_msg_icon
        self.updateThumbnailAvatarSize(true)
        let avatarId = model.avatarId ?? model.id
        let avatarKey = model.avatarKey
        self.thumbnailAvatarView.setAvatarByIdentifier(avatarId,
                                                       avatarKey: avatarKey,
                                                       avatarViewParams: .init(sizeType: .size(22)),
                                                       completion: { result in
            if case let .failure(error) = result {
                Self.logger.error("Forward.Cell: load thumbnail avatar {id: \(avatarId), key: \(avatarKey)} \(error)")
            }
        })

    }

    private func updateThumbnailAvatarSize(_ isMsgThread: Bool) {
       self.thumbnailAvatarView.isHidden = false
        if isMsgThread {
            thumbnailAvatarView.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: 22, height: 22))
                make.right.equalTo(personInfoView.avatarView.snp.right).offset(2)
            }
        } else {
            thumbnailAvatarView.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: 20, height: 20))
                make.right.equalTo(personInfoView.avatarView.snp.right).offset(0)
            }
        }
    }
}

extension ForwardChatTableCell {
    final class Layout {
        //根据UI设计图而来
        static let infoIconWidth: CGFloat = 20
        static let personInfoMargin: CGFloat = 8 + 20 + 16
        static let targetInfoMargin: CGFloat = 16
    }
}
