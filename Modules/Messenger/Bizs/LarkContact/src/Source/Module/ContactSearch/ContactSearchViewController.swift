//
//  ContactSearchViewController.swift
//  LarkContact
//
//  Created by SuPeng on 5/13/19.
//

import Foundation
import UIKit
import Homeric
import LarkUIKit
import RxSwift
import LarkModel
import LarkCore
import LKCommonsLogging
import LKCommonsTracker
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkSearchCore
import LarkAlertController
import LarkFeatureGating
import RustPB
import LarkContainer

final class ContactSearchViewController: UIViewController, ContactSelect, ContactSearchable, UserResolverWrapper {

    static let logger = Logger.log(ContactSearchViewController.self, category: "Module.IM.Message")

    var isPublic: Bool = false
    var selectChannel: SelectChannel { return .search }

    private let searchAPI: SearchAPI
    private let passportUserService: PassportUserService
    var userResolver: LarkContainer.UserResolver
    private let serverNTPTimeService: ServerNTPTimeService
    private let router: ContactSearchViewControllerRouter

    /// 勿扰模式检查
    lazy var checkInDoNotDisturb: ((Int64) -> Bool) = { [weak self] time -> Bool in
        guard let `self` = self else { return false }
        return self.serverNTPTimeService.afterThatServerTime(time: time)
    }

    private let emailRegexStr = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    lazy var emailRegex = NSPredicate(format: "SELF MATCHES %@", emailRegexStr)

    private var lastestSearchText: String = ""
    internal var results: [SearchResultType] = []
    private(set) var chattersIdsInChat: Set<String> = []

    internal lazy var resultView: SearchResultView = {
        return SearchResultView()
    }()
    private let mailSuggestView = ContactSearchMailSuggestionView()

    private let disposeBag = DisposeBag()
    private var bindDisposeBag = DisposeBag()

    var switchToolTitle: ((Bool) -> Void)?

    private lazy var vm: SearchSimpleVM<SearchResultType> = self.makeSearchSimpleVM()

    // TODO: 打通继承session
    init(searchAPI: SearchAPI,
         serverNTPTimeService: ServerNTPTimeService,
         router: ContactSearchViewControllerRouter, resolver: UserResolver) throws {
        self.searchAPI = searchAPI
        self.serverNTPTimeService = serverNTPTimeService
        self.router = router
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)

