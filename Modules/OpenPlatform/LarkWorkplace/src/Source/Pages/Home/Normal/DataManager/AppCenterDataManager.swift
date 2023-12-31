//
//  AppCenterDataManager.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/10/10.
//

import Foundation
import LKCommonsLogging
import LarkRustClient
import LarkUIKit
import RxSwift
import SwiftyJSON
import Swinject
import ECOInfra
import ECOProbe
import ECOProbeMeta
import LarkSetting
import LarkContainer
import LarkStorage
import LarkAccountInterface

final class AppCenterDataManager {
    static let logger = Logger.log(AppCenterDataManager.self)

    /// 是否支持使用内存中的数据来加载工作台
    private var enableUseDataFromMemory: Bool {
        return configService.fgValue(for: .enableUseDataFromMemory)
    }

    /// 默认错误信息
    static let defaultErrCode: Int = -1
    static let defaultErrMsg: String = "unkown error"

    /// 工作台数据是否正在更新
    private(set) var isWorkplaceDataRefreshing = false
    /// 工作台主页数据上次更新时间戳
    private(set) var workplaceDataLastRefreshTime: TimeInterval = 0

    private(set) var navTitle: String = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title

    let userId: String
    let traceService: WPTraceService
    let dependency: WPDependency
    let networkService: WPNetworkService
    let userService: PassportUserService
    private let rustService: RustService
    private let homeDataService: WPNormalHomeDataService
    private let configService: WPConfigService
    private let appCenterBadgeServiceProvider: () -> AppCenterBadgeService?
    let disposeBag = DisposeBag()
    var appCenterBadgeService: AppCenterBadgeService? {
        return appCenterBadgeServiceProvider()
    }

    init(
        userId: String,
        traceService: WPTraceService,
        dependency: WPDependency,
        networkService: WPNetworkService,
        rustService: RustService,
        homeDataService: WPNormalHomeDataService,
        configService: WPConfigService,
        appCenterBadgeServiceProvider: @escaping () -> AppCenterBadgeService?,
        userService: PassportUserService
    ) {
        self.userId = userId
        self.traceService = traceService
        self.dependency = dependency
        self.networkService = networkService
        self.rustService = rustService
        self.homeDataService = homeDataService
        self.configService = configService
        self.appCenterBadgeServiceProvider = appCenterBadgeServiceProvider
        self.userService = userService
    }

    /// 上报热度
    func feedbackRecentApp(appId: String, appType: AppType) {
        var request = FeedbackRecentAppRequest()
        request.appID = appId
        request.appType = appType
        var disposeBag = DisposeBag()
        rustService
            .sendAsyncRequest(request)
            .subscribe(onNext: {(_) in
                disposeBag = DisposeBag()
            }).disposed(by: disposeBag)
    }
}

// MARK: File Cache
extension AppCenterDataManager {
    /// 检查原生工作台首页数据是否有缓存
    func checkHasCache() -> Bool {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        return store.contains(key: WPCacheKey.nativePortalModule)
    }

    /// 获取原生工作台首页数据缓存
    func getWidgetHomeModelFromCache() -> WorkPlaceDataModel? {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        let model: WorkPlaceDataModel? = store.value(forKey: WPCacheKey.nativePortalModule)
        Self.logger.info("[\(WPCacheKey.nativePortalModule)] cache \(model == nil ? "miss" : "hit").")
        return model
    }

    /// 将原生工作台首页数据写入缓存
    /// - Parameter model: 原生工作台首页数据
    private func cacheWidgetHomeModel(model: WorkPlaceDataModel) {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        store.set(model, forKey: WPCacheKey.nativePortalModule)
        Self.logger.info("[\(WPCacheKey.nativePortalModule)] cache data.")
    }
}

// MARK: 配置版工作台（widget）
extension AppCenterDataManager {
    /// 首页数据返回之后，在子线程构造WidgetCenterHomeModel
    /// - Parameter from: 远程拉取的json
    private func buildWidgetCenterHomeModel(with json: JSON) -> WorkPlaceDataModel? {
        assert(!Thread.isMainThread, "Widgetcheck work thread")
        let monitorEvent = OPMonitor(AppCenterMonitorEvent.appcenter_build_home_model)
        let start = Date()
        let model = WorkPlaceDataModel(json: json, dependency: dependency)
        Self.logger.info("Widget：json -> WorkPlaceDataModel cost %@ s\(Date().timeIntervalSince(start))")
        /// 如果code不是0，则网络失败
        guard json["code"].int == 0 else {
            Self.logger.error("Widget: build model from json failed,\(json)")
            monitorEvent
                .setResultTypeFail()
                .setErrorCode("\(json["code"].int ?? AppCenterDataManager.defaultErrCode)")
                .setErrorMessage("Widget: build model from json failed, \(String(describing: json["msg"].string))")
                .setErrorCode(json["code"].string)
                .flush()
            return nil
        }
        let time = Date().timeIntervalSince1970
        Self.logger.info("Widget: start to build work place home model: \(time)")
        return model
    }

