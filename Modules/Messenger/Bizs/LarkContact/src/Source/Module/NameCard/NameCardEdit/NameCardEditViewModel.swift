//
//  NameCardEditViewModel.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/13.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB
import LarkSDKInterface
import LKCommonsLogging
import LarkUIKit
import LarkFeatureGating
import LarkLocalizations
import LarkAccountInterface
import LarkContainer
import AppReciableSDK
import LarkSetting

extension NSNotification.Name {
    static let LKNameCardEditNotification = NSNotification.Name("LKNameCardEditNotification")
    static let LKNameCardDeleteNotification = NSNotification.Name("LKNameCardDeleteNotification")
    static let LKNameCardNoPermissionNotification = NSNotification.Name("LKNameCardNoPermissionNotification")
}

final class NameCardEditViewModel {
    static let log = Logger.log(NameCardEditViewModel.self, category: "Namecard.Edit")

    private let disposeBag: DisposeBag = DisposeBag()
    private let dependency: NameCardEditDependency
    private let pushCenter: PushNotificationCenter

    private var dataSourceRelay = BehaviorRelay<[[NameCardEditItemViewModel]]>(value: [])
    var dataSourceObservable: Observable<[[NameCardEditItemViewModel]]> {
        return dataSourceRelay.asObservable()
    }

    var shouldShowEmptyState = false
    // 是否可以点击保存/更新
    var savableStateObserable = BehaviorSubject<Bool>(value: false)

    // 原始数据，用来进行比对，退出页面时提醒用户未保存
    private var originInfo: Email_Client_V1_NamecardMetaInfo

    // 列表数据源
    var dataSource: [[NameCardEditItemViewModel]] {
        return _dataSource
    }
    private var _dataSource = [[NameCardEditItemViewModel]]()

    private var id: String?
    private var email: String?
    private var source: String?
    private var name: String?

    // Mail account id this name card belong to
    private var accountID: String?
    private var accountList: [MailAccountBriefInfo]

    var mailAccounts: [String] {
        accountList.map { $0.displayAddress }
    }

    var callback: ((Bool) -> Void)?
    let resolver: UserResolver
    // 防止多次点击
    var isLoading = false
    let isFromAdd: Bool
    let isFromContact: Bool
    let passportService: PassportService

    init(id: String? = nil,
         email: String? = nil,
         name: String? = nil,
         source: String? = nil,
         accountID: String? = nil,
         accountList: [MailAccountBriefInfo],
         callback: ((Bool) -> Void)? = nil,
         pushCenter: PushNotificationCenter,
         dependency: NameCardEditDependency,
         resolver: UserResolver) throws {
        self.id = id
        self.email = email
        self.name = name
        self.source = source
        self.accountID = accountID
        self.accountList = accountList
        self.callback = callback
        self.dependency = dependency
        self.pushCenter = pushCenter
        self.resolver = resolver
        self.passportService = try resolver.resolve(assert: PassportService.self)
        self.originInfo = Email_Client_V1_NamecardMetaInfo()
        self.isFromContact = source == "contact"
        if let id = self.id, !id.isEmpty {
            isFromAdd = false
        } else {
            isFromAdd = true
        }
        self.getData()
        self.updateSavableState()
    }
}

// MARK: - 处理数据
extension NameCardEditViewModel {

    private func getData() {
        if !isFromAdd, let id {
            dependency.getNamecardsByID(id, accountID: accountID ?? "")
                .subscribe(onNext: { [weak self] response in
                    guard let self = self else { return }
                    var isSuccess = false
                    if response != nil {
                        isSuccess = true
                    }
                    Self.log.info("getData-edit: success: \(isSuccess)")
                    self.handleData(response)
                }, onError: { [weak self] error in
                    Self.log.info("getData-edit: error: \(error)")
                    self?.shouldShowEmptyState = true
                    self?.dataSourceRelay.accept([])
                }).disposed(by: disposeBag)
        } else {
            Self.log.info("getData-add")
            self.handleData(nil)
        }
        fetchAccountListIfNeeded()
    }