        super.init(nibName: nil, bundle: nil)

    }
    static let defaultPagecount = 30

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.N00

        self.view.addSubview(mailSuggestView)
        mailSuggestView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        mailSuggestView.addTarget(self, action: #selector(addMailByClickingSuggestion), for: .touchUpInside)
        mailSuggestView.isHidden = true

        // NOTE: must set delegate before reloadData, else the result top have 35 pixel padding..
        resultView.tableview.delegate = self
        resultView.tableview.dataSource = self
        resultView.tableview.lu.register(cellSelf: ContactSearchTableViewCell.self)
        resultView.tableview.separatorStyle = .none
        self.view.addSubview(resultView)
        resultView.snp.makeConstraints({ make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(mailSuggestView.snp.bottom)
        })

        self.bindResultView().disposed(by: self.bindDisposeBag)

        dataSource.getSelectedObservable
            .map { _ in }
            .subscribe(onNext: { [weak self] () in
                self?.resultView.tableview.reloadData()
            })
            .disposed(by: disposeBag)

        if let parent = parent as? LKContactViewController {
            let textField = parent.searchFieldWrapperView?.searchUITextField
            // hide search icon
            textField?.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 36))
            if configuration.needSearchMail {
                textField?.placeholder = BundleI18n.Calendar.Calendar_Edit_AddGuestPlaceholder
                textField?.addTarget(self, action: #selector(addMailByClickingEnter), for: .editingDidEndOnExit)
            }
        }
    }

    /// 根据self.configuration生成SearchVM
    private func makeSearchSimpleVM() -> SearchSimpleVM<SearchResultType> {
        let configuration = self.configuration
        func makeSource(searchAPI: SearchAPI) -> SearchSource {
            var authPermissions: [RustPB.Basic_V1_Auth_ActionType] {
                if configuration.checkInvitePermission == true {
                    // 是否需要判断密聊权限
                    if userResolver.fg.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate"),
                       configuration.isCryptoModel {
                        return [.inviteSameCryptoChat]
                    }
                    if configuration.isCrossTenantChat {
                        return [.inviteSameCrossTenantChat]
                    }
                    return [.inviteSameChat]
                }
                return []
            }

            let scene: SearchScene = configuration.chooseChatterOnly ? .addChatChatters : .searchInCalendarScene
            var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(scene))
            maker.needSearchOuterTenant = configuration.needSearchOuterTenant
            maker.authPermissions = authPermissions
            maker.doNotSearchResignedUser = true // 测试addChatChatters场景搜索不出来离职的，只有大搜能搜索出来
            // 默认选中群里的所有人。使用场景为：群添加人，能搜索到这个人，但已经选中在群里，不需要再添加了
            // Rust会返回meta.inChatIds来标记这个人在哪些群里
            if let chatID = configuration.forceSelectedChattersInChatId {
                maker.inChatID = chatID
            }
            if configuration.eventSearchMeetingGroup {
                maker.includeMeetingGroup = true
            }
            return maker.makeAndReturnProtocol()
        }
        let source = makeSource(searchAPI: searchAPI)
        let listvm = SearchListVM(
            source: source, pageCount: Self.defaultPagecount, compactMap: { [weak self] (item: SearchItem) -> SearchResultType? in
                guard let self = self, let result = item as? Search.Result else { return nil }
                let filter = { () -> Bool in
                    if result.type == .chatter {
                        return configuration.filterChatter?(result.id) ?? true
                    }
                    if result.type == .mailContact {
                        return configuration.needSearchMail
                    }
                    return true
                }
                return filter() ? result : nil
            })
        return SearchSimpleVM(result: listvm)
    }

    private func checkMailMatchText(text: String) {
        let validEmailAddrs = extractMailAddrs(from: text)
        if !validEmailAddrs.isEmpty {
            var text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if validEmailAddrs.count == 1 {
                text = BundleI18n.Calendar.Calendar_CalMail_InviteEmail + text
            } else {
                text = BundleI18n.Calendar.Calendar_EmailGuest_AddXEmailsMobile(validEmailAddrs.count, text)
            }
            mailSuggestView.updateText(text)
            mailSuggestViewUpdate(isHidden: false)
        } else {
            mailSuggestViewUpdate(isHidden: true)
        }
    }

    private func mailSuggestViewUpdate(isHidden: Bool) {
        var hidden = isHidden
        if !configuration.needSearchMail {
            hidden = true
        }

        mailSuggestView.isHidden = hidden
        if hidden {
            mailSuggestView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(0)
            }
        } else {
            mailSuggestView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(54)
            }
        }
    }

    func reloadData() {
        resultView.tableview.reloadData()
    }

    func search(text: String) {
        vm.query.text.accept(text)

        if configuration.needSearchMail {
            self.checkMailMatchText(text: text)
        }
    }

    private func extractMailAddr(from text: String) -> String? {
        guard let leftBracketIndex = text.range(of: "<")?.lowerBound else {
            return emailRegex.evaluate(with: text) ? text : nil
        }
        guard let rightBracketIndex = text.range(of: ">")?.lowerBound else {
            return nil
        }
        guard leftBracketIndex < text.endIndex,
            rightBracketIndex <= text.endIndex,
            leftBracketIndex < rightBracketIndex else {
            return nil
        }
        let addrText = String(text[text.index(after: leftBracketIndex) ..< rightBracketIndex])
            .trimmingCharacters(in: .whitespaces)
        return emailRegex.evaluate(with: addrText) ? addrText : nil
    }

    private func extractMailAddrs(from text: String) -> [String] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else {
            return []
        }

        let separators: CharacterSet
        if text.contains("<") {
            // 分隔符：全角/半角分号，全角/半角逗号
            separators = CharacterSet(charactersIn: ";；,，")
        } else {
            // 分隔符：全角/半角分号，全角/半角逗号，全角/半角空格
            separators = CharacterSet(charactersIn: ";；,， 　")
        }
        let texts = text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let validAddrs = texts.compactMap(extractMailAddr(from:))
        guard texts.count == validAddrs.count else {
            return []
        }

        return validAddrs
    }

    private func addMailFromSuggesttion() {
        let addrs = extractMailAddrs(from: vm.query.text.value)
        guard !addrs.isEmpty else { return }
        addrs.forEach(dataSource.addMail(mail:))
        if let parent = parent as? LKContactViewController {
            parent.searchFieldWrapperView?.searchUITextField.text = ""
            self.search(text: "")
        }
    }

    @objc
    private func addMailByClickingEnter() {
        addMailFromSuggesttion()
        Tracker.post(TeaEvent(Homeric.CAL_EMAIL_GUEST, params: ["action_type": "enter"]))
    }

    @objc
    private func addMailByClickingSuggestion() {
        addMailFromSuggesttion()
        Tracker.post(TeaEvent(Homeric.CAL_EMAIL_GUEST, params: ["action_type": "invite"]))
    }

    // 判断是否是外部成员
    private func isExternalChatter(resultItem: SearchResultType) -> Bool {
        let currentTenantID = passportUserService.userTenant.tenantID
        if case let .chatter(chatterMeta) = resultItem.meta {
            guard chatterMeta.tenantID == currentTenantID else {
                return true
            }
        }
        return false
    }

    var listState: SearchListStateCases?
}
extension ContactSearchViewController: SearchResultViewListBindDelegate {
    var listvm: ListVM { vm.result }
    typealias Item = SearchResultType

