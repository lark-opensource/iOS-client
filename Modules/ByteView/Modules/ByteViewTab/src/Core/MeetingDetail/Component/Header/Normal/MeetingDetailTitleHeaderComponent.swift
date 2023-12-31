//
//  MeetingDetailTitleHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI
import SnapKit
import RichLabel
import UniverseDesignIcon

class MeetingDetailTitleHeaderComponent: MeetingDetailHeaderComponent {

    private static let maximumLineForTitle = 4

    private var labelPreferedWidthTag: Bool = true
    private var isLongTitle = false

    private var fullTitleView: FullTitleView?
    private var title = ""

    var titleLeadingEdge: Constraint?
    var titleLeadingCalendar: Constraint?
    var titleLeadingProfile: Constraint?
    var titleTopEdge: Constraint?
    var titleTrailingEdge: Constraint?
    var profileBottom: Constraint?

    private func isExternalHidden(model: TabHistoryCommonInfo) -> Bool {
        guard let account = self.viewModel?.account, account.tenantTag == .standard else { // 小B用户不显示外部标签
            return true
        }
        if model.containsMultipleTenant {
            return false
        } else {
            return model.sameTenantID.isEmpty || model.sameTenantID == "-1" || model.sameTenantID == account.tenantId
        }
    }

    private lazy var titleFont = UIFont.systemFont(ofSize: 20, weight: .medium)
    private lazy var externalTextFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    private lazy var titleParagraphStyle: NSParagraphStyle = {
        let lineHeight: CGFloat = 28
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        return style
    }()
    private lazy var titleAttribute: [NSAttributedString.Key: Any] = [.font: titleFont,
                                                                      .paragraphStyle: titleParagraphStyle,
                                                                      .foregroundColor: UIColor.ud.textTitle]

    private lazy var externalTextWidth: CGFloat = {
        guard let text = meetingTagType.text else { return 0 }
        return Util.textSize(text, font: .systemFont(ofSize: 12, weight: .medium))
            .width
    }()

    private lazy var webinarTextWidth: CGFloat = {
        return Util.textSize(I18n.View_G_Webinar, font: .systemFont(ofSize: 12, weight: .medium))
            .width
    }()

    private var hasSetMeetingTagType = false

    private var isShowTitleNormal: Bool = false {
        didSet {
            self.titleLabel.isHidden = isShowTitleNormal
            self.titleLabelNormal.isHidden = !isShowTitleNormal
        }
    }

    @RwAtomic
    var meetingTagType: MeetingTagType = .none {
        didSet {
            guard meetingTagType != oldValue else { return }
            Logger.ui.info("update meetingTagType for detail view meeting: \(viewModel?.meetingNumber ?? "")")
            hasSetMeetingTagType = true
            DispatchQueue.main.async { [weak self] in
                self?.updateExternalView()
            }
        }
    }

