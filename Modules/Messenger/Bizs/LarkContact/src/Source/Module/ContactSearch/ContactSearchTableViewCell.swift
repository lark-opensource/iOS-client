//
//  ContactSearchTableViewCell.swift
//  LarkContact
//
//  Created by SuPeng on 5/13/19.
//

import Foundation
import UIKit
import SnapKit
import LarkCore
import LarkModel
import LarkUIKit
import LarkTag
import LarkAccountInterface
import LarkMessengerInterface
import LarkListItem
import LarkSDKInterface
import LarkFeatureGating
import LarkBizTag
import RustPB

final class ContactSearchTableViewCell: UITableViewCell {
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") var isSupportAnotherNameFG: Bool
    private let _contentView = UIView()
    private let personInfoView = ListItem()
    /// 公开群不能拉入外部人员，不能被选中
    /// 1. 复选框覆盖灰色View
    /// 2. 右侧覆盖半透明遮盖
    private let grayView = UIView()
    private let coverView = UIView()

    private var isPublic: Bool = false

    lazy var chatterTagBuilder: ChatterTagViewBuilder = ChatterTagViewBuilder()
    lazy var chatterTagView: TagWrapperView = {
        let tagView = chatterTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    lazy var chatTagBuild: ChatTagViewBuilder = ChatTagViewBuilder()
    lazy var chatTagView: TagWrapperView = {
        let tagView = chatTagBuild.build()
        tagView.isHidden = true
        return tagView
    }()

    // 用于选中时弹出不可选中toast
    var canSelect: Bool = true

    override public var contentView: UIView {
        return self._contentView
    }

    public lazy var targetInfo: UIButton = {
        let targetInfo = UIButton(type: .custom)
        targetInfo.setImage(Resources.target_info, for: .normal)
        targetInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return targetInfo
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.ud.bgBody

        setupBackgroundViews(highlightOn: true)

        self.addSubview(_contentView)
        _contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        personInfoView.bottomSeperator.isHidden = true
        contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        /// grayView
        self.grayView.backgroundColor = UIColor.ud.N300
        self.grayView.alpha = 0.6
        self.grayView.layer.cornerRadius = 9
        self.grayView.layer.masksToBounds = true
        self.contentView.addSubview(self.grayView)
        self.grayView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.personInfoView.checkBox)
        }

