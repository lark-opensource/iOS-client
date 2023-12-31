//
//  LarkWidgetService.swift
//  ColorfulWidght
//
//  Created by ZhangHongyun on 2020/11/25.
//

import Foundation
import UIKit
import Homeric
import RxSwift
import ServerPB
import WidgetKit
import LarkWidget
import LarkSetting
import LarkContainer
import LarkFoundation
import LarkSDKInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkFeatureGating
import LarkTimeFormatUtils
import LarkAccountInterface
import LarkExtensionServices
import LarkLocalizations
import SuiteAppConfig

// 日历 Widget
typealias GetSmartWidgetResquest = ServerPB_Smart_widget_GetSmartWidgetRequest
typealias GetSmartWidgetResponse = ServerPB_Smart_widget_GetSmartWidgetResponse
typealias ServerTodayWidgetEvent = ServerPB_Smart_widget_Event
typealias ServerTodayWidgetAction = ServerPB_Smart_widget_Action

// 常用工具 Widget
typealias GetUtilityWidgetListRequest = ServerPB_Retention_GetWidgetAppListRequest
typealias GetUtilityWidgetListReponse = ServerPB_Retention_GetWidgetAppListResponse
typealias ServerUtilityItemList = ServerPB_Retention_entities_WidgetAppList
typealias ServerUtilityItem = ServerPB_Retention_entities_WidgetApp

// 飞书任务 Widget
typealias GetTodoWidgetRequest = ServerPB_Todos_GetTodoWidgetRequest
typealias GetTodoWidgetResponse = ServerPB_Todos_GetTodoWidgetResponse
typealias ServerTodoItemList = ServerPB_Todos_PagingWidgetResult

public final class LarkWidgetService: NSObject {
    static private let logger = Logger.log(LarkWidgetService.self, category: "LarkWidgetService")
    /// 单例
    public static let share = LarkWidgetService()

    @UserDefaultEncoded(key: WidgetDataKeys.legacyData, default: .notLoginData)
    private var legacyWidgetData: WidgetData

    @UserDefaultEncoded(key: WidgetDataKeys.calendarData, default: .emptyData)
    private var calendarWidgetData: CalendarWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.displayedCalendarData, default: .emptyData)
    private var calendarWidgetDataDisplayed: CalendarWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.utilityData, default: .defaultData)
    private var utilityWidgetData: UtilityWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.todoData, default: .emptyData)
    private var todoWidgetData: TodoWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.displayedTodoData, default: .emptyData)
    private var todoWidgetDataDisplayed: TodoWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .notLoginInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    @UserDefaultEncoded(key: WidgetDataKeys.docsWidgetConfig, default: .default)
    private var docsWidgetConfig: DocsWidgetConfig

    /// 请求API
    private let widgetAPI: WidgetAPI = {
        RustWidgetAPI()
    }()

    @Provider private var accountService: AccountService
    @InjectedLazy var userGeneralSettings: UserGeneralSettings

    /// 防止重复请求（iPad 多 scene 时会收到多个 enterbackground 通知）
    private var isRequestingData: Bool = false

    private let diaposeBag = DisposeBag()

    public func observeAppLanguageChange() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationLanguageDidChange),
            name: Notification.Name.preferLanguageDidChange,
            object: nil
        )
    }
}

// MARK: - App Life Cycle

extension LarkWidgetService {

    /// 应用冷启动时调用
    public func applicationDidLaunch() {
        syncWidgetLanguageWithHostApp()
        fetchCalendarWidgetTimeline()
        fetchUtilityWidgetConfiguration()
        fetchTodoWidgetTimeline()
        updateDocsWidgetConfig()
    }

    /// 飞书登录时调用
    public func applicationDidLogin() {
        authInfo = getCurrentAuthInfo(login: true, minimumMode: false)
        fetchCalendarWidgetTimeline()
        fetchUtilityWidgetConfiguration()
        fetchTodoWidgetTimeline()
        updateDocsWidgetConfig()
    }

    /// 飞书登出时调用
    public func applicationDidLogout() {
        authInfo = getCurrentAuthInfo(login: false, minimumMode: false)
        legacyWidgetData = .notLoginData
        todoWidgetData = .emptyData
        LarkWidgetManager.reloadWidgets(ofType: .all)
    }

