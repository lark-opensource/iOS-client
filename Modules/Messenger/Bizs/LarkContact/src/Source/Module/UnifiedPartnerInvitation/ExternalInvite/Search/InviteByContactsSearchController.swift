//
//  InviteByContactsSearchController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/24.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import Swinject
import SnapKit
import LarkSDKInterface
import LarkAlertController
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkMessengerInterface
import UniverseDesignColor
import LKCommonsLogging
import LarkContainer
import LarkContactComponent

protocol InviteByContactsSearchRouter {
    /// profile page
    func pushContactProfileViewController(vc: BaseUIViewController,
                                          userProfile: UserProfile,
                                          searchContentType: SearchContentType)
    /// invite send page
    func presentInviteSendViewController(vc: UIViewController,
                                         source: SourceScene,
                                         type: InviteSendType,
                                         content: String,
                                         countryCode: String,
                                         inviteMsg: String,
                                         uniqueId: String,
                                         sendCompletionHandler: @escaping () -> Void)
}

final class InviteByContactsSearchController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private let router: InviteByContactsSearchRouter
    private let viewModel: ContactSearchViewModel
    private let disposeBag = DisposeBag()
    private let inviteMsg: String
    private let uniqueId: String
    private let userResolver: UserResolver
    private let tenantNameService: LarkTenantNameService
    static let logger = Logger.log(InviteByContactsSearchController.self, category: "LarkContact.InviteByContactsSearchController")

    init(viewModel: ContactSearchViewModel,
         router: InviteByContactsSearchRouter,
         inviteMsg: String,
         uniqueId: String,
         userResolver: UserResolver) throws {
        self.router = router
        self.inviteMsg = inviteMsg
        self.uniqueId = uniqueId
        self.viewModel = viewModel
        self.userResolver = userResolver
        self.tenantNameService = try userResolver.resolve(assert: LarkTenantNameService.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        self.titleString = BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB
        tableView.register(SearchOpearationCell.self, forCellReuseIdentifier: NSStringFromClass(SearchOpearationCell.self))
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: NSStringFromClass(SearchResultCell.self))
        layoutPageSubviews()
        addKeyboardObserver()
        addSearchStateObserver()
        addFriendStatusChangedObserver()
        searchTextField.text = ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }

    private var searchWrapper = SearchUITextFieldWrapperView()
    private lazy var searchTextField: SearchUITextField = { [unowned self] in
        let field = self.searchWrapper.searchUITextField
        field.canEdit = true
        field.placeholder = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleSearchSwitchto
        field.returnKeyType = .done
        field.delegate = self
        field.rx.text
            .filter({ return $0 != nil })
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                var text = self.searchTextField.text ?? ""
                text = text.trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    self.viewModel.searchStateSubject.accept(.none)
                } else {
                    self.viewModel.searchStateSubject.accept(.inital)
                }
                self.tableView.reloadData()
                }, onError: { (_) in
            })
            .disposed(by: self.disposeBag)
        return field
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.N00
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        return tableView
    }()

    private lazy var searchLoadingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .center
        label.text = BundleI18n.LarkContact.Lark_Legacy_InLoading
        return label
    }()

    private lazy var searchLoadingView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.startAnimating()
        return view
    }()

    private lazy var invitePlaceHolderView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var inviteTipImageView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.invite_search_empty
        return view
    }()

    private lazy var inviteTipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private lazy var inviteButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsSearchShareLinkText, for: .normal)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.presentInviteForm(type: self.viewModel.type)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var recommandedUserView: ContactSearchResultView = {
        let recommandedUserView = ContactSearchResultView(frame: .zero)
        recommandedUserView.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecommandedUserView))
        recommandedUserView.addGestureRecognizer(tap)
        return recommandedUserView
    }()

    private lazy var moreBindingUsersView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var splitLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N100
        return view
    }()

    private lazy var moreBindingUsersLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        if self.viewModel.type == .phone {
            label.text = BundleI18n.LarkContact.Lark_IM_AddContacts_PhoneLinkedToMultipleAccounts_Title
        } else {
            label.text = BundleI18n.LarkContact.Lark_IM_AddContacts_EmailLinkedToMultipleAccounts_Title
        }
        label.textAlignment = .left
        return label
    }()

    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.searchStateSubject.value {
        case .inital, .searching, .noneNext:
            return 0
        case .none:
            return 1
        case .hasResult:
            return viewModel.dataSource.count
        }
    }

    // MARK: - TableView Delegates
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.viewModel.searchStateSubject.value == .none {
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SearchOpearationCell.self), for: indexPath) as? SearchOpearationCell
            if let content = searchTextField.text {
                cell?.bindWithSearchContent(content: content)
            }
            return cell ?? UITableViewCell()
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SearchResultCell.self), for: indexPath) as? SearchResultCell
            if viewModel.dataSource.count > indexPath.row {
                let userProfile: UserProfile = viewModel.dataSource[indexPath.row]
                cell?.bindWithModel(model: userProfile, tenantNameService: tenantNameService, fgService: userResolver.fg)
                let tenantNameStatus = userProfile.company.tenantNameStatus
                let tenantName = userProfile.company.tenantName
                let isShowCertSign = userProfile.company.certificationInfo.isShowCertSign
                let certificateStatus = userProfile.company.certificationInfo.certificateStatus
                Self.logger.info("index row: \(indexPath.row) tenantNameStatus: \(tenantNameStatus) tenantNameIsEmpty: \(tenantName.isEmpty) isShowCertSign: \(isShowCertSign) certificateStatus: \(certificateStatus)")
                return cell ?? UITableViewCell()
            }
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if viewModel.searchStateSubject.value == .none {
            searchTextField.resignFirstResponder()
            viewModel.fetchSearchResult(
                searchTextField.text?.replacingOccurrences(of: "\\p{Cf}", with: "", options: .regularExpression) ?? ""
            )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (userProfiles) in
                guard let `self` = self else { return }
                Tracer.trackInvitePeopleExternalSearch(result: userProfiles.count, source: self.viewModel.fromEntrance.rawValue)
                if self.viewModel.type == .phone {
                    self.moreBindingUsersLabel.text = BundleI18n.LarkContact.Lark_IM_AddContacts_PhoneLinkedToMultipleAccounts_Title
                } else {
                    self.moreBindingUsersLabel.text = BundleI18n.LarkContact.Lark_IM_AddContacts_EmailLinkedToMultipleAccounts_Title
                }
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
            })
            .disposed(by: disposeBag)
        } else if viewModel.searchStateSubject.value == .hasResult {
            Tracer.trackInvitePeopleExternalSearchAdd(source: viewModel.fromEntrance.rawValue)
            router.pushContactProfileViewController(
                vc: self,
                userProfile: viewModel.dataSource[indexPath.row],
                searchContentType: viewModel.type
            )
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.searchStateSubject.value == .none {
            return 54.0
        } else {
            return 64.0
        }
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
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }

    @objc
    func tapRecommandedUserView() {
        if let recUser = viewModel.recommandUser {
            Tracer.trackInvitePeopleExternalSearchAdd(source: viewModel.fromEntrance.rawValue)
            router.pushContactProfileViewController(
                vc: self,
                userProfile: recUser,
                searchContentType: viewModel.type
            )
        }
    }
}

