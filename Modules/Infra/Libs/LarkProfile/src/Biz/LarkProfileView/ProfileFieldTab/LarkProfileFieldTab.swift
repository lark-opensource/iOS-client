//
//  ProfileFieldTab.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/30.
//

import Foundation
import RxSwift
import RxCocoa
import EENavigator
import SwiftProtobuf
import LarkFeatureGating
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast
import LarkUIKit
import UniverseDesignDialog
import LarkContainer
import Swinject
import LKCommonsTracker
import Homeric
import UniverseDesignIcon
import UIKit

public final class LarkProfileFieldTab: ProfileFieldTab, LarkProfileTab {
    
    public static func createTab(by tab: LarkUserProfilTab,
                                 resolver: UserResolver,
                                 context: ProfileContext,
                                 profile: ProfileInfoProtocol,
                                 dataProvider: ProfileDataProvider) -> ProfileTabItem? {
        guard tab.tabType == .fCommonInfo else {
            return nil
        }

        let title = tab.name.getString()
        return ProfileTabItem(title: title,
                              identifier: "ProfileFieldTab") { [weak dataProvider] in
            guard let provider =  dataProvider else {
                return ProfileBaseTab()
            }
            return LarkProfileFieldTab(resolver: resolver,
                                       title: title,
                                       profile: profile,
                                       dataProvider: provider)
        }
    }

    @ScopedInjectedLazy var chatterAPI: ChatterAPI?

    private weak var dataProvider: ProfileDataProvider?
    private var profile: ProfileInfoProtocol
    private var disposeBag = DisposeBag()

    private var memoImage: UIImage?
    private var memoText: String = ""
    private var memoDescription: ProfileMemoDescription?
    private var alias = ""