    private func fetchAccountListIfNeeded() {
        guard isFromAdd,
              accountList.isEmpty,
              resolver.fg.staticFeatureGatingValue(with: "larkmail.cli.new_contact_ui")
        else { return }
        listenToAccountChanged()
        dependency.getAllMailAccountDetail(latest: false)
            .subscribe(onNext: { [weak self] accountList in
                guard let self = self else { return }
                Self.log.info("accountList-edit: success, count: \(accountList.count)")
                self.accountList = accountList
                self.decideAccountRow(list: self._dataSource)
            }, onError: { error in
                Self.log.info("accountList-edit: failed error: \(error)")
            }).disposed(by: disposeBag)
    }

    private func listenToAccountChanged() {
        pushCenter.observable(for: MailContactChangedPush.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                Self.log.info("receive account push, count: \(push.briefInfos.count)")
                self.accountList = push.briefInfos
                self.decideAccountRow(list: self._dataSource)
            }).disposed(by: disposeBag)
    }

    func updateData() -> Observable<(Bool, String)> {
        self.isLoading = true
        let observable: Observable<(Bool, String)> = Observable.create { [weak self] observer in
            guard let self = self, let accountID = self.accountID else { return Disposables.create() }
            var localDispose = DisposeBag()
            let info = self.getUploadNameCardInfo()
            if !self.isFromAdd {
                self.dependency.updateSingleNamecard(namecard: info, accountID: accountID)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        Self.log.info("updateData-edit: success")
                        self.isLoading = false
                        NameCardTrack.trackAddOkInEdit(self.source)
                        self.resetOriginInfo(info)
                        self.postNameCard()
                        observer.onNext((true, BundleI18n.LarkContact.Lark_Contacts_SavedToast))
                        observer.onCompleted()
                        localDispose = DisposeBag()
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        self.isLoading = false
                        Self.log.info("updateData-edit: error: \(error)")
                        var errorCode: Int = 0
                        if let error = error.underlyingError as? APIError {
                            if self.updateErrorFromServer(error.code) {
                                // 只需要刷新红框
                                observer.onNext((false, ""))
                                errorCode = Int(error.code)
                            } else {
                                // 需要弹toast
                                observer.onNext((false, error.displayMessage))
                            }
                        }
                        let reciableError = ErrorParams(biz: .Mail, scene: .Unknown,
                                                        eventable: MailContactEvent.contactSaveFail,
                                                        errorType: .Unknown, errorLevel: .Exception,
                                                        errorCode: errorCode, userAction: nil,
                                                        page: "mailContact", errorMessage: "updateData-edit: error: \(error)",
                                                        extra: nil)
                        AppReciableSDK.shared.error(params: reciableError)
                        observer.onCompleted()
                        localDispose = DisposeBag()
                    }).disposed(by: localDispose)
            } else {
                self.dependency.setSingleNamecard(namecardInfo: info, accountID: accountID)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        Self.log.info("updateData-add: success")
                        self.isLoading = false
                        NameCardTrack.trackAddOkInEdit(self.source)
                        self.resetOriginInfo(info)
                        self.postNameCard()
                        observer.onNext((true, BundleI18n.LarkContact.Lark_Contacts_SavedToast))
                        observer.onCompleted()
                        localDispose = DisposeBag()
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        self.isLoading = false
                        Self.log.info("updateData-add: error: \(error)")
                        if let error = error.underlyingError as? APIError {
                            if self.updateErrorFromServer(error.code) {
                                // 只需要刷新红框
                                observer.onNext((false, ""))
                            } else {
                                // 需要弹toast
                                observer.onNext((false, error.displayMessage))
                            }
                        }
                        observer.onCompleted()
                        localDispose = DisposeBag()
                    }).disposed(by: localDispose)
            }
            return Disposables.create()
        }
        return observable
    }

    private func handleData(_ data: RustPB.Email_Client_V1_NamecardMetaInfo?) {

        // 保存原始数据
        if let serverData = data {
            self.originInfo = serverData
        }

        let regionCode = NameCardEditPhoneViewModel.getDefaultRegionCode()
        if self.originInfo.phone.districtNumber.isEmpty {
            self.originInfo.phone.districtNumber = regionCode.districtNumber
        }
        if self.originInfo.phone.regionCode.isEmpty {
            self.originInfo.phone.regionCode = regionCode.regionCode
        }

        // 姓名
        let nameModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .name, desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardName, maxCharLength: 32)
        nameModel.isShowStrongReminder = true
        nameModel.updateContent(data?.name ?? self.name)

        // 公司
        let companyModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .company, desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardCompany, maxCharLength: 64)
        companyModel.updateContent(data?.companyName)

        // 职务
        let titleModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .title, desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardRole, maxCharLength: 64)
        titleModel.updateContent(data?.title)

        // 手机号        
        let phoneModel = NameCardEditPhoneViewModel(type: .phone,
                                                    fgService: resolver.fg,
                                                    desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardMobile,
                                                    phone: data?.phone,
                                                    maxCharLength: 40)

        // 邮箱
        let emailModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .email, desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardEmail, maxCharLength: 320)
        emailModel.updateContent(data?.email ?? self.email)

        // 标签
        let groupModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .group, desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardTag, maxCharLength: 64)
        groupModel.updateContent(data?.group)

        // 备注
        let extraModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .extra, desc: BundleI18n.LarkContact.Lark_Contacts_ContactCardNotes, maxCharLength: 1000)
        extraModel.updateContent(data?.extra)

        // 按类型分 section 展示
        let list = [[nameModel, companyModel, titleModel],
                    [phoneModel],
                    [emailModel],
                    [groupModel],
                    [extraModel]]

        decideAccountRow(list: list)
    }

    private func decideAccountRow(list: [[NameCardEditItemViewModel]]) {
        var list = list

        if accountList.count <= 1 {
            if getItem(type: .account) != nil {
                list.removeFirst()
            }
        } else {
            if getItem(type: .account) == nil {
                // 添加到账号
                let accountModel = NameCardEditItemViewModel(fgService: resolver.fg, type: .account,
                                                             desc: BundleI18n.LarkContact.Mail_ThirdClient_AddToAccount,
                                                             maxCharLength: 320)
                accountModel.isShowStrongReminder = true
                list.insert([accountModel], at: 0)
            }
            list.first?.first?.isSelectable = isFromContact
            if let accountID = accountID,
               let mailAddress = accountList.first(where: { $0.accountID == accountID })?.displayAddress {
                list.first?.first?.updateContent(mailAddress)
            }
        }

        _dataSource = list
        dataSourceRelay.accept(list)
    }

    private func updateSavableState() {
        let savable = _dataSource
            .flatMap({ $0 })
            .filter({ $0.isShowStrongReminder })
            .allSatisfy({ $0.content?.isEmpty == false })

        savableStateObserable.onNext(savable)
    }

    func getItem(type: NameCardEditType) -> NameCardEditItemViewModel? {
        _dataSource.flatMap({ $0 }).first(where: { $0.type == type })
    }

    private func getItemContent(type: NameCardEditType) -> String? {
        getItem(type: type)?.content
    }

    private func getUploadNameCardInfo() -> Email_Client_V1_NamecardMetaInfo {
        var info = getNameCardInfo()
        if let phoneModel = getPhoneModel(),
           let phone = phoneModel.getUploadPhone() {
            info.phone = phone
        }
        return info
    }

    private func getNameCardInfo(_ isUpload: Bool = true) -> Email_Client_V1_NamecardMetaInfo {
        var info = Email_Client_V1_NamecardMetaInfo()
        if let id = self.id {
            info.namecardID = id
        }
        if let name = getItemContent(type: .name) {
            if isUpload {
                info.name = name.removeHeadAndTailSpace()
            } else {
                info.name = name
            }
        }
        if let companyName = getItemContent(type: .company) {
            if isUpload {
                info.companyName = companyName.removeHeadAndTailSpace()
            } else {
                info.companyName = companyName
            }
        }
        if let title = getItemContent(type: .title) {
            if isUpload {
                info.title = title.removeHeadAndTailSpace()
            } else {
                info.title = title
            }
        }
        if let email = getItemContent(type: .email) {
            if isUpload {
                info.email = email.removeHeadAndTailSpace()
            } else {
                info.email = email
            }
        }
        if let group = getItemContent(type: .group) {
            if isUpload {
                info.group = group.removeHeadAndTailSpace()
            } else {
                info.group = group
            }
        }
        if let extra = getItemContent(type: .extra) {
            if isUpload {
                info.extra = extra.removeHeadAndTailSpace()
            } else {
                info.extra = extra
            }
        }
        return info
    }

    func getIndex(_ cellVM: NameCardEditItemViewModel) -> IndexPath? {
        for section in 0..<_dataSource.count {
            for row in 0..<_dataSource[section].count where _dataSource[section][row].type == cellVM.type {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }

    func getTitle() -> String {
        if isFromAdd {
            return BundleI18n.LarkContact.Lark_Contacts_AddContactCardTitle
        } else {
            return BundleI18n.LarkContact.Lark_Contacts_EditContactCardTitle
        }
    }

    private func postNameCard() {
        NotificationCenter.default.post(name: .LKNameCardEditNotification, object: nil,
                                        userInfo: ["id": self.id ?? "", "accountID": accountID ?? "", "isAdded": isFromAdd])
    }
}

// MARK: - Check
extension NameCardEditViewModel {

    func checkAll() -> String? {
        if let phone = getPhoneModel(), !checkPhone(phone) {
            return phone.errorDesc
        }

        if let email = getItem(type: .email), !checkEmail(email) {
            return email.errorDesc
        }
        return nil
    }

    func checkSingle(_ cellVM: NameCardEditItemViewModel) -> IndexPath? {
        var isOldChecked = false
        if cellVM.errorDesc == nil {
            isOldChecked = true
        }
        var needUpdatendexPath: IndexPath?
        if cellVM.type == .name {
            updateSavableState()
        } else if cellVM.type == .phone {
            if let phone = getPhoneModel() {
                _ = checkPhone(phone)
                needUpdatendexPath = getIndex(cellVM)
            }
        } else if cellVM.type == .email {
            _ = checkEmail(cellVM)
            needUpdatendexPath = getIndex(cellVM)
        }
        guard let idexPath = needUpdatendexPath else { return nil }
        var isNewChecked = false
        if cellVM.errorDesc == nil {
            isNewChecked = true
        }
        guard isNewChecked != isOldChecked else { return nil }
        return idexPath
    }

    private func checkName(_ cellVM: NameCardEditItemViewModel) -> Bool {
        guard var name = cellVM.content else {
            cellVM.updateErrorDesc(BundleI18n.LarkContact.Lark_Contacts_PlsEnterName)
            return false
        }
        name = name.removeAllCharSpace()
        let isChecked = !name.isEmpty
        if isChecked {
            cellVM.updateErrorDesc(nil)
        } else {
            cellVM.updateErrorDesc(BundleI18n.LarkContact.Lark_Contacts_PlsEnterName)
        }
        return isChecked
    }

    private func updateErrorFromServer(_ errorCode: Int32) -> Bool {
        if errorCode == 370_000 {
            // 邮箱无效
            getItem(type: .email)?.updateErrorDesc(BundleI18n.LarkContact.Lark_Contacts_PlsEnterValidEmailToast)
            return true
        } else if errorCode == 370_002 {
            // 手机号无效
            if let phone = getPhoneModel() {
                phone.updateErrorDesc(BundleI18n.LarkContact.Mail_Contacts_PlsEnterValidMobile_Error)
                return true
            }
        } else if errorCode == 370_001 {
            // 邮箱已存在
            getItem(type: .email)?.updateErrorDesc(BundleI18n.LarkContact.Mail_ThirdClient_EmailAddressExists)
            return true
        } else if errorCode == 370_003 {
            // 手机号已存在
            if let phone = getPhoneModel() {
                phone.updateErrorDesc(BundleI18n.LarkContact.Mail_ThirdClient_PhoneNumberExists)
                return true
            }
        } else if errorCode == 250_504 {
            // 邮箱账号权限失效
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .LKNameCardNoPermissionNotification,
                                                object: nil,
                                                userInfo: ["id": self.id ?? "", "accountID": self.accountID ?? ""])
            }
            return true
        }
        return false
    }

    private func checkPhone(_ cellVM: NameCardEditPhoneViewModel) -> Bool {
        var isChecked = false
        if var number = cellVM.phoneNumber, !number.isEmpty {
            number = number.removeAllCharSpace()
            if number.isEmpty {
                isChecked = true
            } else {
                var pattern = "^[+*#0-9]+$"
                var result = ""
                do {
                    guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) else { return false }
                    let res = regex.matches(in: number, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: number.count))
                    for checkingRes in res {
                        result += (number as NSString).substring(with: checkingRes.range)
                    }
                } catch _ {
                    isChecked = false
                }
                isChecked = (result == number)
            }
        } else {
            isChecked = true
        }
        if isChecked {
            cellVM.updateErrorDesc(nil)
        } else {
            cellVM.updateErrorDesc(BundleI18n.LarkContact.Mail_Contacts_PlsEnterValidMobile_Error)
        }
        return isChecked
    }

    private func checkEmail(_ cellVM: NameCardEditItemViewModel) -> Bool {
        let isChecked: Bool
        if let text = cellVM.content {
            if text.isEmpty {
                isChecked = true
            } else {
                isChecked = isLegalForEmail(text)
            }
        } else {
            isChecked = true
        }
        if isChecked {
            cellVM.updateErrorDesc(nil)
        } else {
            cellVM.updateErrorDesc(BundleI18n.LarkContact.Lark_Contacts_PlsEnterValidEmailToast)
        }
        return isChecked
    }

    private func isLegalForEmail(_ email: String) -> Bool {
        // 规则
        var pattern = "^((?!\\s)[+a-zA-Z0-9_.!#$%&'*\\/=?^`{|}~\\u0080-\\uffffFF-])+@((?!\\s)"
        pattern.append("[a-zA-Z0-9\\u0080-\\u3001\\u3003-\\uff0d\\uff0f-\\uff60\\uff62-\\uffffFF-]+[\\.\\uFF0E\\u3002\\uFF61])+(?!\\s)")
        pattern.append("[a-zA-Z0-9\\u0080-\\u3001\\u3003-\\uff0d\\uff0f-\\uff60\\uff62-\\uffffFF-]{2,63}$")
        var result = ""
        do {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) else { return false }
            let res = regex.matches(in: email, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: email.count))
            for checkingRes in res {
                result += (email as NSString).substring(with: checkingRes.range)
            }
        } catch _ {
            return false
        }
        return result == email ? true : false
    }
}