    /// 获取新版工作台首页列表数据
    /// - Parameter needCache: 是否需要缓存数据
    /// - Parameter success: 成功回调
    /// - Parameter failure: 失败回调
    func fetchItemInfoWith(
        needCache: Bool = true,
        success: @escaping (_ model: WorkPlaceDataModel, _ isFromCache: Bool) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 涉及极其耗时的操作，不要在主线程执行
        // 标识正在刷新数据
        isWorkplaceDataRefreshing = true
        let trace = self.traceService.lazyGetTrace(for: .normal, with: nil)
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            /// 1. 如果需要cache从本地拉取数据，若成功则进行success回调
            let getHomeCacheData = OPMonitor(WPMWorkplaceCode.workplace_home_get_cache_data).timing()
            let homeData = self.homeDataService.getHomeData()
            if needCache {
                Self.logger.info("WorkPlace start check cache for first enter", additionalData: [
                    "enableUseDataFromMemory": "\(self.enableUseDataFromMemory)",
                    "hasData": "\(homeData != nil)"
                ])
                if self.enableUseDataFromMemory,
                   let workplaceDataModel = homeData {
                    Self.logger.info("read workplace home data from memory")
                    DispatchQueue.main.async {
                        success(workplaceDataModel, true)
                        getHomeCacheData.setResultTypeSuccess().timing().flush()
                        // 数据更新通知
                        self.onWorkplaceDataUpdate(dataModel: workplaceDataModel, fromCache: true)
                    }
                } else {
                    if let model = self.getWidgetHomeModelFromCache() {
                        Self.logger.info("WorkPlace home page hit cache for first enter")
                        DispatchQueue.main.async {
                            success(model, true)
                            getHomeCacheData.setResultTypeSuccess().timing().flush()
                            // 数据更新通知
                            self.onWorkplaceDataUpdate(dataModel: model, fromCache: true)
                        }
                    } else {
                        Self.logger.info("WorkPlace home page missed cache for first enter")
                        getHomeCacheData.setError(nil).setResultTypeFail().timing().flush()
                    }
                }
            }
            /// 2. 异步从远程拉取数据，成功则进行success回调
            let reqOPMonitor = WPMonitor().timing()
            self.requestWidgetCenterHomeInfo(
                success: { [weak self] (json) in
                    Self.logger.info("WorkPlace home page request success via network")
                    let logId = json[WPNetworkConstants.logId].string
                    reqOPMonitor.setCode(WPMCode.workplace_home_data_request_success)
                        .setTrace(trace)
                        .setNetworkStatus()
                        .setInfo([
                            "log_id": logId ?? ""
                        ])
                        .postSuccessMonitor(endTiming: true)
                    let buildWidgetModelEvent = OPMonitor(WPMWorkplaceCode.workplace_home_get_data_build_error).timing()
                    guard let model = self?.buildWidgetCenterHomeModel(with: json) else {
                        Self.logger.error("WorkPlace home page parse dataModel failed")
                        DispatchQueue.main.async {
                            let codeInfo = WPMWorkplaceCode.workplace_fetchiteminfo_model_build_error
                            let monitorCode = OPMonitorCode(
                                domain: codeInfo.domain,
                                code: codeInfo.code,
                                level: codeInfo.level,
                                message: codeInfo.message
                            )
                            let error = OPError.error(monitorCode: monitorCode)
                            failure(error)
                            buildWidgetModelEvent.setError(error).timing().flush()
                        }
                        return
                    }
                    /// 远程拉取成功则进行数据持久化
                    self?.cacheWidgetHomeModel(model: model)
                    self?.homeDataService.updateHomeData(dataModel: model)
                    // 远程数据更新时间
                    self?.workplaceDataLastRefreshTime = TimeInterval(model.timestamp)
                    DispatchQueue.main.async {
                        success(model, false)
                        self?.isWorkplaceDataRefreshing = false // 数据刷新停止
                        // 数据更新通知
                        Self.logger.info("WorkPlace home page data model ready, refresh page")
                        self?.onWorkplaceDataUpdate(dataModel: model, fromCache: false)
                    }
                },
                failure: { [weak self] (error) in
                    Self.logger.error("WorkPlace home page request failed via network")
                    let nsError = error as NSError
                    let logId = nsError.userInfo[WPNetworkConstants.logId] as? String
                    let rustStatus = nsError.userInfo[WPNetworkConstants.rustStatus] as? String
                    reqOPMonitor.setCode(WPMCode.workplace_home_data_request_fail)
                        .setTrace(trace)
                        .setNetworkStatus()
                        .setError(errMsg: error.localizedDescription, error: error)
                        .setInfo([
                            "log_id": logId ?? "",
                            "rust_status": rustStatus ?? ""
                        ])
                        .postFailMonitor(endTiming: true)
                    DispatchQueue.main.async {
                        failure(error)
                        self?.isWorkplaceDataRefreshing = false // 数据刷新停止
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 远程拉取Widget工作台首页列表数据
    /// - Parameter success: 成功回调
    /// - Parameter failure: 失败回调
    private func requestWidgetCenterHomeInfo(
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        Self.logger.info("Widget: start to request home data via network from remote")
        let monitorEvent = OPMonitor(AppCenterMonitorEvent.appcenter_main_page_request).timing()
        let trace = self.traceService.lazyGetTrace(for: .normal, with: nil)
        
        let context = WPNetworkContext(injectInfo: .session, trace: trace)
        let params: [String: Any] = [
            "needWidget": true,
            "needBlock": true
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPNormalHomeDataConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        .subscribe(onSuccess: { (json) in
            let resCode: Int = json["code"].int ?? AppCenterDataManager.defaultErrCode
            let resMsg: String = json["msg"].string ?? AppCenterDataManager.defaultErrMsg
            if resCode == 0 {
                success(json)
                Self.logger.info("Widget: request home data via network from remote successed")
                monitorEvent.setResultTypeSuccess().timing().flush()
            } else {
                let errCodeInfo = WPMWorkplaceCode.workplace_fetchwidgetcenterhomeinfo_error
                let error = NSError(
                    domain: errCodeInfo.domain,
                    code: errCodeInfo.code,
                    userInfo: [NSLocalizedDescriptionKey: json.description]
                )
                failure(error)
                Self.logger.error(
                    "Widget: request home data via network from remote failed",
                    additionalData: [
                        "code": "\(String(describing: resCode))",
                        "msg": "\(resMsg)"
                    ],
                    error: error
                )
                monitorEvent
                    .setResultTypeFail()
                    .setError(error)
                    .timing()
                    .setErrorCode(json["code"].string)
                    .flush()
            }
            // swiftlint:enable closure_body_length
        }, onError: { (err) in
            Self.logger.error("Widget: request home data via network from remote failed", error: err)
            monitorEvent
                .setResultTypeFail()
                .setError(err)
                .timing()
                .flush()
            failure(err)
        })
        .disposed(by: disposeBag)
    }
}

// MARK: 工作台配置&管理
extension AppCenterDataManager {
    /// 获取工作台配置
    /// - Parameters:
    ///   - needCache: 是否需要缓存
    ///   - success: 成功主线程回调
    ///   - failure: 失败主线程回调
    func fetchWorkPlaceSettingWith(
        needCache: Bool = true,
        success: @escaping (_ model: WorkPlaceSetting) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            /// 1. 如果需要cache从本地拉取数据，若成功则进行success回调
            let settingCache = OPMonitor(WPMWorkplaceCode.workplace_setting_get_cache_data).timing()
            let settingModelReq = WPMonitor().timing()
            if needCache {
                if let model = self.getWorkPlaceSettingCache() { // 命中🎯缓存
                    Self.logger.info("workPlace hits setting cache")
                    settingCache.setResultTypeSuccess().timing().flush()
                    DispatchQueue.main.async {
                        success(model)
                    }
                } else { // 未命中缓存
                    Self.logger.info("workPlace miss setting cache")
                    settingCache.setError(nil).timing().flush()
                }
            }
            /// 2. 异步从远程拉取数据，成功则进行success回调
            // 网络⚡️请求
            self.requestWorkPlaceSetting(
                success: { [weak self] (json) in
                    guard let model = self?.buildWorkPlaceSetting(with: json) else {
                        let errCodeInfo = WPMWorkplaceCode.workplace_fetchworkplacesetting_model_build_error
                        let error = NSError(domain: errCodeInfo.domain, code: errCodeInfo.code, userInfo: nil)
                        settingModelReq.setCode(WPMCode.workplace_get_user_setting_fail)
                            .setError(errMsg: "parse model failed", error: error).postFailMonitor()
                        DispatchQueue.main.async {
                            failure(error)
                        }
                        return
                    }
                    /// 3.远程拉取成功则进行本地缓存 👌
                    self?.cacheWorkPlaceSetting(model: model)
                    Self.logger.info("workPlace setting fetch remote success")
                    settingModelReq.setCode(WPMCode.workplace_get_user_setting_success)
                        .postSuccessMonitor(endTiming: true)
                    DispatchQueue.main.async {
                        success(model)
                    }
                },
                failure: { (error) in
                    settingModelReq.setCode(WPMCode.workplace_get_user_setting_fail)
                        .setError(error: error)
                        .postFailMonitor()
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 从缓存获取工作台配置（导航栏应用商店配置）
    private func getWorkPlaceSettingCache() -> WorkPlaceSetting? {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        let model: WorkPlaceSetting? = store.value(forKey: WPCacheKey.workplaceSettings)
        Self.logger.info("[\(WPCacheKey.workplaceSettings)] cache \(model == nil ? "miss" : "hit").")
        return model
    }

    /// 缓存工作台配置（导航栏应用商店配置）
    /// - Parameter model: 工作台配置（导航栏应用商店配置）
    private func cacheWorkPlaceSetting(model: WorkPlaceSetting) {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        store.set(model, forKey: WPCacheKey.workplaceSettings)
        Self.logger.info("[\(WPCacheKey.workplaceSettings)] cache data.")
    }

    /// 异步远程拉取Setting
    private func requestWorkPlaceSetting(
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 开始请求
        Self.logger.info("dataManager start to request workPlace setting")
        let context = WPNetworkContext(injectInfo: .cookie, trace: traceService.currentTrace)
        networkService.request(
            WPFrontSettingConfig.self,
            params: [:],
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {
                success(json)
                Self.logger.info("workPlace setting request success")
            } else {
                failure(
                    NSError(
                        domain: "requestWorkPlaceSetting",
                        code: json["code"].int ?? AppCenterDataManager.defaultErrCode,
                        userInfo: [
                            "msg": "workPlace setting request failed,\(String(describing: json["msg"].string))"
                        ]
                    )
                )
                Self.logger.error("workPlace setting request failed with \(json["code"].intValue)")
            }
        }, onError: { (err) in
            Self.logger.error("workPlace setting request failed with :\(err.localizedDescription)")
            failure(err)
        })
        .disposed(by: disposeBag)
    }

    /// 通过json构造配置model
    private func buildWorkPlaceSetting(with json: JSON) -> WorkPlaceSetting? {
        assert(!Thread.isMainThread, "illegal working on main thread")
        /// 确保返回码正常
        guard json["code"].int == 0 else {
            Self.logger.error("build workPlace model from json failed with reply code: \(json["code"])")
            /// 需要增加埋点监控（三端需对齐）
            return nil
        }
        return buildDataModel(
            with: JSON(parseJSON: json["data"]["workplaceSetting"].stringValue),
            type: WorkPlaceSetting.self
        )
    }
}

// MARK: 工作台缓存相关
extension AppCenterDataManager {

    /// 获取本地缓存数据
    /// - Parameters:
    ///   - cacheKey: 缓存 Key 值
    ///   - type: 数据Model类型
    func getInfoFromCache<T: Codable>(cacheKey: String, type: T.Type) -> T? {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        let model: T? = store.value(forKey: cacheKey)
        Self.logger.info("[\(cacheKey)] cache \(model == nil ? "miss" : "hit").")
        return model
    }
    /// 保存数据到本地缓存
    /// - Parameters:
    ///   - cacheKey: 缓存 Key 值
    ///   - type: 数据model类型
    func setInfoToCache<T: Codable>(cacheKey: String, model: T) {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        store.set(model, forKey: cacheKey)
        Self.logger.info("[\(cacheKey)] cache data.")
    }
}

// MARK: 工作台Model构造
extension AppCenterDataManager {
    /// 将json数据转化为指定类型的model
    /// - Parameters:
    ///   - json: json数据
    ///   - type: model类型
    func buildDataModel<T: Codable>(with json: JSON, type: T.Type) -> T? {
        do {
            let model = try JSONDecoder().decode(type, from: json.rawData())
            Self.logger.info("parse data to model(\(type)) success")
            return model
        } catch {
            Self.logger.error("parse data to model(\(type)) failed with error: \(error)")
            return nil
        }
    }
}
