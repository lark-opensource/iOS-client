//
//  PageCell.swift
//  MailPager
//
//  Created by majx on 2020/3/5.
//

import UIKit
import WebKit
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LKCommonsLogging
import LarkLocalizations
import LarkAlertController
import Homeric
import LarkAppLinkSDK
import LarkFoundation
import Reachability
import LarkWebViewContainer
import UniverseDesignButton
import UniverseDesignColor

protocol MailMessageListCellDelegate: AnyObject {
    func onClickMessageListRetry(threadId: String)
    func startLoadHtml(threadId: String)
    func titleLabelsTapped()
    func flagTapped()
    func notSpamTapped()
    func bannerTermsAction()
    func bannerSupportAction()
    func didClickStrangerReply(status: Bool)
    func avatarClickHandler(mailAddress: MailAddress)
}

class MailMessageLoadFailView: UIView {
    private let errorIcon = UIImageView()
    private let label = UILabel()
    private var labelBottomConstraint: Constraint?
    private var retryButtonBottomConstraint: Constraint?
    private lazy var retryButton: UDButton = {
        var config = UDButtonUIConifg.secondaryGray
        config.type = .middle
        var button = UDButton(config)
        button.setTitle(BundleI18n.MailSDK.Mail_InternetCutOff_Reload_Button, for: .normal)
        button.isUserInteractionEnabled = false
        button.isHidden = true
        return button
    }()

    init() {
        super.init(frame: .zero)

        // layout
        let container = UIView()
        backgroundColor = UDColor.readMsgListBG
        errorIcon.image = Resources.feed_error_icon
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.MailSDK.Mail_Common_NetworkError
        label.textAlignment = .center
        label.numberOfLines = 0

        addSubview(container)
        [errorIcon, label, retryButton].forEach { container.addSubview($0) }
        container.snp.makeConstraints { make in
            let centerYoffset = -(Display.realNavBarHeight() + Display.bottomSafeAreaHeight) / 2
            make.centerY.equalToSuperview().offset(centerYoffset)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
        }
        errorIcon.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.width.equalTo(100)
        }
        label.snp.makeConstraints { (make) in
            make.top.equalTo(errorIcon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.greaterThanOrEqualTo(22)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            self.labelBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        retryButton.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(16)
            self.retryButtonBottomConstraint = make.bottom.equalToSuperview().constraint
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }
        updateError(type: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateError(type: LoadFailType?) {
        let type = type ?? .normal
        switch type {
        case .botLabelError:
            retryButton.isHidden = true
            errorIcon.image = Resources.mail_load_fail_icon
            label.text = BundleI18n.MailSDK.Mail_ReadMailBot_UnableToView_Empty
        case .botLabelNetworkError:
            retryButton.isHidden = true
            errorIcon.image = Resources.feed_error_icon
            label.text = BundleI18n.MailSDK.Mail_ReadMailBot_UnableToViewUnstableNetwork_Empty
        case .noPermission:
            retryButton.isHidden = true
            errorIcon.image = Resources.mail_no_access
            label.text = BundleI18n.MailSDK.Mail_KeyContact_EmailNotInUseCantView_EmptyState
        case .normal:
            retryButton.isHidden = true
            errorIcon.image = Resources.feed_error_icon
            label.text = BundleI18n.MailSDK.Mail_Common_NetworkError
        case .offline:
            retryButton.isHidden = false
            errorIcon.image = Resources.feed_error_icon
            label.text = BundleI18n.MailSDK.Mail_InternetCutOff_ConnectAndReload_Empty
        case .strangerError:
            retryButton.isHidden = true
            errorIcon.image = Resources.feed_error_icon
            label.text = BundleI18n.MailSDK.Mail_StrangerMail_EmailMovedGoBackAndRefresh_ErrorText
        case .feedEmpty:
            retryButton.isHidden = true
            errorIcon.image = Resources.mail_feed_im
            label.text = BundleI18n.MailSDK.Mail_KeyContact_ChatPage_EmptyState
        }
        if retryButton.isHidden {
            labelBottomConstraint?.activate()
            retryButtonBottomConstraint?.deactivate()
        } else {
            labelBottomConstraint?.deactivate()
            retryButtonBottomConstraint?.activate()
        }
        layoutIfNeeded()
    }
}

class MailMessageListPageCell: UICollectionViewCell {
    weak var viewModel: MailMessageListPageViewModel?
    weak var delegate: MailMessageListCellDelegate?
    weak var webDelegate: WKNavigationDelegate?
    weak var controller: MailMessageListController?
    private var isHtmlLoaded: Bool {
        get {
            return mailMessageListView?.isHtmlLoaded == true
        }
        set {
            mailMessageListView?.isHtmlLoaded = newValue
        }
    }
    /// if webview call domReady already
    var isDomReady: Bool {
        get {
            return mailMessageListView?.isDomReady == true
        }
        set {
            mailMessageListView?.onDomReady(newValue)
        }
    }

    weak var mailMessageListView: MailMessageListView?

    private lazy var loadFailView: MailMessageLoadFailView = {
        let view = MailMessageLoadFailView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickRetry))
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        view.isHidden = true
        return view
    }()