    func showPlaceholder(state: ListVM.State) {
        self.view.isHidden = true
        self.lastestSearchText = ""
    }
    func hidePlaceholder(state: ListVM.State) {
        self.view.isHidden = false
    }
    func on(state: ListVM.State, results: [Item], event: ListVM.Event) {
        self.lastestSearchText = state.lastestRequest?.query ?? ""
        func convert(results: [Item]) -> [SearchResultType] {
            // NOTE: concat有一些额外的数据过滤和mail视图更新。可能需要进一步梳理。
            var needHideMailSuggestion = false
            for result in results {
                if case .chatter(let meta) = result.meta {
                    if meta.isInChat {
                        // chat是创建时不会动的。所以这里只更新在chat里的chatter，可以不用管清理.
                        self.chattersIdsInChat.update(with: meta.id)
                    }

                    if !needHideMailSuggestion && meta.mailAddress.caseInsensitiveCompare(state.lastestRequest?.query ?? "") == .orderedSame {
                        needHideMailSuggestion = true
                    }
                }
            }
            if needHideMailSuggestion { self.mailSuggestViewUpdate(isHidden: true) }
            return results
        }
        if !self.results.isEmpty, case let .success(req: _, appending: appending?) = event {
            self.results.append(contentsOf: convert(results: appending))
        } else {
            self.results = convert(results: state.results)
        }
        self.resultView.tableview.reloadData()
    }
    var searchLocation: String { "choose" }
}