    /// 飞书切换租户时调用
    public func applicationDidSwitchAccount() {
        fetchCalendarWidgetTimeline()
        fetchUtilityWidgetConfiguration()
        fetchTodoWidgetTimeline()
        updateDocsWidgetConfig()
    }

    /// 应用返回前台前调用
    public func applicationWillEnterForeground() {
        guard #available(iOS 14, *) else { return }
        syncWidgetLanguageWithHostApp()
        LarkWidgetManager.checkWidgetExistence { [weak self] (types, _, _) in
            if types.contains(.todoWidget) {
                self?.refreshTodoWidgetTimelineIfNeeded()
            }
            if types.contains(.calendarWidget) {
                self?.refreshCalendarWidgetTimelineIfNeeded()
            }
        }
    }

    /// 应用退出后台时调用
    public func applicationDidEnterBackground() {
        guard #available(iOS 14, *) else { return }
        LarkWidgetManager.checkWidgetExistence { [weak self] (types, infoList, error) in
            if types.contains(.calendarWidget) || types.contains(.todayWidget) {
                self?.fetchCalendarWidgetTimeline()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.refreshCalendarWidgetTimelineIfNeeded()
                }
            }
            if types.contains(.todoWidget) {
                self?.fetchTodoWidgetTimeline()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.refreshTodoWidgetTimelineIfNeeded()
                }
            }
            // 日志
            if let infoList = infoList {
                var widgetInfos: [String] = infoList.map { info in
                    "\(info.kind)(\(info.family.trackName))"
                }
                LarkWidgetService.logger.info("check widget existence: \(widgetInfos.joined(separator: ","))")
            } else if let error = error {
                LarkWidgetService.logger.error("check widget existence failed: \(error)")
            }
        }
    }

    @objc public func applicationLanguageDidChange() {
        let appLanguage = LanguageManager.currentLanguage
        LarkWidgetService.logger.warn("app language did change: \(appLanguage.rawValue)")
        UserDefaults(suiteName: appGrounpName)?.set([appLanguage.languageIdentifier], forKey: "AppleLanguages")
        authInfo.appLanguage = appLanguage.rawValue
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 从 Widget 中点击链接跳转到应用内时调用
    /// - Parameter url: Widget 中点击的链接（将埋点加到参数里）
    public func applicationDidOpenURL(_ url: URL) {
        guard let trackParams = WidgetTrackingTool.parseParams(url) else { return }
        Tracker.post(TeaEvent("public_widget_click", params: trackParams))
        // Log
        var readableURL = "scheme: \(url.scheme ?? "none")"
        /*
        if #available(iOS 16.0, *) {
            readableURL.append("url: \(url.host(percentEncoded: false) ?? "none"), ")
            readableURL.append("path: \(url.path(percentEncoded: false)), ")
        } else {
            readableURL.append("url: \(url.host ?? "none"), ")
            readableURL.append("path: \(url.path), ")
        }
        */
        var params = url.queryParameters
        params.removeValue(forKey: WidgetTrackingTool.paramsKey)
        readableURL.append("params: \(params), ")
        readableURL.append("trakcs: \(trackParams)")
        Self.logger.info("Widget link clicked, \(readableURL)")
    }
}

// MARK: - Widget Language

extension LarkWidgetService {

    /// 同步 App 与 Widget 的语言设置
    func syncWidgetLanguageWithHostApp() {
        let authInfo = authInfo
        let widgetLanguage = authInfo.appLanguage
        let appLanguage = LanguageManager.currentLanguage.rawValue
        if widgetLanguage != appLanguage {
            var newAuthInfo = authInfo
            newAuthInfo.appLanguage = appLanguage
            self.authInfo = newAuthInfo
            LarkWidgetManager.reloadWidgets(ofType: .all)
            LarkWidgetService.logger.warn("widget language will change from \(widgetLanguage) to \(appLanguage)")
        }
    }
}

// MARK: - Lean Mode

extension LarkWidgetService {
    
