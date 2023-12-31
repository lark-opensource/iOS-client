//
//  DailyDetailViewController.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/2/8.
//

import UIKit
import SnapKit
import WebKit
import RxSwift
import RxCocoa
import UniverseDesignTheme
import ByteViewCommon
import UniverseDesignIcon
import ByteViewUI

protocol DailyDetailViewControllerDismissDelegate: AnyObject {
    func dailyDetailViewControllerDidDismiss()
}

class DailyDetailViewController: VMViewController<DailyDetailViewModel>, UIScrollViewDelegate {
    let disposeBag = DisposeBag()

    private lazy var topicLabel: UILabel = {
        let topicLabel = UILabel()
        topicLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapTopic(_:)))
        topicLabel.addGestureRecognizer(tap)
        topicLabel.textColor = UIColor.ud.textTitle
        topicLabel.font = .systemFont(ofSize: 17.0, weight: .medium)
        topicLabel.numberOfLines = 2
        topicLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        topicLabel.lineBreakMode = .byTruncatingTail
        return topicLabel
    }()

    private lazy var topStackView: UIStackView = {
        let topStackView = UIStackView()
        topStackView.axis = .vertical
        topStackView.alignment = .leading
        topStackView.distribution = .equalSpacing
        topStackView.spacing = 4.0
        return topStackView
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.indicatorStyle = .black
        scrollView.contentInset = .init(top: 8, left: 0, bottom: 8, right: 0)
        scrollView.delegate = self
        return scrollView
    }()

    lazy var contentStack: UIStackView = {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.spacing = contentSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        return contentStack
    }()

    private lazy var bottomView: UIStackView = {
        let bottomView = UIStackView()
        bottomView.axis = .vertical
        bottomView.alignment = .fill
        bottomView.distribution = .fill
        bottomView.spacing = buttonSpacing
        return bottomView
    }()

    let meetingShareView = MeetingShareView()
    lazy var enterMeetingGroupButton: VisualButton = {
        let button = VisualButton(type: .custom)
        button.clipsToBounds = true
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        button.setTitleColor(UIColor.ud.textTitle.withAlphaComponent(0.5), for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .highlighted)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(didEnterGroup), for: .touchUpInside)
        return button
    }()
    let contentLayoutGuide = UILayoutGuide()
    let verticalSeparator = UILayoutGuide()
    lazy var leadingConstraint: NSLayoutConstraint = contentLayoutGuide.leftAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16)
    lazy var trailingConstraint: NSLayoutConstraint = contentLayoutGuide.rightAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16)
    lazy var topConstraint: NSLayoutConstraint = contentLayoutGuide.topAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topHeight)

    lazy var meetingIdLabel = CopyableTextView(shouldLimit: true)
    lazy var meetingIdCopyButton: DailyDetailButton = {
        let button = DailyDetailButton(customType: .image(CGSize(width: 20, height: 20)))
        button.setImage(UDIcon.getIconByKey(.copyOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(copyMeetingNumber), for: .touchUpInside)
        return button
    }()
    lazy var organizerLabel = CopyableTextView(shouldLimit: true)
    lazy var organizerAvatarView: AvatarView = {
        let view = AvatarView()
        return view
    }()
    lazy var meetingLinkLabel = CopyableTextView(shouldLimit: true)
    lazy var meetingLinkCopyButton: DailyDetailButton = {
        let button = DailyDetailButton(customType: .image(CGSize(width: 20, height: 20)))
        button.setImage(UDIcon.getIconByKey(.copyOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(copyMeetingLink), for: .touchUpInside)
        return button
    }()
    lazy var dialInLabel = CopyableTextView(shouldLimit: true)
    var dialInView: DailyDetailContentView?
    var organizerView: DailyDetailContentView?
    lazy var morePhoneButton: DailyDetailButton = {
        let button = DailyDetailButton(customType: .image(CGSize(width: 20, height: 20)))
        button.setImage(UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(showMoreDialInNumbers), for: .touchUpInside)
        return button
    }()
    lazy var meetingMaxParticipantsLabel = CopyableTextView()
    // 扩容最大参会人数
    lazy var expandButton: DailyDetailButton = {
        let button = DailyDetailButton(customType: .text(24, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)))
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.setTitle(I18n.View_G_ExpandIt_Button, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.layer.vc.borderColor = UIColor.ud.primaryContentDefault
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(didTapExpandButton), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()
    lazy var meetingLimitTimeLabel = CopyableTextView()
    // 升级单次会议时间
    lazy var upgradeButton: DailyDetailButton = {
        let button = DailyDetailButton(customType: .text(24, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)))
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.titleLabel?.textAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.setTitle(I18n.View_G_UpgradeIt_Button, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.layer.vc.borderColor = UIColor.ud.primaryContentDefault
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(didTapUpgradeButton), for: .touchUpInside)
        button.layer.masksToBounds = true
        return button
    }()
    lazy var e2EeMeetingLabel = CopyableTextView()

    lazy var refLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .clear
        label.text = I18n.View_M_MorePhoneNumbers
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()

    lazy var closePeopleMinutesButton: DailyDetailButton = {
        let button = DailyDetailButton(customType: .text(24, .zero))
        button.setTitle(PeopleMinutesText.stop, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentLoading, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(closePeopleMinutesButtonAction), for: .touchUpInside)
        return button
    }()

    lazy var peopleMinutesMessageLabel = CopyableTextView()

    lazy var timeLabel = CopyableTextView()
    lazy var roomLabel = CopyableTextView()
    lazy var locationLabel = CopyableTextView()
    lazy var descriptionView = UIView()

    private var webView: WKWebView?
    private lazy var docsViewHolder: CalendarDocsViewHolder = {
        var holder = viewModel.service.calendar.createDocsView()
        holder.setThemeConfig(
            backgroundColor: view.backgroundColor ?? UIColor.ud.bgBody,
            foregroundFontColor: UIColor.ud.textTitle,
            linkColor: UIColor.ud.textLinkNormal,
            listMarkerColor: UIColor.ud.primaryContentDefault
        )
        holder.delegate = self
        let router = self.viewModel.meeting.router
        let larkRouter = self.viewModel.larkRouter
        holder.customHandle = { url, _ in
            if url.absoluteString == "about:blank" {
                return
            }
            router.setWindowFloating(true)
            larkRouter.push(url, context: ["from": "ByteView"])
        }
        return holder
    }()

    private lazy var alertTextView: AlertTextView = AlertTextView()
    private lazy var effectview: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        let gesture = UITapGestureRecognizer(target: self, action: #selector(effectviewTaped))
        view.addGestureRecognizer(gesture)
        return view
    }()

    private var menuFixer: MenuFixer?

    // MARK: - layout
    var isPopover = false

    var bottomHeight: CGFloat {
        return isPopover ? 24 : 12
    }

    let topicLabelHeight: CGFloat = 24
    let lineHeight: CGFloat = 20
    var topicLabelLineNum: Int = 1

    let stackSpacing: CGFloat = 8
    let contentSpacing: CGFloat = 16
    var buttonHeight: CGFloat = 36
    let popoverWidth: CGFloat = 440

    var fitTitleWidths: [CGFloat] = []

    var topHeight: CGFloat {
        return isPopover ? 24 : 8
    }

    var buttonSpacing: CGFloat {
        if isPopover || view.orientation?.isPortrait == true {
            return 10
        } else {
            return 14
        }
    }

    var maxHeight: CGFloat {
        let insets = VCScene.safeAreaInsets
        let safeHeight = VCScene.bounds.height - (insets.top + insets.bottom)
        if view.orientation?.isPortrait == true {
            return isPopover ? safeHeight - 91 : safeHeight - 60
        } else {
            return isPopover ? safeHeight - 87 : safeHeight - 23
        }
    }

    private var isTruncated: Bool {
        guard let labelText = topicLabel.text else {
            return false
        }
        let labelTextHeight = labelText.vc.boundingHeight(width: topicLabel.frame.size.width, font: topicLabel.font ?? .systemFont(ofSize: 17))
        return labelTextHeight > topicLabel.bounds.size.height + 1
    }
    private var _popoverHeight: CGFloat = 0

    weak var dismissDelegate: DailyDetailViewControllerDismissDelegate?

    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.menuFixer = MenuFixer(viewController: self)
        viewModel.hostViewController = self
    }

    deinit {
        /*
         实现的时候为了箭头改变及时一点使用的是viewWillDisapper的回调，但是当分屏从R 到 C的时候居然也会调用viewWillDisapper
         */
        dismissDelegate?.dailyDetailViewControllerDidDismiss()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if _popoverHeight != popoverHeight {
            self.updateContentSize()
        }
    }

    // avoid nested uistackviews: https://stackoverflow.com/questions/33073127/nested-uistackviews-broken-constraints
    override func setupViews() {
        self.view.backgroundColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        view.addLayoutGuide(contentLayoutGuide)
        view.addLayoutGuide(verticalSeparator)

        leadingConstraint.isActive = true
        trailingConstraint.isActive = true
        topConstraint.isActive = true

        verticalSeparator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        verticalSeparator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        verticalSeparator.widthAnchor.constraint(equalToConstant: 12).isActive = true

        // stack
        view.addSubview(topStackView)
        topStackView.addArrangedSubview(topicLabel)
        topStackView.snp.makeConstraints {
            $0.top.left.right.equalTo(contentLayoutGuide)
            let height = topicLabelHeight * CGFloat(topicLabelLineNum)
            $0.height.greaterThanOrEqualTo(height)
        }

        topicLabel.snp.makeConstraints {
            $0.height.equalTo(topicLabelHeight * CGFloat(topicLabelLineNum))
            $0.left.right.equalToSuperview()
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(topStackView.snp.bottom).offset(stackSpacing)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0)
        }
        contentStack.snp.makeConstraints { maker in
            maker.width.equalTo(scrollView)
            maker.edges.equalToSuperview()
        }

        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (maker) in
            maker.left.right.equalTo(contentLayoutGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(-bottomHeight)
        }

        if viewModel.isMeetingShareViewVisible {
            self.setupMeetingShareView()
        }
        setupDailyDetailContent()
        updateContentSize()
    }

    private func setupDailyDetailContent() {
        for content in viewModel.dailyDetailContent {
            switch content {
            case .meetingNum:
                addContentCopyableViews(I18n.View_N_MeetingId, meetingIdLabel, additionalView: meetingIdCopyButton, viewSize: CGSize(width: 20, height: 20))
                setContentText(meetingIdLabel, viewModel.meetingNumber)
            case .organizer:
                addContentCopyableViews(I18n.View_G_CardHost_Desc, organizerLabel, additionalView: organizerAvatarView, viewSize: CGSize(width: 24, height: 24), additionalDirection: .left, tapCompletion: { [weak self] in
                    guard let self = self, let id = self.viewModel.meeting.info.meetingOwner?.participantId.larkUserId else { return }
                    InMeetUserProfileAction.show(userId: id, meeting: self.viewModel.meeting)
                })
                organizerLabel.isUserInteractionEnabled = false
                if let pid = viewModel.meetingOwner?.participantId {
                    viewModel.meeting.httpClient.participantService.participantInfo(pid: pid, meetingId: viewModel.meetingId) { [weak self] ap in
                        guard let self = self else { return }
                        self.organizerAvatarView.setTinyAvatar(ap.avatarInfo)
                        self.setContentText(self.organizerLabel, ap.name, shouldHideIfNeeded: true)
                    }
                }
            case .meetingLink:
                addContentViews(I18n.View_M_MeetingLink, meetingLinkLabel, additionalView: meetingLinkCopyButton, viewSize: CGSize(width: 20, height: 20))
            case .dialIn:
                dialInView = addContentCopyableViews(I18n.View_M_DialIn, dialInLabel, additionalView: morePhoneButton, viewSize: CGSize(width: 20, height: 20))
                dialInView?.isHidden = !viewModel.isDialInViewVisible
            case .benefit(let benefitInfo):
                benefitInfo.benefits.forEach { benefit in
                    switch benefit {
                    case .maxParticipant(let canExpand):
                        let participantContentView: DailyDetailContentView
                        // 有扩容权限
                        if canExpand {
                            participantContentView = addContentCopyableViews(I18n.View_G_CardCurrentBenefits_Desc, meetingMaxParticipantsLabel, additionalView: expandButton, viewSize: CGSize(width: expandButton.intrinsicContentSize.width, height: 24))
                        } else {
                            participantContentView = addContentViews(I18n.View_G_CardCurrentBenefits_Desc, meetingMaxParticipantsLabel)
                        }
                        let displayMaxParticipant: String
                        if viewModel.meeting.info.settings.subType == .webinar {
                            participantContentView.horizontalOffset = 4.0
                            displayMaxParticipant = I18n.View_G_CardMaxPartPanelAndAttendee_Desc(viewModel.meeting.setting.maxParticipantNum + viewModel.meeting.setting.maxAttendeeNum)
                        } else {
                            participantContentView.horizontalOffset = 8.0
                            displayMaxParticipant = I18n.View_G_CardMaxPart_Desc(viewModel.meeting.setting.maxParticipantNum)
                        }
                        setContentText(meetingMaxParticipantsLabel, displayMaxParticipant)
                    case .maxTime(let canUpgrade):
                        // 有升级会议时间权限
                        if canUpgrade {
                            addContentCopyableViews("", meetingLimitTimeLabel, additionalView: upgradeButton, viewSize: CGSize(width: upgradeButton.intrinsicContentSize.width, height: 24))
                        } else {
                            addContentViews("", meetingLimitTimeLabel)
                        }
                        let shouldShowPlanTimeLimit = viewModel.meeting.setting.billingSetting.planTimeLimit < 1440 && viewModel.meeting.setting.billingSetting.planTimeLimit > 0
                        // 如果套餐时长小于1440分钟并大于0分钟，显示具体数值，反之直接显示24小时
                        setContentText(meetingLimitTimeLabel, shouldShowPlanTimeLimit ?  I18n.View_G_CardTimeLmtPerMeeting_Desc(viewModel.meeting.setting.billingSetting.planTimeLimit) : I18n.View_G_CardMaxMeetingDuration_Desc)
                    }
                }
            case .e2EeMeeting:
                addContentViews(I18n.View_G_EncryptionTitle, e2EeMeetingLabel)
                setContentText(e2EeMeetingLabel, I18n.View_G_EncryptionEnabled)
            case .peopleMinutes:
                addContentViews(PeopleMinutesText.title, peopleMinutesMessageLabel, additionalView: closePeopleMinutesButton, viewSize: .zero, additionalDirection: .bottom)
                setContentText(peopleMinutesMessageLabel, PeopleMinutesText.content)
            case .date:
                addContentViews(I18n.View_G_Date, timeLabel).isHidden = true
            case .roomInfo:
                addContentViews(I18n.View_M_MeetingRoom, roomLabel).isHidden = true
            case .location:
                addContentViews(I18n.View_M_Location, locationLabel).isHidden = true
            case .description:
                addContentViews(I18n.View_S_Description, descriptionView).isHidden = true
                let docsView = self.docsViewHolder.getDocsView(true, shouldJumpToWebPage: true)
                descriptionView.addSubview(docsView)
                docsView.snp.makeConstraints({ (maker) in
                    maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 0))
                })

                docsViewHolder.setEditable(false, success: nil, fail: { _ in })
                webView = docsView.vc.getWebView()
                docsView.backgroundColor = .clear
                webView?.isOpaque = false
                webView?.backgroundColor = .clear
                webView?.scrollView.backgroundColor = .clear
                webView?.scrollView.contentInset = .zero
            }
        }
    }

    private func setupMeetingShareView() {
        bottomView.addArrangedSubview(meetingShareView)
        meetingShareView.update(shareCardEnabled: viewModel.isShareCardEnabled)
        meetingShareView.snp.makeConstraints { maker in
            maker.height.equalTo(buttonHeight)
        }
    }

    private func calCulateTopicLabelLines() {
        if let text = topicLabel.text, !text.isEmpty, self.view.frame.width > 0 {
            let topicFont: UIFont = .systemFont(ofSize: 17.0, weight: .medium)
            let topicWidth = text.vc.boundingWidth(height: topicLabelHeight, font: topicFont)
            let lines = Int(ceil(Double(topicWidth / (view.frame.width - 32))))
            topicLabelLineNum = lines > 2 ? 2 : lines
        }
    }

    @discardableResult
    private func addContentViews(_ title: String, _ contentView: UIView, hasMoreView: Bool = false) -> DailyDetailContentView {
        let view = DailyDetailContentView(contentView: contentView)
        let fitWidth = view.setContent(title: title)
        fitTitleWidths.append(fitWidth)
        contentStack.addArrangedSubview(view)
        return view
    }

    @discardableResult
    private func addContentCopyableViews(_ title: String, _ contentView: CopyableTextView, additionalView: UIView, viewSize: CGSize, additionalDirection: DailyDetailContentView.AdditionViewDirection = .right, tapCompletion: (() -> Void)? = nil) -> DailyDetailContentView {
        let view = DailyDetailContentView(contentView: contentView, additionalView: additionalView, viewSize: viewSize, additionalDirection: additionalDirection, tapCompletion: tapCompletion)
        let fitWidth = view.setContent(title: title)
        fitTitleWidths.append(fitWidth)
        contentStack.addArrangedSubview(view)
        return view
    }

    @discardableResult
    private func addContentViews(_ title: String, _ contentView: UIView, additionalView: UIView, viewSize: CGSize, additionalDirection: DailyDetailContentView.AdditionViewDirection = .right, tapCompletion: (() -> Void)? = nil) -> DailyDetailContentView {
        let view = DailyDetailContentView(contentView: contentView, additionalView: additionalView, viewSize: viewSize, additionalDirection: additionalDirection, tapCompletion: tapCompletion)
        let fitWidth = view.setContent(title: title)
        fitTitleWidths.append(fitWidth)
        contentStack.addArrangedSubview(view)
        return view
    }

    private func updateStackContent() {
        let maxFitWidth = fitTitleWidths.max()
        for view in contentStack.arrangedSubviews {
            guard let view = view as? DailyDetailContentView else { return }
            view.setupConstraints(contentLayoutGuide: contentLayoutGuide,
                                  verticalSeparator: verticalSeparator,
                                  titleWidth: maxFitWidth)
        }
    }

    private var lastViewSize: CGSize = .zero
    private var lastMaxHeight: CGFloat = 0

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        calCulateTopicLabelLines()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            let maxHeight = self.maxHeight
            let isMaxHeightChanged = self.lastMaxHeight != maxHeight
            guard self.lastViewSize != self.view.frame.size || isMaxHeightChanged else {
                return
            }

            let isWidthChanged = self.lastViewSize.width != self.view.frame.width
            self.lastViewSize = self.view.frame.size
            self.lastMaxHeight = maxHeight
            self.updateContentSize()
            if isWidthChanged || isMaxHeightChanged {
                self.reloadMeetingDescription()
            }
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
            self.updateContentSize()
            self.reloadMeetingDescription()
    }

    private func updateLayoutForMeetingShare() {
        guard viewModel.isMeetingShareViewVisible else { return }
        guard viewModel.isShareCardEnabled else { return }
        let textWidth = (meetingShareView.copyMeetingInfoButton.titleLabel?.intrinsicContentSize.width ?? 0) + (meetingShareView.shareButton.titleLabel?.intrinsicContentSize.width ?? 0)
        let totalWidth = textWidth + 4 * 16 + meetingShareView.buttonPadding
        if meetingShareView.shouldFixHeight || totalWidth <= contentLayoutGuide.layoutFrame.width {
            buttonHeight = 36
            meetingShareView.update(shareCardEnabled: true)
        } else {
            buttonHeight = 84
            meetingShareView.update(shareCardEnabled: true, isHorizontal: false)
        }
        meetingShareView.snp.remakeConstraints { maker in
            maker.height.equalTo(buttonHeight)
        }
    }

    private func updateContentSize(shouldReloadDescription: Bool = true) {
        var needsLayout = false
        updateStackContent()
        topicLabel.snp.remakeConstraints {
            $0.height.equalTo(topicLabelHeight * CGFloat(topicLabelLineNum))
            $0.left.right.equalToSuperview()
        }
        topStackView.snp.remakeConstraints {
            $0.top.left.right.equalTo(contentLayoutGuide)
            $0.height.greaterThanOrEqualTo(topicLabelHeight * CGFloat(topicLabelLineNum))
        }
        bottomView.snp.remakeConstraints { (maker) in
            maker.left.right.equalTo(contentLayoutGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(-bottomHeight)
        }
        updateLayoutForMeetingShare()
        let height = popoverHeight
        if self.preferredContentSize.height != height {
            updateDynamicModalSize(CGSize(width: popoverWidth, height: height))
            _popoverHeight = height
            panViewController?.updateBelowLayout()
            needsLayout = true
        }

        let marginLeft: CGFloat = isPopover ? 24 : view.safeAreaInsets.left > 0 ? 0 : 16
        let marginRight: CGFloat = isPopover ? -24 : view.safeAreaInsets.right > 0 ? 0 : -16
        if marginLeft != leadingConstraint.constant || marginRight != trailingConstraint.constant {
            leadingConstraint.constant = marginLeft
            trailingConstraint.constant = marginRight
            needsLayout = true
        }

        let topHeight = self.topHeight
        let buttonSpacing = self.buttonSpacing
        if topConstraint.constant != topHeight || bottomView.spacing != buttonSpacing {
            topConstraint.constant = topHeight
            bottomView.spacing = buttonSpacing
            needsLayout = true
        }

        if !contentStack.arrangedSubviews.isEmpty {
            let height = self.preferredContentSize.height
            let scrollHeight = max(0, height - self.fixedHeight - self.stackSpacing)
            if scrollView.frame.height != scrollHeight {
                scrollView.snp.updateConstraints { (maker) in
                    maker.height.equalTo(scrollHeight)
                }
                needsLayout = true
            }
        }
        if needsLayout {
            view.setNeedsLayout()
        }
    }

    // MARK: - Actions
    @objc private func didTapTopic(_ gesture: UIGestureRecognizer) {
        if let topic = self.topicLabel.text, self.isTruncated {
            self.alertTextView.setText(text: topic)
            if let maskView = panViewController?.panMaskView {
                maskView.addSubview(effectview)
                maskView.isHidden = false
                maskView.addSubview(alertTextView)
            } else {
                self.view.addSubview(effectview)
                self.view.addSubview(alertTextView)
            }
            effectview.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            alertTextView.snp.makeConstraints { (make) in
                make.top.equalTo(view.snp.top).offset(40)
                make.left.equalToSuperview().offset(view.safeAreaInsets.left + 20)
                make.right.equalToSuperview().offset(-20)
            }
            alertTextView.show()
        }
    }

    @objc func copyMeetingNumber() {
        MeetingTracks.trackCopyMeetingID()
        if viewModel.meeting.security.copy(viewModel.meetingNumber, token: .meetingDetailCopyMeetingContent) {
            dismiss(animated: true)
            Toast.showOnVCScene(I18n.View_G_OKIDCopied_Toast)
        }
    }

    @objc func copyMeetingLink() {
        MeetingTracks.trackCopyMeetingLink()
        if viewModel.meeting.security.copy(meetingLinkLabel.text, token: .meetingDetailCopyMeetingContent) {
            dismiss(animated: true)
            Toast.showOnVCScene(I18n.View_G_OkLinkCopied_Toast)
        }
    }

    @objc func didTapExpandButton() {
        MeetingTracks.trackExpandMaxParticipants(isSuperAdministrator: viewModel.setting.isSuperAdministrator)
        upgradeBenefit()
    }

    @objc func didTapUpgradeButton() {
        MeetingTracks.trackUpgradeMeetingTime(isSuperAdministrator: viewModel.setting.isSuperAdministrator)
        upgradeBenefit()
    }

    private func upgradeBenefit() {
        let link = viewModel.meeting.setting.billingLinkConfig.upgradeLink
        if !link.isEmpty {
            guard let url = URL(string: link) else { return }
            let router = viewModel.meeting.router
            let larkRouter = viewModel.meeting.larkRouter
            router.dismissTopMost(animated: false) {
                router.setWindowFloating(true)
                larkRouter.push(url, context: ["from": "byteView"], forcePush: true)
            }
        }
    }

    @objc func effectviewTaped() {
        alertTextView.hide()
        alertTextView.removeFromSuperview()
        effectview.removeFromSuperview()
        panViewController?.panMaskView?.isHidden = true
    }

    override func bindViewModel() {
        viewModel.meetingLinkObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (text) in
                guard let self = self else { return }
                self.setContentText(self.meetingLinkLabel, text)
            }).disposed(by: disposeBag)

        viewModel.dialIn
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (text) in
                self?.updateDialInText(text)
            }).disposed(by: disposeBag)

        viewModel.detailInfoObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                self?.updateDetailInfo(info)
            }).disposed(by: disposeBag)

        if viewModel.isMeetingShareViewVisible {
            meetingShareView.shareButton.addTarget(self, action: #selector(didShare), for: .touchUpInside)
            meetingShareView.copyMeetingInfoButton.addTarget(self, action: #selector(didCopyMeetingInfo), for: .touchUpInside)
        }
    }

    @objc private func showMoreDialInNumbers() {
        MeetingTracks.trackMorePhoneNumbers()
        presentingViewController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let vm = PhoneListViewModel(meetingNumber: self.viewModel.meeting.info.meetNumber,
                                        pstnIncomingCallPhoneList: self.viewModel.setting.pstnIncomingCallPhoneList,
                                        security: self.viewModel.meeting.security)
            let viewController = PhoneListViewController(viewModel: vm)
            self.viewModel.meeting.router.presentDynamicModal(
                viewController,
                regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        }
    }

    @objc private func didShare() {
        viewModel.shareViaCall(from: self)
    }

    @objc private func didCopyMeetingInfo() {
        MeetingTracks.trackCopyMeetingInfo()
        MeetingTracksV2.trackCopyMeetingInfo()
        MeetingTracksV2.trackCopyMeetingInfoClick()
        if viewModel.meeting.setting.isMeetingLocked {
            Toast.show(I18n.View_MV_MeetingLocked_Toast)
            return
        }
        CopyMeetingInviteLinkAction.copy(meeting: viewModel.meeting, token: .meetingDetailCopyMeetingContent)
    }

    private func updateDialInText(_ text: String) {
        let shouldHideMore = !viewModel.hasMoreDialInPhones
        if dialInLabel.attributedText.string == text && morePhoneButton.isHidden == shouldHideMore {
            return
        }

        setContentText(dialInLabel, text)
        dialInLabel.superview?.isHidden = !viewModel.isDialInViewVisible
        if viewModel.isDialInViewVisible && morePhoneButton.isHidden != shouldHideMore {
            morePhoneButton.isHidden = shouldHideMore
            dialInView?.updateConstraintsWithButton(contentLayoutGuide: contentLayoutGuide, verticalSeparator: verticalSeparator, shouldHiddenButton: shouldHideMore)
        }
        updateContentSize()
    }

    private func updateDetailInfo(_ info: DailyDetailInfo) {
        topicLabel.text = info.topic
        calCulateTopicLabelLines()
        if viewModel.isCalendarMeeting {
            setContentText(timeLabel, info.time, shouldHideIfNeeded: true)
            setContentText(roomLabel, info.room, shouldHideIfNeeded: true)
            setContentText(locationLabel, info.location, shouldHideIfNeeded: true)
            reloadMeetingDescription()

            if viewModel.isEnterGroupButtonVisible {
                enterMeetingGroupButton.setTitle(info.enterGroupText, for: .normal)
                if enterMeetingGroupButton.superview == nil {
                    meetingShareView.shouldFixHeight = true
                    bottomView.addArrangedSubview(enterMeetingGroupButton)
                    enterMeetingGroupButton.snp.makeConstraints { maker in
                        maker.height.equalTo(36)
                    }
                    updateContentSize()
                }
            }
        }

        updateContentSize()
    }

    @objc private func didEnterGroup() {
        viewModel.enterGroup(from: self)
    }

    @objc private func closePeopleMinutesButtonAction() {
        presentingViewController?.dismiss(animated: true)
        PeopleMinutesViewModel.stopPeopleMinutes(meeting: viewModel.meeting,
                                                 isShareing: viewModel.context.meetingContent.isShareContent)
    }

    private func setContentText(_ label: CopyableTextView, _ text: String, shouldHideIfNeeded: Bool = false) {
        let s = NSMutableAttributedString(string: text, config: .r_14_22)
        s.addAttribute(.foregroundColor, value: UIColor.ud.textTitle, range: NSRange(0 ..< s.length))
        let textSize: CGSize = s.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 22), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
        label.customIntrinsicContentSize = textSize
        label.attributedText = s
        if shouldHideIfNeeded {
            label.superview?.isHidden = text.isEmpty
        }
    }

    private func reloadMeetingDescription() {
        let desc = viewModel.currentDetailInfo.desc
        guard viewModel.isCalendarMeeting && !desc.isEmpty else {
            descriptionView.superview?.isHidden = true
            return
        }

        if let sv = descriptionView.superview, sv.isHidden {
            sv.alpha = 0
            sv.isHidden = false
        }
        let dispalyWidth = descriptionView.frame.width

        let textColor = isDarkMode() ? "#F0F0F0" : "#1F2329"
        let linkColor = isDarkMode() ? "#4382FF" : "#3370FF"
        docsViewHolder.setDoc(data: desc, displayWidth: dispalyWidth, success: { [weak self] in
            guard let self = self else { return }
            let js = """
                        function injectCss() {
                            var headerNode = document.getElementsByTagName('head');
                            var cssNode = document.createElement('Style');
                            cssNode.type='text/css';
                            cssNode.innerHTML = `
                            body {
                                background-color: transparent !important;
                            }
                            #editor, #main .innerdocbody {
                                background-color: transparent !important;
                                color: \(textColor) !important;
                                font-size: 14px !important;
                                line-height: 22px !important;
                            }
                            #editor li:before, #main li .list-prefix {
                                color: \(textColor) !important;
                            }
                            #editor a, #main .innerdocbody.adit-container a {
                                color: \(linkColor) !important;
                            }
                            `;
                            headerNode[0].appendChild(cssNode);
                        }
                        injectCss()
                        """
            self.webView?.evaluateJavaScript(js, completionHandler: { [weak self] (any, error) in
                Self.logger.info("DailyDetail did evalute JavaScript \(any), error = \(error)")
                guard let self = self else { return }
                if error == nil {
                    self.updateContentSize(shouldReloadDescription: false)
                    guard let documentView = self.descriptionView.superview else { return }
                    // nolint-next-line: magic number
                    UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseInOut, animations: {
                        documentView.alpha = 1
                    }, completion: nil)
                }
            }) }, fail: { (error) in
                Self.logger.error("DailyDetail did set dscription", error: error)
        })
    }

    private func isDarkMode() -> Bool {
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            return true
        } else {
            return false
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if let previousTraitCollection = previousTraitCollection, previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                reloadMeetingDescription()
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            view.endEditing(false)
        }
    }
}

extension DailyDetailViewController: CalendarDocsViewDelegate {
    func docsView(requireOpen url: URL) {
        if url.absoluteString == "about:blank" {
            return
        }
        viewModel.meeting.router.setWindowFloating(true)
        viewModel.larkRouter.push(url, context: ["from": "ByteView"])
    }
}
