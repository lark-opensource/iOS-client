//
//  ContactAddListController.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/10.
//
import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignToast
import LKCommonsLogging
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface

protocol ContactAddListRouter {
    func presentContactAddressBookList(_ vc: ContactAddListController,
                                       inviteInfo: InviteAggregationInfo,
                                       showSkipButton: Bool,
                                       source: ExternalInviteSourceEntrance,
                                       skipCallback: ContactSkipCallback?)
    func pushAddContactRelation(addContactRelationBody: AddContactRelationBody, vc: ContactAddListController)
}

/// Onboarding 导入联系人
final class ContactAddListController: BaseUIViewController {

    private let disposeBag: DisposeBag = DisposeBag()
    static let logger = Logger.log(ContactAddListController.self, category: "LarkContact")

    private let viewModel: ContactAddListViewModel
    private let finishCallBack: ContactPickFinishCallBack?

    private lazy var contactListView: ContactAddListView = {
        let contactListView = ContactAddListView(viewModel: self.viewModel)
        contactListView.delegate = self
        return contactListView
    }()
    private lazy var rightNaviItem: LKBarButtonItem = {
        let _rightItem = LKBarButtonItem(image: nil, title: BundleI18n.LarkContact.Lark_Legacy_Completed)
        _rightItem.addTarget(self, action: #selector(onSkipButtonTapped), for: UIControl.Event.touchUpInside)
        _rightItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        return _rightItem
    }()
    // loading view
    private lazy var loadingView: ContactPickSkeletonTableView = {
        let view = ContactPickSkeletonTableView()
        return view
    }()
    // empty view
    private lazy var emptyView: LarkUIKit.EmptyDataView = {
        let emptyView = LarkUIKit.EmptyDataView(
            content: BundleI18n.LarkContact.Lark_NewContacts_NoLarkUserFoundInMobileContacts(),
            placeholderImage: Resources.contacts_import_banner
        )
        emptyView.backgroundColor = UIColor.ud.N00
        emptyView.isHidden = true
        return emptyView
    }()
    private lazy var inviteButton: UIButton = {
        let inviteButton = UIButton()
        inviteButton.backgroundColor = UIColor.ud.colorfulBlue
        inviteButton.layer.cornerRadius = 4
        inviteButton.setTitle(BundleI18n.LarkContact.Lark_NewContacts_InviteMobileContactsButton(), for: UIControl.State.normal)
        inviteButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        inviteButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.onInviteButtonTapped()
            })
            .disposed(by: disposeBag)
        return inviteButton
    }()

    private let appreciableTracker: PickerAppReciable

    /// @params finishCallBack: 完成的回调
    init(viewModel: ContactAddListViewModel,
         finishCallBack: ContactPickFinishCallBack? = nil,
         appreciableTracker: PickerAppReciable) {
        self.viewModel = viewModel
        self.finishCallBack = finishCallBack
        self.appreciableTracker = appreciableTracker
        super.init(nibName: nil, bundle: nil)
        self.appreciableTracker.initViewEnd()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.bindObservers()
        let startTime = CACurrentMediaTime()
        self.viewModel.fetchContactData(callback: { error in
            if let error = error {
                return self.appreciableTracker.error(error)
            }
            self.appreciableTracker.updateSDKCost(CACurrentMediaTime() - startTime)
            self.appreciableTracker.endLoadingTime()
        })
        self.appreciableTracker.firstRenderEnd()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewModel.isShowBehaviorPush {
            // 去掉present的close按钮
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func setupUI() {
        self.view.backgroundColor = UIColor.ud.N00

        self.title = viewModel.textInfo.title
        self.navigationItem.rightBarButtonItem = self.rightNaviItem

        self.view.addSubview(self.emptyView)
        self.emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.emptyView.addSubview(self.inviteButton)
        self.inviteButton.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.height.equalTo(48)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-90)
        }

        // list
        self.view.addSubview(self.contactListView)
        self.contactListView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.avoidKeyboardBottom)
        }

        self.refreshEmptyView()
    }

    func bindObservers() {
        viewModel.loadingStatusDriver.drive(onNext: { [weak self] (loadingStatus) in
            guard let self = self else { return }
            let isLoadingStatusStart = loadingStatus == .start
            let isLoadingStatusError = loadingStatus == .error
            let isLoadingStatusCompleted = loadingStatus == .finish
                || loadingStatus == .emptyData
                || loadingStatus == .error
            /// loading时
            self.showLoadingView(isLoadingStatusStart)
            /// 接口失败时
            self.retryLoadingView.isHidden = !isLoadingStatusError
            /// 页面展示时
            if isLoadingStatusCompleted {
                self.refreshEmptyView()
                self.viewModel.trackOnbardingAddContactShow()
            }
            ContactAddListController.logger.debug("loadingStatus changed",
                                                  additionalData: ["loadingStatus": "\(loadingStatus)"])
        }).disposed(by: viewModel.disposeBag)

        viewModel.reloadDataDriver.drive(onNext: { [weak self] _ in
            self?.contactListView.reloadContactList()
            self?.refreshEmptyView()
            self?.refreshTopNaviBar()
        }).disposed(by: viewModel.disposeBag)
    }

    private func showLoadingView(_ isShow: Bool) {
        if isShow {
            if self.loadingView.superview == nil {
                self.view.addSubview(self.loadingView)
                self.loadingView.snp.remakeConstraints({ (make) in
                    make.edges.equalTo(self.contactListView.snp.edges)
                })
            }
            self.loadingView.isHidden = false
            self.loadingView.startLoading()
        } else {
            if self.loadingView.superview != nil {
                self.loadingView.stopLoading()
                self.loadingView.isHidden = true
                self.loadingView.removeFromSuperview()
            }
        }
    }

    /// 刷新空页面状态
    func refreshEmptyView() {
        if viewModel.contacts.isEmpty {
            self.contactListView.isHidden = true
            self.emptyView.isHidden = false
        } else {
            self.contactListView.isHidden = false
            self.emptyView.isHidden = true
        }
    }

    /// 刷新顶部导航状态
    func refreshTopNaviBar() {
        self.rightNaviItem.resetTitle(title: viewModel.rightNaviItemText)
    }

    @objc
    private func onSkipButtonTapped() {
        DispatchQueue.main.async {
            self.handleOnFinish()
        }
        self.viewModel.trackOnbardingAddContactSkip()
        ContactAddListController.logger.debug("onSkipButtonTapped")
        self.dismiss(animated: true, completion: nil)
    }
}

