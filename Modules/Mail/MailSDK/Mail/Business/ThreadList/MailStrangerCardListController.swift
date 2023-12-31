//
//  MailStrangerCardListController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/6/28.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkAlertController
import RxSwift
import RustPB
import LarkSplitViewController
import EENavigator
import LarkUIKit

protocol MailStrangerCardListControllerDelegate: AnyObject {
    func strangerCardSelectAllHandler(status: Bool)
    func strangerCardListItemReplyHandler(threadIDs: [String]?, status: Bool, maxTimestamp: Int64?, fromList: [String]?)
}

class MailStrangerCardListController: MailBaseViewController, MailStrangerCardListDelegate, MailMessageListExternalDelegate {

    enum StrangerCardListStatus {
        case none
        case empty
        case canRetry
    }
    weak var delegate: MailStrangerCardListControllerDelegate?
    let accountContext: MailAccountContext
    private lazy var viewModel = MailThreadListViewModel(labelID: Mail_LabelId_Stranger, userID: accountContext.user.userID)
    private let label: MailClientLabel?
    var pageSize: CGSize {
        didSet {
            listView.frame = CGRect(origin: .zero, size: pageSize)
            listView.setNeedsLayout()
            listView.layoutIfNeeded()
            listView.collectionView.reloadData()
        }
    }
    private lazy var listView = MailStrangerCardListView(frame: CGRect(origin: .zero, size: pageSize),
                                                         viewModel: self.viewModel,
                                                         listDirection: CardListDirection.vert)
    var markSelectedThreadId: String?
    var oldMarkSelectedThreadId: String?
    var currentLabelID: String?
    var status: StrangerCardListStatus = .none
    let titleLabel = UILabel()
    let subTitleLabel = UILabel()
    let allowBtn = UIButton(type: .custom)
    let rejectBtn = UIButton(type: .custom)
    var batchConfirmAlert: LarkAlertController? = nil
    private let disposeBag = DisposeBag()

    var defaultPage = UIView()
    private lazy var defaultPageTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    private lazy var defaultPageIcon: UIImageView = {
        let imageview = UIImageView()
        imageview.image = Resources.feed_empty_data_icon
        return imageview
    }()
    private var canRetry: Bool = false
    var didAppearHandler: (() -> Void)?
    var clearSelectedHandler: (() -> Void)?

    init(accountContext: MailAccountContext, pageSize: CGSize) {
        self.accountContext = accountContext
        self.label = MailTagDataManager.shared.getFolderModel([Mail_LabelId_Stranger])
        self.pageSize = pageSize
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        showLoading()
        bindVMState()
        viewModel.getMailListFromLocal()
        listView.selectedThreadIDObservable
            .asDriver()
            .drive { [weak self] (refreshThreadID) in
                MailLogger.info("[mail_stranger] cardlist markSelectedThreadId change: \(refreshThreadID ?? "") ")
                guard let threadID = refreshThreadID, !threadID.isEmpty else {
                    return
                }
                self?.markSelectedThreadId = refreshThreadID
            }.disposed(by: disposeBag)
        MailTracker.log(event: "email_stranger_list_view", params: ["label_item": currentLabelID ?? ""])

        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    if let strangerLabel = change.labels.first(where: { $0.id == Mail_LabelId_Stranger }) {
                        self?.subTitleLabel.text = strangerLabel.getStrangerListSubtitleText()
                    }
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }

    func bindVMState() {
        PushDispatcher.shared.mailChange.filter { push in
            if case .cacheInvalidChange(_) = push {
                return true
            }
            return false
        }.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .cacheInvalidChange(let change) = push {
                    self?.cacheInvalidChange(change)
                }
            }).disposed(by: disposeBag)

        viewModel.dataState
            .observeOn(MainScheduler.instance)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                self.defaultPage.isHidden = true
                self.canRetry = false
                self.listView.isHidden = false
                self.allowBtn.isEnabled = true
                self.rejectBtn.isEnabled = true
                switch state {
                case .refreshed(data: let datas, resetLoadMore: _):
                    MailLogger.info("[mail_stranger] cardlist listViewController dataState refreshed datas: \(datas.count)")
                    self.status = .none
                    if datas.isEmpty {
                        self.updateViewModel(selectedThreadId: nil, viewModel: self.viewModel)
                        self.handleStrangerCardListEmpty()
                        self.listView.stopLoadMore()
                    } else {
                        let oldSelectedThreadID = self.oldMarkSelectedThreadId
                        self.updateViewModel(selectedThreadId: nil, viewModel: self.viewModel)
                        let refreshThreadInfo = self.listView.upsetViewModel(viewModel: self.viewModel, selectedThreadId: self.markSelectedThreadId)
                        MailLogger.info("[mail_stranger] cardlist listViewController refreshThreadInfo: \(refreshThreadInfo) oldSelectedThreadID: \(oldSelectedThreadID)")
                        if self.rootSizeClassIsRegular && refreshThreadInfo.1 && refreshThreadInfo.0 != oldSelectedThreadID {
                            self.oldMarkSelectedThreadId = refreshThreadInfo.0
                            self.enterThread(with: refreshThreadInfo.0, forceRefresh: refreshThreadInfo.1)
                        }
                        if datas.count < StrangerCardConst.cacheCardCount && !self.viewModel.isLoading && !self.viewModel.isLastPage {
                            MailLogger.info("[mail_stranger] cardlist listViewController loadmore auto, datas.count: \(datas.count)")
                            self.viewModel.getMailListFromLocal()
                        }
                    }
                case .loadMore(data: let datas):
                    MailLogger.info("[mail_stranger] cardlist listViewController dataState loadMore datas: \(datas.count)")
                    self.status = .none
                    if !datas.isEmpty {
                        let oldSelectedThreadID = self.oldMarkSelectedThreadId
                        let refreshThreadInfo = self.listView.upsetViewModel(viewModel: self.viewModel, selectedThreadId: self.markSelectedThreadId)
                        if self.rootSizeClassIsRegular && refreshThreadInfo.1 && refreshThreadInfo.0 != oldSelectedThreadID {
                            self.oldMarkSelectedThreadId = refreshThreadInfo.0
                            self.enterThread(with: refreshThreadInfo.0, forceRefresh: refreshThreadInfo.1)
                        }
                    } else {
                        self.listView.stopLoadMore()
                    }
                case .pageEmpty:
                    self.status = .empty
                    MailLogger.info("[mail_stranger] cardlist listViewController dataState pageEmpty")
                    self.showLoading()
                case .failed(labelID: let _, err: let error):
                    MailLogger.error("[mail_stranger] cardlist listViewController dataState fail error: \(error)")
                    if self.viewModel.mailThreads.all.isEmpty {
                        self.status = .canRetry
                        self.handleDatasError()
                    } else {
                        self.listView.stopLoadMore()
                    }
                }
                self.hideLoading()
            }).disposed(by: disposeBag)
    }

    func cacheInvalidChange(_ change: MailCacheInvalidChange) {
        MailLogger.info("[mail_stranger] cardlist receive cacheInvalid")
        clearSelectedHandler?()
        listView.clearSelectedStatus()
        viewModel.cleanMailThreadCache()
        viewModel.getMailListFromLocal()
    }

    func clearSelectedStatus() {
        markSelectedThreadId = nil
        listView.clearSelectedStatus()
    }

    func handleDatasError() {
        listView.isHidden = true
        canRetry = true
        defaultPage.isHidden = false
        defaultPageIcon.image = Resources.feed_error_icon
        defaultPageTitleLabel.text = BundleI18n.MailSDK.Mail_Common_NetworkError
        allowBtn.isEnabled = false
        rejectBtn.isEnabled = false
    }

    func handleStrangerCardListEmpty() {
        listView.isHidden = true
        defaultPage.isHidden = false
        defaultPageIcon.image = Resources.feed_empty_data_icon
        defaultPageTitleLabel.text = BundleI18n.MailSDK.Mail_List_Empty(BundleI18n.MailSDK.Mail_Stranger_Folder_Title)
        allowBtn.isEnabled = false
        rejectBtn.isEnabled = false
        markSelectedThreadId = nil
        clearSelectedHandler?()
        backToMailHome()
    }

    func enterThread(with threadId: String?, forceRefresh: Bool = false) {
        if let threadID = threadId, let index = viewModel.mailThreads.all.firstIndex(where: { $0.threadID == threadID }) {
            cardItemHandler(index: index, threadID: threadID)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavElementHidden(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavElementHidden(false)
        didAppearHandler?()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupNavElementHidden(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setupNavElementHidden(true)
    }

    deinit {
        titleLabel.removeFromSuperview()
        subTitleLabel.removeFromSuperview()
        allowBtn.removeFromSuperview()
        rejectBtn.removeFromSuperview()
    }

    func setupNavElementHidden(_ isHidden: Bool) {
        titleLabel.isHidden = isHidden
        subTitleLabel.isHidden = isHidden
        allowBtn.isHidden = isHidden
        rejectBtn.isHidden = isHidden
    }

    func setupNavViews() {
        guard let navigationVC = navigationController else { return }
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.MailSDK.Mail_StrangerMail_Stranger_Title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textAlignment = .center
        navigationVC.navigationBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.centerY.equalToSuperview().offset(-10)
        }

        subTitleLabel.textColor = UIColor.ud.textCaption
        if let strangerLabel = self.label {
            subTitleLabel.text = strangerLabel.getStrangerListSubtitleText()
        }
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.textAlignment = .center
        navigationVC.navigationBar.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(10)
            make.height.equalTo(14)
            make.top.equalTo(titleLabel.snp.bottom)
        }

        allowBtn.addTarget(self, action: #selector(allowBtnHandler), for: .touchUpInside)
        allowBtn.setImage(UDIcon.yesOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        allowBtn.tintColor = .ud.functionSuccess500
        allowBtn.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        rejectBtn.addTarget(self, action: #selector(rejectBtnHandler), for: .touchUpInside)
        rejectBtn.setImage(UDIcon.noOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        rejectBtn.tintColor = .ud.functionDanger500

        navigationVC.navigationBar.addSubview(allowBtn)
        navigationVC.navigationBar.addSubview(rejectBtn)
        rejectBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        allowBtn.snp.makeConstraints { make in
            make.right.equalTo(rejectBtn.snp.left)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
    }

    func setupViews() {
        updateNavAppearanceIfNeeded()
        view.backgroundColor = UIColor.ud.bgBody
        setupNavViews()
        listView.selectedThreadID = markSelectedThreadId
        oldMarkSelectedThreadId = markSelectedThreadId
        if let index = viewModel.mailThreads.all.firstIndex(where: { $0.threadID == markSelectedThreadId }) {
            listView.selectedIndex = IndexPath(row: index, section: 0)
        }
        listView.delegate = self
        listView.cellDelegate = self
        view.addSubview(listView)

        defaultPage.isHidden = true
        defaultPage.backgroundColor = UIColor.ud.bgBody
        defaultPage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(retryFetchList)))
        view.addSubview(defaultPage)
        defaultPage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        defaultPage.addSubview(defaultPageTitleLabel)
        defaultPage.addSubview(defaultPageIcon)
        defaultPageIcon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.width.height.equalTo(100)
        }
        defaultPageTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(defaultPageIcon.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.centerX.equalToSuperview()
        }
    }

    @objc func retryFetchList() {
        guard status == .canRetry else { return }
        showLoading()
        viewModel.getMailListFromLocal()
    }

    func updateViewModel(selectedThreadId: String? , viewModel: MailThreadListViewModel) {
        _ = listView.upsetViewModel(viewModel: viewModel, selectedThreadId: selectedThreadId)
        if Display.pad {
            markSelectedThreadId = selectedThreadId ?? markSelectedThreadId
            listView.selectedThreadID = markSelectedThreadId
        }
    }

    func updateSelectedStatus(selectedThreadId: String?) {
        if Display.pad {
            markSelectedThreadId = selectedThreadId ?? markSelectedThreadId
            listView.selectedThreadID = markSelectedThreadId
        }
    }

    @objc func allowBtnHandler() {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_StrangerMail_AllowAllConfirmation_Title)
        alert.setContent(text: BundleI18n.MailSDK.Mail_StrangerMail_AllowAllConfirmation_Desc, alignment: .center)
        alert.addCancelButton()
        alert.addButton(text: BundleI18n.MailSDK.Mail_StrangerMail_AllowAllConfirmation_AllowAll, color: .ud.primaryPri500, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.strangerCardSelectAllHandler(status: true)
        })
        batchConfirmAlert = alert
        accountContext.navigator.present(alert, from: self)
    }

    @objc func rejectBtnHandler() {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_StrangerMail_RejectAllConfirmation_Title)
        alert.setContent(text: BundleI18n.MailSDK.Mail_StrangerMail_RejectAllConfirmation_Desc, alignment: .center)
        alert.addCancelButton()
        alert.addButton(text: BundleI18n.MailSDK.Mail_StrangerMail_RejectAllConfirmation_RejectAll, color: .ud.primaryPri500, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.strangerCardSelectAllHandler(status: false)
        })
        batchConfirmAlert = alert
        accountContext.navigator.present(alert, from: self)
    }

    func cardItemHandler(index: Int, threadID: String) {
        guard !(markSelectedThreadId == nil || markSelectedThreadId != threadID) else { return }
        let vc = MailMessageListController.makeForMailHome(accountContext: accountContext,
                                                           threadList: viewModel.mailThreads.all,
                                                           threadId: threadID,
                                                           labelId: Mail_LabelId_Stranger,
                                                           statInfo: MessageListStatInfo(from: .threadList, newCoreEventLabelItem: ""),
                                                           pageWidth: view.bounds.width,
                                                           templateRender: nil,
                                                           externalDelegate: self)
        vc.currentAccount = accountContext.mailAccount
        markSelectedThreadId = threadID
        vc.backCallback = { [weak self] in
            guard let strongSelf = self, Display.pad else { return } // !strongSelf.rootSizeClassIsRegular
            strongSelf.markSelectedThreadId = nil
            strongSelf.clearSelectedStatus()
        }
        if Display.pad {
            accountContext.navigator.showDetail(vc, wrap: MailMessageListNavigationController.self, from: self)
            let newIndex = IndexPath(item: index, section: 0)
            var indexPathsToReload = [newIndex]
            if let preIndex = listView.collectionView.indexPathsForSelectedItems?.first, preIndex != newIndex {
                indexPathsToReload.append(preIndex)
            }
            listView.collectionView.reloadItemsAtIndexPaths(indexPathsToReload, animationStyle: .none)
        } else {
            accountContext.navigator.push(vc, from: self)
        }
        MailTracker.log(event: "email_stranger_list_click", params: ["click": "stranger_card", "label_item": currentLabelID ?? ""])
    }

    func msgListManageStrangerThread(threadIDs: [String]?, status: Bool, isSelectAll: Bool, maxTimestamp: Int64?, fromList: [String]?) {
        delegate?.strangerCardListItemReplyHandler(threadIDs: threadIDs, status: status, maxTimestamp: maxTimestamp, fromList: fromList)
    }

    func didMoveToNewFolder(toast: String, undoInfo: (String, String)) {}
    func moreActionHandler(sender: UIControl) {}
    func moreCardItemHandler() {}

    func loadMoreIfNeeded() {
        let lastMessageTimeStamp = viewModel.mailThreads.all.last?.lastmessageTime ?? 0
        if !viewModel.isLoading && !viewModel.isLastPage {
            viewModel.getMailListFromLocal()
            MailLogger.info("[mail_stranger] card list Load More - timeStamp: \(lastMessageTimeStamp)")
        }
    }
}