    func switchLeanModeIfNeeded() -> Bool {
        if AppConfigManager.shared.leanModeIsOn {
            legacyWidgetData = WidgetData.minimumModeData
            authInfo = getCurrentAuthInfo(login: false, minimumMode: true)
            calendarWidgetDataDisplayed = .emptyData
            todoWidgetData = .emptyData
            LarkWidgetManager.reloadWidgets(ofType: .all)
            return true
        } else {
            let prevAuthInfo = authInfo
            authInfo = getCurrentAuthInfo(login: accountService.isLogin, minimumMode: false)
            if prevAuthInfo.isMinimumMode == true {
                LarkWidgetManager.reloadWidgets(ofType: .all)
            }
            return false
        }
    }
}

// MARK: - Calendar Widget

extension LarkWidgetService {

    private func refreshCalendarWidgetTimelineIfNeeded() {
        let newCalendarData = calendarWidgetData
        if calendarWidgetDataDisplayed != newCalendarData {
            LarkWidgetManager.reloadWidgets(ofType: .calendarWidget)
        }
    }

    /// 发起获取时间线数据的请求
    public func fetchCalendarWidgetTimeline() {
        guard accountService.isLogin, !isRequestingData else { return }
        if switchLeanModeIfNeeded() { return }
        isRequestingData = true
        widgetAPI.fetchCalendarWidgetTimeline()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                LarkWidgetService.logger.info("fetch calendar widget data succeed, \(response)")
                // TodayWidget 和 CalendarWidget 共用一个网络请求，但是数据模型拆分开
                self?.generateLegacyWidgetData(with: response)
                self?.generateCalendarWidgetData(with: response)
                self?.isRequestingData = false
            }, onError: { [weak self] (error) in
                LarkWidgetService.logger.error("fetch calendar widget data failed, error >>> \(error)")
                self?.isRequestingData = false
            })
            .disposed(by: diaposeBag)
    }

    /// 将服务端数据转化为时间线的Entry
    /// - Parameter response: 服务端数据
    private func generateLegacyWidgetData(with response: GetSmartWidgetResponse) {

        let widgetEvents = response.events.map {
            $0.convertToCalendarEvent()
        }

        var widgetActions = response.actions.map {
            $0.convertToTodayWidgetAction()
        }.filter {
            UIImage(named: $0.iconUrl) != nil
        }

        if widgetActions.isEmpty || widgetActions.count != 3 {
            widgetActions = TodayWidgetAction.defaultActions
        }

        let oldWidgetData = legacyWidgetData
        let newWidgetData = WidgetData(events: widgetEvents, actions: widgetActions)
        if oldWidgetData == newWidgetData {
            LarkWidgetService.logger.info("skip reloading legacy widget timelines")
        } else {
            legacyWidgetData = newWidgetData
            LarkWidgetManager.reloadWidgets(ofType: .todayWidget)
            LarkWidgetService.logger.info("trigger reloading legacy widget timelines")
        }
    }

    private func generateCalendarWidgetData(with response: GetSmartWidgetResponse) {

        let allEvents = response.events.map { $0.convertToCalendarEvent() }
        let newCalendarData = CalendarWidgetModel(events: allEvents)

        if newCalendarData == calendarWidgetDataDisplayed {
            LarkWidgetService.logger.info("skip reloading calendar widget timelines")
        } else {
            calendarWidgetData = newCalendarData
            LarkWidgetManager.reloadWidgets(ofType: .calendarWidget)
            LarkWidgetService.logger.info("trigger reloading calendar widget timelines")
        }
    }
}

extension ServerPB_Smart_widget_Event {

    func convertToCalendarEvent() -> CalendarEvent {
        let displayDate = Date(timeIntervalSince1970: TimeInterval(displayTime) ?? Date().timeIntervalSince1970)
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTime) ?? Date().timeIntervalSince1970)
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTime) ?? Date().timeIntervalSince1970)
        let customOptions = Options(
            timeZone: TimeZone.current,
            is12HourStyle: false,
            shouldShowGMT: true,
            timeFormatType: .short,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .absolute
        )
        let subTitle = TimeFormatUtils.formatDateTimeRange(
            startFrom: startDate,
            endAt: endDate,
            with: customOptions
        )
        return CalendarEvent(displayTime: displayDate,
                             name: name,
                             subtitle: subTitle,
                             description: description_p,
                             appLink: appLink,
                             startTime: startDate,
                             endTime: endDate)
    }
}