    public init(resolver: UserResolver,
                title: String,
                profile: ProfileInfoProtocol,
                dataProvider: ProfileDataProvider) {
        self.profile = profile
        self.dataProvider = dataProvider
        super.init(resolver: resolver, title: title)
        bindData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(_ profile: ProfileInfoProtocol, context: ProfileContext) {
        self.profile = profile
        // 更新时重置数据
        self.memoImage = nil
        self.memoText = ""
        self.memoDescription = nil
        self.alias = ""
        
        DispatchQueue.global().async {
            let fields: [ProfileFieldItem] = self.createItemWithProfile()
            DispatchQueue.main.async {
                self.updateField(fields: fields)
            }
        }
    }

    private func bindData() {
        DispatchQueue.global().async {
            let fields: [ProfileFieldItem] = self.createItemWithProfile()
            DispatchQueue.main.async {
                self.updateField(fields: fields)
            }
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // swiftlint:disable function_body_length
    // nolint: long_function - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    public func createItemWithProfile() -> [ProfileFieldItem] {
        guard let profileVC = dataProvider?.profileVC else {
            return []
        }
        LarkProfileDataProvider.logger.info("createItem fieldOrders: \(profile.fieldOrders.count)")
        let fieldOrders = profile.fieldOrders
        let userInfo = profile.userInfoProtocol
        let isNewAlias = userResolver.fg.staticFeatureGatingValue(with: "messenger.profile.more_alias")

        var fields: [ProfileFieldItem] = []
        // 用以部门可见下将部门信息传递至手机号item中，便于保存至通讯录
        var departmentName: String = ""

        for field in fieldOrders {
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true
            switch field.fieldType {
            case .aliasAndMemo:
                if let text = try? LarkUserProfile.Text(jsonString: field.jsonFieldVal, options: options) {
                    var detailString = ""
                    if text.text.i18NVals.isEmpty,
                        text.text.defaultVal.isEmpty {
                        detailString = BundleI18n.LarkProfile.Lark_Legacy_EditAlias
                    } else {
                        detailString = text.text.getString()
                    }

                    let item = ProfileFieldPushItem(fieldKey: field.key,
                                                    title: field.i18NNames.getString(),
                                                    numberOfLines: 1,
                                                    contentText: detailString,
                                                    textAlignment: .right) { [weak profileVC, weak self] in
                        guard let fromVC = profileVC, let `self` = self else { return }
                        let vc = LarkProfileAliasViewController(resolver: self.userResolver,
                                                                userID: userInfo.userID,
                                                                name: userInfo.userName,
                                                                alias: "",
                                                                memoDescription: self.memoDescription,
                                                                memoText: self.memoText,
                                                                memoImage: self.memoImage) { [weak self] (alias, memoText, image) in
                            self?.memoDescription = nil
                            self?.alias = alias
                            self?.memoImage = image
                            self?.memoText = memoText
                            self?.dataProvider?.reloadData()
                        }

                        var params: [AnyHashable: Any] = [:]
                        params["click"] = "alias"
                        params["target"] = "profile_alias_setting_view"
                        params["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
                        params["to_user_id"] = userInfo.userID
                        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
                        
                        self.userResolver.navigator.present(vc,
                                                 wrap: LkNavigationController.self,
                                                 from: fromVC)
                    }
                    if isNewAlias {
                        fields.append(item)
                    }
                }
            case .memoDescription:
                if let memo = try? LarkUserProfile.MemoDescription(jsonString: field.jsonFieldVal, options: options) {
                    var detailString = ""
                    if memo.memoText.isEmpty, !memo.hasMemoPicture {
                        detailString = BundleI18n.LarkProfile.Lark_ProfileMemo_SetNotes_Placeholder
                    } else {
                        detailString = memo.memoText
                    }

                    self.memoDescription = memo

                    var icon: UIImage?
                    if memo.hasMemoPicture {
                        icon = UDIcon.nopictureFilled.ud.withTintColor(UIColor.ud.iconN3)
                    }

                    let item = ProfileFieldPushItem(fieldKey: field.key,
                                                    title: field.i18NNames.getString(),
                                                    icon: icon,
                                                    numberOfLines: 3,
                                                    contentText: detailString,
                                                    textAlignment: .left) { [weak profileVC, weak self] in
                        guard let fromVC = profileVC, let `self` = self else { return }
                        let vc = LarkProfileAliasViewController(resolver: self.userResolver,
                                                                userID: userInfo.userID,
                                                                name: userInfo.userName,
                                                                alias: self.alias,
                                                                memoDescription: self.memoDescription,
                                                                memoText: self.memoText,
                                                                memoImage: self.memoImage) { [weak self] (alias, memoText, image) in
                            self?.memoDescription = nil
                            self?.alias = alias
                            self?.memoImage = image
                            self?.memoText = memoText
                            self?.dataProvider?.reloadData()
                        }

                        var params: [AnyHashable: Any] = [:]
                        params["click"] = "description"
                        params["target"] = "profile_alias_setting_view"
                        params["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
                        params["to_user_id"] = userInfo.userID
                        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))

                        self.userResolver.navigator.present(vc,
                                                 wrap: LkNavigationController.self,
                                                 from: fromVC)
                    }
                    if isNewAlias {
                        fields.append(item)
                    }
                }
            case .cAlias:
                if let text = try? LarkUserProfile.Text(jsonString: field.jsonFieldVal, options: options) {
                    var detailString = ""
                    if text.text.i18NVals.isEmpty,
                        text.text.defaultVal.isEmpty {
                        detailString = BundleI18n.LarkProfile.Lark_Legacy_EditAlias
                    } else {
                        detailString = text.text.getString()
                        self.alias = text.text.getString()
                    }

                    let item = ProfileFieldPushItem(fieldKey: field.key,
                                                    title: field.i18NNames.getString(),
                                                    numberOfLines: 1,
                                                    contentText: detailString,
                                                    textAlignment: .right) { [weak profileVC, weak self] in
                        guard let fromVC = profileVC, let `self` = self else { return }

                        if isNewAlias {
                            let vc = LarkProfileAliasViewController(resolver: self.userResolver,
                                                                    userID: userInfo.userID,
                                                                    name: userInfo.userName,
                                                                    alias: self.alias,
                                                                    memoDescription: self.memoDescription,
                                                                    memoText: self.memoText,
                                                                    memoImage: self.memoImage) { [weak self] (alias, memoText, image) in
                                self?.memoDescription = nil
                                self?.alias = alias
                                self?.memoImage = image
                                self?.memoText = memoText
                                self?.dataProvider?.reloadData()
                            }

                            var params: [AnyHashable: Any] = [:]
                            params["click"] = "alias_name"
                            params["target"] = "profile_alias_setting_view"
                            params["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
                            params["to_user_id"] = userInfo.userID
                            Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))

                            self.userResolver.navigator.present(vc,
                                                     wrap: LkNavigationController.self,
                                                     from: fromVC)
                        } else {
                            let body = SetAliasViewControllerBody(currentAlias: text.text.getString()) { alias in
                                self.setAliasBlock(alias)
                                var params: [AnyHashable: Any] = [:]
                                params["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
                                params["to_user_id"] = userInfo.userID
                                params["click"] = "save"
                                params["target"] = "profile_main_view"
                                Tracker.post(TeaEvent(Homeric.PROFILE_ALIAS_SETTING_CLICK, params: params, md5AllowList: ["to_user_id"]))
                            }

                            self.userResolver.navigator.push(body: body, from: fromVC)

                            var params: [AnyHashable: Any] = [:]
                            params["click"] = "alias"
                            params["target"] = "profile_alias_setting_view"
                            params["alias_length"] = text.text.getString().count
                            params["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
                            params["to_user_id"] = userInfo.userID
                            Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))

                            var viewParams: [AnyHashable: Any] = [:]
                            viewParams["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
                            viewParams["to_user_id"] = userInfo.userID
                            Tracker.post(TeaEvent(Homeric.PROFILE_ALIAS_SETTING_VIEW, params: viewParams, md5AllowList: ["to_user_id"]))
                        }
                    }

                    if !(text.text.i18NVals.isEmpty &&
                         text.text.defaultVal.isEmpty &&
                         isNewAlias) {
                        fields.append(item)
                    }

                }
            case .link:
                if let link = try? LarkUserProfile.Href(jsonString: field.jsonFieldVal, options: options),
                    !link.title.i18NVals.isEmpty || !link.title.defaultVal.isEmpty,
                    !link.link.i18NVals.isEmpty || !link.link.defaultVal.isEmpty {

                    let url = link.link.getString()
                    let isIpad = UIDevice.current.userInterfaceIdiom == .pad
                    let displayStyle: UIModalPresentationStyle = isIpad ? .formSheet : .fullScreen
                    let item = ProfileFieldLinkItem(
                        fieldKey: field.key,
                        title: field.i18NNames.getString(),
                        contentText: link.title.getString(),
                        url: url
                    ) { [weak self] (text, fromVC) in
                        let urlType = LarkUserProfileLinkType.getLinkType(url: text)
                        guard let pushUrl = try? URL.forceCreateURL(string: text), let self = self else { return }
                        LarkProfileDataProvider.logger.info("click item push vc \(urlType)")
                        switch urlType {
                        case .calendar:
                            self.userResolver.navigator.present(pushUrl, context: ["isFromProfile": true],
                                                     from: fromVC,
                                                     prepare: { $0.modalPresentationStyle = displayStyle })
                        case .h5, .mail, .microApp:
                            if isIpad {
                                self.userResolver.navigator.present(pushUrl,
                                                         wrap: LkNavigationController.self,
                                                         from: fromVC,
                                                         prepare: { $0.modalPresentationStyle = displayStyle })
                            } else {
                                self.userResolver.navigator.push(pushUrl, from: fromVC)
                            }
                        case .profile:
                            self.userResolver.navigator.push(pushUrl, from: fromVC)
                        case .unknown:
                            break
                        }
                    }
                    fields.append(item)
                }
            case .linkList:
                if let hrefList = try? LarkUserProfile.HrefList(jsonString: field.jsonFieldVal,
                                                                options: options).hrefList,
                   !hrefList.isEmpty {
                    let list = hrefList.map { text -> LarkProfile.ProfileHref in
                        var href = LarkProfile.ProfileHref()
                        href.text = text.title.getString()
                        href.url = text.link.getString()
                        return href
                    }
                    let item = ProfileFieldHrefListItem(fieldKey: field.key,
                                                        title: field.i18NNames.getString(),
                                                        hrefList: list)
                    fields.append(item)
                }
            case .sDepartment:
                if let departments = try? LarkUserProfile.Department(jsonString: field.jsonFieldVal, options: options),
                        !departments.departmentPaths.isEmpty {
                    let list = departments.departmentPaths.map { departmentPath -> ProfileHref in
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
                        if departmentName.isEmpty {
                            departmentName = path
                        } else {
                            departmentName = departmentName + "/" + path
                        }
                        return ProfileHref(url: departmentPath.redirectLink,
                                           text: path,
                                           accessible: departmentPath.accessible) { [weak profileVC, weak self] in
                            guard let profileVC = profileVC, let self = self else { return }
                            let noAccessDescription = departmentPath.noAccessDescription.getString()
                            guard departmentPath.accessible else {
                                if !noAccessDescription.isEmpty {
                                    UDToast.showWarning(with: noAccessDescription,
                                                        on: profileVC.view ?? UIView())
                                }
                                return
                            }
                            if let url = try? URL.forceCreateURL(string: departmentPath.redirectLink) {
                                self.userResolver.navigator.open(url, from: profileVC)
                            }
                        }
                    }
                    let item = ProfileFieldHrefListItem(fieldKey: field.key,
                                                        title: field.i18NNames.getString(),
                                                        hrefList: list,
                                                        enableLongPress: true)
                    fields.append(item)
                }
            case .sFriendLink:
                if let link = try? LarkUserProfile.Href(jsonString: field.jsonFieldVal, options: options),
                    !link.title.i18NVals.isEmpty || !link.title.defaultVal.isEmpty {
                    let shareURL = "//client/contact/share"
                    let item = ProfileFieldLinkItem(
                        fieldKey: field.key,
                        title: field.i18NNames.getString(),
                        contentText: link.title.getString(),
                        url: shareURL
                    )
                    fields.append(item)
                }
            case .sPhoneNumber:
                if let phoneNumber = try? LarkUserProfile.PhoneNumber(jsonString: field.jsonFieldVal, options: options),
                    !phoneNumber.number.isEmpty {
                    let settingService = try? userResolver.resolve(assert: UserUniversalSettingService.self)
                    let item = ProfileFieldPhoneNumberItem(
                        fieldKey: field.key,
                        title: field.i18NNames.getString(),
                        contentText: BundleI18n.LarkProfile.Lark_Profile_PhoneV6,
                        userID: userInfo.userID,
                        phoneNumber: phoneNumber.number,
                        countryCode: phoneNumber.countryCode,
                        avatarKey: userInfo.avatarKey,
                        aliasName: userInfo.alias,
                        userName: userInfo.displayName(with: settingService),
                        tenantName: userInfo.tenantName.getString(),
                        departmentName: departmentName,
                        isPlain: phoneNumber.isPlain)
                    fields.append(item)
                }
            case .text:
                if let text = try? LarkUserProfile.Text(jsonString: field.jsonFieldVal, options: options),
                      (!text.text.defaultVal.isEmpty || !text.text.i18NVals.isEmpty) {
                    let item = ProfileFieldNormalItem(fieldKey: field.key,
                                                      title: field.i18NNames.getString(),
                                                      contentText: text.text.getString())
                    fields.append(item)
                }
            case .textList:
                if let textList = try? LarkUserProfile.TextList(jsonString: field.jsonFieldVal,
                                                                options: options).textList,
                   !textList.isEmpty {
                    let list = textList.map { text in
                        return text.text.getString()
                    }
                    let item = ProfileFieldTextListItem(type: .textList,
                                                        fieldKey: field.key,
                                                        title: field.i18NNames.getString(),
                                                        textList: list)
                    for index in 0..<textList.count {
                        item.expandItemDir[index] = .folded // 初始值
                    }
                    fields.append(item)
                }
            case .unknown, .customFieldImage, .cDescription:
                break
            @unknown default:
                break
            }
        }
        LarkProfileDataProvider.logger.info("createItem after filterfields: \(fields.count)")
        return fields
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        guard self.fields.count > indexPath.row else {
            return
        }
        let userInfo = profile.userInfoProtocol
        var params: [AnyHashable: Any] = [:]
        params["click"] = "basic_information_fields"
        params["target"] = "none"
        params["type"] = self.fields[indexPath.row].fieldKey
        params["contact_type"] = LarkProfileTracker.userMap[userInfo.userID]?["contact_type"] ?? ""
        params["to_user_id"] = userInfo.userID
        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    // swiftlint:enable function_body_length

    // 修改备注的回调，得到修改的备注之后更新cell
    func setAliasBlock(_ alias: String) {

        guard let checkedAlias = self.checkName(alias) else { return }
        let userInfo = profile.userInfoProtocol

        chatterAPI?.setChatterAlias(chatterId: userInfo.userID,
                                   contactToken: userInfo.contactToken,
                                   alias: checkedAlias).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.dataProvider?.reloadData()
                self?.profileVC?.navigationController?.popViewController(animated: true)
            }, onError: { [weak self] (error) in
                    UDToast.showFailure(with: BundleI18n.LarkProfile.Lark_Legacy_PersoncardAliasSettingFailed,
                                        on: self?.profileVC?.view ?? UIView(),
                                        error: error)
            }).disposed(by: self.disposeBag)
    }

    private func checkName(_ name: String) -> String? {
        if name.isEmpty {
            return name
        }
        let name = name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            self.showAlertifInputIsEmpty()
            return nil
        } else {
            return name
        }
    }

    // 如果输入内容为空alert提示
    private func showAlertifInputIsEmpty() {
        guard let from = profileVC else { return }
        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.LarkProfile.Lark_Legacy_Hint)
        alert.setContent(text: BundleI18n.LarkProfile.Lark_Legacy_ContentEmpty)
        alert.addPrimaryButton(text: BundleI18n.LarkProfile.Lark_Legacy_ConfirmOk)
        self.userResolver.navigator.present(alert, from: from)
    }
}