extension MailStrangerCardListController: MailStrangerThreadCellDelegate {
    func didClickStrangerReply(_ cell: MailStrangerThreadCell, cellModel: MailThreadListCellViewModel, status: Bool) {
        MailLogger.info("[mail_stranger] cardList didClickStrangerReply threadID: \(cellModel.threadID) status: \(status)")
        /// 本地乐观更新数据源，兼容快速点击操作
        var vmDatas = viewModel.mailThreads.all
        vmDatas.lf_remove(object: cellModel)
        viewModel.setThreadsListOfLabel(Mail_LabelId_Stranger, mailList: vmDatas)
        delegate?.strangerCardListItemReplyHandler(threadIDs: [cellModel.threadID], status: status, maxTimestamp: (viewModel.mailThreads.all.first?.lastmessageTime ?? 0) + 1, fromList: cellModel.fromList)
        MailTracker.log(event: "email_stranger_list_click", params: ["click": status ? "allow_sender" : "reject_sender",
                                                                     "label_item": currentLabelID ?? ""])
    }

    func didClickAvatar(mailAddress: MailAddress, cellModel: MailThreadListCellViewModel) {
        let name = mailAddress.mailDisplayName
        let userid = mailAddress.larkID
        //let entityType = mailAddress.type ?? .unknown
        let entityType = Email_Client_V1_Address.LarkEntityType(rawValue: 0) ?? .user
        let tenantId = mailAddress.tenantId
        let address = mailAddress.address
        let accountId = accountContext.accountID
        MailContactLogic.default.checkContactDetailAction(userId: userid,
                                                          tenantId: tenantId,
                                                          currentTenantID: accountContext.user.tenantID,
                                                          userType: entityType.toContactType()) { [weak self] result in
            guard let self = self else { return }
            if result == MailContactLogic.ContactDetailActionType.profile {
                // internal user, show Profile
                self.accountContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
            } else if result == MailContactLogic.ContactDetailActionType.nameCard {
                if MailAddressChangeManager.shared.addressNameOpen() {
                    var item = AddressRequestItem()
                    item.address =  address
                    MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
                        guard let `self` = self else { return }
                            if let item = MailAddressNameResponse.addressNameList.first, !item.larkEntityID.isEmpty &&
                                item.larkEntityID != "0" {
                                self.accountContext.profileRouter.openUserProfile(userId: item.larkEntityID, fromVC: self)
                            } else {
                                self.accountContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self) { [weak self] success in
                                    self?.handleSaveContactResult(success, cellModel: cellModel)
                                }
                            }
                        }, onError: { [weak self] (error) in
                            guard let `self` = self else { return }
                            MailLogger.error("handle peronal click resp error \(error)")
                            self.accountContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self) { [weak self] success in
                                self?.handleSaveContactResult(success, cellModel: cellModel)
                            }
                        }).disposed(by: self.disposeBag)
                } else {
                    self.accountContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self) { [weak self] success in
                        self?.handleSaveContactResult(success, cellModel: cellModel)
                    }
                }
            }
        }
    }

    func handleSaveContactResult(_ success: Bool, cellModel: MailThreadListCellViewModel) {
        MailLogger.info("[mail_stranger] cardList vc openNameCard callback: \(success)")
        if success {
            delegate?.strangerCardListItemReplyHandler(threadIDs: [cellModel.threadID], status: true,
                                                       maxTimestamp: cellModel.lastmessageTime + 1, fromList: cellModel.fromList)
        }
    }
}