    #if DEBUG
    var delayingHtmlLoad = true
    #endif

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.readMsgListBG
        self.contentView.addSubview(loadFailView)
        self.loadFailView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mailMessageListView?.prepareForReuse()
        mailMessageListView?.removeFromSuperview()
        mailMessageListView = nil
    }

    private func hide(view: UIView) {
        view.isHidden = true
        view.alpha = 0.0
    }

    func showLoading(_ show: Bool, delay: TimeInterval = 1) {
        if show {
            showLoadFail(false)
        }
        mailMessageListView?.showLoading(show, delay: delay)
    }

    func showLoadFail(_ show: Bool) {
        // 更新错误页样式
        loadFailView.updateError(type: viewModel?.loadErrorType)
        if !show {
            hide(view: loadFailView)
        } else {
            if loadFailView.isHidden == true {
                // 埋点相关
                InteractiveErrorRecorder.recordError(event: .messagelist_error_page, tipsType: .error_page)
            }
            loadFailView.isHidden = false
            loadFailView.alpha = 1.0
            mailMessageListView?.showLoading(false)
        }
    }

    func updateBottomActionItems(_ mailActionItems: [MailActionItem]) {
        if self.viewModel?.labelId == Mail_LabelId_Stranger {
            mailMessageListView?.updateStrangerActionItems(mailActionItems, mailItem: viewModel?.mailItem)
        } else {
            mailMessageListView?.updateBottomActionItems(mailActionItems)
        }
    }

    func render(
        by viewModel: MailMessageListPageViewModel?,
        baseURL: URL?,
        provider: MailSharedServicesProvider,
        mailActionItemsBlock: @escaping (() -> [MailActionItem])
    ) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            if let viewModel = viewModel {
                if self.mailMessageListView == nil || self.mailMessageListView?.superview !== self.contentView {
                    let isFeed = !viewModel.feedCardId.isEmpty
                    self.mailMessageListView = MailMessageListViewsPool.getViewFor(threadId: viewModel.threadId, isFullReadMessage: viewModel.isFullReadMessage, controller: self.controller, provider: provider, isFeed: isFeed)
                }
                guard let mailMessageListView = self.mailMessageListView else {
                    return
                }
                if mailMessageListView.superview !== self.contentView {
                    mailMessageListView.removeFromSuperview()
                    self.contentView.insertSubview(mailMessageListView, at: 0)
                    mailMessageListView.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }
                }
                self.viewModel = viewModel
                #if DEBUG
                let kvStore = MailKVStore(space: .global, mSpace: .global)
                if kvStore.bool(forKey: MailDebugViewController.kMailDelayLoadTemplate) == true && self.delayingHtmlLoad {
                    return
                }
                #endif

                mailMessageListView.render(by: viewModel,
                                           webDelegate: self.webDelegate,
                                           controller: self.controller,
                                           superContainer: self,
                                           mailActionItemsBlock: mailActionItemsBlock,
                                           baseURL: baseURL,
                                           delegate: self)
                if viewModel.bodyHtml != nil {
                    self.showLoading(!self.isDomReady)
                } else if viewModel.loadErrorType != nil {
                    self.showLoadFail(true)
                } else {
                    self.showLoading(viewModel.showLoading || (!self.isHtmlLoaded && !self.isDomReady))
                }
            } else {
                self.mailMessageListView?.identifier = nil
                self.showLoading(true)
            }
        }
    }

    func webViewLoadComplete() {
        if viewModel?.bodyHtml != nil {
            isHtmlLoaded = true
        }
    }

    func webViewDidLoadFinish() -> Bool {
        return isHtmlLoaded
    }

    @objc
    func onClickRetry() {
        // Bot 读信错误页禁用重试功能 && feed读信空页面禁用重试功能
        guard viewModel?.loadErrorType != .botLabelError && viewModel?.loadErrorType != .botLabelNetworkError else { return }
        if viewModel?.loadErrorType == .feedEmpty && controller?.isFeedCard == true {
            return
        }
        if let threadId = viewModel?.threadId {
            if let reach = Reachability(), reach.connection == .none && FeatureManager.open(FeatureKey(fgKey: .offlineSearch, openInMailClient: true)) {
                showLoading(true, delay: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.large, execute: { [weak self] in
                    guard let `self` = self else { return }
                    self.showLoading(false)
                    self.delegate?.onClickMessageListRetry(threadId: threadId)
                })
            } else {
                delegate?.onClickMessageListRetry(threadId: threadId)
            }
        }
    }
}

extension MailMessageListPageCell: MailMessageListViewDelegate {
    func webViewOnDomReady() {
        if viewModel?.bodyHtml != nil {
            self.showLoading(false)
            self.showLoadFail(false)
        }
    }

    func titleLabelsTapped() {
        delegate?.titleLabelsTapped()
    }

    func flagTapped() {
        delegate?.flagTapped()
    }

    func notSpamTapped() {
        delegate?.notSpamTapped()
    }

    func bannerTermsAction() {
        delegate?.bannerTermsAction()
    }

    func bannerSupportAction() {
        delegate?.bannerSupportAction()
    }

    func didClickStrangerReply(status: Bool) {
        delegate?.didClickStrangerReply(status: status)
    }

    func avatarClickHandler(mailAddress: MailAddress) {
        delegate?.avatarClickHandler(mailAddress: mailAddress)
    }
}
