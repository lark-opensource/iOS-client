//
//  CalendarTopStructureSelectViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/8/21.
//

import Foundation
import LarkSearchCore
import LarkModel
import LarkSDKInterface
import UniverseDesignToast
import LarkMessengerInterface
import LKCommonsLogging
import LarkContainer
import RustPB
import ServerPB
import RxSwift
import RxCocoa
import LarkRustClient
import ThreadSafeDataStructure

typealias DepartmentRecipients = ServerPB_Mails_DepartmentRecipients
typealias DepartmentRecipientResult = ServerPB_Mails_MGetDepartmentRecipientResponse
typealias LarkUser = ServerPB_Mails_LarkUser
typealias ServerRequestBase = ServerPB_Mail_entities_MailRequestBase
typealias ServerShareEmailAccount = ServerPB_Mail_entities_SharedEmailAccount
typealias MailContact = Search_V2_MailContactMeta

struct MailTopStructSelectVCParams {
    var navTitle: String
    var navTitleView: UIView?
    var chatterPicker: ChatterPicker
    var style: NewDepartmentViewControllerStyle
    var allowSelectNone: Bool
    var allowDisplaySureNumber: Bool
    var limitInfo: SelectChatterLimitInfo?
    var tracker: PickerAppReciable?
    var selectedCount: Int
    var selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)?
    var resolver: UserResolver
    var pickerDepartmentFG: Bool = false
}

enum loadStatus {
    case none
    case succeeded
    case loading
    case failed(Department)
}