extension ServerPB_Smart_widget_Action {

    func convertToTodayWidgetAction() -> TodayWidgetAction {
        return TodayWidgetAction(name: name,
                                 appLink: appLink,
                                 iconUrl: iconURL)
    }
}

extension ServerPB_Smart_widget_GetSmartWidgetResponse: CustomStringConvertible {

    public var description: String {
        "<GetSmartWidgetResponse> \(self.events.count) events: \(self.events.map({ $0.description }).joined(separator: ", "))"
    }
}

extension ServerPB_Smart_widget_Event: CustomStringConvertible {

    public var description: String {
        "[\(name.desensitized()), \(subtitle), start at \(startTime), end at \(endTime)]"
    }
}

// MARK: - Utility Widget

extension LarkWidgetService {

    public func fetchUtilityWidgetConfiguration() {
        guard accountService.isLogin else { return }
        if switchLeanModeIfNeeded() { return }
        let isFeishu = accountService.isFeishuBrand
        widgetAPI.fetchUtilityWidgetData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                LarkWidgetService.logger.info("fetch utility widget data succeed, \(response)")
                let quickTools = response.list["quick_tools"]?.convertToToolsList() ?? []
                let navigationTools = response.list["navigations"]?.convertToToolsList() ?? []
                let workplaceTools = response.list["workplace"]?.convertToToolsList() ?? []
                let data = UtilityWidgetModel(
                    quickTools: quickTools,
                    navigationTools: navigationTools,
                    workplaceTools: workplaceTools
                )
                self.utilityWidgetData = data
                self.authInfo = self.getCurrentAuthInfo(login: true, minimumMode: false)
                LarkWidgetManager.reloadWidgets(ofType: .utilityWidget)
                // 线上存在 key 上报错误的情况，此处添加 Slardar 埋点排查问题
                if data.lostTrackingKeys {
                    Tracker.post(SlardarEvent(name: "utility_widget_lost_tracking_keys", metric: [
                        "response": response,
                        "userID": self.accountService.currentChatterId
                    ], category: [:], extra: [:]))
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                LarkWidgetService.logger.error("fetch utility widget data failed, error >>> \(error)")
                if self.utilityWidgetData.isEmpty {
                    self.utilityWidgetData = .defaultData
                }
                self.authInfo = self.getCurrentAuthInfo(login: true, minimumMode: false)
                LarkWidgetManager.reloadWidgets(ofType: .utilityWidget)
            })
            .disposed(by: diaposeBag)
    }
}

extension ServerPB_Retention_entities_WidgetAppList {

    func convertToToolsList() -> [UtilityTool] {
        return widgetAppList.map { widgetApp in
            UtilityTool(
                name: widgetApp.name,
                iconKey: widgetApp.icon,
                colorKey: widgetApp.color,
                resourceKey: widgetApp.resource,
                appLink: widgetApp.appLink,
                key: widgetApp.key
            )
        }.filter { utilityTool in
             utilityTool.isValid
        }
    }
}

// MARK: - Todo Widget

extension LarkWidgetService {

    private func refreshTodoWidgetTimelineIfNeeded() {
        let newTodoData = todoWidgetData
        if todoWidgetDataDisplayed != todoWidgetData {
            LarkWidgetManager.reloadWidgets(ofType: .todoWidget)
        }
    }

    private func fetchTodoWidgetTimeline() {
        if switchLeanModeIfNeeded() { return }
        widgetAPI.fetchTodoWidgetTimeline()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                LarkWidgetService.logger.info("fetch todo widget data succeed, \(response)")
                let newTodoData = self.createTodoWidgetModel(with: response)
                if newTodoData == self.todoWidgetDataDisplayed {
                    LarkWidgetService.logger.info("skip reloading todo widget timelines")
                } else {
                    self.todoWidgetData = newTodoData
                    LarkWidgetManager.reloadWidgets(ofType: .todoWidget)
                    LarkWidgetService.logger.info("trigger reloading todo widget timelines")
                }
            }, onError: { (error) in
                LarkWidgetService.logger.error("fetch todo widget data failed, error >>> \(error)")
            })
            .disposed(by: diaposeBag)
    }

    private func createTodoWidgetModel(with response: GetTodoWidgetResponse) -> TodoWidgetModel {
        let userID = accountService.currentChatterId
        return TodoWidgetModel(
            items: response.widgetResult.todoWidget.map { $0.convertToTodoItem(userID: userID) },
            totalCount: Int(response.total),
            todoNewLink: response.createTodoAppLink,
            todoTabLink: response.enterTabAppLink,
            is24Hour: userGeneralSettings.is24HourTime.value
        )
    }
}

