//
//  AppSettingViewModel.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/20.
//

import EENavigator
import LKCommonsLogging
import LarkRustClient
import LarkSetting
import RxSwift
import SwiftyJSON
import Swinject
import LarkUIKit
import EEMicroAppSDK
import LarkContainer
import LarkOPInterface
import LarkAccountInterface
import UIKit
import SwiftUI

protocol AppSettingViewModelDelegate: AnyObject {
    func viewModelChanged()
}

class AppSettingViewModel {
    struct Const {
        let resolve: UserResolver
        let normalCellHeight: CGFloat = 52
        lazy var Report: String = {
            if let reportDomain = AppDetailUtils(resolver: resolve).internalDependency?.host(for: .suiteReport) {
                let reportUrl = "https://\(reportDomain)/report/"
                return reportUrl
            } else {
                return ""
            }
        }()
    }

    private var httpClient: OpenPlatformHttpClient
    static let log = Logger.log(AppSettingViewModel.self, category: "LarkAppCenter.AppSettingViewModel")

    weak var delegate: AppSettingViewModelDelegate?

    private let botId: String
    let appId: String
    private let params: [String: String]?
    private let resolver: UserResolver
    private let fileCacheManager: LarkOPFileCacheManager?
    private let microAppService: MicroAppService
    private let client: RustService
    private let disposeBag = DisposeBag()
    private var dataSourceType = [AppSettingCellType]()
    private var dataSourceHeight = [CGFloat]()
    private var const: Const
    let appInfoUpdate = PublishSubject<Bool>()
    var superViewSize: (() -> CGSize)!
    var appDetailInfo: AppDetailInfo?
    var scene: AppSettingOpenScene
    var permissionData: [MicroAppPermissionData]?
    var permissionIndex = -1
    var appBadgePermissionData: MicroAppPermissionData?
    // FG
    let reportEnabled: Bool // 举报入口FG控制
    var containerWidth = UIScreen.main.bounds.size.width
    var isShowAppSettingHeader = false //是否显示应用设置的header
    /// 是否展示分享入口
    var isShowShare: Bool = false

    init(botId: String = "",
         appId: String = "",
         params: [String: String]? = nil,
         scene: AppSettingOpenScene,
         resolver: UserResolver) throws {
        self.scene = scene
        self.botId = botId
        self.appId = appId
        self.params = params
        self.resolver = resolver
        client = try resolver.resolve(assert: RustService.self)
        self.httpClient = try resolver.resolve(assert: OpenPlatformHttpClient.self)
        let userId = resolver.userID
        self.fileCacheManager = AppDetailUtils(resolver: resolver).internalDependency?.buildFileCache(for: userId)
        microAppService = try resolver.resolve(assert: MicroAppService.self)
        reportEnabled = resolver.fg.dynamicFeatureGatingValue(with: "feishu.report")
        const = AppSettingViewModel.Const(resolve: resolver, Report: nil)
    }

    func cellCount() -> Int {
        guard dataSourceType.count == dataSourceHeight.count else { return 0 }
        return dataSourceHeight.count
    }

    func heightForCurCell(index: Int) -> CGFloat {
        guard index >= 0, index < cellCount() else { return 0 }
        return dataSourceHeight[index]
    }

    func cellTypeAt(index: Int) -> AppSettingCellType? {
        guard index >= 0, index < dataSourceType.count else { return nil }
        return dataSourceType[index]
    }

    func appBadgeData() -> MicroAppPermissionData? {
        let badgeOnFG = resolver.fg.dynamicFeatureGatingValue(with: "gadget.open_app.badge")
        return badgeOnFG ? appBadgePermissionData : nil
    }

    func permissionStateAt(index: Int) -> (permission: MicroAppPermissionData, isLastPermission: Bool)? {
        guard index >= 0, index < dataSourceType.count, let curPermissions = permissionData else {
            return nil
        }
        guard permissionIndex >= 0, permissionIndex + curPermissions.count <= dataSourceType.count else {
            return nil
        }
        let curPermIndex = index - permissionIndex
        guard curPermIndex >= 0, curPermIndex < curPermissions.count else {
            return nil
        }
        let curPermission = curPermissions[curPermIndex]
        let isLastPermission = (curPermIndex == curPermissions.count - 1)
        return (curPermission, isLastPermission)
    }

