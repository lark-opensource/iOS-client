//
//  ChatterSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 3/26/19.
//

import Foundation
import SnapKit
import UIKit
import LarkCore
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkUIKit
import LarkTag
import Swinject
import LarkAccountInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import EETroubleKiller
import LarkBizAvatar
import LarkInteraction
import LarkSearchCore
import LarkListItem
import LarkFocus
import LarkSDKInterface
import RustPB

final class ChatterSearchTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    static let logger = Logger.log(ChatterSearchTableViewCell.self, category: "Module.IM.Search")
    private(set) var viewModel: SearchCellViewModel?
    private let templateManager: DSLTemplateManager = DSLTemplateManager()

    var isEmailHidden = false
    var isInfoLabelHidden = false
    private let bgView = UIView()
    private let avatarView = BizAvatar()
    private let newNameStatusView = SearchResultNameStatusView()
    private let infoView = UIView()
    private let searchDSLView = ChatterDSLView()
    // DSLView的render操作会改变frame
    // 在iOS12的一些版本上，偶现，view加入StackView后，再直接更改view的frame，会导致StackView布局不生效，所以需要一个Container将DSLView包起来
    private let searchDSLContainerView = UIView()
    private let infoLabel = UILabel()
    private let organizationTag = TagWrapperView()
    private let emailLabel = UILabel()
    private let chatterInfoContainerView = UIStackView()
    private let personCardButton = UIButton()

    private var organizationTagConstraint: Constraint?
    private var infoLabelConstraint: Constraint?

    private let avatarViewLeadingOffset: CGFloat = 16

    private let chatterContainerViewLeadingOffset: CGFloat = 12
    private let chatterContainerViewTrailingOffset: CGFloat = 2

    private let personCardButtonWidth: CGFloat = 50
    private let personCardButtonImageWidth: CGFloat = 24
    private let personCardButtonTrailingOffset: CGFloat = 8

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        let containerGuide = UILayoutGuide()
        contentView.addLayoutGuide(containerGuide)
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        bgView.addSubview(avatarView)
        bgView.addSubview(chatterInfoContainerView)
        bgView.addSubview(personCardButton)

        avatarView.avatar.ud.setMaskView()
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: SearchResultDefaultView.searchAvatarImageDefaultSize, height: SearchResultDefaultView.searchAvatarImageDefaultSize))
            make.leading.equalToSuperview().offset(avatarViewLeadingOffset)
            make.top.equalToSuperview().offset(12)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }

        chatterInfoContainerView.axis = .vertical
        chatterInfoContainerView.spacing = 4
        chatterInfoContainerView.alignment = .leading
        chatterInfoContainerView.distribution = .fill
        chatterInfoContainerView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview().offset(12)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.leading.equalTo(avatarView.snp.trailing).offset(chatterContainerViewLeadingOffset)
            make.trailing.equalTo(personCardButton.snp.leading).offset(-chatterContainerViewTrailingOffset)
        }

        chatterInfoContainerView.addArrangedSubview(newNameStatusView)
        chatterInfoContainerView.addArrangedSubview(infoView)

        infoView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        infoView.addSubview(organizationTag)
        organizationTag.snp.makeConstraints({ make in
            organizationTagConstraint = make.top.bottom.left.right.equalToSuperview().constraint
        })
        organizationTagConstraint?.deactivate()

        infoView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints({ make in
            infoLabelConstraint = make.top.bottom.left.right.equalToSuperview().constraint
        })
        infoLabelConstraint?.deactivate()
        emailLabel.textColor = UIColor.ud.textPlaceholder
        emailLabel.font = UIFont.systemFont(ofSize: 14)
        emailLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        emailLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        chatterInfoContainerView.addArrangedSubview(emailLabel)
        emailLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
        }

        searchDSLContainerView.isHidden = true //DSLView默认隐藏
        searchDSLContainerView.addSubview(searchDSLView)
        chatterInfoContainerView.addArrangedSubview(searchDSLContainerView)
        searchDSLContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
        searchDSLView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        personCardButton.setImage(Resources.personal_card.withRenderingMode(.alwaysTemplate), for: .normal)
        let interval = personCardButtonWidth - personCardButtonImageWidth
        personCardButton.imageEdgeInsets = UIEdgeInsets(top: interval / 2, left: interval - 8, bottom: interval / 2, right: 8)
        personCardButton.tintColor = UIColor.ud.iconN3
        personCardButton.addTarget(self, action: #selector(personCardButtonDidClick), for: .touchUpInside)
        personCardButton.setContentHuggingPriority(.required, for: .horizontal)
        personCardButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        personCardButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6)
            make.width.height.equalTo(personCardButtonWidth)
            make.trailing.equalToSuperview().offset(-personCardButtonTrailingOffset)
        }

        Feature.on(.searchProfile).apply(on: {}, off: {
            self.personCardButton.isHidden = true
        })

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }

        avatarView.topBadge.setMaxNumber(to: 999)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        newNameStatusView.restoreViewsContent()
        infoLabel.attributedText = nil
        emailLabel.attributedText = nil
        searchDSLContainerView.isHidden = true
        organizationTag.isHidden = true
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        guard let currentAccount = currentAccount else { return }
        guard let userResolver = (viewModel as? ChatterSearchViewModel)?.userResolver else { return }
        self.viewModel = viewModel
        let searchResult = viewModel.searchResult
        var sourceType: Search_V2_ResultSourceType = .net
        if let result = searchResult as? Search.Result {
            sourceType = result.sourceType
        }

        var nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()

        // 头像
        avatarView.setAvatarByIdentifier(viewModel.avatarID,
                                         avatarKey: searchResult.avatarKey,
                                         scene: .Search,
                                         avatarViewParams: .init(sizeType: .size(SearchResultDefaultView.searchAvatarImageDefaultSize)))

        // nameLabel
        nameStatusConfig.nameAttributedText = searchResult.title

        // showDynamicTag
        if let result = viewModel.searchResult as? Search.Result {
            nameStatusConfig.tags = SearchResultNameStatusView.customTagsWith(result: result)
        }

        switch searchResult.meta {
        case let .chatter(chatterMeta):
            // emailLabel
            let extra = searchResult.extra
            emailLabel.isHidden = extra.length == 0
            if extra.length > 0 {
                emailLabel.attributedText = extra
            } else {
                isEmailHidden = true
            }
            showWith(chatterMeta: chatterMeta,
                     currentAccount: currentAccount,
                     summary: searchResult.summary,
                     sourceType: sourceType,
                     nameStatusConfig: &nameStatusConfig)

            searchDSLContainerView.isHidden = true
            chatterInfoContainerView.spacing = 4
            if let searchResult = searchResult as? Search.Result,
               chatterMeta.type != .ai {
                if !searchResult.renderData.isEmpty {
                    chatterInfoContainerView.spacing = 0
                    showDSLView(by: searchResult.renderData)
                }
            }
        case let .cryptoP2PChat(cryptoP2PChatMeta):
            // emailLabel
            emailLabel.isHidden = true
            isEmailHidden = true
            infoView.isHidden = false
            isInfoLabelHidden = false
            searchDSLContainerView.isHidden = true
            showWith(chatterMeta: cryptoP2PChatMeta,
                     currentAccount: currentAccount,
                     summary: searchResult.summary,
                     sourceType: sourceType,
                     nameStatusConfig: &nameStatusConfig)
        case let .shieldP2PChat(shieldP2PChatMeta):
            emailLabel.isHidden = true
            isEmailHidden = true
            infoView.isHidden = false
            isInfoLabelHidden = false
            searchDSLContainerView.isHidden = true
            showWithShield(chatterMeta: shieldP2PChatMeta,
                           currentAccount: currentAccount,
                           summary: searchResult.summary,
                           sourceType: sourceType,
                           nameStatusConfig: &nameStatusConfig)
        default: break
        }
        if isEmailHidden && isInfoLabelHidden {
            infoView.isHidden = true
            isEmailHidden = false
            isInfoLabelHidden = false
        } else {
            infoView.isHidden = false
        }
        if viewModel.searchResult.isSpotlight && SearchFeatureGatingKey.enableSpotlightLocalTag.isUserEnabled(userResolver: userResolver) {
            nameStatusConfig.shouldAddLocalTag = true
        }

        newNameStatusView.updateContent(content: nameStatusConfig)

        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.backgroundColor = UIColor.ud.bgBody
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    private func showWith(chatterMeta: ChatterMeta,
                          currentAccount: User,
                          summary: NSAttributedString,
                          sourceType: Search_V2_ResultSourceType,
                          nameStatusConfig: inout SearchResultNameStatusView.SearchNameStatusContent) {
        guard let userResolver = try? Container.shared.getUserResolver(userID: currentAccount.userID) else { return }
        // FocusTagView
        var tagView: FocusTagView?
        if let userMeta = chatterMeta as? SearchMetaChatterType, let personalStatus = userMeta.customStatus.topActive {
            tagView = FocusTagView()
            tagView?.config(with: personalStatus)
        } else if let userMeta = chatterMeta as? SearchMetaCryptoP2PChatType, let personalStatus = userMeta.customStatus.topActive {
            tagView = FocusTagView()
            tagView?.config(with: personalStatus)
        }

        newNameStatusView.setFocusTag(tagView)

        // nameStatusView
        nameStatusConfig.descriptionText = chatterMeta.description_p
        nameStatusConfig.descriptionType = chatterMeta.descriptionFlag
        nameStatusConfig.shouldShowChatterStatus = true

        // My AI 签名信息
        if chatterMeta.type == .ai {
            showInfoLabel(summary: summary)
            return
        }

        // 该fg下个q会下掉，这里不做过多耦合
        if sourceType != .net {
            var tagTypes: [TagType] = []
            if chatterMeta.type == .bot {
                showInfoLabel(summary: summary)
                if !chatterMeta.withBotTag.isEmpty {
                    tagTypes.append(.robot)
                }
            } else {
                if !chatterMeta.isRegistered {
                    tagTypes.append(.unregistered)
                }

                // 判断勿扰模式
                if let viewModel = self.viewModel as? ChatterSearchViewModel {
                    if viewModel.serverNTPTimeService.afterThatServerTime(time: chatterMeta.doNotDisturbEndTime) {
                        tagTypes.append(.doNotDisturb)
                    }
                }

                if chatterMeta.isCrypto {
                    tagTypes.append(.crypto)
                }

                // infoView
                if SearchFeatureGatingKey.isEnableOrganizationTag.isUserEnabled(userResolver: userResolver) {
                    if chatterMeta.tenantID != currentAccount.tenant.tenantID {
                        showOrganizationTag(organizationName: summary)
                    } else {
                        showInfoLabel(summary: summary)
                    }
                } else {
                    if chatterMeta.tenantID != currentAccount.tenant.tenantID {
                        if case .standard = currentAccount.type {
                            tagTypes.append(.external)
                        }
                    }
                    showInfoLabel(summary: summary)
                }
                var tags = tagTypes.map({ tagType in
                    Tag(type: tagType)
                })
                if let userMeta = chatterMeta as? SearchMetaChatterType, userMeta.isBlockedFromLocalSearch {
                    tags.append(Tag(title: BundleI18n.LarkSearch.Lark_Search_ContactInfo_Tags_Blocked,
                                    image: nil,
                                    style: SearchResultNameStatusView.getTagColor(withTagType: "NR"),
                                    type: .customIconTextTag))
                }
                nameStatusConfig.tags = tags
            }
        } else {
            // infoView
            if SearchFeatureGatingKey.isEnableOrganizationTag.isUserEnabled(userResolver: userResolver) {
                if chatterMeta.tenantID != currentAccount.tenant.tenantID {
                    showOrganizationTag(organizationName: summary)
                } else {
                    showInfoLabel(summary: summary)
                }
            } else {
                showInfoLabel(summary: summary)
            }
        }
    }

    private func showWithShield(chatterMeta: Search_V2_ShieldP2PChatMeta,
                                currentAccount: User,
                                summary: NSAttributedString,
                                sourceType: Search_V2_ResultSourceType,
                                nameStatusConfig: inout SearchResultNameStatusView.SearchNameStatusContent) {

        guard let userResolver = try? Container.shared.getUserResolver(userID: currentAccount.userID) else { return }
        // FocusTagView
        if let personalStatus = chatterMeta.customStatuses.topActive {
            let tagView = FocusTagView()
            tagView.config(with: personalStatus)
            newNameStatusView.setFocusTag(tagView)
        }

        if sourceType != .net {
            var tagTypes: [TagType] = []

            if !chatterMeta.isRegistered {
                tagTypes.append(.unregistered)
            }

            // 判断勿扰模式
            if let viewModel = self.viewModel as? ChatterSearchViewModel {
                if viewModel.serverNTPTimeService.afterThatServerTime(time: chatterMeta.doNotDisturbEndTime) {
                    tagTypes.append(.doNotDisturb)
                }
            }

            // infoView
            if SearchFeatureGatingKey.isEnableOrganizationTag.isUserEnabled(userResolver: userResolver) {
                if chatterMeta.tenantID != currentAccount.tenant.tenantID {
                    showOrganizationTag(organizationName: summary)
                } else {
                    showInfoLabel(summary: summary)
                }
            } else {
                if chatterMeta.tenantID != currentAccount.tenant.tenantID {
                    if case .standard = currentAccount.type {
                        tagTypes.append(.external)
                    }
                }
                showInfoLabel(summary: summary)
            }

            tagTypes.append(.isPrivateMode)

            nameStatusConfig.tags = tagTypes.map({ tagType in
                Tag(type: tagType)
            })
        } else {
            // infoView
            if SearchFeatureGatingKey.isEnableOrganizationTag.isUserEnabled(userResolver: userResolver) {
                if chatterMeta.tenantID != currentAccount.tenant.tenantID {
                    showOrganizationTag(organizationName: summary)
                } else {
                    showInfoLabel(summary: summary)
                }
            } else {
                showInfoLabel(summary: summary)
            }
        }
    }

    func showOrganizationTag(organizationName: NSAttributedString) {
        infoLabel.isHidden = true
        infoLabelConstraint?.deactivate()
        organizationTag.isHidden = false
        organizationTagConstraint?.activate()
        if !organizationName.string.isEmpty {
            organizationTag.setElements([Tag(title: organizationName.string,
                                     style: .blue,
                                     type: .organization)])
        } else {
            organizationTag.setTags([.organization])
        }
    }

    func showInfoLabel(summary: NSAttributedString) {
        organizationTag.isHidden = true
        organizationTagConstraint?.deactivate()
        guard summary.length > 0 else {
            isInfoLabelHidden = true
            infoLabel.isHidden = true
            return
        }
        infoLabel.isHidden = false
        infoLabelConstraint?.activate()
        infoLabel.textColor = UIColor.ud.textPlaceholder
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        infoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        infoLabel.isHidden = summary.length == 0

        infoLabel.attributedText = summary
        if let chatterViewModel = viewModel as? ChatterSearchViewModel,
           !chatterViewModel.divisionInFoldStatus {
            // 如果是展开态，展开所有的部门信息
            infoLabel.numberOfLines = 0
        } else {
            infoLabel.numberOfLines = 2
            infoLabel.lineBreakMode = .byTruncatingHead
        }

    }

    func showDSLView(by renderData: String) {
        infoView.isHidden = true
        isInfoLabelHidden = true
        emailLabel.isHidden = true
        isEmailHidden = true

        var cellWidth: CGFloat = 0
        if let chatterViewModel = viewModel as? ChatterSearchViewModel {
            templateManager.divisionInFoldStatus = chatterViewModel.divisionInFoldStatus
            cellWidth = chatterViewModel.tableViewWidth - avatarViewLeadingOffset
                                                            - SearchResultDefaultView.searchAvatarImageDefaultSize
                                                            - chatterContainerViewLeadingOffset
                                                            - chatterContainerViewTrailingOffset
                                                            - personCardButtonWidth
                                                            - personCardButtonTrailingOffset
            templateManager.cellWidth = cellWidth
        }

        if let renderer = templateManager.getDSLRenderer(by: renderData) {
            searchDSLContainerView.isHidden = false
            searchDSLView.update(with: renderer)
            let dslViewSize = renderer.size()
            searchDSLView.snp.remakeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.height.equalTo(dslViewSize.height)
                make.width.equalTo(cellWidth).priority(.high)
                make.trailing.lessThanOrEqualToSuperview().priority(.required)
            }
        }
    }

    @objc
    private func personCardButtonDidClick() {
        if let model = viewModel as? ChatterSearchViewModel, let controller = controller {
            model.didSelectPersonCard(fromVC: controller)
        } else {
            assertionFailure("personCardButtonDidClick model or controller nil")
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellState(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellState(animated: animated)
    }

    private func updateCellState(animated: Bool) {
        updateCellStyle(animated: animated)
        if needShowDividerStyle() {
            self.selectedBackgroundView?.backgroundColor = UIColor.clear
            updateCellStyleForPad(animated: animated, view: bgView)
        }
    }

    override func layoutSubviews() {
        var bottom = 1
        if needShowDividerStyle() {
            bottom = 13
        }
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: CGFloat(bottom), right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }
}

// MARK: - EETroubleKiller
extension ChatterSearchTableViewCell: CaptureProtocol & DomainProtocol {

    public var isLeaf: Bool {
        return true
    }

    public var domainKey: [String: String] {
        var tkDescription: [String: String] = [:]
        tkDescription["id"] = "\(self.viewModel?.searchResult.id ?? "")"
        tkDescription["type"] = "\(self.viewModel?.searchResult.type ?? .unknown)"
        tkDescription["cid"] = "\(self.viewModel?.searchResult.contextID ?? "")"
        return tkDescription
    }
}
