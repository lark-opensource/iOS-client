//
//  MailThreadListHeaderView.swift
//  MailSDK
//
//  Created by majx on 2020/2/11.
//

import Foundation
import SnapKit
import LarkAlertController
import UniverseDesignNotice
import UniverseDesignIcon

let kHeaderOutboxTextBtnUrl = "UDNOTICE://outbox"

protocol MailStorageLimitDelegate: AnyObject {
    func storageLimitContactHelp()
    func storageLimitCancelWarning()
}

protocol MailClientExpiredDelegate: AnyObject {
    func clientReVerify()
    func clientReLink()
}

protocol MailClearTrashTipsViewDelegate: AnyObject {
    func clickTrashClearAll()
}

protocol MailPreloadCacheTipsDelegate: AnyObject {
    func preloadCacheTipShowDetail(preloadProgress: MailPreloadProgressPushChange)
    func dismissPreloadCacheTip(preloadProgress: MailPreloadProgressPushChange)
}

protocol MailThreadListHeaderViewDelegate: MailTipViewTipViewDelegate,
                                           MailOutboxTipsViewDelegate,
                                           MailMigrationStateTipsViewDelegate,
                                           MailSmartInboxPreviewCardViewDelegate,
                                           MailFilterTypeTipsViewDelegate,
                                           MailStorageLimitDelegate,
                                           MailClientExpiredDelegate,
                                           MailClearTrashTipsViewDelegate,
                                           MailPreloadCacheTipsDelegate,
                                           MailStrangerCardListDelegate,
                                           MailStrangerThreadCellDelegate {

}

// This view is to show header tips
// Support:
// ----------------
// Multi account view
// ----------------
// current FilterType Tips
// ----------------
// No Net / Syny tips view / Out of Office / Cache Preload
// ----------------
// Outbox tips view
// ----------------
// SmartInbox Preview Card View
// ----------------
class MailThreadListHeaderView: UITableViewHeaderFooterView {
    weak var delegate: MailThreadListHeaderViewDelegate?