    func fetchAppInfo() {
        guard !(appId.isEmpty && botId.isEmpty) else { return }
        fetchAppInfoFromLocal()
        if appDetailInfo != nil {
            appInfoUpdate.onNext(false)
        }
        fetchAppInfoFromRemote()
    }

    func openUserAgreement(from: UIViewController) {
        guard let appInfo = appDetailInfo,
            !appInfo.getLocalClauseUrl().isEmpty,
            let url = URL(string: appInfo.getLocalClauseUrl()) else { return }
        resolver.navigator.push(url, from: from)
    }

    func openPrivacyPolicy(from: UIViewController) {
        guard let appInfo = appDetailInfo,
            !appInfo.getLocalPrivacyUrl().isEmpty,
            let url = URL(string: appInfo.getLocalPrivacyUrl()) else { return }
        resolver.navigator.push(url, from: from)
    }

    func updatePermission(scope: String, isGranted: Bool) {
        guard !scope.isEmpty, !appId.isEmpty else { return }
        let type: OPAppType = scene == .H5 ? .webApp : .gadget
        microAppService.setPermissonWith(appID: appId, scope: scope, isGranted: isGranted, appType: type)
        var trackParams = [AnyHashable: Any]()
        trackParams["app_id"] = appId
        if let detailInfo = appDetailInfo {
            trackParams["appname"] = detailInfo.getLocalTitle()
        }
        if scene == .H5 {
            trackParams["application_type"] = "H5"
        } else {
            trackParams["application_type"] = "MP"
        }
        trackParams["action"] = isGranted ? "open" : "close"
        trackParams["source"] = "about"
        trackParams["appname"] = appDetailInfo?.getLocalTitle()
        AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: "app_setting_set_Badge", params: trackParams)
    }

    func updateNotificationWith(isOn: Bool) {
        /// 需要的参数有 appID 和 notificationtype 1 - 开启  2 - 关闭
        var notificationtype: Int
        if isOn {
            notificationtype = 1
        } else {
            notificationtype = 2
        }
        let requestAPI = OpenPlatformAPI.updateNotifacation(appID: appId, notificationType: notificationtype, resolver: resolver)
        httpClient.request(api: requestAPI).subscribe().dispose()
    }

    func openDeveloperChat(from: UIViewController) {
        guard let appInfo = appDetailInfo, !appInfo.developerId.isEmpty, !appInfo.isISV() else { return }
        let info = AppDetailChatInfo(
            userId: appInfo.developerId,
            from: from,
            disposeBag: self.disposeBag
        )
        AppDetailUtils(resolver: resolver).internalDependency?.toChat(info, completion: nil)
    }

    func openReport(from: UIViewController) {
        let reportId = appDetailInfo?.appId ?? appId
        let params = JSON(["app_id": reportId]).rawString()
        guard !reportId.isEmpty, let paramsStr = params else {
            Self.log.error("openReport reportid is empty or params json failed")
            return
        }
        guard let url = URL(string: const.Report) else {
            Self.log.error("openReport url init string failed")
            return
        }
        let reportUrl = url.lf.addQueryDictionary(["type": "app",
                                                   "params": paramsStr])
        guard let reportStr = reportUrl?.lf.toHttpUrl() else {
            Self.log.error("openReport url with query to http url failed")
            return
        }
        resolver.navigator.push(reportStr, from: from)
    }

    /// 打开分享模块
    func openShare(from: UIViewController) {
        guard !appId.isEmpty else {
            AppSettingViewModel.log.error("appId missing, can't open share")
            return
        }
        AppSettingViewModel.log.info("open share with appId:\(appId), scene:\(scene)")
        switch scene {
        case .H5:
            AppDetailUtils(resolver: resolver).internalDependency?.shareApp(with: appId, entry: .webAppAbout, from: from)
        case .MiniApp:
            AppDetailUtils(resolver: resolver).internalDependency?.shareApp(with: appId, entry: .gadgetAbout, from: from)
        }
    }

    /// 本地拉取 app 信息
    private func fetchAppInfoFromLocal() {
        let fileName = self.appId.isEmpty ? self.botId : self.appId
        guard !fileName.isEmpty else { return }
        let result = fileCacheManager?.readFromFile(fileName: fileName)
        guard let jsonStr = result, !jsonStr.isEmpty else { return }
        let json = JSON(parseJSON: jsonStr)
        appDetailInfo = AppDetailInfo(json: json)
        computeDataSource()
        delegate?.viewModelChanged()
    }

    /// 远程拉取 app 信息
    private func fetchAppInfoFromRemote() {
        guard !(appId.isEmpty && botId.isEmpty) else {
            appInfoUpdate.onNext(true)
            return
        }
        var request = GetAppDetailRequest()
        request.appID = appId
        request.botID = botId
        if let version = params?["version"] {
            request.miniProgramVersion = version
        }
        let monitorSuccess = OPMonitor(EPMClientOpenPlatformAppSettingCode.pull_about_info_success)
            .setResultTypeSuccess()
            .addCategoryValue("app_id", appId)
            .addCategoryValue("bot_id", botId)
            .setPlatform([.tea, .slardar])
        let monitorFail = OPMonitor(EPMClientOpenPlatformAppSettingCode.pull_about_info_fail)
            .setResultTypeFail()
            .addCategoryValue("app_id", appId)
            .addCategoryValue("bot_id", botId)
            .setPlatform([.tea, .slardar])
        client.sendAsyncRequest(request, transform: { [weak self] (response: GetAppDetailResponse) -> Void in
            guard let `self` = self else { return }
            let json = JSON(parseJSON: response.jsonResp)
            let errorCode = json["code"].intValue
            if errorCode == 0 { // 成功
                monitorSuccess.timing().flush()
                let appDetailInfo = AppDetailInfo(json: json)
                self.appDetailInfo = appDetailInfo
                let fileName = self.appId.isEmpty ? self.botId : self.appId
                if let result = json.rawString(), !fileName.isEmpty {
                    self.fileCacheManager?.writeToFile(fileName: fileName, data: result)
                }
                self.computeDataSource()
                self.appInfoUpdate.onNext(false)
                self.delegate?.viewModelChanged()
                self.fetchAuthorizeData()
                return
            }
            AppSettingViewModel.log.debug("fetchAppInfoFromRemote error: \(errorCode)")
            monitorFail.addCategoryValue("error_code", errorCode).timing().flush()
            self.appInfoUpdate.onNext(true)
            self.fetchAuthorizeData()
        }) .catchError({[weak self] (error) -> Observable<Void> in
            self?.appInfoUpdate.onNext(true)
            monitorFail.addCategoryValue("error", error).timing().flush()
            AppSettingViewModel.log.debug("fetchAppInfoFromRemote error: \(error)")
            self?.fetchAuthorizeData()
            return .empty()
        }).subscribe()
            .disposed(by: disposeBag)
    }

    private func fetchAuthorizeData() {
        AppSettingViewModel.log.error("start fetchAuthData")
        let type: OPAppType = scene == .H5 ? .webApp : .gadget
        microAppService.fetchAuthorizeData(appID: appId, appType: type, storage: true) { [weak self] (result, bizData, error) in
            AppSettingViewModel.log.error("fetchAuthData,result: \(String(describing: result)),bizdata:\(String(describing: bizData)),error:\(String(describing: error))")
            guard let `self` = self else {
                AppSettingViewModel.log.error("viewModel is nil")
                return
            }
            if let error = error {
                OPMonitor(EPMClientOpenPlatformAppSettingCode.pull_authorize_data_info_fail)
                    .setResultTypeFail()
                    .timing()
                    .addCategoryValue("app_id", self.appId)
                    .setPlatform([.tea, .slardar])
                    .flush()
            } else {
                OPMonitor(EPMClientOpenPlatformAppSettingCode.pull_authorize_data_info_success)
                    .setResultTypeSuccess()
                    .timing()
                    .setPlatform([.tea, .slardar])
                    .addCategoryValue("app_id", self.appId)
                    .flush()
            }
            guard let bizData = bizData else {
                AppSettingViewModel.log.info("bizData is nil")

                return
            }
            if let hasNewData = bizData["hasNewData"] as? Bool, hasNewData {
                DispatchQueue.main.async {
                    self.computeDataSource()
                    self.appInfoUpdate.onNext(false)
                }
            }
        }
    }

    /// 处理数据源数据
    private func computeDataSource() {
        guard let appInfo = appDetailInfo else { return }
        dataSourceType.removeAll()
        dataSourceHeight.removeAll()

        // 拉取权限信息
        if !appId.isEmpty, [.MiniApp, .H5].contains(scene) {
            let type: OPAppType = scene == .H5 ? .webApp : .gadget
            let permissionDataSource = microAppService.getPermissionDataArrayWith(appID: self.appId, appType: type)
            var appendPermissionDatas = [MicroAppPermissionData]()
            for permission in permissionDataSource {
                if let permission = permission as? MicroAppPermissionData {
                    var allowAppend = true
                    if permission.scope == "appBadge" {
                        allowAppend = false
                        appBadgePermissionData = permission
                    }
                    if allowAppend {
                        appendPermissionDatas.append(permission)
                    }
                }
            }
            permissionData = appendPermissionDatas
        }

        /// 1.处理 TopView 展示应用 info
        dataSourceType.append(.TopView)
        var topViewHeight: CGFloat
        if appInfo.version.isEmpty {
            topViewHeight = 155
        } else {
            topViewHeight = 177
        }
        /// app 名字若是两行则增加高度
        topViewHeight += isSingleAppName() ? 0 : 28
        dataSourceHeight.append(topViewHeight)

        /// 2.处理开发者信息
        if !appInfo.getLocalDeveloperInfo().isEmpty {
            /// 开发者信息换行也需要增加高度
            if isSingleDeveloperInfo() {
                dataSourceType.append(.Developer)
                dataSourceHeight.append(const.normalCellHeight + (self.permissionData?.isEmpty ?? true &&
                    (!appInfo.getLocalClauseUrl().isEmpty || !appInfo.getLocalPrivacyUrl().isEmpty) && !isShowAppSettingHeader ? 8 : 0))
            } else {
                dataSourceType.append(.Developer)
                dataSourceHeight.append(72 + (self.permissionData?.isEmpty ?? true &&
                    (!appInfo.getLocalClauseUrl().isEmpty || !appInfo.getLocalPrivacyUrl().isEmpty) && !isShowAppSettingHeader ? 8 : 0))
            }
        }

        let authFreeFG = BDPAuthorization.authorizationFree()
        /// 4.处理应用通知
        let addNotificationItem = (appInfo.notificationType == .Open || appInfo.notificationType == .Close)
        let addAppBadgeItem = (appBadgeData() != nil) ? true : false
        let hasPermissionData = permissionData != nil
        if !authFreeFG {
            var notificationItemHeight = const.normalCellHeight
            var appBadgeItemHeight = const.normalCellHeight
            if addNotificationItem && !addAppBadgeItem {
                notificationItemHeight = const.normalCellHeight + (hasPermissionData ? 0 : 8)
            }
            if addAppBadgeItem {
                let text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_EnableBadge
                let maxWidth = containerWidth - 16 - 24 - 16 - 51
                var height = (text as NSString).boundingRect(with: CGSize(width: maxWidth, height: 200),
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)],
                                                       context: nil).height
                if height < 0 {
                    height = 65 // 给个默认值
                }
                appBadgeItemHeight = const.normalCellHeight + 8 + height + 8 + (hasPermissionData ? 0 : 8) // height subttitle 高度，2 subtitle 和 title 距离, 增加分割区域高度
            }
            if addNotificationItem || addAppBadgeItem {
                isShowAppSettingHeader = true
                dataSourceType.append(.AppSettingHeader)
                dataSourceHeight.append(42)
            }
            if addNotificationItem {
                dataSourceType.append(.AppSettingCell)
                dataSourceHeight.append(notificationItemHeight + (addAppBadgeItem ? 8 : 0))
            }
            if addAppBadgeItem {
                dataSourceType.append(.AppSettingSubtitleCell)
                dataSourceHeight.append(appBadgeItemHeight)
            }
        } else if addNotificationItem {
            isShowAppSettingHeader = true
            dataSourceType.append(.AppSettingHeader)
            dataSourceHeight.append(42)
            dataSourceType.append(.AppSettingCell)
            dataSourceHeight.append(const.normalCellHeight)
        }

        /// 5.处理消息红点
        if appBadgeData() != nil && authFreeFG {
            if !addNotificationItem {
                // 如果没有通知的item，那么这边需要加settingheader
                isShowAppSettingHeader = true
                dataSourceType.append(.AppSettingHeader)
                dataSourceHeight.append(42)
            }
            dataSourceType.append(.AppBadgeCell)
            let text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_EnableBadge
            let maxWidth = containerWidth - 16 - 24 - 16 - 51
            var height = (text as NSString).boundingRect(with: CGSize(width: maxWidth, height: 200),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)],
                                                   context: nil).height
            if height < 0 {
                height = 65 // 给个默认值
            }
            let appBadgeHeight = const.normalCellHeight + 8 + height + 8 + (hasPermissionData ? 0 : 8) // height subttitle 高度，2 subtitle 和 title 距离, 增加分割区域高度
            dataSourceHeight.append(appBadgeHeight)
        }
        
        /// 6.处理多个权限 cell
        /// 若是一方应用 权限不可修改
        if let permissions = permissionData, !permissions.isEmpty {
            dataSourceType.append(.PermissionComment)
            dataSourceHeight.append(42)
            if isModPermission(permissions: permissions) {
                permissionIndex = dataSourceType.count
                for index in 0 ..< permissions.count {
                    dataSourceType.append(.Permission)
                    if index == permissions.count - 1 {
                        dataSourceHeight.append(const.normalCellHeight + 8)
                        continue
                    }
                    dataSourceHeight.append(const.normalCellHeight)
                }
            } else {
                dataSourceType.append(.UnModPermission)
                let w = UIScreen.main.bounds.width - 32
                let appAuthExemptAuthText = BundleI18n.AppDetail.LittleApp_AppAuth_ExemptAuthorization()
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                let labelH = NSString(string: appAuthExemptAuthText).boundingRect(
                    with: CGSize(width: w, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 14.0), .paragraphStyle: paragraphStyle], context: nil
                ).size.height
                dataSourceHeight.append(labelH + 24)
            }
        }

        /// 7.处理用户协议 cell
        if !appInfo.getLocalClauseUrl().isEmpty {
            dataSourceType.append(.UserAgreement)
            dataSourceHeight.append(const.normalCellHeight)
        }

        /// 8.处理隐私条款 cell
        if !appInfo.getLocalPrivacyUrl().isEmpty {
            dataSourceType.append(.PrivacyPolicy)
            dataSourceHeight.append(const.normalCellHeight)
        }
        
        /// 9.举报应用 cell
        if showReport() {
            dataSourceType.append(.ReportApp)
            dataSourceHeight.append(64)
        }
    }

    // 判断权限是否可以修改
    private func isModPermission(permissions: [MicroAppPermissionData]) -> Bool {
        for index in 0 ..< permissions.count {
            if permissions[index].mod == .readOnly {
                return false
            }
        }
        return true
    }
    
    func isSingleDeveloperInfo() -> Bool {
        guard let appInfo = appDetailInfo else { return true }
        return widthForText(text: appInfo.getLocalDeveloperInfo(),
                            font: UIFont.systemFont(ofSize: 14.0),
                            height: 20) <= superViewSize().width - 168 - (appInfo.isISV() ? 22 : 0)
    }

    // 是否显示举报入口
    func showReport() -> Bool {
        /// 以前判断的是oversea，这里判断是飞书品牌
        let reportId = appDetailInfo?.appId ?? appId
        return !reportId.isEmpty && reportEnabled && AppDetailUtils(resolver: resolver).internalDependency?.isFeishuBrand ?? false
    }

    private func isSingleAppName() -> Bool {
        guard let appInfo = appDetailInfo else { return true }
        return widthForText(text: appInfo.getLocalTitle(),
                            font: UIFont.systemFont(ofSize: 20.0),
                            height: 28) <= superViewSize().width - 32
    }

    private func isSinglePermComment() -> Bool {
        guard let appInfo = appDetailInfo else { return true }
        let text = BundleI18n.AppDetail.AppDetail_Setting_PermissionTitle(app_name: appInfo.getLocalTitle())
        return widthForText(text: text,
                            font: UIFont.systemFont(ofSize: 12.0),
                            height: 17) <= superViewSize().width - 32
    }

    private func widthForText(text: String, font: UIFont?, height: CGFloat) -> CGFloat {
        if let curFont = font {
            return (text as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [.font: curFont],
                                                   context: nil).width
        }
        return (text as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                               options: .usesLineFragmentOrigin,
                                               attributes: nil,
                                               context: nil).width
    }
}
