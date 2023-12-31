//
//  ContactBatchInvitePresenter.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/30.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkAlertController
import EENavigator
import AsyncComponent
import LarkRustClient
import LarkFoundation
import LKCommonsLogging
import UniverseDesignToast
import LarkAddressBookSelector
import LKMetric
import LarkMessengerInterface
import Homeric
import LarkSDKInterface
import LarkContainer

/// 批量导入失败的原因及名单
struct FailedTypeResult {
    let reason: String
    let names: [String]
}

/// 通讯录批量导入结果处理的代理
final class ContactBatchInvitePresenter: NSObject, UITableViewDataSource, UITableViewDelegate, SelectContactListControllerDelegate, UserResolverWrapper {

    static let logger = Logger.log(ContactBatchInvitePresenter.self, category: "LarkContact.ContactBatchInvitePresenter")
    static let timeout: Int = 20
    static let omitLength: Int = 5
    private var failedResults: [FailedTypeResult] = []
    private var cellHeights: [CGFloat] = []
    private let disposeBag = DisposeBag()
    private let memberInviteAPI: MemberInviteAPI
    private let monitor = InviteMonitor()
    private let sourceScenes: MemberInviteSourceScenes
    private let departments: [String]
    private var addressBookLoadStart: TimeInterval = 0
    // 容错控制
    private let tolerantControl: VerificationBaseViewModel
    weak var drawer: SelectiveDrawerController?
    var userResolver: LarkContainer.UserResolver

