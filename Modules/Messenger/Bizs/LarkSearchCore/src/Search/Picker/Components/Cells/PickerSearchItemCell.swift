//
//  PickerSearchItemCell.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/14.
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
import LarkFocusInterface
import LarkContainer
import LarkBizTag

protocol PickerSearchItemCellType: UITableViewCell {
    // 参数超过9个,暂时跳过后续该cell会下线
    // swiftlint:disable all
    func setContent(resolver: LarkContainer.UserResolver,
                    searchResult: SearchResultType,
                    currentTenantId: String,
                    hideCheckBox: Bool,
                    enabled: Bool,
                    isSelected: Bool,
                    checkInDoNotDisturb: ((Int64) -> Bool),
                    needShowMail: Bool,
                    currentUserType: PassportUserType,
                    targetPreview: Bool)
    // swiftlint:enable all

    var targetInfo: UIButton { get }

    var isShowDepartmentInfo: Bool { get set }
}

final class PickerSearchItemCell: UITableViewCell, PickerSearchItemCellType {
    var isShowDepartmentInfo: Bool = false

    private var focusService: FocusService?

    private let personInfoView = PickerItemInfoView()

    let countLabel = UILabel()
    /// 公开群不能拉入外部人员，不能被选中
    /// 1. 复选框覆盖灰色View
    /// 2. 右侧覆盖半透明遮盖
    private let grayView = UIView()
    private let coverView = UIView()

    public var shouldHideAccessoryViews = false
    // 优先展示 email 如果没有 email 这个开关才会生效
    public var shouldShowSecondaryInfo = false
    public var shouldShowDividor = false

    public lazy var targetInfo: UIButton = {
        let targetInfo = UIButton(type: .custom)
        targetInfo.setImage(Resources.target_info, for: .normal)
        targetInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return targetInfo
    }()