        /// coverView
        self.coverView.backgroundColor = UIColor.ud.N00
        self.coverView.alpha = 0.5
        self.contentView.addSubview(self.coverView)
        self.coverView.snp.makeConstraints { (make) in
            make.left.equalTo(self.personInfoView.avatarView.snp.left)
            make.right.equalTo(self.contentView.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        self.contentView.addSubview(targetInfo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    typealias TimeStringFormatter = (_ timeZoneId: String) -> String?
    func setContent(searchResult: SearchResultType,
                    searchText: String?,
                    currentTenantId: String,
                    hideCheckBox: Bool = false,
                    hideTimeLabel: Bool = false,
                    hideStatusLabel: Bool = false,
                    enableCheckBox: Bool = false,
                    isSelected: Bool = false,
                    checkInDoNotDisturb: ((Int64) -> Bool),
                    needShowMail: Bool = false,
                    currentUserType: AccountUserType,
                    isPublic: Bool = false,
                    canSelect: Bool = true,
                    targetPreview: Bool = false,
                    tagData: Basic_V1_TagData? = nil) {
        self.isPublic = isPublic
        self.canSelect = true
        self.grayView.isHidden = true
        self.coverView.isHidden = true
        self.personInfoView.alpha = 1
        self.canSelect = canSelect
        if hideCheckBox {
            personInfoView.checkBox.isHidden = true
        } else {
            selectionStyle = enableCheckBox ? .default : .none
            personInfoView.checkBox.isHidden = false
            personInfoView.checkBox.isEnabled = enableCheckBox
            personInfoView.checkBox.isSelected = isSelected
        }

        personInfoView.avatarView.setAvatarByIdentifier(searchResult.id,
                                                        avatarKey: searchResult.avatarKey,
                                                        scene: .Contact,
                                                        avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
        personInfoView.nameLabel.attributedText = searchResult.title

        if !searchResult.summary.string.isEmpty {
            personInfoView.infoLabel.attributedText = searchResult.summary
            personInfoView.infoLabel.isHidden = false
        } else {
            personInfoView.infoLabel.isHidden = true
        }

        if case .mail = searchResult.meta {
            if searchResult.summary.string.elementsEqual(searchResult.title.string) {
                personInfoView.infoLabel.isHidden = true
            }
        }

        switch searchResult.meta {
        case .chatter(let meta):
            personInfoView.statusLabel.isHidden = hideStatusLabel
            if !hideStatusLabel {
                personInfoView.setDescription(NSAttributedString(string: meta.description_p),
                                              descriptionType: ListItem.DescriptionType(rawValue: meta.descriptionFlag.rawValue))
            }
            chatterTagBuilder.reset(with: [])
                .isRobot(meta.type == .bot && !meta.withBotTag.isEmpty)
                .isDoNotDisturb(checkInDoNotDisturb(meta.doNotDisturbEndTime))
                .isOnLeave(meta.hasWorkStatus && meta.workStatus.status == .onLeave && meta.tenantID == currentTenantId)
                .isUnregistered(!meta.isRegistered)
                .addTags(with: tagData?.transform() ?? [])
                .refresh()
            chatterTagView.isHidden = chatterTagBuilder.isDisplayedEmpty()
            personInfoView.setNameTag(chatterTagView)
            if meta.tenantID != currentTenantId, self.isPublic {
                self.canSelect = false
            }

            if !self.canSelect {
                if self.personInfoView.checkBox.isHidden == false {
                    self.grayView.isHidden = false
                }
                self.personInfoView.alpha = 0.5
            }
            if ContactSearchTableViewCell.resultShouldShowMail(searchResult: searchResult, needShowMail: needShowMail) {
                let mailAttr = NSAttributedString(string: meta.mailAddress)
                personInfoView.secondaryInfoLabel.attributedText = mailAttr
                personInfoView.secondaryInfoLabel.isHidden = false
            } else {
                personInfoView.secondaryInfoLabel.isHidden = true
            }

        case .chat(let meta):
            personInfoView.statusLabel.isHidden = true
            personInfoView.additionalIcon.isHidden = true
            chatTagBuild.reset(with: [])
                .addTags(with: tagData?.transform() ?? [])
                .refresh()
            chatTagView.isHidden = chatTagBuild.isDisplayedEmpty()
            personInfoView.setNameTag(chatTagView)
        case .mail:
            personInfoView.nameTag.setTags([.external])
            personInfoView.nameTag.isHidden = false
            personInfoView.statusLabel.isHidden = true
            personInfoView.additionalIcon.isHidden = true
            personInfoView.secondaryInfoLabel.isHidden = true
        default:
            personInfoView.statusLabel.isHidden = true
            personInfoView.additionalIcon.isHidden = true
            personInfoView.nameTag.isHidden = true
            personInfoView.secondaryInfoLabel.isHidden = true
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
    }

    static func getCellHeight(searchResult: SearchResultType, needShowMail: Bool) -> CGFloat {
        if resultShouldShowMail(searchResult: searchResult, needShowMail: needShowMail) {
            return 84
        } else {
            return 68
        }
    }

    static func resultShouldShowMail(searchResult: SearchResultType, needShowMail: Bool) -> Bool {
        if case .chatter(let meta) = searchResult.meta, !meta.mailAddress.isEmpty, needShowMail {
            return true
        } else {
            return false
        }
    }

    func updateSelected(isSelected: Bool) {
        personInfoView.checkBox.isSelected = isSelected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}

extension ContactSearchTableViewCell {
    final class Layout {
        //根据UI设计图而来
        static let infoIconWidth: CGFloat = 20
        static let personInfoMargin: CGFloat = 8 + 20 + 16
        static let targetInfoMargin: CGFloat = 16
    }
}