extension ServerPB_Entities_TodoWidget {

    func convertToTodoItem(userID: String) -> TodoItem {
        return TodoItem(
            id: guid,
            title: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            deadline: dueTime == 0 ? nil : dueTime,
            isAllDay: isAllDay,
            hasPermission: userID == creatorID || permission.canCompleteSelf || permission.canCompleteTodo,
            appLink: appLink
        )
    }
}

// ServerPB_Todos_GetTodoWidgetResponse

extension ServerPB_Todos_GetTodoWidgetResponse: CustomStringConvertible {

    public var description: String {
        "<GetTodoWidgetResponse> \(widgetResult.todoWidget.count) events: \(widgetResult.todoWidget.map({ $0.summary.desensitized() }).joined(separator: ", "))"
    }
}

// MARK: - Docs Widget

extension LarkWidgetService {

    private func updateDocsWidgetConfig() {
        // docs domain
        let settings = DomainSettingManager.shared.currentSetting
        let prefixMainDomain = AccountServiceAdapter.shared.currentAccountInfo.tenantInfo.tenantCode
        let postMainDomain = settings[.docsMainDomain]?.first ?? ""
        let mainDomain = "\(prefixMainDomain).\(postMainDomain)"
        // docs FG
        let isNewAPIEnabled = LarkFeatureGating.shared.getFeatureBoolValue(for: "spacekit.mobile.single_container_enable")
        var docsWidgetConfig = DocsWidgetConfig(domain: mainDomain, useNewPath: isNewAPIEnabled)
        // app version
        if let dictionary = Bundle.main.infoDictionary,
           let version = dictionary["CFBundleShortVersionString"] as? String {
            docsWidgetConfig.appVersion = version
        }
        self.docsWidgetConfig = docsWidgetConfig
        // request drive domain
        DocsWidgetNetworking.getDriveDomain { [weak self] driveDomain, error in
            if let driveDomain = driveDomain {
                self?.docsWidgetConfig.driveDomain = driveDomain
            } else if let error = error {
                LarkWidgetService.logger.error("request drive domain failed: \(error)")
            }
        }
    }
}

// MARK: - Auth Info

extension LarkWidgetService {
    
    func getCurrentAuthInfo(login: Bool, minimumMode: Bool) -> WidgetAuthInfo {
        let isFeishu = accountService.isFeishuBrand
        // Help Center: https://bytedance.larkoffice.com/docs/doccnJXVYOle7Etw6dQZYvSMdUc
        let helpCenterHost = DomainSettingManager.shared.currentSetting["help_center"]?.first
        // Applink: https://bytedance.larkoffice.com/wiki/wikcnWUM6b8Or3fg6ZOhVrKmARb
        let applinkHost = DomainSettingManager.shared.currentSetting["applink"]?.first
        let docsHomeHost = DomainSettingManager.shared.currentSetting[.docsHome]?.first
        // log
        LarkWidgetService.logger.info("Update widget auth info. isFeishu: \(isFeishu), helpCenter: \(helpCenterHost ?? ""), applink: \(applinkHost ?? ""), docsHome: \(docsHomeHost ?? "")")
        if helpCenterHost == nil {
            LarkWidgetService.logger.error("Got empty help center host.")
        }
        if applinkHost == nil {
            LarkWidgetService.logger.error("Got empty applink host.")
        }
        if docsHomeHost == nil {
            LarkWidgetService.logger.error("Got empty docs home host.")
        }
        let authInfo = WidgetAuthInfo(
            isMinimumMode: minimumMode,
            isLogin: login,
            isFeishuBrand: isFeishu,
            helpCenterHost: helpCenterHost,
            applinkHost: applinkHost,
            docsHost: docsHomeHost
        )
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)
        return authInfo
    }
}
