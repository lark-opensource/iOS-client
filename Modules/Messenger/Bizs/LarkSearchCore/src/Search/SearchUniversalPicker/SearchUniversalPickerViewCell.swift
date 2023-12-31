//
//  SearchUniversalPickerViewCell.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/9/7.
//

import UIKit
import Logger
import RxSwift
import LarkTag
import LarkCore
import LarkUIKit
import LarkFocusInterface
import LarkContainer
import Foundation
import LarkListItem
import LarkBizAvatar
import LarkRichTextCore
import LKCommonsLogging
import LarkAccountInterface
import LarkMessengerInterface

final class WikiPickerTableCell: UITableViewCell {

    static let logger = Logger.log(WikiPickerTableCell.self, category: "WikiPickerTableCell")
    let personInfoView = ListItem()
    private lazy var thumbnailAvatarView = BizAvatar()

    var checkbox: LKCheckbox {
        return personInfoView.checkBox
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBackgroundViews(highlightOn: true)
        self.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(personInfoView)
        personInfoView.avatarView.avatar.ud.setMaskView()
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.contentView.addSubview(thumbnailAvatarView)
        thumbnailAvatarView.snp.makeConstraints { make in
            make.right.equalTo(personInfoView.avatarView)
            make.bottom.equalTo(personInfoView.avatarView)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(model: ForwardItem,
                    pickType: UniversalPickerType,
                    currentTenantId: String,
                    isSelected: Bool = false,
                    hideCheckBox: Bool = false,
                    enable: Bool = true,
                    animated: Bool = false,
                    checkInDoNotDisturb: ((Int64) -> Bool)) {

        checkbox.isSelected = isSelected
        checkbox.isHidden = hideCheckBox
        checkbox.isEnabled = enable
        personInfoView.alpha = enable ? 1 : 0.5
        personInfoView.bottomSeperator.isHidden = true
        personInfoView.avatarView.snp.remakeConstraints({ make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        })
        personInfoView.contentView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(16)
        }
        switch pickType {
        case .folder:
            if let isShardFolder = model.isShardFolder, isShardFolder {
                personInfoView.avatarView.image = Resources.doc_sharefolder_circle
            } else {
                personInfoView.avatarView.image = LarkCoreUtils.docIcon(docType: .folder,
                                                                        fileName: "jpg")
            }
            personInfoView.infoLabel.text = model.description
        case .workspace:
            personInfoView.avatarView.image = Resources.wikibook_circle
            personInfoView.infoLabel.text = model.description
        case .chat, .defaultType, .filter:
            break
        default: break
        }
        personInfoView.avatarView.setMiniIcon(nil)
        thumbnailAvatarView.isHidden = true

        if let attributedTitle = model.attributedTitle {
            personInfoView.nameLabel.attributedText = attributedTitle
        } else {
            personInfoView.nameLabel.text = model.name
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}

final public class ChatPickerTableCell: UITableViewCell {
    static let logger = Logger.log(ChatPickerTableCell.self, category: "ChatPickerTableCell")
    var disposeBag = DisposeBag()
    let personInfoView = ListItem()
    let countLabel = UILabel()
    private lazy var thumbnailAvatarView = BizAvatar()

    var focusService: FocusService?

    var resolver: UserResolver? {
        didSet {
            focusService = try? resolver?.resolve(assert: FocusService.self)
        }
    }

    var checkbox: LKCheckbox {
        return personInfoView.checkBox
    }

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        personInfoView.avatarView.image = nil
        personInfoView.setFocusIcon(nil)
        personInfoView.nameTag.clean()
    }
    // nolint: duplicated_code 不同cell的渲染代码类似,但是逻辑不同
    func setContent(model: ForwardItem,
                    currentTenantId: String,
                    isSelected: Bool = false,
                    hideCheckBox: Bool = false,
                    enable: Bool = true,
                    animated: Bool = false,
                    checkInDoNotDisturb: ((Int64) -> Bool)) {
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
        personInfoView.avatarView.setAvatarByIdentifier(model.id, avatarKey: model.avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(48)))
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
        if let customStatus = model.customStatus {
            if let tagView = focusService?.generateTagView() {
                tagView.config(with: customStatus)
                personInfoView.setFocusTag(tagView)
            } else {
                assertionFailure("ChatPickerTableCell without resolver")
            }
        }
        countLabel.text = model.chatUserCount > 0 ? "(\(model.chatUserCount))" : nil
        if model.isUserCountVisible == false {
            countLabel.text = nil
        }
        /*
         显示部门 + 签名
         但default数据会用最近的联系人，这些数据不需要显示部门信息
         */
        personInfoView.infoLabel.isHidden = model.subtitle.isEmpty
        if let attributedSubtitle = model.attributedSubtitle {
            personInfoView.infoLabel.attributedText = attributedSubtitle
        } else {
            personInfoView.infoLabel.text = model.subtitle
        }
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

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    // enable-lint: duplicated_code

    private func updateTagsView(model: ForwardItem,
                                currentTenantId: String,
                                needDoNotDisturb: Bool,
                                userType: PassportUserType?) {
        var tagTypes: [TagType] = []
        // 密盾聊模式
        if model.isPrivate {
            //跨租户不支持密盾聊
            tagTypes.append(.isPrivateMode)
        }
        // 判断勿扰模式 user：单聊，单聊才转发
        if model.type == .user, needDoNotDisturb {
            tagTypes.append(.doNotDisturb)
        }

        // 如果是官方OnCall群，则不显示robot、oncall和external，只显示"官方"
        if model.isOfficialOncall || model.tags.contains(.official) {
            tagTypes.append(.officialOncall)
        } else {
            if model.isCrossWithKa {
                if let userType = userType {
                    UserStyle.on(.connectTag, userType: userType).apply(on: {
                        tagTypes.append(.connect)
                    }, off: {})
                } else if !isCustomer(tenantId: currentTenantId) {
                    tagTypes.append(.connect)
                }
            } else if model.isCrossTenant {
                if let userType = userType {
                    UserStyle.on(.externalTag, userType: userType).apply(on: {
                        tagTypes.append(.external)
                    }, off: {})
                } else if !isCustomer(tenantId: currentTenantId) {
                    tagTypes.append(.external)
                }
            } else if model.tags.contains(.public) {
                tagTypes.append(.public)
            }
        }

        personInfoView.nameTag.setTags(tagTypes)
        personInfoView.nameTag.isHidden = tagTypes.isEmpty
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }

    func updateCellPerviewAvatarWith(model: ForwardItem) {
        /// 防止cell的复用 清空一下数据
        personInfoView.avatarView.setAvatarByIdentifier("", avatarKey: "")
        personInfoView.avatarView.image = BundleResources.LarkSearchCore.Picker.thread_msg_icon
        self.updateThumbnailAvatarSize(true)
        self.thumbnailAvatarView.setAvatarByIdentifier(model.id,
                                                       avatarKey: model.avatarKey,
                                                       avatarViewParams: .init(sizeType: .size(22)),
                                                       completion: { result in
            if case let .failure(error) = result {
                print("aaaaaaa ---\(error)")
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
