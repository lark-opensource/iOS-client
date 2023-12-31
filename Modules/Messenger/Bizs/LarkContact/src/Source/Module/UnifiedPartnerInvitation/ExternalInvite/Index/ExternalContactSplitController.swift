//
//  ExternalContactSplitController.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/12/30.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LKCommonsLogging
import LarkFoundation
import RxSwift
import LarkMessengerInterface
import LarkContainer

protocol ExternalContactSplitRouter {
    // 外部邀请帮助中心
    func pushHelpCenterForExternalInvite(vc: BaseUIViewController)
    // 通过手机联系人邀请
    func pushAddFromContactsViewController(vc: BaseUIViewController, presenter: ContactImportPresenter, fromEntrance: ExternalInviteSourceEntrance)
    // 扫码
    func pushQRCodeControllerr(vc: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance)
    // 通过手机/邮箱邀请外部联系人
    func pushExternalContactsSearchViewController(vc: BaseUIViewController, inviteMsg: String, uniqueId: String, fromEntrance: ExternalInviteSourceEntrance)
    // 引导页
    func presentGuidePage(from: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance, completion: @escaping () -> Void)
    // 我的二维码
    func pushMyQRCodeController(from: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance)
    // 面对面建群
    func pushFaceToFaceCreateGroupController(vc: BaseUIViewController)
}

final class ExternalContactSplitController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UserResolverWrapper {
    static private let logger = Logger.log(ExternalContactSplitController.self,
                                           category: "LarkContact.ExternalContactSplitController")
    private let viewModel: ExternalContactSplitViewModel
    private var contactImportPresenter: ContactImportPresenter?
    private var canShareLink: Bool = false
    private var inviteInfo: InviteAggregationInfo?
    private let disposeBag = DisposeBag()
    var userResolver: LarkContainer.UserResolver

    init(viewModel: ExternalContactSplitViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
        retryLoadingView.retryAction = { [unowned self] in
            self.fetchInviteLinkInfo()
        }
        fetchInviteLinkInfo()
    }