    init(isOversea: Bool,
         departments: [String],
         memberInviteAPI: MemberInviteAPI,
         sourceScenes: MemberInviteSourceScenes,
         resolver: UserResolver) {
        self.memberInviteAPI = memberInviteAPI
        self.departments = departments
        self.sourceScenes = sourceScenes
        self.userResolver = resolver
        self.tolerantControl = VerificationBaseViewModel(isOversea: isOversea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handle(contactModels: [AddressBookContact],
                type: ContactContentType,
                controller: SelectContactListController) {
        func sendInviteRequest(inviteInfos: [String], names: [String]) {
            var inviteWay: MemberInviteAPI.InviteWay = .email
            switch type {
            case .email:
                inviteWay = .email
            case .phone:
                inviteWay = .phone
            }
            let hud = UDToast.showLoading(on: controller.view, disableUserInteraction: true)
            memberInviteAPI.sendAddMemberInviteRequest(
                timeout: ContactBatchInvitePresenter.timeout,
                inviteInfos: inviteInfos,
                names: names,
                inviteWay: inviteWay,
                departments: departments).subscribe(onNext: { [weak self] (result) in
                    hud.remove()
                    self?.handleResponse(response: result, inviteNumber: inviteInfos.count, selectorController: controller)
                }, onError: { (error) in
                    hud.remove()
                    guard let wrappedError = error as? WrappedError,
                        let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError else { return }
                    ContactBatchInvitePresenter.logger.info("sendAddMemberInviteRequest.error >>> \(rcError.localizedDescription)")
                    switch rcError {
                    case .businessFailure(let buzErrorInfo):
                        UDToast.showTips(with: buzErrorInfo.displayMessage, on: controller.view)
                    default: break
                    }
                }, onDisposed: {
                    hud.remove()
                }).disposed(by: disposeBag)
        }

        var inviteInfos: [String] = []
        var names: [String] = []
        // 本地校验不通过的联系人名称
        var localVerifyFailContacts: [String] = []
        contactModels.forEach { (contact) in
            var info = ""
            switch type {
            case .email:
                info = tolerantControl.getPureEmail(contact.email ?? "")
                if !tolerantControl.verifyEmailValidation(info) {
                    localVerifyFailContacts.append(contact.fullName)
                    return
                }
            case .phone:
                let (countryCode, phoneNumber) = tolerantControl.getDisassemblePhoneNumber(content: contact.phoneNumber ?? "")
                info = "\(countryCode)\(phoneNumber)"
                if !tolerantControl.verifyPhoneNumberValidation(phoneNumber, countryCode: countryCode) {
                    localVerifyFailContacts.append(contact.fullName)
                    return
                }
            }
            // 去重
            if inviteInfos.contains(info) || info.isEmpty { return }
            inviteInfos.append(info)
            names.append(contact.fullName)
        }

        if localVerifyFailContacts.isEmpty {
            sendInviteRequest(inviteInfos: inviteInfos, names: names)
        } else {
            // 如果存在本地校验不通过的联系人，则先向用户确认邀请行为
            let alertController = LarkAlertController()
            let channelName = type == .email ?
                BundleI18n.LarkContact.Lark_Invitation_AddMembersChannelEmail :
                BundleI18n.LarkContact.Lark_Invitation_AcceptInvtationVerifyChannelPhone
            let contactSen: String = {
                if localVerifyFailContacts.count > ContactBatchInvitePresenter.omitLength {
                    return localVerifyFailContacts[0...ContactBatchInvitePresenter.omitLength - 1].joined(separator: CopyWritingLogic.contactSplitter())
                } else {
                    return localVerifyFailContacts.joined(separator: CopyWritingLogic.contactSplitter())
                }
            }()
            let title: String
            if localVerifyFailContacts.count == 1 {
                title = BundleI18n.LarkContact.Lark_Invitation_MembersBatchInvalidFormatOnlyOne(contactSen, channelName)
            } else {
                title = BundleI18n.LarkContact.Lark_Invitation_MembersBatchInvalidFormat(
                    contactSen,
                    localVerifyFailContacts.count,
                    channelName)
            }
            alertController.setContent(text: title)
            alertController.addCancelButton(dismissCompletion: {
                Tracer.trackMembersBatchFormatDialogCancelClick()
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Invitation_MembersBatchInvalidFormatContinue, dismissCompletion: {
                Tracer.trackMembersBatchFormatDialogContinueClick()
                if inviteInfos.isEmpty {
                    controller.navigationController?.popViewController(animated: true)
                    return
                }
                sendInviteRequest(inviteInfos: inviteInfos, names: names)
            })
            Tracer.trackMembersBatchFormatFeedbackDialogShow()
            navigator.present(alertController, from: controller)
        }
    }

    private lazy var headerView: UIView = {
        let view = UIView()
        view.addSubview(titleLabel)
        view.addSubview(tipLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(24)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(7)
            make.left.right.equalToSuperview().inset(16)
        }
        return view
    }()

    private lazy var footerView: UIControl = {
        let view = UIControl()
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(doneLabel)
        doneLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(52)
        }
        view.layer.borderColor = UIColor.ud.N1000.withAlphaComponent(0.3).cgColor
        view.layer.borderWidth = 0.5
        view.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            Tracer.trackMembersBatchFeedbackDialogConfirmClick()
            self?.drawer?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        return view
    }()

    private lazy var doneLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.ud.N00
        label.textColor = UIColor.ud.colorfulBlue
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.text = BundleI18n.LarkContact.Lark_Invitation_MembersBatchConfirmButton
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.text = BundleI18n.LarkContact.Lark_Invitation_MembersBatchFeedHasFailedTitle
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N1000
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
}

// MARK: - SelectContactListControllerDelegate
extension ContactBatchInvitePresenter {
    /// 搜索联系人结果变化
    func onContactSearchChanged(filteredContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController) {}

    /// 多选模式下，选中联系人发生变化
    func selectedContactsChanged(selectedContacts: [AddressBookContact],
                                 contentType: ContactContentType,
                                 from: UIViewController) {
        guard let vc = from as? SelectContactListController else { return }
        if selectedContacts.isEmpty {
            vc.rightItemTitle = BundleI18n.LarkContact.Lark_Invitation_MembersBatchContactsSendButton
        } else {
            vc.rightItemTitle = "\(BundleI18n.LarkContact.Lark_Invitation_MembersBatchContactsSendButton)(\(selectedContacts.count))"
        }
    }

    /// 多选模式下选择联系人
    func didSelectContactInMultipleType(contact: AddressBookContact,
                                        contentType: ContactContentType,
                                        toSelected: Bool,
                                        from: UIViewController) {
        if toSelected {
            Tracer.trackMembersBatchChooseClick()
        } else {
            Tracer.trackMembersBatchChooseClickCancel()
        }
    }

    /// 点击右上角导航按钮
    func didTapNaviBarRightItem(selectedContacts: [AddressBookContact],
                                contentType: ContactContentType,
                                from: UIViewController) {
        guard let vc = from as? SelectContactListController, !selectedContacts.isEmpty else { return }
        Tracer.trackMembersBatchSendClick()
        handle(contactModels: selectedContacts, type: contentType, controller: vc)
    }

    /// 点击选择列表的indexView
    func didSelectSectionIndexView(section: Int,
                                   contentType: ContactContentType,
                                   from: UIViewController) {}

    /// vc 生命周期回调
    func onLifeCycleEvent(type: LifeCycleEventType) {
        if case .viewDidLoad = type {
            Tracer.trackImportContactsChooseShow(source: sourceScenes)
            // Record contacts loadCost metric data
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
        // 异步加载用户标签
        var mobiles: [String] = []
        var emails: [String] = []
        var cp2contacts: [String: [AddressBookContact]] = [:]
        allContacts.forEach { (contact) in
            switch contact.contactPointType {
            case .email:
                let email = tolerantControl.getPureEmail(contact.email ?? "")
                if tolerantControl.verifyEmailValidation(email), !emails.contains(email) {
                    emails.append(email)
                    if cp2contacts[email] != nil {
                        cp2contacts[email]?.append(contact)
                    } else {
                        cp2contacts[email] = [contact]
                    }
                }
            case .phone:
                let (countryCode, phoneNumber) = tolerantControl.getDisassemblePhoneNumber(content: contact.phoneNumber ?? "")
                let mobile = countryCode + phoneNumber
                if tolerantControl.verifyPhoneNumberValidation(phoneNumber, countryCode: countryCode), !mobiles.contains(mobile) {
                    mobiles.append(mobile)
                    if cp2contacts[mobile] != nil {
                        cp2contacts[mobile]?.append(contact)
                    } else {
                        cp2contacts[mobile] = [contact]
                    }
                }
            }
        }
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_CONTACT_CONTACT_IS_LINKED_TO_USER,
            indentify: String(startTimeInterval)
        )
        return memberInviteAPI
            .fetchCpActiveFlags(mobiles: mobiles, emails: emails)
            .do(onNext: { [weak self] (_) in
                self?.monitor.endEvent(
                    name: Homeric.UG_CONTACT_CONTACT_IS_LINKED_TO_USER,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true"],
                    extra: [:]
                )
            }, onError: { [weak self] (error) in
                guard let apiError = error.underlyingError as? APIError else { return }
                self?.monitor.endEvent(
                    name: Homeric.UG_CONTACT_CONTACT_IS_LINKED_TO_USER,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "false",
                               "error_code": apiError.code],
                    extra: ["error_msg": apiError.serverMessage]
                )
            })
            .flatMap { (cp2active) -> Observable<[ContactExtraInfo]> in
                let valid = cp2contacts.filter { (kv) -> Bool in
                    return cp2active.keys.contains(kv.key)
                }.map { (kv) -> [ContactExtraInfo] in
                    return kv.value.map { (contact) -> ContactExtraInfo in
                        return ContactExtraInfo(
                            contact: contact,
                            contactTag: ContactTag(tagContent: BundleI18n.LarkContact.Lark_InviteMembers_ImportFromContacts_FeishuUser())
                        )
                    }
                }
                return .just(valid.reduce([], { (result, contacts) -> [ContactExtraInfo] in
                    var res: [ContactExtraInfo] = result
                    res.append(contentsOf: contacts)
                    return res
                }))
            }
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
extension ContactBatchInvitePresenter {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return failedResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ContactImportPanelCell? = tableView.dequeueReusableCell(withIdentifier: drawer?.cellReuseIdentifier ??
            NSStringFromClass(ContactImportPanelCell.self)) as? ContactImportPanelCell
        let failedResult = failedResults[indexPath.row]
        let contactsSen = failedResult.names.joined(separator: CopyWritingLogic.contactSplitter())
        cell?.setContent("\(failedResult.reason)\n\(contactsSen)")
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
}

private extension ContactBatchInvitePresenter {
    func genDrawerConfig(by vc: UIViewController) -> DrawerConfig {
        var offset: CGFloat = 0
        if let safeAreaInsets = vc.view.window?.safeAreaInsets {
            offset = safeAreaInsets.bottom
        }
        let config = DrawerConfig(cornerRadius: 6.0,
                                  thresholdOffset: 120,
                                  maxContentHeight: UIScreen.main.bounds.height - 78,
                                  cellType: ContactImportPanelCell.self,
                                  tableViewDataSource: self,
                                  tableViewDelegate: self,
                                  headerView: headerView,
                                  footerView: footerView,
                                  headerViewHeight: 92,
                                  footerViewHeight: 52 + offset)
        return config
    }

    func calculateCellHeights(failedResults: [FailedTypeResult]) {
        cellHeights = []
        cellHeights = failedResults.map { (result) -> CGFloat in
            let contactsSen = result.names.joined(separator: CopyWritingLogic.contactSplitter())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6.0
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left
            let content = "\(result.reason)\n\(contactsSen)"
            let contentAttr = NSMutableAttributedString(string: content)
            contentAttr.addAttributes([.paragraphStyle: paragraphStyle,
                                       .font: UIFont.systemFont(ofSize: 16, weight: .regular)],
                                      range: NSRange(location: 0, length: content.count))
            let limitSize = CGSize(width: UIScreen.main.bounds.width - 54, height: CGFloat.greatestFiniteMagnitude)
            let size = contentAttr.componentTextSize(for: limitSize, limitedToNumberOfLines: Int.max)
            return size.height + 22
        }
    }

    func handleResponse(response: MemberInviteAPI.AddMemberResult, inviteNumber: Int, selectorController: SelectContactListController) {
        guard let from = selectorController.navigationController else { return }
        selectorController.popSelf(animated: true, dismissPresented: false, completion: { [weak self] in
            guard let `self` = self else { return }
            self.failedResults = []
            if response.isSuccess {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkContact.Lark_Invitation_MembersBatchFeedSucTitle)
                alertController.setContent(text: BundleI18n.LarkContact.Lark_Invitation_MembersBatchFeedSucContent(inviteNumber, inviteNumber))
                alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Invitation_MembersBatchConfirmButton)
                Tracer.trackMembersBatchFeedbackDialogShow(result: "suc")
                self.navigator.present(alertController, from: from)
            } else {
                var typeResult: [String: [String]] = [:]
                // merge names
                for context in response.failContexts {
                    let reason = context.errorMsg
                    if var names = typeResult[reason] {
                        names.append(context.name)
                        typeResult[context.errorMsg] = names
                    } else {
                        typeResult[context.errorMsg] = [context.name]
                    }
                }
                for (reason, names) in typeResult {
                    self.failedResults.append(FailedTypeResult(reason: reason, names: names))
                }

                // update tip text
                let successInviteNumber = inviteNumber - response.failContexts.count
                self.tipLabel.text = BundleI18n.LarkContact.Lark_Invitation_MembersBatchFeedHasFailedContent(inviteNumber, successInviteNumber)

                // calculate dynamic cellHeight
                self.calculateCellHeights(failedResults: self.failedResults)

                // present drawer
                let config = self.genDrawerConfig(by: selectorController)
                let drawer = SelectiveDrawerController(config: config)
                self.drawer = drawer
                Tracer.trackMembersBatchFeedbackDialogShow(result: response.failContexts.count == inviteNumber ? "fail" : "mixed")
                self.navigator.present(drawer, from: from)
            }
        })
    }
}