final class MailTopStructureSelectViewController: TopStructureSelectViewController {
    private var selectedCount: Int
    private var mailLimitInfo: SelectChatterLimitInfo?
    private var pickerDepartmentFG: Bool
    private var selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)?
    private var mailAccount: Email_Client_V1_MailAccount?
    private static let logger = Logger.log(MailTopStructureSelectViewController.self, category: "MailPickerDepartment")
    private var localBag = DisposeBag()
    /// 被选中的部门
    private var departmentSelected: [OptionIdentifier: Option] = [:]
    /// 被选中的部门中所含的具有有效邮箱的用户
    private var selectedChatters: [OptionIdentifier: [Chatter]] = [:]
    /// 被选中的部门中所含的无有效邮箱的用户
    private var noEmailUserList: [OptionIdentifier: [Chatter]] = [:]

    private var isShowingLoading: SafeAtomic<Bool> = SafeAtomic(false, with: .unfairLock)

    private var taskStatus = BehaviorRelay<loadStatus>(value: .none)

    private var onLoadingTask: SafeAtomic<Int> = SafeAtomic(0, with: .unfairLock)

    private var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "mail.picker.dataService"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private lazy var observeScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    init(params: MailTopStructSelectVCParams) throws {
        self.selectedCount = params.selectedCount
        self.mailLimitInfo = params.limitInfo
        self.pickerDepartmentFG = params.pickerDepartmentFG
        self.selectedCallback = params.selectedCallback
        try super.init(navTitle: params.navTitle,
                       navTitleView: params.navTitleView,
                       chatterPicker: params.chatterPicker,
                       style: params.style,
                       allowSelectNone: params.allowSelectNone,
                       allowDisplaySureNumber: params.allowDisplaySureNumber,
                       limitInfo: params.limitInfo,
                       tracker: params.tracker,
                       selectedCallback: params.selectedCallback,
                       resolver: params.resolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if pickerDepartmentFG {
            setupObserver()
        }
    }

    private func setupObserver() {
        taskStatus.subscribe(onNext: { [weak self] status in
            guard let `self` = self else { return }
            switch status {
            case .none:
                break
            case .succeeded:
                self.onLoadingTask.value -= 1
                self.removeLoadingAndFinishIfNeeded(isSucceeded: true)
            case .failed(let department):
                self.onLoadingTask.value -= 1
                self.removeLoadingAndFinishIfNeeded(isSucceeded: false)
                let tips = BundleI18n.LarkContact.Mail_ContactPicker_InternetError_Toast
                asyncRunInMainThread {
                    _ = self.picker.deselect(option: department, from: nil)
                    UDToast.showFailure(with: tips, on: self.view)
                }
            case .loading:
                self.onLoadingTask.value += 1
            }
        }).disposed(by: localBag)

    }

    override func picker(_ picker: LarkSearchCore.Picker, willSelected option: Option, from: Any?) -> Bool {
        if !hasEmail(option: option), let window = self.view.window {
            if let v = option as? SearchResultType, case let .chat(meta) = v.meta {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_Contacts_NoPermission, on: window)
            } else if option is Chatter || option is SearchResultType {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_Contacts_NoBusinessEmail, on: window)
            } else {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_Contacts_CantSelectEmptyEmailAddress, on: window)
            }
        }
        if pickerDepartmentFG, let mailLimitInfo = self.mailLimitInfo {
            if let department = option as? Department, let window = self.view.window {
                var pickerSelectedCount = 0
                for selected in picker.selected {
                    if let selectedDepartment = selected as? Department {
                        pickerSelectedCount += Int(selectedDepartment.memberCount)
                    } else {
                        pickerSelectedCount += 1
                    }
                }
                let totalCount = Int(department.memberCount) + pickerSelectedCount + self.selectedCount
                let isOverLimit = totalCount > mailLimitInfo.max
                if isOverLimit {
                    let tipsContent = BundleI18n.LarkContact.Mail_ContactPicker_DeparmentLimitAddContactsManually_Toast
                    UDToast.showTips(with: tipsContent, on: window)
                    return false
                }
            }
        }
        return super.picker(picker, willSelected: option, from: from)
    }

    override func picker(_ picker: LarkSearchCore.Picker, didSelected option: Option, from: Any?) {
        if pickerDepartmentFG, let department = option as? Department {
            taskStatus.accept(.loading)
            self.handleDepartmentSelect(picker, didSelected: department, from: from)
        } else {
            super.picker(picker, didSelected: option, from: from)
        }
    }

    override func picker(_ picker: LarkSearchCore.Picker, didDeselected option: Option, from: Any?) {
        if pickerDepartmentFG, let department = option as? Department {
            guard let targetChatters = selectedChatters[department.optionIdentifier] else { return }
            departmentSelected.removeValue(forKey: department.optionIdentifier)
            selectedChatters.removeValue(forKey: department.optionIdentifier)
            noEmailUserList.removeValue(forKey: department.optionIdentifier)
        }
        super.picker(picker, didDeselected: option, from: from)
    }

    override func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        // 不可选状态的适配
        if !hasEmail(option: option) {
            return true
        }
        return super.picker(picker, disabled: option, from: from)
    }

    override func sureDidClick() {
        guard pickerDepartmentFG else {
            return super.sureDidClick()
        }
        if showLoadingIfNeeded() {
            return
        }
        self.finishSelect()
    }

    private var comfirmDate: TimeInterval = 0
    private func comfirmRepeated() -> Bool {
        let currentDate = Date().timeIntervalSince1970 * 1000
        if (currentDate - comfirmDate) > 500 {
            comfirmDate = currentDate
            return false
        }
        Self.logger.info("[Mail_Picker_Department] comfirm repeated true")
        return true
    }
    private func finishSelect() {
        guard let nav = self.navigationController else {
            return
        }
        if comfirmRepeated() { return } // 避免短时间多次触发
        let noEmailUsers = getNoEmailUsers()
        let noEmailChatterInfos = ContactPickerResult.FromOptionBuilder(resolver: userResolver).chatterInfos(from: noEmailUsers)
        let extra = noEmailChatterInfos
        // 点击完成，收起键盘
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
        selectedCallback?(nav, convertOptionToContactPickerResult(options: picker.selected, extra: extra))
    }

}

