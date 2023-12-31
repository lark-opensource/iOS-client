//
//  NameCardWrapperViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import UniverseDesignColor
import EENavigator
import LarkSDKInterface
import RxSwift
import LarkFeatureGating
import LarkContainer
import UniverseDesignToast

final class NameCardWrapperViewController: BaseUIViewController, UDTabsViewDelegate, UDTabsListContainerViewDataSource {
    // MARK: views
    private lazy var titleTabsView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UDColor.lineDividerDefault
        tabsView.addSubview(bottomBorder)
        bottomBorder.snp.updateConstraints { (make) in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        tabsView.titles = [BundleI18n.LarkContact.Mail_ThirdClient_AddToAccountContacts,
                           BundleI18n.LarkContact.Mail_MailingList_MailingListTab]
        let config = tabsView.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        tabsView.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        tabsView.indicators = [indicator]
        tabsView.delegate = self
        tabsView.backgroundColor = UIColor.ud.bgBody
        return tabsView
    }()

    private lazy var tabsContainer: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    var items = [NameCardListViewController]()

    let namecardAPI: NamecardAPI
    let pushCenter: PushNotificationCenter

    let disposeBag = DisposeBag()

    private var accountListVM: MailAccountListViewModel?
    private var mailAccountType: String = "None"
    private var isInitialListEmpty = false
    private var currentAccountInfos: [MailAccountBriefInfo]?
    private let userResolver: UserResolver
    // MARK: life Circle
    init(namecardAPI: NamecardAPI, pushCenter: PushNotificationCenter, resolver: UserResolver) {
        self.namecardAPI = namecardAPI
        self.pushCenter = pushCenter
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        setupNavigationBar()
        fetchMailAccountList()
        retryLoadingView.retryAction = { [weak self] in
            self?.fetchMailAccountList()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountPermissionLost), name: .LKNameCardNoPermissionNotification, object: nil)

