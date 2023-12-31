//
//  ContactImportPresenter.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/5/18.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import EENavigator
import LarkRustClient
import LarkFoundation
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsLogging
import UniverseDesignToast
import LarkAddressBookSelector
import LKMetric
import LarkContainer

protocol ExternalContactImportRouter {
    /// 个人信息详情页
    func pushPersonalCardVC(from: UIViewController,
                            userProfile: UserProfile,
                            inviteType: InviteSendType)
    /// 邀请信息发送页
    func presentInviteSendViewController(vc: UIViewController,
                                         source: SourceScene,
                                         type: InviteSendType,
                                         content: String,
                                         countryCode: String,
                                         inviteMsg: String,
                                         uniqueId: String,
                                         sendCompletionHandler: @escaping () -> Void)
}

/// 通讯录单点邀请外部联系人
final class ContactImportPresenter: NSObject, UITableViewDataSource, UITableViewDelegate, SelectContactListControllerDelegate, UserResolverWrapper {
    static let logger = Logger.log(ContactImportPresenter.self, category: "LarkContact.ContactImportPresenter")
    static let omitLength: Int = 5
    private let disposeBag = DisposeBag()
    private let isOversea: Bool
    private let inviteMsg: String
    private let uniqueId: String
    private var userProfiles: [UserProfile] = []
    private let applicationAPI: ChatApplicationAPI
    private let router: ExternalContactImportRouter
    private var addressBookLoadStart: TimeInterval = 0
    private let source: ExternalInviteSourceEntrance
    // 容错控制
    private let tolerantControl: VerificationBaseViewModel
    weak var drawer: SelectiveDrawerController?
    var userResolver: LarkContainer.UserResolver

    init(isOversea: Bool,
         applicationAPI: ChatApplicationAPI,
         router: ExternalContactImportRouter,
         inviteMsg: String,
         uniqueId: String,
         source: ExternalInviteSourceEntrance,
         resolver: UserResolver) {
        self.isOversea = isOversea
        self.applicationAPI = applicationAPI
        self.router = router
        self.inviteMsg = inviteMsg
        self.uniqueId = uniqueId
        self.source = source
        self.userResolver = resolver
        self.tolerantControl = VerificationBaseViewModel(isOversea: isOversea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handle(contactModels: [AddressBookContact],
                type: ContactContentType,
                controller: UIViewController,
                completionHandler: @escaping () -> Void) {
        let hud = UDToast.showLoading(on: controller.view, disableUserInteraction: true)
        guard let model = contactModels.first else { return }
        var contactContent = ""
        switch type {
        case .email:
            contactContent = tolerantControl.getPureEmail(model.email ?? "")
        case .phone:
            contactContent = tolerantControl.getPurePhoneNumber(model.phoneNumber ?? "")
        }
        applicationAPI.searchUser(contactContent: contactContent)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (userProfiles) in
                hud.remove()
                self?.userProfiles = userProfiles
                self?.handleResponse(userProfiles: userProfiles,
                                     contactInfo: contactContent,
                                     contactModel: model,
                                     type: type,
                                     controller: controller,
                                     completionHandler: completionHandler)
            }, onError: { (_) in
                hud.remove()
            }, onDisposed: {
                hud.remove()
            }).disposed(by: disposeBag)
    }

    private lazy var headerView: UIView = {
        let headerView = UnifiedContactTenantHeaderView()
        return headerView
    }()
}

// MARK: - SelectContactListControllerDelegate
extension ContactImportPresenter {
    /// 搜索联系人结果变化
    func onContactSearchChanged(filteredContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController) {}
    /// 点击选择列表的indexView
    func didSelectSectionIndexView(section: Int,
                                   contentType: ContactContentType,
                                   from: UIViewController) {
        Tracer.trackInvitePeopleExternalImportIndex(source: source.rawValue)
    }

    /// 单选模式下选择联系人
    func didChooseContactInSingleType(contact: AddressBookContact,
                                      contentType: ContactContentType,
                                      from: UIViewController) {
        handle(contactModels: [contact], type: isOversea ? .email : .phone, controller: from) {
            if let selectContactListVC = from as? SelectContactListController {
                selectContactListVC.reset()
            }
        }
    }

    func inviteFriend(contact: AddressBookContact,
                      type: ContactContentType,
                      from: UIViewController,
                      completionHandler: @escaping () -> Void) {
        handle(contactModels: [contact], type: type, controller: from, completionHandler: completionHandler)
    }

