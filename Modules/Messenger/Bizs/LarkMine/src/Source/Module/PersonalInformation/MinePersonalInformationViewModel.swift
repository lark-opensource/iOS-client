//
//  MinePersonalInformationViewModel.swift
//  LarkMine
//
//  Created by 姚启灏 on 2018/12/26.
//

import Foundation
import LarkModel
import RxSwift
import LarkAccountInterface
import LarkSDKInterface
import LarkStorage
import LarkContainer
import RustPB
import ServerPB
import LarkLocalizations
import SwiftProtobuf
import LarkSetting

public typealias I18nVal = Contact_V2_GetUserProfileResponse.I18nVal
public typealias CertificateStatus = Contact_V2_GetUserProfileResponse.UserInfo.CertificateStatus
private let LKSettingFieldName = UserSettingKey.make(userKeyLiteral: "user_another_name_config")
private let LKFieldTextKey = "field_text"

final class MinePersonalInformationViewModel {
    private let userResolver: UserResolver
    private let passportService: PassportUserService
    private let chatterAPI: ChatterAPI
    private let chatterManager: ChatterManagerProtocol
    /// 是否能够修改用户名
    private(set) var canChangeUserName: Bool?

    typealias AuthInfo = (hasAuth: Bool, isAuth: Bool, authURL: String, certificateStatus: CertificateStatus)
    private(set) var authInfo: AuthInfo = (hasAuth: false, isAuth: false, authURL: "", certificateStatus: .uncertificated)

    private lazy var userStore = KVStores.Mine.build(forUser: self.passportService.user.userID)
    // shortshut to `self.userStore`
    static let userStore = \MinePersonalInformationViewModel.userStore

    /// 别名权限
    @KVBinding(to: userStore, key: KVKeys.Mine.enableAnotherName)
    var canChangeAnotherName: Bool

    /// 别名
    @KVBinding(to: userStore, key: KVKeys.Mine.anotherName)
    var anotherName: String

    /// 部门
    @KVBinding(to: userStore, key: KVKeys.Mine.department)
    var department: String

    @KVBinding(to: userStore, key: KVKeys.Mine.description)
    var personalStatus: String?

    var enabelMedal: Bool = false

    var isDefaultAvatar: Bool = false

    var enableQrcodeEntry: Bool {
        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        return featureGatingService?.staticFeatureGatingValue(with: .contactOptForUI) ?? false
    }

    /// 工作状态：「请假中」
    var workStatus: String {
        if !self.currentUser.workStatus.hasStatus { return "" }
        let startTime = self.transformData(timeStamp: self.currentUser.workStatus.startTime)
        let endTime = self.transformData(timeStamp: self.currentUser.workStatus.endTime)
        if startTime == endTime {
            return String(format: BundleI18n.LarkMine.Lark_Legacy_MineMainWorkdayTimeOneday, startTime)
        }
        return String(format: BundleI18n.LarkMine.Lark_Legacy_MineMainWorkdayTime, startTime, endTime)
    }
    var currentUser: Chatter {
        return self.chatterManager.currentChatter
    }

    var currentChatterObservable: Observable<Chatter> {
        return self.chatterManager.currentChatterObservable
    }

    var currentUserStateObservable: Observable<PassportUserState> {
        return self.passportService.state
    }

    init(userResolver: UserResolver,
        passportService: PassportUserService,
         chatterAPI: ChatterAPI,
         chatterManager: ChatterManagerProtocol) {
        self.userResolver = userResolver
        self.passportService = passportService
        self.chatterAPI = chatterAPI
        self.chatterManager = chatterManager
    }

    private func transformData(timeStamp: Int64) -> String {
        let timeMatter = DateFormatter()
        timeMatter.dateFormat = "MM/dd"

        let timeInterval: TimeInterval = TimeInterval(timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)
        return timeMatter.string(from: date)
    }

    /// 获取修改用户名权限
    func fetchUserUpdateNamePermission() -> Observable<Void> {
        return self.chatterAPI.fetchUserUpdateNamePermission().do(onNext: { [weak self] (value) in
            guard let self = self else { return }
            self.canChangeUserName = value.0
            self.canChangeAnotherName = value.1
            MineTracker.trackAnotherNameEntranceView(hasShown: self.isAnotherNameEnable)
        }).map({ _ in })
    }

    var isAnotherNameEnable: Bool {
        return self.canChangeAnotherName || !self.anotherName.isEmpty
    }

    var anotherNameTitle: String {
        if let anotherNameConfig = try? userResolver.settings.setting(
            with: LKSettingFieldName
        ) {
            let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
            if let textConfig = anotherNameConfig[LKFieldTextKey] as? [String: String],
            let subTitle = textConfig[currentLocalizations] as? String {
                return subTitle
            }
        }
        return BundleI18n.LarkMine.Lark_ProfileMyAlias_MyAlias_Subtitle
    }

    var tenantName: String {
        return self.passportService.userTenant.localizedTenantName
    }

    var isTenantNameEnabled: Bool {
        // C端用户隐藏「企业」字段
        return self.passportService.user.type != .c
    }

    var isDepartmentEnabled: Bool {
        // C端用户 & 小B 隐藏「部门」字段
        let roleEnable = !(self.passportService.user.type == .c || self.passportService.user.type == .simple)
        return roleEnable && !self.department.isEmpty
    }

    private let disposeBag = DisposeBag()