extension MailTopStructureSelectViewController {
    private func doSuperPicker(_ picker: Picker, didSelected option: Option, from: Any?) {
        asyncRunInMainThread {
            super.picker(picker, didSelected: option, from: from)
        }
    }

    private func hasEmail(option: Option) -> Bool {
        switch option {
        case let v as SearchResultType:
            if case let .chatter(meta) = v.meta { return !meta.enterpriseEmail.isEmpty }
            if case let .mailContact(meta) = v.meta { return !meta.email.isEmpty }
            if case let .chat(meta) = v.meta { return meta.enabledEmail && !meta.isCrossTenant }
        case let v as Chatter:
            return !(v.enterpriseEmail ?? "").isEmpty
        case let v as NameCardInfo:
            return !v.email.isEmpty
        case let v as Department:
            // 部门不做人数的验证，默认都可以选中
            if pickerDepartmentFG {
                return true
            }
        default:
            if pickerDepartmentFG, option.optionIdentifier.type == "mailContact" {
                return !option.optionIdentifier.id.isEmpty
            }
        }
        return false
    }

    private func showLoadingIfNeeded() -> Bool {
        guard self.onLoadingTask.value != 0 else {
            Self.logger.info("[Mail_Picker_Department] showLoadingIfNeeded NO NEED")
            return false
        }
        Self.logger.info("[Mail_Picker_Department] showLoadingIfNeeded SHOW Loading")
        asyncRunInMainThread {
            UDToast.showLoading(with: BundleI18n.LarkContact.Lark_Legacy_BaseUiLoading,
                                on: self.view,
                                disableUserInteraction: true)
        }
        isShowingLoading.value = true
        return true
    }

    private func removeLoadingAndFinishIfNeeded(isSucceeded: Bool) {
        if self.isShowingLoading.value {
            Self.logger.info("[Mail_Picker_Department] Remove loading")
            asyncRunInMainThread {
                UDToast.removeToast(on: self.view)
            }
            isShowingLoading.value = false
            if isSucceeded, self.onLoadingTask.value == 0 {
                asyncRunInMainThread {
                    self.finishSelect()
                }
            }
        }
    }

    private func convertOptionToContactPickerResult(options: [Option], extra: Any? = nil) -> ContactPickerResult {
        localBag = DisposeBag()
        var chatters: [Option] = []
        for option in options {
            let identifier = option.optionIdentifier
            switch identifier.type {
            case OptionIdentifier.Types.department.rawValue:
                if let selectedChatter = selectedChatters[identifier] {
                    chatters += selectedChatter
                }
            default: chatters.append(option)
            }
        }
        return convert(selected: chatters, extra: extra)
    }

    public func handleDepartmentSelect(_ picker: LarkSearchCore.Picker, didSelected department: Department, from: Any?) {
        Self.logger.info("[Mail_Picker_Department] handleDepartmentSelect Start to fetch Department")
        self.fetchChattersByDepartment(department: department)
            .subscribeOn(observeScheduler)
            .subscribe(onNext: { [weak self] result in
                guard let `self` = self else { return }
                Self.logger.info("[Mail_Picker_Department] handleResponse from server SUCCESS")
                self.doSuperPicker(picker, didSelected: department, from: from)
                self.handleResponse(option: department, result: result)
                self.taskStatus.accept(.succeeded)
            }, onError: { [weak self] error in
                Self.logger.info("[Mail_Picker_Department] handleResponse from server ERROR \(error)")
                self?.taskStatus.accept(.failed(department))
            }).disposed(by: localBag)
    }

    private func fetchChattersByDepartment(department: Department) -> Observable<DepartmentRecipientResult> {
        guard let rustService = try? self.resolver.resolve(assert: RustService.self),
            let departmentId = Int64(department.id)
        else { return Observable<DepartmentRecipientResult>.empty() }
        var request = ServerPB_Mails_MGetDepartmentRecipientRequest()
        request.departmentIDList = [departmentId]
        request.base = genRequestBase()
        return rustService
                .sendPassThroughAsyncRequest(request, serCommand: .mailMgetDepartmentRecipient)
    }