extension ContactAddListController: ContactAddListViewDelegate {
    func onContactApplyTapped(selectContact: ContactItem) {
        ContactAddListController.logger.debug("onContactApplyTapped",
                                              additionalData: [
                                                "applyStatus": "\(String(describing: selectContact.applyStatus))",
                                                "userInfo": "\(String(describing: selectContact.contactInfo?.userInfo))"])
        /// 申请状态为未申请
        let isApplyStatusValid = selectContact.applyStatus == .contactStatusNotFriend
        guard let userInfo = selectContact.contactInfo?.userInfo, isApplyStatusValid else { return }
        var source = Source()
        let isEmail: Bool = selectContact.contactInfo?.contactPoint.contains("@") ?? false
        source.sourceType = isEmail ? .searchEmail : .searchPhone
        let addContactRelationBody = AddContactRelationBody(
            userId: userInfo.userID,
            chatId: nil,
            token: nil,
            source: source,
            addContactBlock: { [weak self] userID in
                guard userInfo.userID == userID else {
                    ContactAddListController.logger.debug("Contact Add userId not match",
                                                          additionalData: [
                                                            "userID": "\(String(describing: userID))",
                                                            "userInfo": "\(userInfo)"
                    ])
                    return
                }
                var newSelectContact = selectContact
                newSelectContact.applyStatus = ContactApplyStatus.contactStatusRequest
                self?.viewModel.updateContact(contact: newSelectContact)
                ContactAddListController.logger.debug("Contact Add applied",
                                                      additionalData: ["newSelectContact": "\(newSelectContact)"])
            },
            userName: userInfo.userName,
            businessType: nil)
        viewModel.router?.pushAddContactRelation(addContactRelationBody: addContactRelationBody, vc: self)
    }

    func onPickConfirm(selectedContacts: [ContactItem]) {
        DispatchQueue.main.async {
            self.handleOnFinish(selectedContacts: selectedContacts)
        }
        Tracer.trackOnbardingCNUploadUserCount(count: selectedContacts.count)
        ContactAddListController.logger.debug("onPickConfirm",
                                              additionalData: ["selectedContacts": "\(selectedContacts)"])
        self.dismiss(animated: true, completion: nil)
    }

    private func onInviteButtonTapped() {
        // 请求邀请信息
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        self.viewModel.fetchInviteLinkInfo()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteInfo) in
                hud.remove()
                guard let `self` = self else { return }
                // 跳转通讯录
                self.viewModel.router?
                    .presentContactAddressBookList(self,
                                                   inviteInfo: inviteInfo,
                                                   showSkipButton: true,
                                                   source: .onboarding) { (contactVC) in
                                                    contactVC.dismiss(animated: true) { [weak self] in
                                                        self?.onSkipButtonTapped()
                                                    }
                    }
                self.viewModel.trackOnboardingSystemInvite()
                }, onError: { error in
                    hud.remove()
                    ContactAddListController.logger.error("fetchInviteLink failed", error: error)
            }).disposed(by: disposeBag)

        ContactAddListController.logger.debug("onInviteButtonTapped")
    }

    private func handleOnFinish(selectedContacts: [ContactItem]? = nil) {
        if let finishCallBack = self.finishCallBack {
            finishCallBack()
        }
        self.viewModel.trackOnbardingAddContactConfirm()
    }
}