    lazy var calendarIcon: UIImageView = {
        let calendarIcon = UIImageView(image: UDIcon.getIconByKey(.calendarLineOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)))
        calendarIcon.isHidden = true
        return calendarIcon
    }()

    lazy var profileView: AvatarView = {
        let profileView = AvatarView()
        profileView.isHidden = true
        return profileView
    }()

    lazy var titleLabel: AttachmentLabel = {
        let titleLabel = AttachmentLabel()
        titleLabel.delegate = self
        titleLabel.isUserInteractionEnabled = true
        titleLabel.numberOfLines = Self.maximumLineForTitle
        titleLabel.backgroundColor = .clear
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textVerticalAlignment = .middle
        titleLabel.contentFont = titleFont
        titleLabel.contentParagraphStyle = titleParagraphStyle

        titleLabel.addAttributedString(titleAttributedString)
        titleLabel.addArrangedSubview(webinarLabel)
        titleLabel.addArrangedSubview(externalLabel)
        return titleLabel
    }()

    lazy var titleLabelNormal: UILabel = {
        let titleLabel = UILabel()
        titleLabel.isUserInteractionEnabled = true
        titleLabel.numberOfLines = Self.maximumLineForTitle
        titleLabel.backgroundColor = .clear
        titleLabel.font = titleFont

        titleLabel.attributedText = titleAttributedString
        return titleLabel
    }()

    lazy var titleAttributedString = NSMutableAttributedString(string: "", attributes: titleAttribute)

    lazy var externalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.text = I18n.View_G_ExternalLabel
        label.textAlignment = .center
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 4
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999.0), for: .horizontal)
        return label
    }()

    lazy var webinarLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.text = I18n.View_G_Webinar
        label.textAlignment = .center
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 4
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999.0), for: .horizontal)
        return label
    }()

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.participantAbbrInfos.addObserver(self)
    }

    override func setupViews() {
        super.setupViews()

        addSubview(calendarIcon)
        calendarIcon.snp.makeConstraints {
            $0.top.equalTo(Display.pad ? 0 : 24) // top与设计稿略有差异，为保证calendarIcon在水平/竖直方向与文字/其他icon对齐
            $0.left.equalToSuperview() // left也略有差异，相同原因
            $0.width.height.equalTo(24)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        addSubview(profileView)
        profileView.snp.makeConstraints {
            $0.top.equalTo(Display.pad ? 0 : 20)
            $0.left.equalToSuperview()
            $0.width.height.equalTo(32)
            profileBottom = $0.bottom.lessThanOrEqualToSuperview().constraint
        }

        // LKLabel 会把点击手势干掉，只有点击 outofRangeText 才响应，不符合我们的预期，所以添加一个父视图处理点击事件
        let labelContainer = UIView()
        labelContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTitleTap(_:))))
        addSubview(labelContainer)
        labelContainer.snp.makeConstraints { make in
            titleLeadingCalendar = make.left.equalTo(calendarIcon.snp.right).offset(8).constraint
            titleLeadingEdge = make.left.equalToSuperview().constraint
            titleLeadingProfile = make.left.equalTo(profileView.snp.right).offset(8).constraint

            titleTopEdge = make.top.equalTo(Display.pad ? 0 : 20).constraint
            make.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        labelContainer.addSubview(titleLabel)
        labelContainer.addSubview(titleLabelNormal)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
        titleLabelNormal.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }

        titleLeadingEdge?.activate()
        titleLeadingCalendar?.deactivate()
        titleLeadingProfile?.deactivate()
        profileBottom?.deactivate()
    }

    override func updateLayout() {
        super.updateLayout()
        fullTitleView?.hide(animated: false)
        updateTitle(title)
    }

    override var shouldShow: Bool {
        true
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel,
              let model = viewModel.commonInfo.value else { return }

        webinarLabel.isHidden = !(viewModel.isWebinarMeeting == true)
        updateMeetingTagTypeWith(model: model)

        titleLeadingProfile?.deactivate()
        titleLeadingEdge?.deactivate()
        titleLeadingCalendar?.deactivate()
        profileBottom?.deactivate()

        let meetingType = model.meetingType
        let tabListItem = viewModel.tabListItem
        let isPhoneCall: Bool = viewModel.isPhoneCall
        let isPstnIpPhone: Bool = viewModel.isPstnIpPhone

        if meetingType == .call || isPhoneCall {
            calendarIcon.isHidden = true
            profileView.isHidden = false
            titleLeadingProfile?.activate()
            profileBottom?.activate()
            // nolint-next-line: magic number
            titleTopEdge?.update(offset: Display.pad ? 2 : 22)

            if isPhoneCall {
                updateTitle(isPstnIpPhone ? tabListItem?.ipPhoneNumber ?? "" : tabListItem?.phoneNumber ?? "")
                profileView.setAvatarInfo(.asset(ByteViewCommon.BundleResources.ByteViewCommon.Avatar.unknown))
            } else if let historyInfo = viewModel.historyInfo {
                var id = ParticipantId(id: historyInfo.interacterUserID, type: historyInfo.interacterUserType)
                if let abbr = viewModel.participantAbbrInfos.value?.last {
                    id = ParticipantId(id: historyInfo.interacterUserID, type: historyInfo.interacterUserType,
                                       bindInfo: BindInfo(id: abbr.bindID, type: abbr.bindType))
                }
                viewModel.httpClient.participantService.participantInfo(pid: id, meetingId: viewModel.meetingID) { [weak self] user in
                    self?.updateTitle(user.name)
                    self?.profileView.setAvatarInfo(user.avatarInfo)
                    self?.profileView.setTapAction({ [weak self] in
                        self?.didTapProfileView(userID: id.larkUserId ?? user.id)
                    })
                }
            }
        } else {
            profileView.isHidden = true
            if [.vcFromCalendar, .vcFromInterview].contains(model.meetingSource) {
                calendarIcon.isHidden = false
                titleLeadingCalendar?.activate()
            } else {
                calendarIcon.isHidden = true
                titleLeadingEdge?.activate()
            }

            let title = model.meetingTopic.isEmpty ?
                I18n.View_G_ServerNoTitle : model.meetingSource == .vcFromInterview ?
                I18n.View_M_VideoInterviewNameBraces(model.meetingTopic) : model.meetingTopic
            labelPreferedWidthTag = true
            updateTitle(title)
        }
        // 不显示日历图标
        calendarIcon.isHidden = true
        titleLeadingCalendar?.deactivate()
        if profileView.isHidden {
            titleLeadingEdge?.activate()
            titleLeadingProfile?.deactivate()
        } else {
            titleLeadingEdge?.deactivate()
            titleLeadingProfile?.activate()
        }
    }

    func updateTitle(_ text: String) {
        guard !text.isEmpty else { return }

        title = text

        titleAttributedString.mutableString.setString(text)
        titleAttributedString.setAttributes(titleAttribute, range: NSRange(location: 0, length: text.count))

        if viewModel?.isWebinarMeeting == true {
            webinarLabel.isHidden = false
            isShowTitleNormal = false
            let webinarTextWidth = webinarTextWidth
            titleLabel.updateArrangedSubview(webinarLabel) {
                $0.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
                $0.size = CGSize(width: webinarTextWidth + 8, height: 18)
            }
        } else {
            webinarLabel.isHidden = true
        }

        if meetingTagType.hasTag {
            externalLabel.isHidden = false
            isShowTitleNormal = false
            let externalTextWidth = externalTextWidth
            titleLabel.updateArrangedSubview(externalLabel) {
                $0.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
                $0.size = CGSize(width: externalTextWidth + 8, height: 18)
            }
        } else {
            externalLabel.isHidden = true
        }
        if !meetingTagType.hasTag && viewModel?.isWebinarMeeting == false {
            isShowTitleNormal = true
            titleLabelNormal.text = title
        }

        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width + (labelPreferedWidthTag ? 32 : 0)
        labelPreferedWidthTag = false // 针对titleLabel显示后布局变动问题
        titleLabel.reload()
        layoutIfNeeded()
    }

    private func updateExternalView() {
        if let tagText = self.meetingTagType.text {
            self.externalLabel.isHidden = false
            self.externalLabel.text = tagText
        } else {
            self.externalLabel.isHidden = true
        }
        self.updateTitle(self.title)
    }

    // MARK: - Title Config
    private func updateMeetingTagTypeWith(model: TabHistoryCommonInfo) {
        guard let viewModel = self.viewModel else { return }
        let account = viewModel.account
        Logger.ui.info("getMeetingTagType \(model.allParticipantTenant), meetingID: \(viewModel.meetingID)")
        if viewModel.tabViewModel.setting.isRelationTagEnabled, model.allParticipantTenant.filter({ String($0) != account.tenantId }).count == 1,
        let tenantId = model.allParticipantTenant.first(where: { String($0) != account.tenantId }) {
            Logger.ui.info("fetch TenantInfo for tenant \(tenantId)")
            let service = MeetTabRelationTagService(httpClient: viewModel.httpClient)
            let info = service.getTargetTenantInfo(tenantId: tenantId, completion: { [weak self] info in
                guard let self = self else {
                    return
                }
                guard let info = info, let tag = info.relationTag?.meetingTagText else {
                    self.meetingTagType = model.isCrossWithKa ? .cross : self.isExternalWith(model: model) ? .external : .none
                    return
                }
                self.meetingTagType = .partner(tag)
            })

            if let info = info, let tag = info.relationTag?.meetingTagText, !hasSetMeetingTagType {
                Logger.ui.info("set meetingTagType from cache")
                self.meetingTagType = .partner(tag)
            }
        } else {
            Logger.ui.info("set meetingTagType without network request")
            self.meetingTagType = model.isCrossWithKa ? .cross : self.isExternalWith(model: model) ? .external : .none
        }
    }

    private func isExternalWith(model: TabHistoryCommonInfo) -> Bool {
        guard let account = self.viewModel?.account, account.tenantTag == .standard else { // 小B用户不显示外部标签
            return false
        }
        if model.containsMultipleTenant {
            return true
        } else {
            return !model.sameTenantID.isEmpty && model.sameTenantID != "-1" && model.sameTenantID != account.tenantId
        }
    }

    @objc
    private func handleTitleTap(_ recognizer: UITapGestureRecognizer) {
        if isLongTitle {
            showFullTitle(title)
        }
    }

    private func didTapProfileView(userID: String) {
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "vc_meeting_username", .from_source: "meeting_detail"])
        viewModel?.handleAvatarTapped(userID: userID)
    }

    private func showFullTitle(_ text: String) {
        guard let from = viewModel?.hostViewController else { return }
        fullTitleView = FullTitleView(title: text)
        if traitCollection.isRegular {
            if titleLabel.isHidden == false {
                fullTitleView?.show(on: titleLabel, from: from, animated: false)
            } else {
                fullTitleView?.show(on: titleLabelNormal, from: from, animated: false)
            }
        } else {
            fullTitleView?.showFullScreen(animated: false, from: from)
        }
    }
}

extension MeetingDetailTitleHeaderComponent: MeetingDetailParticipantAbbrInfoObserver {
    func didReceive(data: [ParticipantAbbrInfo]) {
        updateViews()
    }
}

extension MeetingDetailTitleHeaderComponent: LKLabelDelegate {
    func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {
        if label === titleLabel {
            isLongTitle = isShowMore
        }
    }
}