    func fetchInviteLinkInfo() {
        loadingPlaceholderView.isHidden = false
        var isShowing = false
        viewModel.fetchInviteContextFromLocal()
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteContext) in
                guard let `self` = self else { return }
                self.inviteInfo = inviteContext.inviteInfo
                self.canShareLink = inviteContext.inviteInfo.externalExtraInfo?.canShareLink ?? false
                if inviteContext.needDisplayGuide {
                    self.viewModel.router?.presentGuidePage(
                        from: self,
                        fromEntrance: self.viewModel.fromEntrance) {
                            self.loadingPlaceholderView.isHidden = true
                            isShowing = true
                    }
                } else {
                    self.loadingPlaceholderView.isHidden = true
                    isShowing = true
                }
            }, onError: { (_) in
                isShowing = false
            }, onDisposed: { [weak self] in
                self?.loadingPlaceholderView.isHidden = true
            }).disposed(by: disposeBag)
        viewModel.fetchInviteContextFromServer()
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteContext) in
                guard let `self` = self else { return }
                self.inviteInfo = inviteContext.inviteInfo
                self.canShareLink = inviteContext.inviteInfo.externalExtraInfo?.canShareLink ?? false
                if inviteContext.needDisplayGuide {
                    self.viewModel.router?.presentGuidePage(
                        from: self,
                        fromEntrance: self.viewModel.fromEntrance) {
                        self.loadingPlaceholderView.isHidden = true
                    }
                } else {
                    self.loadingPlaceholderView.isHidden = true
                }
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                if !isShowing {
                    self.loadingPlaceholderView.isHidden = true
                    self.retryLoadingView.isHidden = false
                }
            }, onDisposed: { [weak self] in
                self?.loadingPlaceholderView.isHidden = true
            }).disposed(by: disposeBag)
    }

    @objc
    private func routeToHelpPage() {
        Tracer.trackInvitePeopleHelpClick()
        viewModel.router?.pushHelpCenterForExternalInvite(vc: self)
    }

    @objc
    private func routeToMyQRCodePage() {
        Tracer.trackInvitePeopleExternalQrcodeClick(source: viewModel.fromEntrance.rawValue)
        viewModel.router?.pushMyQRCodeController(from: self, fromEntrance: viewModel.fromEntrance)
    }

    private lazy var searchWrapper: SearchUITextFieldWrapperView = {
        let wrapper = SearchUITextFieldWrapperView()
        wrapper.backgroundColor = .clear
        wrapper.searchUITextField.placeholder = BundleI18n.LarkContact.Lark_NewContacts_ProfileSearchUsersPlaceholder
        wrapper.searchUITextField.delegate = self
        return wrapper
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = headerView
        tableView.register(ExternalInviteCell.self, forCellReuseIdentifier: NSStringFromClass(ExternalInviteCell.self))
        return tableView
    }()

    private lazy var headerView: UIControl = {
        let header = UIControl()
        header.backgroundColor = .clear
        header.addTarget(self, action: #selector(routeToMyQRCodePage), for: .touchUpInside)
        let container = UIView()
        container.isUserInteractionEnabled = false
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.N900
        label.text = BundleI18n.LarkContact.Lark_NewContacts_AddExternalContacts_MyQRCode
        let iconView = UIImageView()
        iconView.image = Resources.my_qrcode_entrance

        container.addSubview(label)
        container.addSubview(iconView)
        header.addSubview(container)
        label.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        iconView.snp.makeConstraints { (make) in
            make.leading.equalTo(label.snp.trailing).offset(4)
            make.width.height.equalTo(20)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        container.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(20)
        }
        header.lu.addBottomBorder()
        return header
    }()

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCountInSection[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ExternalInviteCell.self))
        if let cell = cell as? ExternalInviteCell {
            cell.bind(with: viewModel.entrances[indexPath.row])
        }
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let entrance = viewModel.entrances[indexPath.row]

        switch entrance.flag {
        case .createNearbyGroup:
            viewModel.router?.pushFaceToFaceCreateGroupController(vc: self)
        case .importFromAddressbook:
            guard let externalExtra = inviteInfo?.externalExtraInfo, let chatApplicationAPI = viewModel.chatApplicationAPI, let presenterRouter = viewModel.presenterRouter else {
                return
            }
            let presenter = ContactImportPresenter(
                isOversea: viewModel.isOversea,
                applicationAPI: chatApplicationAPI,
                router: presenterRouter,
                inviteMsg: externalExtra.linkInviteData.inviteMsg,
                uniqueId: externalExtra.linkInviteData.uniqueID,
                source: viewModel.fromEntrance,
                resolver: userResolver)
            contactImportPresenter = presenter
            viewModel.router?.pushAddFromContactsViewController(vc: self, presenter: presenter, fromEntrance: viewModel.fromEntrance)
        case .scan:
            Tracer.trackScan(source: "add_external_contact")
            Tracer.trackInvitePeopleExternalScanQRCodeClick(source: viewModel.fromEntrance.rawValue)
            viewModel.router?.pushQRCodeControllerr(vc: self, fromEntrance: viewModel.fromEntrance)
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let externalExtra = inviteInfo?.externalExtraInfo, let router = viewModel.router else {
            Self.logger.info("push external contacts search failure")
            return false
        }
        router.pushExternalContactsSearchViewController(
            vc: self,
            inviteMsg: externalExtra.linkInviteData.inviteMsg,
            uniqueId: externalExtra.linkInviteData.uniqueID,
            fromEntrance: viewModel.fromEntrance
        )
        return false
    }
}

// MARK: - Private Methods
private extension ExternalContactSplitController {
    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBody
        setupNavigationBar()
        view.addSubview(searchWrapper)
        view.addSubview(tableView)

        searchWrapper.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview().inset(0)
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(50)
        }
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchWrapper.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tableView.tableHeaderView?.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(52)
        })
        tableView.tableHeaderView?.superview?.layoutIfNeeded()
    }

    func setupNavigationBar() {
        self.title = viewModel.title()
        let rBarItem = LKBarButtonItem(image: Resources.invite_help)
        rBarItem.button.addTarget(self, action: #selector(routeToHelpPage), for: .touchUpInside)
        navigationItem.rightBarButtonItem = rBarItem
    }
}