        getAccountTypeAndTrack()
    }

    private func fetchMailAccountList() {
        retryLoadingView.isHidden = true
        namecardAPI.getAllMailAccountDetail(latest: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
                guard let self = self else { return }
                self.handleFetchedList(list)
            }, onError: { [weak self] _ in
                self?.retryLoadingView.isHidden = false
            }).disposed(by: disposeBag)
        listenAccountPush()
    }

    private func handleFetchedList(_ list: [MailAccountBriefInfo]) {
        currentAccountInfos = list
        if list.isEmpty {
            self.isInitialListEmpty = true
            self.setupOldTabbarUI(accountInfo: .empty)
        } else if list.count == 1, let account = list.first, account.mailGroupTotalCount == 0 {
            self.isInitialListEmpty = true
            self.setupOldTabbarUI(accountInfo: account)
        } else {
            self.isInitialListEmpty = false
            self.setupMailAccount(accountInfos: list)
        }
    }

    private func updateMailAccountList(from push: MailContactChangedPush) {
        namecardAPI.sortMailAccountInfos(push.briefInfos)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] list in
                guard let self = self else { return }
                self.accountListVM?.updateMailAccountDetail(list)
            }).disposed(by: disposeBag)
    }

    private func listenAccountPush() {
        pushCenter.observable(for: MailContactChangedPush.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                if self?.isInitialListEmpty == true {
                    if self?.currentAccountInfos != push.briefInfos {
                        self?.removeAllChildViewController()
                        self?.setupNavigationBar()
                        self?.handleFetchedList(push.briefInfos)
                    }
                } else {
                    self?.updateMailAccountList(from: push)
                }
            }).disposed(by: disposeBag)
        pushCenter.observable(for: MailShareAccountChangedPush.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchMailAccountList()
            }).disposed(by: disposeBag)
    }

    private func getAccountTypeAndTrack() {
        namecardAPI.getCurrentMailAccountType()
            .subscribe(onNext: { [weak self] type in
                guard let self = self else { return }
                self.mailAccountType = type
                MailContactStatistics.view(accountType: type)
            }, onError: { _ in
                MailContactStatistics.view(accountType: "None")
            }).disposed(by: disposeBag)
    }

    private func setupOldTabbarUI(accountInfo: MailAccountBriefInfo) {
        setupNaviRightItem()
        if userResolver.fg.staticFeatureGatingValue(with: "larkmail.contact.mail_group") {
            namecardAPI.checkServerMailGroupPermission()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] show in
                    if show {
                        self?.setupTabsVC()
                    } else {
                        self?.setupContact(accountInfo: accountInfo)
                    }
                }) { [weak self] _ in
                    self?.setupContact(accountInfo: accountInfo)
                }.disposed(by: disposeBag)
        } else {
            setupContact(accountInfo: accountInfo)
        }
    }

    private func setupContact(accountInfo: MailAccountBriefInfo) {
        let contactVM = MailContactListViewModel(nameCardAPI: namecardAPI, accountType: mailAccountType, accountInfo: accountInfo, asChildList: true)
        let vc = NameCardListViewController(viewModel: contactVM, resolver: userResolver)
        setupChildViewController(vc)
    }

    private func setupMailAccount(accountInfos: [MailAccountBriefInfo]) {
        if let accountListVM = accountListVM {
            accountListVM.updateMailAccountDetail(accountInfos)
        } else {
            let mailAccountVM = MailAccountListViewModel(nameCardAPI: namecardAPI, accountType: mailAccountType, accountInfos: accountInfos, resolver: userResolver)
            accountListVM = mailAccountVM
            let vc = MailAccountListViewController(viewModel: mailAccountVM)
            setupChildViewController(vc)
        }
    }

    private func removeAllChildViewController() {
        children.forEach { viewController in
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }

    private func setupChildViewController(_ viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        viewController.didMove(toParent: self)
    }

    private func setupNavigationBar() {
        isNavigationBarHidden = false
        self.title = BundleI18n.LarkContact.Mail_MailingList_EmailContacts
    }

    func setupNaviRightItem() {
         let rightButton = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Add)
         rightButton.button.tintColor = UIColor.ud.primaryContentDefault
         rightButton.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
         rightButton.addTarget(self, action: #selector(didClickAddButton), for: .touchUpInside)
         navigationItem.rightBarButtonItem = rightButton
     }

     private func setupTabsVC() {
         titleTabsView.listContainer = tabsContainer

         let contactVM = MailContactListViewModel(nameCardAPI: namecardAPI, accountType: mailAccountType, accountInfo: .empty)
         let mailContact = NameCardListViewController(viewModel: contactVM, resolver: userResolver)
         items.append(mailContact)

         let groupVM = MailGroupListViewModel(nameCardAPI: namecardAPI, accountInfo: .empty)
         let mailGroup = NameCardListViewController(viewModel: groupVM, resolver: userResolver)
         items.append(mailGroup)

         view.addSubview(titleTabsView)
         view.addSubview(tabsContainer)

         titleTabsView.snp.makeConstraints {
             $0.left.right.equalToSuperview()
             $0.width.equalToSuperview()
             $0.height.equalTo(40)
             $0.top.equalToSuperview().offset(0)
         }

         tabsContainer.snp.makeConstraints {
             $0.top.equalTo(titleTabsView.snp.bottom)
             $0.left.right.equalToSuperview()
             $0.bottom.equalToSuperview()
         }
     }

     // MARK: handler
     @objc
     private func didClickAddButton() {
         let nameCardEditBody = NameCardEditBody(source: "contact", accountID: "")
         userResolver.navigator.push(body: nameCardEditBody, from: self)
         NameCardTrack.trackClickAddInList()
         MailContactStatistics.addContact(accountType: mailAccountType)
     }

    /// 邮箱账号权限失效
    @objc
    private func onAccountPermissionLost(notification: Notification) {
        UDToast.showFailure(with: BundleI18n.LarkContact.Mail_ThirdClient_UnableToSaveDesc, on: view)
    }

     // MARK: UDTabsListContainerViewDataSource
     func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
         return items.count
     }

     func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
         return items[index]
     }

     public func tabsView(_ segmentedView: UDTabsView, didSelectedItemAt index: Int) {
         self.navigationItem.rightBarButtonItem?.isEnabled = index == 0
     }
}