// MARK: - 数据Diff
extension NameCardEditViewModel {

    private func resetOriginInfo(_ info: Email_Client_V1_NamecardMetaInfo) {
        originInfo = info
    }

    func judgeIsModified() -> Bool {
        guard !dataSource.isEmpty else { return false }

        guard let phoneModel = getPhoneModel() else { return false }
        var newInfo = getNameCardInfo(false)
        newInfo.phone = phoneModel.getUIPhone()

        var isModified = newInfo.name != originInfo.name
        || newInfo.companyName != originInfo.companyName
        || newInfo.title != originInfo.title
        || newInfo.email != originInfo.email
        || newInfo.group != originInfo.group
        || newInfo.extra != originInfo.extra
        isModified = isModified || newInfo.phone.fullPhoneNumber != originInfo.phone.fullPhoneNumber
        return isModified
    }
}

// MARK: - 账号选择
extension NameCardEditViewModel {
    func updateSelectedAccount(_ account: String) -> IndexPath {
        accountID = accountList.first(where: { $0.displayAddress == account })?.accountID
        getItem(type: .account)?.updateContent(account)
        updateSavableState()
        return IndexPath(row: 0, section: 0)
    }
}

// MARK: - 手机号国家代码选择
extension NameCardEditViewModel {

    func getCodeSettings() -> (language: LarkLocalizations.Lang, countryList: [String], blackCountryList: [String]) {
        let language = LanguageManager.currentLanguage
        let countryList = passportService.getTopCountryList()
        let blackCountryList = passportService.getBlackCountryList()
        return (language, countryList, blackCountryList)
    }

    func updateCountryCode(_ code: LarkUIKit.MobileCode) -> IndexPath? {
        guard let cellVM = getPhoneModel() else { return nil }
        cellVM.updatePhone(code.code, code.key)
        return getIndex(cellVM)
    }

    func getPhoneModel() -> NameCardEditPhoneViewModel? {
        guard let phoneModel = getItem(type: .phone) as? NameCardEditPhoneViewModel else { return nil }
        return phoneModel
    }
}

extension String {
    // 对即将要同步给服务端的字符串进行裁剪处理

    // 去掉首尾空格 包括后面的换行符 \n
    func removeHeadAndTailSpace() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 去掉所有空格
    func removeAllCharSpace() -> String {
        var t = self.removeHeadAndTailSpace()
        t = t.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
        return t
    }
}