    private let MailSyncStatusTipsViewTag = 10000
    private let MailOutboxTipsViewTag = 10001
    private let MailPreloadCacheTag = 10002
    private let MailClearThreadDays = 30
    weak var migrationAlert: LarkAlertController?
    var isSharedAccount: Bool = false {
        didSet {
            if isSharedAccount {
                dismissOOOTips()
                dismissMailSyncTips()
                dismissSmartInboxPreviewCard()
            }
        }
    }
    var superViewWidth: CGFloat = Display.width {
        didSet {
            if oldValue != superViewWidth {
                self.relayout()
            }
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        self.alpha = 0.0
        self.transform = CGAffineTransform(scaleX: 0.88, y: 0.96)
        UIView.animate(
            withDuration: 0.25,
            delay: 0.08,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 5,
            options: .curveEaseOut,
            animations: {
                self.alpha = 1.0
                self.transform = .identity
            },
            completion: nil
        )
    }

    func setupViews() {
        relayout()
    }

    lazy private var stackView: UIStackView = {
        let stackView = UIStackView(frame: contentView.bounds)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()

    private(set) var outboxTipsView: UDNotice?
    private func makeOutboxTipsView() -> UDNotice {
        let text: String
        let range: NSRange
        let newOutbox = FeatureManager.open(.newOutbox)
        if newOutbox {
            text = BundleI18n.MailSDK.Mail_Outbox_UnableToSendCheckMobile
        } else {
            text =  BundleI18n.MailSDK.Mail_UndeliveredMessageInOutbox_banner(0)
        }
        range = (text as NSString).range(of: BundleI18n.MailSDK.Mail_Outbox_OutboxMobile)
        let attrStr = NSMutableAttributedString(string: text,
                                                attributes: [.foregroundColor: UIColor.ud.textTitle])
        attrStr.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: range)
        attrStr.addAttributes([NSAttributedString.Key.link: kHeaderOutboxTextBtnUrl],
                              range: range)
        var config = UDNoticeUIConfig(type: newOutbox ? .warning : .info, attributedText: attrStr)
        if newOutbox {
            config.trailingButtonIcon = UDIcon.closeOutlined
        } else {
            config.leadingButtonText = BundleI18n.MailSDK.Mail_Common_Cancel
        }
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    private func setupOutboxTipsViewIfNeeded() {
        guard outboxTipsView == nil else { return }
        outboxTipsView = makeOutboxTipsView()
    }
    // 定期清理垃圾邮件的tipsView
    private(set) var clearTrashTipsView: UDNotice?
    private func makeClearTrashTipsView() -> UDNotice {
        let attrStr = NSMutableAttributedString(string: BundleI18n.MailSDK.Mail_MessagesInTrashOverNumDaysAutoDelete_Text(MailClearThreadDays),
                                                attributes: [.foregroundColor: UIColor.ud.textTitle])
        var config = UDNoticeUIConfig(type: .info,
                                      attributedText: attrStr)
        config.leadingButtonText = BundleI18n.MailSDK.Mail_MessagesInSpamTrashAutoDelte_DeleteAll_Button
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    private func setupClearTrashTipsViewIfNeeded() {
        guard clearTrashTipsView == nil else { return }
        clearTrashTipsView = makeClearTrashTipsView()
    }

    private(set) var migrationStateTipsView: MailMigrationStateTipsView?
    private func makeMigrationStateTipsView() -> MailMigrationStateTipsView {
        let migrationStateTipsView = MailMigrationStateTipsView(frame: .zero)
        migrationStateTipsView.tag = MailSyncStatusTipsViewTag
        migrationStateTipsView.isHidden = true
        migrationStateTipsView.delegate = self.delegate
        return migrationStateTipsView
    }
    private func setupMigrationStateTipsViewIfNeeded() {
        guard migrationStateTipsView == nil else { return }
        migrationStateTipsView = makeMigrationStateTipsView()
    }

    private(set) var noNetView: UDNotice?
    private func makeNoNetView() -> UDNotice {
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Net_InterruptTipsThreadList,
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        let config = UDNoticeUIConfig(type: .error, attributedText: text)
        let view = UDNotice(config: config)
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    private func setupNoNetViewIfNeeded() {
        guard noNetView == nil else { return }
        noNetView = makeNoNetView()
    }

    private(set) var mailClientExpiredView: UDNotice?
    private func makeMailClientExpiredView() -> UDNotice {
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_ThirdClient_AccountExpiredPleaseReVerifiedMobile,
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        var config = UDNoticeUIConfig(type: .error, attributedText: text)
        config.leadingButtonText = BundleI18n.MailSDK.Mail_ThirdClient_VerifiedAgain
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    private func setupMailClientExpiredViewIfNeeded() {
        guard mailClientExpiredView == nil else { return }
        mailClientExpiredView = makeMailClientExpiredView()
    }

    private(set) var mailClientPassLoginExpiredView: UDNotice?
    private func makeMailClientPassLoginExpiredView() -> UDNotice {
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogInDesc,
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        var config = UDNoticeUIConfig(type: .warning, attributedText: text)
        config.leadingButtonText = BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    private func setupMailClientPassLoginExpiredViewIfNeeded() {
        guard mailClientPassLoginExpiredView == nil else { return }
        mailClientPassLoginExpiredView = makeMailClientPassLoginExpiredView()
    }

    private(set) var outOfOfficeView: UDNotice?
    private func makeOutOfOfficeView() -> UDNotice {
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_OOO_Banner,
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        var config = UDNoticeUIConfig(type: .info, attributedText: text)
        config.leadingButtonText = BundleI18n.MailSDK.Mail_OOO_Banner_Settings
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    private func setupOutOfOfficeViewIfNeeded() {
        guard outOfOfficeView == nil else { return }
        outOfOfficeView = makeOutOfOfficeView()
    }

    private(set) var bilingReminderNotice: UDNotice?
    private func makeBilingReminderNotice() -> UDNotice {
        var warningConfig = UDNoticeUIConfig(type: .warning, attributedText: NSAttributedString())
        warningConfig.trailingButtonIcon = UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate)
        let bilingReminderNotice = UDNotice(config: warningConfig)
        bilingReminderNotice.trailingButton?.tintColor = UIColor.ud.iconN2
        bilingReminderNotice.clipsToBounds = true
        bilingReminderNotice.isHidden = true
        bilingReminderNotice.delegate = self
        return bilingReminderNotice
    }
    private func setupBilingReminderNoticeIfNeeded() {
        guard bilingReminderNotice == nil else { return }
        bilingReminderNotice = makeBilingReminderNotice()
    }

    private(set) var serviceSuspensionNotice: UDNotice?
    private func makeServiceSuspensionNotice() -> UDNotice {
        let errorConfig = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString())
        let serviceSuspensionNotice = UDNotice(config: errorConfig)
        serviceSuspensionNotice.delegate = self
        serviceSuspensionNotice.clipsToBounds = true
        serviceSuspensionNotice.isHidden = true
        return serviceSuspensionNotice
    }
    private func setupServiceSuspensionNoticeIfNeeded() {
        guard serviceSuspensionNotice == nil else { return }
        serviceSuspensionNotice = makeServiceSuspensionNotice()
    }

    private(set) var preloadCacheNotice: MailPreloadCacheTipsView?
    private func makePreloadCacheNotice() -> MailPreloadCacheTipsView {
        let preloadCacheNotice = MailPreloadCacheTipsView(preloadProgress: MailPreloadProgressPushChange(status: .preloadStatusUnspecified, progress: 0, errorCode: .pushErrorUnspecified, preloadTs: .preloadStUnspecified, isBannerClosed: false, needPush: true))
        preloadCacheNotice.delegate = self
        preloadCacheNotice.clipsToBounds = true
        preloadCacheNotice.isHidden = true
        return preloadCacheNotice
    }
    private func setupPreloadCacheNoticeIfNeeded() {
        guard preloadCacheNotice == nil else { return }
        preloadCacheNotice = makePreloadCacheNotice()
    }

    private(set) var preloadCacheStateTipsView: MailMigrationStateTipsView?
    private func makePreloadCacheStateTipsView() -> MailMigrationStateTipsView {
        let preloadCacheStateTipsView = MailMigrationStateTipsView(frame: .zero)
        preloadCacheStateTipsView.tag = MailPreloadCacheTag
        preloadCacheStateTipsView.isHidden = true
        return preloadCacheStateTipsView
    }
    private func setupPreloadCacheStateTipsViewIfNeeded() {
        guard preloadCacheStateTipsView == nil else { return }
        preloadCacheStateTipsView = makePreloadCacheStateTipsView()
    }

    // IMAP Migration Tips
    private(set) var imapMigrationTipsView: MailMigrationStateTipsView?
    private func makeIMAPMigraitonTipsView() -> MailMigrationStateTipsView {
        let tips = MailMigrationStateTipsView(frame: .zero)
        tips.isHidden = true
        return tips
    }
    private func setupIMAPMigraitonTipsViewIfNeeded() {
        guard imapMigrationTipsView == nil else { return }
        imapMigrationTipsView = makeIMAPMigraitonTipsView()
        imapMigrationTipsView?.delegate = self.delegate
    }

    private(set) var smartInboxPreviewCardView: MailSmartInboxPreviewCardView?
    private func makeSmartInboxPreviewCardView() -> MailSmartInboxPreviewCardView {
        let view = MailSmartInboxPreviewCardView()
        view.clipsToBounds = true
        view.isHidden = true
        view.delegate = self.delegate
        return view
    }
    private func setupSmartInboxPreviewCardViewIfNeeded() {
        guard smartInboxPreviewCardView == nil else { return }
        smartInboxPreviewCardView = makeSmartInboxPreviewCardView()
    }

    private(set) var filterTypeTips: MailFilterTypeTipsView?
    private func makeFilterTypeTips() -> MailFilterTypeTipsView {
        let view = MailFilterTypeTipsView()
        view.isHidden = true
        return view
    }
    private func setupFilterTypeTipsIfNeeded() {
        guard filterTypeTips == nil else { return }
        filterTypeTips = makeFilterTypeTips()
    }

    private(set) var strangerCardListView: MailStrangerCardListView?
    func setupStrangerCardListViewIfNeeded(_ viewModel: MailThreadListViewModel) {
        guard strangerCardListView == nil else {
            return
        }
        strangerCardListView = MailStrangerCardListView(frame: self.frame, viewModel: viewModel)
        strangerCardListView?.delegate = self.delegate
        strangerCardListView?.cellDelegate = self.delegate
        strangerCardListView?.isHidden = true
        strangerCardListView?.clipsToBounds = true
    }
    func upsetViewModel(_ viewModel: MailThreadListViewModel) -> (String?, Bool) {
        return strangerCardListView?.upsetViewModel(viewModel: viewModel, selectedThreadId: nil) ?? (nil, false)
    }

    override var intrinsicContentSize: CGSize {
        var height: CGFloat = CGFloat.leastNormalMagnitude
        height += previewCardCurrentTopMargin()
        if let smartInboxPreviewCardView = smartInboxPreviewCardView {
            height += smartInboxPreviewCardView.isHidden ? 0 : smartInboxPreviewCardView.intrinsicContentSize.height
        }
        if let strangerCardListView = strangerCardListView {
            height += strangerCardListView.isHidden ? 0 : strangerCardListView.intrinsicContentSize.height
        }
        return CGSize(width: bounds.width, height: height)
    }
}

extension MailThreadListHeaderView {
    
    func getPreviewCardView() -> MailSmartInboxPreviewCardView {
        setupSmartInboxPreviewCardViewIfNeeded()
        if let smartInboxPreviewCardView = smartInboxPreviewCardView {
            return smartInboxPreviewCardView
        } else {
            return makeSmartInboxPreviewCardView()
        }
    }
    
    func configTipIfNeeded() -> UIView? {
        var topPreviewTips = [clearTrashTipsView ,mailClientExpiredView, serviceSuspensionNotice,
                              preloadCacheStateTipsView, preloadCacheNotice, noNetView, mailClientPassLoginExpiredView,
                              bilingReminderNotice, migrationStateTipsView, imapMigrationTipsView, outOfOfficeView] /// 注意 需要按照优先级插入View
        if let showingIdx = topPreviewTips.firstIndex(where: { if let view = $0 { return !view.isHidden } else { return false} }),
           let showingTipView = topPreviewTips.remove(at: showingIdx) {
            topPreviewTips.forEach { if let view = $0 { view.removeFromSuperview() } }
            let height = showingTipView.intrinsicContentSize.height
            contentView.addSubview(showingTipView)
            showingTipView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(0)
                make.top.equalToSuperview()
                if !(showingTipView is UDNotice) {
                    make.height.equalTo(height)
                }
            }
            return showingTipView
        } else {
            return nil
        }
    }

    private func relayout() {
        let tipView = configTipIfNeeded()
        var currentLayoutView: UIView? = tipView

        if let filterTypeTips = filterTypeTips {
            if filterTypeTips.isHidden {
                filterTypeTips.removeFromSuperview()
            } else {
                contentView.addSubview(filterTypeTips)
                let height = filterTypeTips.intrinsicContentSize.height
                filterTypeTips.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalTo(0)
                    if let v = currentLayoutView {
                        make.top.equalTo(v.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.height.equalTo(height)
                }
                filterTypeTips.separator.isHidden = true
                currentLayoutView = filterTypeTips
            }
        }

        if let outboxTipsView = outboxTipsView {
            if outboxTipsView.isHidden {
                outboxTipsView.removeFromSuperview()
            } else {
                contentView.addSubview(outboxTipsView)
                outboxTipsView.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalTo(0)
                    if let v = currentLayoutView {
                        make.top.equalTo(v.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                }
                currentLayoutView = outboxTipsView
            }
        }

        if let smartInboxPreviewCardView = smartInboxPreviewCardView {
            if smartInboxPreviewCardView.isHidden {
                smartInboxPreviewCardView.removeFromSuperview()
            } else {
                contentView.addSubview(smartInboxPreviewCardView)
                smartInboxPreviewCardView.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalTo(0)
                    if let v = currentLayoutView {
                        make.top.equalTo(v.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.height.equalTo(smartInboxPreviewCardView.intrinsicContentSize.height)
                }
                if let filterTypeTips = filterTypeTips, currentLayoutView == filterTypeTips {
                    self.filterTypeTips?.separator.isHidden = false
                }
                currentLayoutView = smartInboxPreviewCardView
            }
        }


        if let strangerCardListView = strangerCardListView {
            if strangerCardListView.isHidden {
                strangerCardListView.removeFromSuperview()
            } else {
                contentView.addSubview(strangerCardListView)
                strangerCardListView.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalTo(0)
                    if let v = currentLayoutView {
                        make.top.equalTo(v.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.height.equalTo(strangerCardListView.intrinsicContentSize.height)
                }
                if let filterTypeTips = filterTypeTips, currentLayoutView == filterTypeTips {
                    self.filterTypeTips?.separator.isHidden = false
                }
                currentLayoutView = strangerCardListView
            }
        }

        var width: CGFloat = 0.0
        if intrinsicContentSize.width == 0 {
            if superview?.bounds.width == 0 {
                width = superViewWidth
            } else {
                width = superview?.bounds.width ?? superViewWidth
            }
        }
        self.frame = CGRect(x: 0, y: 0, width: width, height: intrinsicContentSize.height)
        layoutIfNeeded()
    }

    func showOutboxTips(_ count: Int) -> MailThreadListHeaderView {
        setupOutboxTipsViewIfNeeded()
        if let outboxTipsView = outboxTipsView, outboxTipsView.isHidden {
            self.outboxTipsView?.isHidden = false
            relayout()
            NewCoreEvent(event: .email_send_status_banner_view).post()
        }
        return self
    }

    func dismissOutboxTips() -> MailThreadListHeaderView {
        guard let outboxTipsView = outboxTipsView else { return self }
        if !outboxTipsView.isHidden {
            outboxTipsView.isHidden = true
            relayout()
        }
        return self
    }

    func showPreloadCacheNotice(_ preloadProgress: MailPreloadProgressPushChange) -> MailThreadListHeaderView {
        if preloadProgress.status == .running || preloadProgress.status == .preparing {
            setupPreloadCacheNoticeIfNeeded()
            if !(preloadCacheNotice?.isHidden ?? true) {
                preloadCacheNotice?.isHidden = true
            }
            return showPreloadCacheStateTips(progressPct: Int(preloadProgress.progress), stateInfo: preloadProgress.status.title(preloadProgress.progress))
        } else {
            setupPreloadCacheNoticeIfNeeded()
            _ = dismissPreloadCacheStateTips()
            preloadCacheNotice?.preloadProgress = preloadProgress
            if preloadCacheNotice?.isHidden ?? true {
                preloadCacheNotice?.isHidden = false
                relayout()
            }
            return self
        }
    }

    func dismissPreloadCacheNotice() -> MailThreadListHeaderView {
        if !(preloadCacheNotice?.isHidden ?? true) {
            preloadCacheNotice?.isHidden = true
            relayout()
        }
        return self
    }

    func showPreloadCacheStateTips(progressPct: Int, stateInfo: String) -> MailThreadListHeaderView {
        setupPreloadCacheStateTipsViewIfNeeded()
        preloadCacheStateTipsView?.config(state: .inProgress, progressPct: progressPct, stateInfo: stateInfo)
        if preloadCacheStateTipsView?.isHidden ?? true {
            preloadCacheStateTipsView?.isHidden = false
            relayout()
        }
        return self
    }

    func dismissPreloadCacheStateTips() -> MailThreadListHeaderView {
        if !(preloadCacheStateTipsView?.isHidden ?? true) {
            preloadCacheStateTipsView?.isHidden = true
            relayout()
        }
        return self
    }

    func dismissPreloadCacheTask() -> MailThreadListHeaderView {
        var needLayout = false
        if let preloadCacheStateTipsView = preloadCacheStateTipsView, !preloadCacheStateTipsView.isHidden {
            self.preloadCacheStateTipsView?.isHidden = true
            needLayout = true
        }
        if let preloadCacheNotice = preloadCacheNotice, !preloadCacheNotice.isHidden {
            self.preloadCacheNotice?.isHidden = true
            needLayout = true
        }
        if needLayout {
            relayout()
        }
        return self
    }

    func shouldUpdateSmartInboxPreviewCard(labelID: String, fromNames: [String]) -> Bool {
        if !(smartInboxPreviewCardView?.isHidden ?? false) { return true }
        return (smartInboxPreviewCardView?.config(labelID) ?? false) && (smartInboxPreviewCardView?.configFromInfos(fromNames) ?? false)
    }

    func showSmartInboxPreviewCard(labelID: String, fromNames: [String]) -> MailThreadListHeaderView {
        setupSmartInboxPreviewCardViewIfNeeded()
        smartInboxPreviewCardView?.config(labelID)
        smartInboxPreviewCardView?.configFromInfos(fromNames)
        if smartInboxPreviewCardView?.isHidden ?? true {
            smartInboxPreviewCardView?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissSmartInboxPreviewCard() -> MailThreadListHeaderView {
        if !(smartInboxPreviewCardView?.isHidden ?? true) {
            smartInboxPreviewCardView?.isHidden = true
            relayout()
        }
        return self
    }

    func showStrangerCardListView(_ viewModel: MailThreadListViewModel) -> MailThreadListHeaderView {
        setupStrangerCardListViewIfNeeded(viewModel)
        if let strangerCardListView = strangerCardListView, strangerCardListView.isHidden, !viewModel.mailThreads.all.isEmpty {
            self.strangerCardListView?.isHidden = false
            self.strangerCardListView?.collectionView.btd_scrollToLeft()
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissStrangerCardListView() -> MailThreadListHeaderView {
        strangerCardListView?.selectedIndex = nil
        strangerCardListView?.selectedThreadID = nil
        if let strangerCardListView = strangerCardListView, !strangerCardListView.isHidden {
            self.strangerCardListView?.isHidden = true
            relayout()
        }
        return self
    }

    func updatePreviewCard(labelID: String) {
        smartInboxPreviewCardView?.config(labelID)
    }

    func previewCardisHidden() -> Bool {
        return smartInboxPreviewCardView?.isHidden ?? true
    }

    func alertOfMigrationTips(at stage: MailMigrationStateTipsView.MigrationStage,
                              onClickOK: (() -> Void)? ) -> LarkAlertController? {
        return MailMigrationStateTipsView.alertOfMigrationState(stage, onClickOK: onClickOK)
    }
    
    // MARK: imap migration
    func showIMAPMigrationTips(stage: MailMigrationStateTipsView.MigrationStage, progressPct: Int, config: MailMigrationStateTipsView.MigrationTipsConfig) -> MailThreadListHeaderView {
        setupIMAPMigraitonTipsViewIfNeeded()
            imapMigrationTipsView?.newConfig(state: stage, progressPct: progressPct, config: config)
        if imapMigrationTipsView?.isHidden ?? true {
            imapMigrationTipsView?.isHidden = false
            relayout()
        }
        return self
    }
        
    func dismissIMAPMigrationTips() -> MailThreadListHeaderView {
        if !(imapMigrationTipsView?.isHidden ?? true) {
            imapMigrationTipsView?.isHidden = true
            relayout()
        }
        return self
    }
}

// MARK: action interface
extension MailThreadListHeaderView {
    func previewCardCurrentTopMargin() -> CGFloat {
        var height: CGFloat = 0
        //print("[client_debug] 111 height: \(height) frame Height: \(frame.size.height) superViewWidth: \(superViewWidth) mailClientExpiredView isHidden: \(mailClientExpiredView.isHidden) noNetView.isHidden: \(noNetView.isHidden) outOfOfficeView.isHidden: \(outOfOfficeView.isHidden)")
        setNeedsLayout()
        layoutIfNeeded()
        if !(clearTrashTipsView?.isHidden ?? true) {
            height += clearTrashTipsView?.sizeThatFits(CGSize(width: superViewWidth, height: CGFloat.greatestFiniteMagnitude)).height ?? 0
        } else if !(mailClientExpiredView?.isHidden ?? true) {
            height += mailClientExpiredView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(serviceSuspensionNotice?.isHidden ?? true) {
            height += serviceSuspensionNotice?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(preloadCacheStateTipsView?.isHidden ?? true) {
            height += preloadCacheStateTipsView?.intrinsicContentSize.height ?? 0
        } else if !(preloadCacheNotice?.isHidden ?? true) {
            height += preloadCacheNotice?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(noNetView?.isHidden ?? true) {
            height += noNetView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(mailClientPassLoginExpiredView?.isHidden ?? true) {
            height += mailClientPassLoginExpiredView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(bilingReminderNotice?.isHidden ?? true) {
            height += bilingReminderNotice?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(migrationStateTipsView?.isHidden ?? true) {
            height += migrationStateTipsView?.intrinsicContentSize.height ?? 0
        } else if !(outOfOfficeView?.isHidden ?? true) {
            height += outOfOfficeView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(imapMigrationTipsView?.isHidden ?? true) {
            height += imapMigrationTipsView?.intrinsicContentSize.height ?? 0
        }
        height += (outboxTipsView?.isHidden ?? true) ? 0 : outboxTipsView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        height += (filterTypeTips?.isHidden ?? true) ? 0 : filterTypeTips?.intrinsicContentSize.height ?? 0
//        print("[client_debug] 222 height: \(height) frame Height: \(frame.size.height) superViewWidth: \(superViewWidth) mailClientExpiredView isHidden: \(mailClientExpiredView?.isHidden ?? true) noNetView.isHidden: \(noNetView?.isHidden ?? true)")
        return height
    }

    func showMailSyncTips(state: MailMigrationStateTipsView.MigrationStage, progressPct: Int) -> MailThreadListHeaderView {

        if state == .invalid {
            return dismissMailSyncTips()
        }
        setupMigrationStateTipsViewIfNeeded()
        migrationStateTipsView?.config(state: state, progressPct: progressPct)
        if migrationStateTipsView?.isHidden ?? true {
            migrationStateTipsView?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissMailSyncTips() -> MailThreadListHeaderView {
        if !(migrationStateTipsView?.isHidden ?? true) {
            migrationStateTipsView?.isHidden = true
            relayout()
        }
        return self
    }

    @discardableResult
    func showBilingReminderNotice(_ limit: Int) -> MailThreadListHeaderView {
        setupBilingReminderNoticeIfNeeded()
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Billing_ExceedNumberPleaseUpgrade(limit),
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        var warningConfig = UDNoticeUIConfig(type: .warning,
                                             attributedText: text)
        warningConfig.leadingButtonText = BundleI18n.MailSDK.Mail_Billing_ContactServiceConsultant
        warningConfig.trailingButtonIcon = UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate)
        bilingReminderNotice?.trailingButton?.tintColor = UIColor.ud.iconN2
        bilingReminderNotice?.updateConfigAndRefreshUI(warningConfig)
        var needRelayout = false
        if !(serviceSuspensionNotice?.isHidden ?? true) { // 这里两个框分优先级，但需要支持回退
            serviceSuspensionNotice?.isHidden = true
            needRelayout = true
        }
        if bilingReminderNotice?.isHidden ?? true {
            bilingReminderNotice?.isHidden = false
            relayout()
        } else if needRelayout {
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissBilingReminderNotice() -> MailThreadListHeaderView {
        if !(bilingReminderNotice?.isHidden ?? true) {
            bilingReminderNotice?.isHidden = true
            relayout()
        }
        return self
    }

    @discardableResult
    func showServiceSuspensionNotice(_ isAdmin: Bool) -> MailThreadListHeaderView {
        setupServiceSuspensionNoticeIfNeeded()
        var tips = ""
        if isAdmin {
            tips = BundleI18n.MailSDK.Mail_Billing_FullUpgradePlan
        } else {
            tips = BundleI18n.MailSDK.Mail_Billing_StorageFullServiceSuspendContactAdmin
        }
        let attributedText = NSAttributedString(string: tips,
                                                attributes: [.foregroundColor: UIColor.ud.textTitle])
        var errorConfig = UDNoticeUIConfig(type: .error,
                                           attributedText: attributedText)
        if isAdmin {
            errorConfig.leadingButtonText = BundleI18n.MailSDK.Mail_Billing_ContactServiceConsultant
        }
        serviceSuspensionNotice?.updateConfigAndRefreshUI(errorConfig)
        if serviceSuspensionNotice?.isHidden ?? true {
            serviceSuspensionNotice?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissServiceSuspensionNotice() -> MailThreadListHeaderView {
        if !(serviceSuspensionNotice?.isHidden ?? true) {
            serviceSuspensionNotice?.isHidden = true
            relayout()
        }
        return self
    }

    @discardableResult
    func showMailClientExpiredTips() -> MailThreadListHeaderView {
        setupMailClientExpiredViewIfNeeded()
        if mailClientExpiredView?.isHidden ?? true {
            mailClientExpiredView?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismisssMailClientExpiredTips() -> MailThreadListHeaderView {
        if !(mailClientExpiredView?.isHidden ?? true) {
            mailClientExpiredView?.isHidden = true
            relayout()
        }
        return self
    }

    @discardableResult
    func showNoNetTips() -> MailThreadListHeaderView {
        setupNoNetViewIfNeeded()
        if (noNetView?.isHidden ?? true) {
            noNetView?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissNoNetTips() -> MailThreadListHeaderView {
        if !(noNetView?.isHidden ?? true) {
            noNetView?.isHidden = true
            relayout()
        }
        return self
    }
    
    @discardableResult
    func showMailClientPassLoginExpiredTips() -> MailThreadListHeaderView {
        setupMailClientPassLoginExpiredViewIfNeeded()
        if mailClientPassLoginExpiredView?.isHidden ?? true {
            mailClientPassLoginExpiredView?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismisssMailClientPassLoginExpiredTips() -> MailThreadListHeaderView {
        if !(mailClientPassLoginExpiredView?.isHidden ?? true) {
            mailClientPassLoginExpiredView?.isHidden = true
            relayout()
        }
        return self
    }

    @discardableResult
    func showOOOTips() -> MailThreadListHeaderView {
        setupOutOfOfficeViewIfNeeded()
        if outOfOfficeView?.isHidden ?? true {
            outOfOfficeView?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissOOOTips() -> MailThreadListHeaderView {
        if !(outOfOfficeView?.isHidden ?? true) {
            outOfOfficeView?.isHidden = true
            relayout()
        }
        return self
    }

    @discardableResult
    func showFilterTips() -> MailThreadListHeaderView {
        setupFilterTypeTipsIfNeeded()
        if filterTypeTips?.isHidden ?? true {
            filterTypeTips?.isHidden = false
            relayout()
        }
        return self
    }

    @discardableResult
    func dismissFilterTips() -> MailThreadListHeaderView {
        if !(filterTypeTips?.isHidden ?? true) {
            filterTypeTips?.isHidden = true
            relayout()
        }
        return self
    }
    
    @discardableResult
    func showClearTrashTipsView(label: String, showBtn: Bool = false) -> MailThreadListHeaderView {
        setupClearTrashTipsViewIfNeeded()
        // 避免重复刷新
        if !(clearTrashTipsView?.isHidden ?? true) {
            if !showBtn && clearTrashTipsView?.config.leadingButtonText == nil {
                return self
            } else if showBtn && clearTrashTipsView?.config.leadingButtonText != nil {
                return self
            }
        }
        var attrStr = NSMutableAttributedString(string: BundleI18n.MailSDK.Mail_MessagesInTrashOverNumDaysAutoDelete_Text(MailClearThreadDays),
                                                attributes: [.foregroundColor: UIColor.ud.textTitle])
        if label == Mail_LabelId_Spam {
            attrStr = NSMutableAttributedString(string: BundleI18n.MailSDK.Mail_MessagesInSpamOverNumDaysAutoDelete_Text(MailClearThreadDays),
                                                attributes: [.foregroundColor: UIColor.ud.textTitle])
        }
        var config = UDNoticeUIConfig(type: .info,
                                      attributedText: attrStr)
        if showBtn {
            config.leadingButtonText = BundleI18n.MailSDK.Mail_MessagesInSpamTrashAutoDelte_DeleteAll_Button
        }
        clearTrashTipsView?.updateConfigAndRefreshUI(config)
        if clearTrashTipsView?.isHidden ?? true {
            clearTrashTipsView?.isHidden = false
        }
        relayout()
        return self
    }
    
    @discardableResult
    func dismissClearTrashTipsView() -> MailThreadListHeaderView {
        if !(clearTrashTipsView?.isHidden ?? true) {
            clearTrashTipsView?.isHidden = true
            relayout()
        }
        return self
    }
}

extension UDNotice {
    /// UDNotice sizeThatFits 多行文案时高度有问题，如果 UDNotice frame height 比较大，优先返回实际高度
    func heightThatFitsOrActualHeight(containerWidth: CGFloat) -> CGFloat {
        let height = sizeThatFits(CGSize(width: containerWidth, height: .greatestFiniteMagnitude)).height
        let actualHeight = frame.height
        return max(height, actualHeight)
    }
}