        /// vc 生命周期回调
    func onLifeCycleEvent(type: LifeCycleEventType) {
        if case .viewDidLoad = type {
            /// Record contacts loadCost metric data
            addressBookLoadStart = Date().timeIntervalSince1970 * 1000
            AddressBookAppReciableTrack.addressBookPageFirstRenderCostTrack(isNeedNet: false)
        }
    }

    /// 获取联系人列表加载完成
    func onContactsDataLoadedByExtrasIfNeeded(loaded: Bool, allContacts: [AddressBookContact]) -> Observable<[ContactExtraInfo]>? {
        let loadCost = TimeInterval(Date().timeIntervalSince1970 * 1000 - addressBookLoadStart)
        LKMetric.C.loadContacts(loadCost: Int64(loadCost))
        AddressBookAppReciableTrack.updateAddressBookPageTrackData(sdkCost: 0, memberCount: allContacts.count)
        AddressBookAppReciableTrack.addressBookPageLoadingTimeEnd(isNeedNet: false)
        return nil
    }

    /// 通讯录模式状态变化
    func onContactListModeDidChange(listMode: ContactListMode) {}

    // 获取联系人列表发送错误
    func showErrorForRequestContacts(error: NSError,
                                     contentType: ContactContentType,
                                     from: UIViewController) {
        AddressBookAppReciableTrack.addressBookPageError(isNewPage: false,
                                              errorCode: error.code,
                                              errorType: .Other,
                                              errorMessage: error.localizedDescription)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ContactImportPresenter {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProfiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UnifiedContactTenantInfoCell? = tableView.dequeueReusableCell(withIdentifier: drawer?.cellReuseIdentifier ??
            NSStringFromClass(UnifiedContactTenantInfoCell.self)) as? UnifiedContactTenantInfoCell
        let userProfile = userProfiles[indexPath.row]
        cell?.bindWithModel(userProfile: userProfile)
        cell?.showBottomLine = indexPath.row < (userProfiles.count - 1)
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard userProfiles.count > indexPath.row else { return }

        if let from = drawer?.presentingViewController {
            drawer?.dismiss(animated: true, completion: { [weak self] in
                guard let `self` = self else { return }
                let profile = self.userProfiles[indexPath.row]
                self.pushPersonalCard(
                    from: from,
                    userProfile: profile,
                    inviteType: self.isOversea ? .email : .phone
                )
            })
        }
    }
}

private extension ContactImportPresenter {
    func genDrawerConfig() -> DrawerConfig {
        let config = DrawerConfig(cornerRadius: 20,
                                  thresholdOffset: 120,
                                  maxContentHeight: UIScreen.main.bounds.height - 78,
                                  cellType: UnifiedContactTenantInfoCell.self,
                                  tableViewDataSource: self,
                                  tableViewDelegate: self,
                                  headerView: headerView,
                                  headerViewHeight: 32)
        return config
    }

    func handleResponse(userProfiles: [UserProfile],
                        contactInfo: String,
                        contactModel: AddressBookContact,
                        type: ContactContentType,
                        controller: UIViewController,
                        completionHandler: @escaping () -> Void) {
        if userProfiles.isEmpty {
            var content = ""
            var code = ""
            switch type {
            case .email:
                code = tolerantControl.defaultCountryCode(isOversea: isOversea)
                content = tolerantControl.getPureEmail(contactInfo)
            case .phone:
                let (countryCode, number) = tolerantControl.getDisassemblePhoneNumber(content: contactInfo)
                code = countryCode
                content = number
            }
            Tracer.trackInvitePeopleExternalImportInviteView(source: source.rawValue)
            router.presentInviteSendViewController(
                vc: controller,
                source: .deviceContacts,
                type: type == .email ? .email : .phone,
                content: content,
                countryCode: code,
                inviteMsg: inviteMsg,
                uniqueId: uniqueId,
                sendCompletionHandler: completionHandler
            )
        } else if userProfiles.count > 1 {
            Tracer.trackInvitePeopleExternalImportAdd(source: source.rawValue)
            let config = genDrawerConfig()
            let drawer = SelectiveDrawerController(config: config)
            self.drawer = drawer
            navigator.present(drawer, from: controller)
        } else {
            Tracer.trackInvitePeopleExternalImportAdd(source: source.rawValue)
            pushPersonalCard(
                from: controller,
                userProfile: userProfiles[0],
                inviteType: isOversea ? .email : .phone
            )
        }
    }

    func pushPersonalCard(from: UIViewController,
                          userProfile: UserProfile,
                          inviteType: InviteSendType) {
        router.pushPersonalCardVC(
            from: from,
            userProfile: userProfile,
            inviteType: inviteType
        )
    }
}