    func genRequestBase() -> ServerRequestBase {
        var base = ServerRequestBase()
        if let account = self.mailAccount, account.isShared {
            var shareAccount = ServerShareEmailAccount()
            shareAccount.userID = Int64(account.mailAccountID) ?? 0
            shareAccount.emailAddress = account.accountAddress
            shareAccount.emailName = account.accountName
            shareAccount.accessToken = account.accountToken
            base.sharedEmailAccount = shareAccount
        }
        return base
    }

    func buildSelectedChatters(identifier: OptionIdentifier, recipients: DepartmentRecipients) {
        selectedChatters[identifier] = convertToChatters(larkUsers: recipients.haveEmailLarkUserList)
        noEmailUserList[identifier] = convertToChatters(larkUsers: recipients.noEmailLarkUserList)
    }

    private func convertToChatters(larkUsers: [ServerPB_Mails_LarkUser]) -> [Chatter] {
        let currentLang = BundleI18n.currentLanguage.localeIdentifier.lowercased()
        var chatters: [Chatter] = []
        for user in larkUsers {
            let chatter = Chatter.placeholderChatter()
            chatter.id = String(user.userID)
            chatter.enterpriseEmail = user.emailAddress
            chatter.avatarKey = user.avatarURL
            if let i18NName = user.i18NName[currentLang], !i18NName.isEmpty {
                chatter.name = user.i18NName[currentLang] ?? ""
            } else {
                chatter.name = user.defaultName
            }
            chatters.append(chatter)
        }
        return chatters
    }

    public func getNoEmailUsers() -> [Chatter] {
        var noEmailChatters: [Chatter] = []
        for chatters in self.noEmailUserList.values {
            noEmailChatters += chatters
        }
        return noEmailChatters
    }

    private func handleResponse(option: Option, result: DepartmentRecipientResult) {
        guard let department = option as? Department,
              let departmentId = Int64(department.id),
              let recipients = result.departmentRecipientMap[departmentId]
        else { return }
        self.buildSelectedChatters(identifier: option.optionIdentifier, recipients: recipients)
        self.departmentSelected[option.optionIdentifier] = option
    }

}

// 邮件组管理
final class MailGroupManagerStructureSelectViewController: TopStructureSelectViewController {
    override func picker(_ picker: LarkSearchCore.Picker, willSelected option: Option, from: Any?) -> Bool {
        // TODO: 选择判断逻辑
        return super.picker(picker, willSelected: option, from: from)
    }

    override func picker(_ picker: Picker, didSelected option: Option, from: Any?) {

        super.picker(picker, didSelected: option, from: from)
    }

    override func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        // TODO: 选择判断逻辑
        return super.picker(picker, disabled: option, from: from)
    }
}

extension Chatter {
    /// 构造一个空的Chatter，参数太多了写一个方法。
    static func placeholderChatter() -> Chatter {
        return Chatter(
            id: "",
            isAnonymous: false,
            isFrozen: false,
            name: "",
            localizedName: "",
            enUsName: "",
            namePinyin: "",
            alias: "",
            anotherName: "",
            nameWithAnotherName: "",
            type: .unknown,
            avatarKey: "",
            avatar: .init(),
            updateTime: .zero,
            creatorId: "",
            isResigned: false,
            isRegistered: false,
            description: .init(),
            withBotTag: "",
            canJoinGroup: false,
            tenantId: "",
            workStatus: .init(),
            majorLanguage: "",
            profileEnabled: false,
            focusStatusList: [],
            chatExtra: nil,
            accessInfo: .init(),
            email: "",
            doNotDisturbEndTime: .zero,
            openAppId: "",
            acceptSmsPhoneUrgent: false)
    }
}

func asyncRunInMainThread(_ block: @escaping () -> Void) {
    if Thread.current == Thread.main {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