private extension InviteByContactsSearchController {
    func layoutPageSubviews() {
        view.addSubview(searchWrapper)
        view.addSubview(recommandedUserView)
        view.addSubview(moreBindingUsersView)
        moreBindingUsersView.addSubview(splitLine)
        moreBindingUsersView.addSubview(moreBindingUsersLabel)
        view.addSubview(tableView)
        tableView.addSubview(searchLoadingView)
        searchLoadingView.addSubview(indicatorView)
        searchLoadingView.addSubview(searchLoadingTitleLabel)
        view.addSubview(invitePlaceHolderView)
        invitePlaceHolderView.addSubview(inviteTipImageView)
        invitePlaceHolderView.addSubview(inviteTipLabel)
        invitePlaceHolderView.addSubview(inviteButton)

        searchWrapper.snp.remakeConstraints({ make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(50)
        })
        recommandedUserView.snp.makeConstraints { make in
            make.top.equalTo(searchWrapper.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(64)
        }
        moreBindingUsersView.snp.makeConstraints { make in
            make.top.equalTo(recommandedUserView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(42)
        }
        splitLine.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
        moreBindingUsersLabel.snp.makeConstraints { make in
            make.top.equalTo(splitLine.snp.bottom).offset(11)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-5)
        }
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchWrapper.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        searchLoadingView.snp.makeConstraints { (make) in
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        indicatorView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        searchLoadingTitleLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalTo(indicatorView.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
        }
        invitePlaceHolderView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-64)
        }
        inviteTipImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(120)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        inviteTipLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(36)
            make.right.equalToSuperview().offset(-36)
            make.top.equalTo(inviteTipImageView.snp.bottom)
            make.height.equalTo(44)
        }
        inviteButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(64)
            make.right.equalToSuperview().offset(-64)
            make.top.equalTo(inviteTipLabel.snp.bottom).offset(26)
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }
    }

    func showRecommandedUserView(_ shouldShow: Bool) {
        recommandedUserView.isHidden = !shouldShow
        recommandedUserView.snp.updateConstraints { make in
            make.height.equalTo(shouldShow ? 64 : 0)
        }
        if shouldShow {
            tableView.snp.remakeConstraints { (make) in
                make.top.equalTo(moreBindingUsersView.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        } else {
            tableView.snp.remakeConstraints { (make) in
                make.top.equalTo(searchWrapper.snp.bottom).offset(8)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
    }

    func showMoreBindingUsersView(_ shouldShow: Bool) {
        moreBindingUsersView.isHidden = !shouldShow
        moreBindingUsersView.snp.updateConstraints { make in
            make.height.equalTo(shouldShow ? 42 : 0)
        }
    }

    func addFriendStatusChangedObserver() {
        let notificationName = Notification.Name(rawValue: LKFriendStatusChangeNotification)
        NotificationCenter.default.rx
        .notification(notificationName)
        .subscribe(onNext: { [weak self] (notification) in
            guard let `self` = self else { return }
            guard let notificationInfo = notification.object as? [String: Any] else { return }
            guard let userId = notificationInfo["userID"] as? String else { return }
            if self.viewModel.recommandUser?.userId == userId,
               let recommendUser = self.viewModel.recommandUser {
                if let isFriend = notificationInfo["isFriend"] as? Bool, isFriend {
                    recommendUser.isFriend = true
                } else if let apply = notificationInfo["apply"] as? Bool, apply {
                    recommendUser.requestUserApply = true
                }
                self.recommandedUserView.bindWithModel(model: recommendUser,
                                                       tenantNameService: self.tenantNameService,
                                                       fgService: self.userResolver.fg)
            }
            var index = NSNotFound
            var notificationUser: UserProfile?
            for i in 0..<self.viewModel.dataSource.count {
                let user: UserProfile = self.viewModel.dataSource[i]
                if user.userId == userId {
                    index = i
                    notificationUser = user
                    break
                }
            }
            guard let updateUser = notificationUser, index != NSNotFound else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SearchResultCell {
                if let isFriend = notificationInfo["isFriend"] as? Bool, isFriend {
                    updateUser.isFriend = true
                } else if let apply = notificationInfo["apply"] as? Bool, apply {
                    updateUser.requestUserApply = true
                }
                cell.bindWithModel(model: updateUser, tenantNameService: self.tenantNameService, fgService: self.userResolver.fg)
            }
        }).disposed(by: self.disposeBag)
    }

    func addKeyboardObserver() {
        if Display.pad {
            return
        }
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification).asDriver(onErrorJustReturn: Notification(name: Notification.Name(rawValue: "")))
            .drive(onNext: { [weak self] (notification) in
                guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue, let `self` = self else { return }
                let duration: Double = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                    self.tableView.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview().offset(-keyboardFrame.height)
                    })
                    self.tableView.superview?.layoutIfNeeded()
                })
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification).asDriver(onErrorJustReturn: Notification(name: Notification.Name(rawValue: "")))
            .drive(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                let duration: Double = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                    self.tableView.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview()
                    })
                    self.tableView.superview?.layoutIfNeeded()
                })
            })
            .disposed(by: disposeBag)
    }

    func addSearchStateObserver() {
        viewModel.searchStateSubject.asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] (state) in
                guard let `self` = self else { return }
                if state == .inital {
                    self.searchTextField.text = ""
                }
                if state == .noneNext {
                    let tipTitle = BundleI18n.LarkContact.Lark_Contacts_NoExternalContactSearchResults()
                    let buttonTitle = self.viewModel.type == .phone ?
                        BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsSearchShareLinkText :
                        BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsSearchShareLinkEmail
                    self.inviteTipLabel.text = tipTitle
                    self.inviteButton.setTitle(buttonTitle, for: .normal)
                }
                if state == .hasResult {
                    if self.viewModel.recommandUser != nil {
                        if let recUser = self.viewModel.recommandUser {
                            self.recommandedUserView.bindWithModel(model: recUser, tenantNameService: self.tenantNameService, fgService: self.userResolver.fg)
                        }
                        self.showRecommandedUserView(true)
                        self.showMoreBindingUsersView(!self.viewModel.dataSource.isEmpty)
                    }
                } else {
                    self.showRecommandedUserView(false)
                    self.showMoreBindingUsersView(false)
                }
                self.invitePlaceHolderView.isHidden = !(state == .noneNext)
                self.searchLoadingView.isHidden = (state != .searching)
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    func presentInviteForm(type: SearchContentType) {
        searchTextField.resignFirstResponder()
        var contactContent = ""
        var code = ""
        if viewModel.type == .phone {
            let (countryCode, phoneNumber) = viewModel.getDisassemblePhoneNumber(content: searchTextField.text ?? "")
            code = countryCode
            contactContent = phoneNumber
        } else if viewModel.type == .email {
            code = viewModel.isOversea ? "+1" : "+86"
            contactContent = viewModel.getPureEmail(searchTextField.text ?? "")
        }
        Tracer.trackInvitePeopleExternalSearchNomatchInvite(source: viewModel.fromEntrance.rawValue)
        router.presentInviteSendViewController(
            vc: self,
            source: .search,
            type: InviteSendType(rawValue: type.rawValue) ?? .phone,
            content: contactContent,
            countryCode: code,
            inviteMsg: inviteMsg,
            uniqueId: uniqueId) { [weak self] in
                self?.viewModel.searchStateSubject.accept(.inital)
        }
    }

}