    lazy var chatterTagBuilder: ChatterTagViewBuilder = ChatterTagViewBuilder()
    lazy var chatterTagView: TagWrapperView = {
        let tagView = chatterTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    lazy var chatTagBuilder: ChatTagViewBuilder = ChatTagViewBuilder()
    lazy var chatTagView: TagWrapperView = {
        let tagView = chatTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    // mail自定义标签
    lazy var mailTagBuilder = TagViewBuilder()
    lazy var mailTagView: TagWrapperView = {
        let tagView = mailTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    // nolint: duplicated_code 不同cell初始化方法不同,后续该cell会废弃
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        personInfoView.avatarView.snp.remakeConstraints({ make in
            make.size.equalTo(CGSize(width: 48, height: 48))
        })
        personInfoView.contentView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(16)
        }
        personInfoView.bottomSeperator.isHidden = true

        /// grayView
        self.grayView.backgroundColor = UIColor.ud.N300
        self.grayView.alpha = 0.6
        self.grayView.layer.cornerRadius = 9
        self.grayView.layer.masksToBounds = true
        personInfoView.checkBox.addSubview(self.grayView)
        grayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        /// coverView
        self.coverView.backgroundColor = UIColor.ud.bgBody
        self.coverView.alpha = 0.5
        self.contentView.addSubview(self.coverView)
        self.coverView.snp.makeConstraints { (make) in
            make.left.equalTo(self.personInfoView.avatarView.snp.left)
            make.right.equalTo(self.contentView.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        self.contentView.addSubview(targetInfo)

        personInfoView.splitNameLabel(additional: countLabel)
        // 设计师说选择的地方不能点进去，所以需要更明显的区分方式
        countLabel.textColor = UIColor.ud.textPlaceholder
    }
    // enable-lint: duplicated_code

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        personInfoView.avatarView.image = nil
    }

    public func setCheckBox(selected: Bool) {
        personInfoView.checkBox.isSelected = selected
    }

    typealias TimeStringFormatter = (_ timeZoneId: String) -> String?
    // TODO: 统一单选，多选，checkbox的状态
    // nolint: * 长函数&重复函数-渲染逻辑需要设置的UI较多,后续该Cell会废弃
    public func setContent(resolver: LarkContainer.UserResolver,
                           searchResult: SearchResultType,
                           currentTenantId: String,
                           hideCheckBox: Bool = false,
                           enabled: Bool,
                           isSelected: Bool = false,
                           checkInDoNotDisturb: ((Int64) -> Bool),
                           needShowMail: Bool = false,
                           currentUserType: PassportUserType,
                           targetPreview: Bool = false) {
        focusService = try? resolver.resolve(assert: FocusService.self)
        // reset state
        personInfoView.statusLabel.isHidden = true
        personInfoView.additionalIcon.isHidden = true
        personInfoView.nameTag.isHidden = true
        personInfoView.secondaryInfoLabel.isHidden = true
        personInfoView.setFocusIcon(nil)
        personInfoView.bottomSeperator.isHidden = !shouldShowDividor

        self.grayView.isHidden = enabled // FIXME: 是否需要单选和多选不一样的样式？
        self.coverView.isHidden = enabled

        if hideCheckBox {
            personInfoView.checkBox.isHidden = true
            self.grayView.isHidden = true
            self.coverView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview()
                make.right.equalTo(self.contentView.snp.right)
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
            }
        } else {
            if enabled {
                selectedBackgroundView = BaseCellSelectView()
                selectedBackgroundView?.backgroundColor = UIColor.ud.bgFiller
            } else {
                self.selectionStyle = .none
            }
            personInfoView.checkBox.isHidden = false
            self.coverView.snp.remakeConstraints { (make) in
                make.left.equalTo(self.personInfoView.avatarView.snp.left)
                make.right.equalTo(self.contentView.snp.right)
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
            }
            personInfoView.checkBox.isEnabled = enabled
            personInfoView.checkBox.isSelected = isSelected
        }

        var info = PickerSearchItemInfo(avatarId: searchResult.avatarID,
                                        avatarKey: searchResult.avatarKey,
                                        avatarBackgroundImage: searchResult.backupImage,
                                        title: searchResult.title,
                                        summary: searchResult.summary)
        switch searchResult.type {
        case .department: info.type = .department
        case .chatter: info.type = .chatter
        default: break
        }
        personInfoView.info = info
        personInfoView.nameStatusView.textContentView.setNeedsLayout()
        personInfoView.nameStatusView.textContentView.layoutIfNeeded()

        personInfoView.timeLabel.timeString = nil // reset timeString for reuse
        countLabel.text = nil
        switch searchResult.meta {
        case .chatter(let meta):
            personInfoView.statusLabel.isHidden = false
            if let personalStatus = meta.customStatus.topActive, let focusService {
                let tagView = focusService.generateTagView()
                tagView.config(with: personalStatus)
                personInfoView.setFocusTag(tagView)
            }
            // if !hideStatusLabel { // always true
                personInfoView.setDescription(NSAttributedString(string: meta.description_p),
                                              descriptionType: PickerItemInfoView.DescriptionType(rawValue: meta.descriptionFlag.rawValue))
            chatterTagBuilder.reset(with: [])
                .isRobot(meta.type == .bot && !meta.withBotTag.isEmpty)
                .isDoNotDisturb(checkInDoNotDisturb(meta.doNotDisturbEndTime))
                .isOnLeave(meta.hasWorkStatus && meta.workStatus.status == .onLeave && meta.tenantID == currentTenantId)
                .isUnregistered(!meta.isRegistered && meta.type == .user)
                .addTags(with: meta.relationTag.transform() ?? [])
                .refresh()
            chatterTagView.isHidden = chatterTagBuilder.isDisplayedEmpty()
            personInfoView.setNameTag(chatterTagView)

            // FIXME: V2三行的Extra高亮支持
            // TODO: 这里用的是mailAttr, 应该用extra, 需要确认v2的支持情况
            if ContactSearchTableViewCell.resultShouldShowMail(searchResult: searchResult, needShowMail: needShowMail) {
                personInfoView.secondaryInfoLabel.attributedText = searchResult.extra(by: "useMail")
                personInfoView.secondaryInfoLabel.isHidden = false
            } else if shouldShowSecondaryInfo {
                personInfoView.secondaryInfoLabel.attributedText = searchResult.summary
                personInfoView.secondaryInfoLabel.isHidden = searchResult.summary.string.isEmpty
            }

        case .chat(let chat):
            chatTagBuilder.reset(with: [])
                .isCrypto(chat.isCrypto)
                .isPrivateMode(chat.isShield)
                .isOfficial(chat.isOfficialOncall || chat.tags.contains(.official))
                .isOncallOffline(!chat.oncallID.isEmpty && chat.oncallID != "0" && chat.tags.contains(.oncallOffline))
                .isOncall(!chat.oncallID.isEmpty && chat.oncallID != "0")
                .isConnect(chat.isCrossWithKa)
                .isPublic(chat.isPublicV2)
                .isTeam(chat.isDepartment)
                .isAllStaff(chat.isTenant)
                .addTags(with: chat.relationTag.transform() ?? [])
                .refresh()
            chatTagView.isHidden = chatTagBuilder.isDisplayedEmpty()
            personInfoView.setNameTag(chatTagView)
            if chat.isUserCountVisible {
                countLabel.text = chat.userCountText
            } else {
                countLabel.text = nil
                PickerLogger.shared.info(module: PickerLogger.Module.view, event: "search chat hide user count", parameters: "id: \(chat.id)")
            }
        case .mail(let mail):
            if searchResult.summary.string == searchResult.title.string {
                personInfoView.infoLabel.isHidden = true
            }
            mailTagBuilder.reset(with: []).addTags(with: []).refresh()
            mailTagView.isHidden = mailTagBuilder.isDisplayedEmpty()
            personInfoView.setNameTag(mailTagView)
        case .mailContact(let mailContact):
            personInfoView.secondaryInfoLabel.text = mailContact.email
            if let result = searchResult as? Search.Result {
                let tags = result.explanationTags.map { Tag(title: $0.text, style: getTagColor(withTagType: $0.tagType), type: .customTitleTag) }
                personInfoView.nameTag.setElements(tags)
                personInfoView.nameTag.isHidden = false
            }
        case .userGroup(let userGroup):
            personInfoView.avatarView.image = BundleResources.LarkSearchCore.Picker.user_group
            personInfoView.nameLabel.text = userGroup.name
            configDynamicUserGroup()
        case .userGroupAssign(let userGroup):
            personInfoView.avatarView.image = BundleResources.LarkSearchCore.Picker.user_group
            personInfoView.nameLabel.text = userGroup.name
            configAssignUserGroup()
        case .newUserGroup(let userGroup):
            personInfoView.avatarView.image = BundleResources.LarkSearchCore.Picker.user_group
            personInfoView.nameLabel.text = userGroup.name
            switch userGroup.userGroupType {
            case .assign:
                configAssignUserGroup()
            case .dynamic:
                configDynamicUserGroup()
            case .unknown:
                break
            @unknown default:
                break
            }
        default: break
        }

        if shouldHideAccessoryViews {
            personInfoView.statusLabel.isHidden = true
            personInfoView.additionalIcon.isHidden = true
            personInfoView.nameTag.isHidden = true
            personInfoView.secondaryInfoLabel.isHidden = true
            personInfoView.setFocusIcon(nil)
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
    // enable-lint: *

    func configDynamicUserGroup() {
        let tagText = BundleI18n.LarkSearchCore.Lark_IM_Picker_DynamicUserGroups_Label
        let frontColor = UIColor.ud.udtokenTagTextPurple
        let backColor = UIColor.ud.udtokenTagBgPurple
        chatTagBuilder.reset(with: [])
            .addTag(with: TagDataItem(text: tagText, tagType: .customTitleTag, frontColor: frontColor, backColor: backColor))
            .refresh()
        chatTagView.isHidden = false
        personInfoView.setNameTag(chatTagView)
    }

    func configAssignUserGroup() {
        chatTagBuilder.reset(with: [])
            .refresh()
        chatTagView.isHidden = true
    }

    private func getTagColor(withTagType tagType: String) -> Style {
        switch tagType {
        case "N": return .init(textColor: .ud.udtokenTagNeutralTextNormal, backColor: .ud.udtokenTagNeutralBgNormal)
        case "B": return .blue
        case "Y": return .yellow
        case "R": return .red
        case "G": return .init(textColor: .ud.udtokenTagTextGreen, backColor: .ud.udtokenTagBgGreen)
        case "O": return .orange
        case "P": return .purple
        case "W": return .init(textColor: .ud.udtokenTagTextWathet, backColor: .ud.udtokenTagBgWathet)
        case "NT": return .turquoise
        default: return .blue
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
        if needShowMail, case .chatter = searchResult.meta, searchResult.extra(by: "useMail").length > 0 {
            return true
        } else {
            return false
        }
    }

    func updateSelected(isSelected: Bool) {
        personInfoView.checkBox.isSelected = isSelected
    }
}

extension PickerSearchItemCell {
    final class Layout {
        //根据UI设计图而来
        static let infoIconWidth: CGFloat = 20
        static let personInfoMargin: CGFloat = 8 + 20 + 16
        static let targetInfoMargin: CGFloat = 16
    }
}