extension ContactSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        resultView.tableview.deselectRow(at: indexPath, animated: true)
        let item = results[indexPath.row]
        guard
            !dataSource.forceSelectedChatterIds.contains(item.id),
            !chattersIdsInChat.contains(item.id),
            let cell = tableView.cellForRow(at: indexPath) as? ContactSearchTableViewCell else  {
            return
        }

        func showAlert() {
            let alert = LarkAlertController()
            alert.setContent(text: configuration.limitTips ?? "")
            alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
            present(alert, animated: true, completion: nil)
        }

        if item.type == .chat {
            if dataSource.containChats(chatId: item.id) {
                dataSource.removeChat(chatId: item.id)
            } else if configuration.maxSelectedNum > dataSource.selectedContactItems().count {
                if case let .chat(chatMeta) = item.meta,
                    chatMeta.isMeeting,
                    configuration.eventSearchMeetingGroup {
                    if let window = self.view.window {
                        UDToast.showTips(with: BundleI18n.Calendar.Calendar_Meeting_AddToastMobile, on: window)
                    }
                    dataSource.addMeetingGroup(groupChatId: item.id)
                } else {
                    dataSource.addChat(chatId: item.id)
                }
            } else {
                showAlert()
            }
        } else if item.type == .chatter {

            var chatterInfo = SelectChatterInfo(ID: item.id)
            chatterInfo.name = item.title.string
            chatterInfo.avatarKey = item.avatarKey
            chatterInfo.isExternal = self.isExternalChatter(resultItem: item)
            // 当前在创建公开群 + 选中外部联系人
            if chatterInfo.isExternal, self.isPublic, let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_Chat_Add_Member_PublicChatAddExternalUser_ErrrorTip, on: window)
                return
            }
            if case let .chatter(chatterMeta) = item.meta,
                let searchDeniedReason = chatterMeta.deniedReason.first?.value {
                if let window = self.view.window {
                    if searchDeniedReason == .beBlocked || searchDeniedReason == .blocked {
                        let blockTip = configuration.contactOptPickerModel?.blockTip ?? BundleI18n.LarkContact.Lark_NewContacts_CantAddToGroupBlockedOthersTip
                        let beBlockTip = configuration.contactOptPickerModel?.beBlockedTip ?? BundleI18n.LarkContact.Lark_NewContacts_CantAddToGroupBlockedTip
                        let tips = searchDeniedReason == .blocked ? blockTip : beBlockTip
                        UDToast.showTips(with: tips, on: window)
                        return
                    }
                    switch searchDeniedReason {
                    case .sameTenantDeny:
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Groups_NoPermissionToAdd, on: window)
                        return
                    case .cryptoChatDeny:
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Chat_CantSecretChatWithUserSecurityRestrict, on: window)
                        return
                    case .targetPrivacySetting, .externalCoordinateCtl:
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission, on: window)
                        return
                    @unknown default:
                        break
                    }
                }

                let deniedReason = RustPB.Basic_V1_Auth_DeniedReason(rawValue: searchDeniedReason.rawValue)
                let hasOUDeniedReason = (searchDeniedReason == .sameTenantDeny)
                let hasContactDeniedReason = (searchDeniedReason == .beBlocked ||
                    searchDeniedReason == .blocked ||
                    searchDeniedReason == .noFriendship)
                let hasCryptoDeniedReason = searchDeniedReason == .cryptoChatDeny
                let hasCoordinateCtl = searchDeniedReason == .externalCoordinateCtl
                    || searchDeniedReason == .targetExternalCoordinateCtl
                if hasOUDeniedReason || hasContactDeniedReason
                    || hasCryptoDeniedReason || hasCoordinateCtl {
                    chatterInfo.deniedReason = deniedReason
                }
            }
            if dataSource.containChatter(chatterId: item.id) {
                dataSource.removeChatter(chatterInfo)
            } else if configuration.maxSelectedNum > dataSource.selectedContactItems().count {
                Tracer.trackCreateGroupSelectMembers(.search)
                dataSource.addChatter(chatterInfo)
            } else {
                let selectedUnauthorizedNum = dataSource.selectedChatters().filter { $0.isNotFriend }.count
                if configuration.maxUnauthorizedSelectedNum > selectedUnauthorizedNum {
                    Tracer.trackCreateGroupSelectMembers(.search)
                    dataSource.addChatter(chatterInfo)
                } else {
                    let alert = LarkAlertController()
                    alert.setContent(text: BundleI18n.LarkContact.Lark_NewContacts_PermissionRequestSelectUserMax)
                    alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
                    present(alert, animated: true, completion: nil)
                }
            }
            // 创建群组时选中为未授权联系人要改变confirmButtonTittle
            let hasSelectedUnauthContacts = !dataSource.selectedChatters().map { $0.isNotFriend }.isEmpty
            switchToolTitle?(hasSelectedUnauthContacts)
        } else if item.type == .mailContact {
            if dataSource.containMail(mail: item.id) {
                dataSource.removeMail(mail: item.id)
            } else if configuration.maxSelectedNum > dataSource.selectedContactItems().count {
                dataSource.addMail(mail: item.id)
            } else {
                showAlert()
            }
        }

        switch self.style {
        case .multi:
            break
        case .single(let style):
            switch style {
            case .callback:
                contactPicker.finishSelect()
            case .defaultRoute:
                if item.type == .chat {
                    router.didSelectWithChat(self, chatId: item.id)
                } else if item.type == .chatter {
                    if case let .chatter(chatterMeta) = item.meta {
                        router.didSelectWithChatter(self, chatterId: chatterMeta.id, type: chatterMeta.type)
                    }
                }
            case .callbackWithReset:
                contactPicker.finishSelect(reset: true, extra: selectChannel)
            }
        case .singleMultiChangeable:
            switch singleMultiChangeableStatus {
            case .multi:
                break
            case .single:
                contactPicker.finishSelect()
            }
        }
        var chatterInfo = SelectChatterInfo(ID: item.id)
        chatterInfo.name = item.title.string
        chatterInfo.avatarKey = item.avatarKey
        // TODO: MAIL_CONTACT
        let isSelected = dataSource.selectedChats().contains(item.id) || dataSource.selectedChatters().contains(chatterInfo)
        cell.updateSelected(isSelected: isSelected)

        if case .single(style: .callbackWithReset) = self.style {
            return
        }
        /// mobilee 群加人搜索 清空textfiledss
        if let parent = parent as? LKContactViewController {
            parent.searchFieldWrapperView?.searchUITextField.text = ""
            self.search(text: "")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let identifier = String(describing: ContactSearchTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ContactSearchTableViewCell else {
            return UITableViewCell()
        }
        let item = results[row]
        let isForceSelected = chattersIdsInChat.contains(item.id) || dataSource.forceSelectedChatterIds.contains(item.id)
        let chatterInfo = SelectChatterInfo(ID: item.id)
        var canSelect = true
        if case let .chatter(chatterMeta) = item.meta,
            let searchDeniedReason = chatterMeta.deniedReason.first?.value {
            let contactAuthNeedBlock = (searchDeniedReason == .beBlocked || searchDeniedReason == .blocked)
            let isExternalCoordinateCtl = searchDeniedReason == .externalCoordinateCtl || searchDeniedReason == .targetExternalCoordinateCtl
            let hasCryptoDeniedReason = searchDeniedReason == .cryptoChatDeny
            let OUAuthNeedBlock = (searchDeniedReason == .sameTenantDeny)
            if contactAuthNeedBlock || OUAuthNeedBlock
                || hasCryptoDeniedReason || isExternalCoordinateCtl {
                canSelect = false
            }
        }
        let isSelected = dataSource.selectedChats().contains(item.id) || dataSource.selectedChatters().contains(chatterInfo) || dataSource.selectedMails().contains(item.id)
        cell.setContent(searchResult: item,
                        searchText: lastestSearchText,
                        currentTenantId: passportUserService.userTenant.tenantID,
                        hideCheckBox: isSingleStatus,
                        enableCheckBox: !isForceSelected && canSelect,
                        isSelected: (isSelected || isForceSelected) && canSelect,
                        checkInDoNotDisturb: self.checkInDoNotDisturb,
                        needShowMail: configuration.needSearchMail,
                        currentUserType: Account.userTypeFromPassportUserType(passportUserService.user.type),
                        isPublic: self.isPublic,
                        canSelect: canSelect)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let item = results[row]
        return ContactSearchTableViewCell.getCellHeight(searchResult: item, needShowMail: configuration.needSearchMail)
    }
}