    func requestProfileInformation(completion: @escaping (String, Chatter.DescriptionType) -> Void) {
        let userId = self.currentUser.id
        let chatterAPI = self.chatterAPI
        let localData = chatterAPI
            .getNewUserProfileInfomation(userId: userId,
                                         contactToken: "",
                                         chatId: "")

        let serverData = self.chatterAPI
            .fetchNewUserProfileInfomation(userId: userId,
                                           contactToken: "",
                                           chatId: "",
                                           sourceType: .chat)
        return Observable.merge(localData, serverData)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (profileModel) in
                guard let `self` = self else { return }
                let department = self.handleDepartName(profileModel: profileModel)
                let tenantName = profileModel.userInfo.tenantName.getString()
                let description = profileModel.userInfo.description_p.text
                let descriptionType = profileModel.userInfo.description_p.type
                // update userDefault
                self.department = department
                self.personalStatus = description
                self.userStore[KVKeys.Mine.descriptionType] = descriptionType.rawValue
                self.userStore[KVKeys.Mine.organization] = tenantName
                self.enabelMedal = profileModel.userInfo.avatarMedal.showSwitch
                self.isDefaultAvatar = profileModel.userInfo.isDefaultAvatar
                if profileModel.userInfo.hasAnotherName {
                    self.anotherName = profileModel.userInfo.anotherName
                } else {
                    self.anotherName = ""
                }
                if !profileModel.userInfo.hasCertificationInfo || !profileModel.userInfo.certificationInfo.isShowCertSign {
                    self.authInfo = (false, false, "", .uncertificated)
                } else {
                    let status = profileModel.userInfo.certificationInfo.certificateStatus
                    let hasTenantCertification = (status != .teamCertificated)
                    let isTenantCertification = (status == .certificated)
                    let tenantCertificationURL = profileModel.userInfo.certificationInfo.tenantCertificationURL
                    self.authInfo = (hasTenantCertification, isTenantCertification, tenantCertificationURL, status)
                }
                completion(description, descriptionType)
            }, onError: { (error) in
                MineMainViewModel.logger.error(
                    "Fetch personal info failed!!",
                    error: error
                )
            }).disposed(by: disposeBag)
    }

    func requestStationAndCustomInfo() -> Observable<[MinePersonalInformationCustomField]> {
        let userId = self.currentUser.id
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        return self.chatterAPI.fetchUserPersonalInfoRequest(userId: userId).map({
            return $0.fields.map({ field in
                let key = field.key
                var name = field.i18NNames.defaultVal
                if let i18nVal = field.i18NNames.i18NVals[currentLocalizations], !i18nVal.isEmpty {
                    name = i18nVal
                }
                let type: MinePersonalInformationCustomFieldType = field.fieldValueType == .link ? .link : .text
                let (text, link) = self.parseCustomInfo(jsonStr: field.strFieldVal, type: type)
                return MinePersonalInformationCustomField(key: key, name: name, text: text, link: link, type: type, enableEdit: field.editable)
            }).filter({ field in
                // 用户可编辑or内容不为空 才在个人信息页展示
                return field.enableEdit || !field.text.isEmpty
            })
        }).do(onNext: {
            MineMainViewModel.logger.error("Fetch person customInfo success!!, field count: \($0.count)")
        }, onError: { error in
            MineMainViewModel.logger.error("Fetch person customInfo failed!!,", error: error)
        })
    }

    private func parseCustomInfo(jsonStr: String, type: MinePersonalInformationCustomFieldType) -> (String, String) {
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        switch type {
        case .text:
            guard let data = try? ServerPB_Users_Profile.Text(jsonString: jsonStr) else {
                return ("", "")
            }
            var text = data.text.defaultVal
            if let i18nText = data.text.i18NVals[currentLocalizations], !i18nText.isEmpty {
                text = i18nText
            }
            return (text, "")
        case .link:
            guard let data = try? ServerPB_Users_Profile.Href(jsonString: jsonStr) else {
                return ("", "")
            }
            var title = data.title.defaultVal, link = data.link.defaultVal
            if let i18nTitle = data.title.i18NVals[currentLocalizations], !i18nTitle.isEmpty {
                title = i18nTitle
            }
            if let i18nLink = data.link.i18NVals[currentLocalizations], !i18nLink.isEmpty {
                link = i18nLink
            }
            return (title, link)
        }
    }

    private func handleDepartName(profileModel: Contact_V2_GetUserProfileResponse) -> String {
        var department = ""
        profileModel.fieldOrders.map { field in
            if field.fieldType == .sDepartment {
                /// 解析出部门
                var options = JSONDecodingOptions()
                options.ignoreUnknownFields = true

                if let departments = try? Contact_V2_GetUserProfileResponse.Department(jsonString: field.jsonFieldVal, options: options),
                    !departments.departmentPaths.isEmpty {
                    let list = departments.departmentPaths.map { departmentPath -> String in
                        var path: String = ""
                        for department in departmentPath.departmentNodes {
                            let id = department.departmentID
                            if !id.isEmpty {
                                path.append(department.departmentName.getString() + "-")
                            }
                        }
                        if !path.isEmpty {
                            path.removeLast()
                        }
                        return path
                    }
                    department = list.first ?? ""
                }
            }
        }
        return department
    }
}

extension I18nVal {
    public func getString() -> String {
        let i18NVal = self.i18NVals
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return self.defaultVal
        }
    }
}

#if !DEBUG && !ALPHA
extension ServerPB_Users_Profile.Text: SwiftProtobuf.MessageJSONLarkExt {}
extension ServerPB_Users_Profile.Href: SwiftProtobuf.MessageJSONLarkExt {}
#endif
