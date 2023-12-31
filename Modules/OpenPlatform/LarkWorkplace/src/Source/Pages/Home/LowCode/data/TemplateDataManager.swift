//
//  MockDataManager.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/12.
//
// swiftlint:disable file_length

import Foundation
import SwiftyJSON
import RxSwift
import ECOProbe
import ByteWebImage
import UIKit
import LarkUIKit
import LarkSetting
import AppContainer
import OPFoundation
import LKCommonsLogging
import Reachability
import Blockit
import OPSDK
import OPBlock
import OPBlockInterface
import LarkStorage
import LarkContainer

enum WPTemplateError: Error {
    case unknown                            // 未知错误
    case network(originError: Error)        // 网络请求出错
    case server(code: Int?, msg: String?)   // 服务器返回 code 不为 0
    case jsonEncode(originError: Error)     // json encode 出错
    case jsonDecode(originError: Error)     // json decode 出错
    case badTemplate                        // 模板为空，或者 url 不存在
    case invalidSchema                      // schema 版本不可用
    case invalidTemplate                    // template 版本不可用
    case invalidModuleData                  // module 数据解析出错
//    case schemaNeedsUpdate                  // schema 需要更新
    case emptyRequest                       // 请求体为空
}

enum WPTemplateUseCacheFailErrorCode: Int {
    case getSchemaFail = 1
    case getModuleFail = 2
    case cacheUnavailable = 3
    case schemaUnavailable = 4
    case templateUnavailable = 5
}

typealias WPTemplateHomeData = (
    components: [GroupComponent],
    backgroundProps: BackgroundPropsModel?,
    preferProps: PreferPropsModel?,
    isFromCache: Bool,
    portalId: String
)

struct WPRequestContext {
    let logId: String?
}

/// 页面配置数据（自定义Icon之类的的）
private var tempPageConfig: ConfigModel?

final class TemplateDataManager {
    static let logger = Logger.log(TemplateDataManager.self)


    let traceService: WPTraceService
    let networkService: WPNetworkService
    private let workplaceBadgeService: WorkplaceBadgeService
    private let configService: WPConfigService

    /// 是否开启 schema 备用 CDN 降级
    private var enableTemplateBackupCDN: Bool {
        return configService.fgValue(for: .enableTemplateBackupCDN)
    }

    /// schema 请求重试配置
    private var templateSchemaRetryConfig: TemplateSchemaRetryConfig {
        return configService.settingValue(TemplateSchemaRetryConfig.self)
    }

    private static let queue = DispatchQueue(label: "com.workplace.TemplateDataManager")

    private let disposeBag = DisposeBag()

    let isPreview: Bool

    private let previewToken: String?

    private let userId: String
    @available(*, deprecated, message: "be compatible for monitor")
    private let tenantId: String

    // Component 依赖使用，层级太深，目前先这么处理，后续改造
    private let userResolver: UserResolver

    init(
        userResolver: UserResolver,
        userId: String,
        tenantId: String,
        isPreview: Bool,
        previewToken: String?,
        traceService: WPTraceService,
        workplaceBadgeService: WorkplaceBadgeService,
        configService: WPConfigService,
        networkService: WPNetworkService
    ) {
        self.userResolver = userResolver
        self.userId = userId
        self.tenantId = tenantId
        self.isPreview = isPreview
        self.previewToken = previewToken
        self.traceService = traceService
        self.workplaceBadgeService = workplaceBadgeService
        self.configService = configService
        self.networkService = networkService
    }
}

extension TemplateDataManager {

    /// 获取模板缓存数据：模板信息 + 模板内容 + 解析好的模板组件
    private func getHomeDataFromCache(
        by template: WPHomeVCInitData.LowCode
    ) -> WPTemplateHomeData? {
        guard checkHasCache(for: template) else {
            return nil
        }
        /// 由于目前四级trace和门户vc的生命周期绑定，在预加载时门户还没有创建，因此需要通过lazy的方式获取四级trace
        /// 后续四级trace生命周期应该跟模版业务的生命周期绑定
        let trace = traceService.lazyGetTrace(for: .lowCode, with: template.id)
        guard let schema = getTemplateSchemaFromCache(for: template) else {
            Self.logger.warn("getHomeComponents from cache fail, get schema fail!")
            monitorTemplateUseCacheFail(errorCode: .getSchemaFail, trace: trace)
            return nil
        }
        guard let modules = getTemplateModulesFromCache(for: template) else {
            Self.logger.warn("getHomeComponents from cache fail, get modules fail!")
            monitorTemplateUseCacheFail(errorCode: .getModuleFail, trace: trace)
            return nil
        }

        guard checkTemplateAvailability(template) else {
            Self.logger.warn("getHomeComponents cache unavailable, template unavailable!")
            monitorTemplateUseCacheFail(errorCode: .templateUnavailable, trace: trace)
            return nil
        }

        guard checkSchemaAvailability(schema) else {
            Self.logger.warn("getHomeComponents cache unavailable, schema unavailable!")
            monitorTemplateUseCacheFail(errorCode: .schemaUnavailable, trace: trace)
            return nil
        }

        Self.logger.info("get home components from cache")
        let backgroundProps = parseBackgroundPropsModel(root: schema.schema)
        let components = parseGroupModels(root: schema.schema)
        updateOfficialModuleData(modules, for: components)
        let preferProps = parsePreferProps(root: schema.schema)

        return (components, backgroundProps, preferProps, true, template.id)
    }

    /// 单个组件请求官方数据，主线程回调
    func updateModuleBizData(
        portalId: String,
        groupComponent: GroupComponent,
        completion: @escaping (WPTemplateError?) -> Void
    ) {
        let trace = traceService.lazyGetTrace(for: .lowCode, with: portalId)
        guard let moduleReq = groupComponent.moduleReqParam else {
            // Only favorite and block component are supported
            Self.monitorGetComponentModuleFailed(errorCode: .empty_request, info: [:], trace: trace)
            Self.logger.warn("get module biz data, but request is empty")
            DispatchQueue.main.async { completion(.emptyRequest) }
            return
        }
        let isPortalPreview = isPreview

        net_getTemplateWorkplaceHome(
            params: [moduleReq],
            trace: trace,
            completion: { (result, _, logId, rustStatus) in
                switch result {
                case .success(let modules):
                    Self.logger.info("try get module data \(groupComponent.groupType)")
                    // Server error
                    guard let errCode = modules.first?.code, errCode == 0,
                          let dataStr = modules.first?.data else {
                        Self.monitorGetComponentModuleFailed(errorCode: .invalid_module_data, info: [
                            "log_id": logId ?? "",
                            "rust_status": rustStatus ?? ""
                        ], trace: trace)
                        DispatchQueue.main.async {
                            completion(.server(code: modules.first?.code, msg: modules.first?.msg))
                        }
                        return
                    }
                    // Decode data model and update view model
                    DispatchQueue.main.async {
                        let json = JSON(parseJSON: dataStr)
                        let updateSuccess = groupComponent.updateModuleData(json, isPortalPreview: isPortalPreview)
                        if updateSuccess {
                            Self.monitorGetComponentModuleSuccess(info: [
                                "log_id": logId ?? ""
                            ], trace: trace)
                            completion(nil)
                        } else {
                            Self.monitorGetComponentModuleFailed(errorCode: .update_module_data_fail, info: [
                                "log_id": logId ?? "",
                                "rust_status": rustStatus ?? ""
                            ], trace: trace)
                            completion(.invalidModuleData)
                        }
                    }
                case .failure(let error):
                    // Network framework error
                    Self.monitorGetComponentModuleFailed(error: error, info: [
                        "log_id": logId ?? "",
                        "rust_status": rustStatus ?? ""
                    ], trace: trace)
                    Self.logger.error("get module data failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.server(code: error.code, msg: error.errorMessage))
                    }
                }
            }
        )
    }

    /// 获取页面配置信息的缓存
    func getPageConfigCache(template: WPHomeVCInitData.LowCode) -> ConfigModel {
        if isPreview {
            return tempPageConfig ?? ConfigModel(showTitle: true, withDefault: true)
        }

        if let schema = getTemplateSchemaFromCache(for: template) {
            return getPageConfig(from: schema.schema) ?? ConfigModel(showTitle: true, withDefault: true)
        }
        return ConfigModel(showTitle: true, withDefault: true)
    }

    /// 根据模板信息获取模板内容
    func getHomeComponents(
        template: WPHomeVCInitData.LowCode,
        useCache: Bool,
        completion: @escaping (Result<WPTemplateHomeData, WPLoadTemplateError>) -> Void
    ) {
        let preview = self.isPreview
        Self.queue.async { [weak self] in
            self?.inner_getHomeComponents(template: template, useCache: useCache) { (result) in
                // badge reload(side effect)
                if !preview, case .success(let homeData) = result {
                    let templatData = BadgeLoadType.LoadData.TemplateData(
                        portalId: homeData.portalId,
                        scene: homeData.isFromCache ? .fromCache : .fromNetwork,
                        components: homeData.components
                    )
                    self?.workplaceBadgeService.refresh(with: .template(templatData))
                }

                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }

    /// 根据模板信息获取具体模板内容
    private func inner_getHomeComponents(
        template: WPHomeVCInitData.LowCode,
        useCache: Bool,
        completion: @escaping (Result<WPTemplateHomeData, WPLoadTemplateError>) -> Void
    ) {
        Self.logger.info("[Template.schema]: start get home components", additionalData: [
            "portalId": template.id,
            "useCache": "\(useCache)",
            "minClientVersion": template.minClientVersion ?? ""
        ])
        if !checkTemplateAvailability(template) {
            completion(.failure((WPLoadTemplateError(error: .invalidTemplate, failFrom: .invalid_template))))
            return
        }

        // 获取缓存，preview 状态下不使用缓存
        if !isPreview, useCache, let cache = getHomeDataFromCache(by: template) {
            completion(.success(cache))
        }

        loadRemoteTemplateSchema(template: template)
            .subscribe(onNext: { [weak self]schema in
                Self.logger.info("[Template.schema]: load remote template schema finished", additionalData: [
                    "schemaVersion": schema.schemaVersion,
                    "hasSelf": "\(self != nil)"
                ])
                guard let `self` = self else {
                    let loadError = WPLoadTemplateError(error: .unknown, failFrom: .download_template)
                    completion(.failure(loadError))
                    return
                }

                // 校验 schema 合法性
                if !self.checkSchemaAvailability(schema) {
                    Self.logger.error("[Template.schema]: check schema availability failed")
                    let loadError = WPLoadTemplateError(error: .invalidSchema, failFrom: .download_template)
                    completion(.failure(loadError))
                    return
                }

                // 网络请求成功，更新
                self.updateSchemaBizData(template: template, schema: schema, completion: completion)
            }, onError: { error in
                Self.logger.error("[Template.schema]: load remote template schema failed", error: error)
                if let workplaceError = error as? WorkplaceError {
                    let templateError = WPTemplateError.server(
                        code: workplaceError.code,
                        msg: workplaceError.errorMessage
                    )
                    let loadError = WPLoadTemplateError(error: templateError, failFrom: .download_template)
                    completion(.failure(loadError))
                } else if let loadError = error as? WPLoadTemplateError {
                    completion(.failure(loadError))
                } else {
                    let loadError = WPLoadTemplateError(error: .unknown, failFrom: .download_template)
                    completion(.failure(loadError))
                }
            }).disposed(by: disposeBag)
    }

    // MARK: private

    /// 检查 schema 可用性
    func checkSchemaAvailability(_ schema: SchemaModel) -> Bool {
        let kRequireSchemaVersion = "1.0"
        if schema.schemaVersion != kRequireSchemaVersion {
            Self.logger.error("schema unavailable, ver: \(schema.schemaVersion), req: \(kRequireSchemaVersion)")
            return false
        }
        return true
    }

    func checkHasCache(for template: WPHomeVCInitData.LowCode) -> Bool {
        let hasTemplateCache: Bool = checkHasTemplateSchemaCache(for: template) ?? false
        let hasModulesCache: Bool = checkHasTemplateModulesCache(for: template) ?? false
        return hasTemplateCache || hasModulesCache
    }

    /// 将组件业务数据更新到各个官方组件中
    private func updateOfficialModuleData(_ modules: [ComponentModule], for components: [GroupComponent]) {
        for component in components {
            // 三方组件数据无需更新
            guard component.moduleReqParam != nil else { continue }

            // 一方组件数据遍历查询
            var componentNotFound = true
            for module in modules where module.componentId == component.componentID {
                if let dataStr = module.data, let code = module.code, code == 0 {
                    let json = JSON(parseJSON: dataStr)
                    let updateSuccess = component.updateModuleData(json, isPortalPreview: isPreview)
                    let newState: ComponentState = updateSuccess ? .running : .loadFailed
                    component.updateGroupState(newState)
                } else {
                    component.updateGroupState(.loadFailed)
                }
                componentNotFound = false
                break
            }
            if componentNotFound {  // 对于只刷新业务数据时，这里第三方组件没有数据是正常的，不必惊慌
                Self.logger.error("component \(component.componentID) not get data")
                component.updateGroupState(.loadFailed)
            }
        }
    }

    /// 更新模板业务数据（官方接口统一请求）
    private func updateSchemaBizData(
        template: WPHomeVCInitData.LowCode,
        schema: SchemaModel,
        completion: @escaping (Result<WPTemplateHomeData, WPLoadTemplateError>) -> Void
    ) {
        // 解析 schema 的 backgroundProps.background 数据
        let backgroundPropsModel = parseBackgroundPropsModel(root: schema.schema)

        let preferProps = parsePreferProps(root: schema.schema)

        // 将 schema 解析成组件列表 - 解析 schema.children 数据
        let components = parseGroupModels(root: schema.schema)

        // 获取组件列表业务数据的请求参数
        let param = components.compactMap({ $0.moduleReqParam })

        let monitor = WPMonitor().timing()
        let trace = traceService.lazyGetTrace(for: .lowCode, with: template.id)
        // 获取组件列表业务数据内容
        // swiftlint:disable closure_body_length
        self.net_getTemplateWorkplaceHome(
            params: param,
            trace: trace
        ) { [weak self] (result2, requestId, logId, rustStatus) in
            guard let self = self else {
                Self.logger.warn("updateSchemaBizData get response, but self released")
                return
            }
            switch result2 {
            case .success(let modules):
                Self.logger.info("updateSchemaBizData success!")

                if !self.isPreview {
                    // 缓存下 network 的数据
                    self.cacheTemplateSchema(schema, for: template)
                    self.cacheTemplateModules(modules, for: template)
                }

                // 将 module 数据更新到 components 数组中
                self.updateOfficialModuleData(modules, for: components)

                let tuple: WPTemplateHomeData = (components, backgroundPropsModel, preferProps, false, template.id)
                completion(.success(tuple))

                monitor.setCode(WPMCode.workplace_get_platform_component_data_success)
                    .setTrace(trace)
                    .setInfo([
                        "log_id": logId ?? "",
                        "request_id": requestId ?? ""
                    ])
                    .setNetworkStatus()
                    .postSuccessMonitor(endTiming: true)
            case .failure(let error):
                monitor.timing()
                    .setCode(WPMCode.workplace_get_platform_component_data_fail)
                    .setTrace(trace)
                    .setInfo([
                        "request_id": requestId ?? "",
                        "log_id": logId ?? "",
                        "rust_status": rustStatus ?? ""
                    ])
                    .setNetworkStatus()
                    .setTemplateResultFail(error: error)
                    .flush()

                let returnError = WPLoadTemplateError(
                    error: .server(code: error.code, msg: error.errorMessage),
                    failFrom: .get_platform_component
                )
                completion(.failure(returnError))
            }
        }
        // swiftlint:enable closure_body_length
    }

    /// 检查 template 可用性
    private func checkTemplateAvailability(_ template: WPHomeVCInitData.LowCode) -> Bool {
        let minVer = template.minClientVersion ?? ""
        guard  NSPredicate(format: "SELF MATCHES %@", "[0-9]+\\.[0-9]+\\.[0-9]+").evaluate(with: minVer) else {
            Self.logger.error("regard err minVersion: \(minVer) as Available")
            return true
        }
        let clientVer = WPUtils.appVersion
        if clientVer.compare(minVer, options: .numeric) == .orderedAscending {
            Self.logger.error("template unavailable, minVer: \(minVer), clientVer: \(clientVer)")
            return false
        }
        return true
    }

    /// 从门户 schema 数据中解析 pageConfig (导航栏配置)
    private func getPageConfig(from root: RootModel) -> ConfigModel? {
        guard let pageConfigJSON = root.children.first(where: { $0[ComponentNameKey].stringValue == PageConfig }) else {
            return nil
        }

        let showTitle = pageConfigJSON[PropsKey][ShowTitle].bool ?? true
        let iconItems = pageConfigJSON[PropsKey]["iconItems"].array ?? []
        let buttons: [HeaderNaviButton] = iconItems.compactMap { item in
            guard let key = item["key"].string else { return nil }
            if InnerNaviIcon.isInnerIcon(key: key) {
                if key == InnerNaviIcon.appDirectory.rawValue {
                    if let schema = item["schema"].string {
                        return HeaderNaviButton(key: key, iconUrl: nil, schema: schema)
                    } else {
                        return nil
                    }
                } else {
                    return HeaderNaviButton(key: key, iconUrl: nil, schema: item["schema"].string)
                }
            } else {
                if let iconUrl = item["iconUrl"].string, let schema = item["schema"].string {
                    return HeaderNaviButton(key: key, iconUrl: iconUrl, schema: schema)
                } else {
                    return nil
                }
            }
        }
        let pageConfig = ConfigModel(showTitle: showTitle)
        pageConfig.naviButtons = buttons
        return pageConfig
    }
}

// 埋点
extension TemplateDataManager {
    func monitorTemplateUseCacheFail(errorCode: WPTemplateUseCacheFailErrorCode, trace: OPTraceProtocol?) {
        WPMonitor().setCode(WPMCode.workplace_template_use_cache_fail)
            .setTrace(trace)
            .setInfo([
                "error_code": errorCode.rawValue
            ])
            .flush()
    }

    static func monitorGetComponentModuleFailed(errorCode: WPTemplateErrorCode.GetPlatformComponent, info: [String: Any], trace: OPTraceProtocol) {
        let error = WorkplaceError(code: errorCode.rawValue, originError: nil)
        WPMonitor().setCode(WPMCode.workplace_get_platform_component_data_fail)
            .setTrace(trace)
            .setNetworkStatus()
            .setInfo(info)
            .setTemplateResultFail(error: error)
            .flush()
    }

    static func monitorGetComponentModuleFailed(error: WorkplaceError, info: [String: Any], trace: OPTraceProtocol) {
        WPMonitor().setCode(WPMCode.workplace_get_platform_component_data_fail)
            .setTrace(trace)
            .setNetworkStatus()
            .setInfo(info)
            .setTemplateResultFail(error: error)
            .flush()
    }

    static func monitorGetComponentModuleSuccess(info: [String: Any], trace: OPTraceProtocol) {
        WPMonitor().setCode(WPMCode.workplace_get_platform_component_data_success)
            .setTrace(trace)
            .setInfo(info)
            .setNetworkStatus()
            .postSuccessMonitor()
    }
}

// MARK: - network

extension TemplateDataManager {
    // 加载远端 schema，包含重试和 CDN 降级策略。
    private func loadRemoteTemplateSchema(template: WPHomeVCInitData.LowCode) -> Observable<SchemaModel> {
        Self.logger.info("[Template.schema]: start load remote template schema", additionalData: [
            "portalId": template.id,
            "templateFileURL": template.templateFileUrl,
            "backupTemplateURLs": "\(template.backupTemplateUrls)",
            "enableTemplateBackupCDN": "\(enableTemplateBackupCDN)",
            "schemaRetryConfig.enable": "\(templateSchemaRetryConfig.enable)",
            "schemaRetryConfig.maxRetryTimes": "\(templateSchemaRetryConfig.maxRetryTimes)"
        ])
        // 获取 Schema URL 列表: 如果开启 CDN 降级，则将 CDN 降级 URL 添加到获取列表中。
        var groupSchemaURLs: [String] = [template.templateFileUrl]
        if enableTemplateBackupCDN {
            groupSchemaURLs.append(contentsOf: template.backupTemplateUrls)
        }

        // 整体重试次数: 如果开启重试能力，则按照远端配置次数重试，首次不算重试。
        var maxRetryTimes: Int = 0
        if templateSchemaRetryConfig.enable {
            maxRetryTimes = templateSchemaRetryConfig.maxRetryTimes
        }

        // 获取 schema
        var currentRetryTimes: Int = 0 // 记录重试次数并传递
        return Observable
            .just(())
            .flatMap({ [weak self]() -> Observable<SchemaModel> in
                Self.logger.info("[Template.schema]: load schema group", additionalData: [
                    "hasSelf": "\(self != nil)",
                    "currentRetryTimes": "\(currentRetryTimes)"
                ])
                guard let `self` = self else {
                    return .error(WPLoadTemplateError(error: .unknown, failFrom: .download_template))
                }
                return self.loadTemplateSchemaGroup(
                    for: groupSchemaURLs, templateId: template.id, currentRetryTimes: currentRetryTimes
                )
            })
            .retryWhen({ errorObservable -> Observable<Void> in
                return errorObservable.flatMap({ error -> Observable<Void> in
                    let reachability = Reachability()
                    Self.logger.info("[Template.schema]: retry when error", additionalData: [
                        "hasReachability": "\(reachability != nil)",
                        "netStatus": "\(reachability?.connection ?? .none)",
                        "currentRetryTimes": "\(currentRetryTimes)"
                    ], error: error)
                    guard currentRetryTimes < maxRetryTimes,
                          let reach = reachability,
                          reach.connection != .none else {
                        throw error
                    }
                    currentRetryTimes += 1
                    return .just(())
                })
            })
    }

    /// 按组顺序加载 schema, 取第一个成功的 schema
    private func loadTemplateSchemaGroup(
        for schemaURLs: [String], templateId: String, currentRetryTimes: Int
    ) -> Observable<SchemaModel> {
        Self.logger.info("[Template.schema]: start load template schema group", additionalData: [
            "schemaURLs": "\(schemaURLs)",
            "templateId": templateId,
            "currentRetryTimes": "\(currentRetryTimes)"
        ])

        var urlIterator = schemaURLs.makeIterator()
        guard !schemaURLs.isEmpty, let firstURL = urlIterator.next() else {
            return .error(WPLoadTemplateError(error: .unknown, failFrom: .download_template))
        }

        Self.logger.info("[Template.schema]: handle first schema url", additionalData: [
            "firstURL": firstURL
        ])
        return net_getTemplateSchema(
            schemaURL: firstURL, templateId: templateId, currentRetryTimes: currentRetryTimes
        ).catchError({ [weak self]error in
            guard let `self` = self else { throw error }
            return try self.recursiveSchemaErrorMap(
                nextURLGenerator: { urlIterator.next() },
                error: error,
                templateId: templateId,
                currentRetryTimes: currentRetryTimes
            )
        }).do(onNext: { schema in
            Self.logger.info("[Template.schema]: load group schema finished", additionalData: [
                "version": schema.schemaVersion,
                "id": schema.schema.id
            ])
        }, onError: { error in
            Self.logger.error("[Template.schema]: load group schema finished with error", error: error)
        })
    }

    /// 递归处理 schema 获取错误，使用 netURLGenerator 获取下一个处理链接并请求。
    private func recursiveSchemaErrorMap(
        nextURLGenerator: @escaping () -> String?,
        error: Error,
        templateId: String,
        currentRetryTimes: Int
    ) throws -> Observable<SchemaModel> {
        guard let nextURL = nextURLGenerator() else { throw error }
        Self.logger.warn("[Template.schema]: handle error for next schema", additionalData: [
            "nextURL": nextURL
        ], error: error)
        return self.net_getTemplateSchema(
            schemaURL: nextURL, templateId: templateId, currentRetryTimes: currentRetryTimes
        ).catchError({ [weak self]nextError in
            guard let `self` = self else { throw nextError }
            return try self.recursiveSchemaErrorMap(
                nextURLGenerator: nextURLGenerator,
                error: nextError,
                templateId: templateId,
                currentRetryTimes: currentRetryTimes
            )
        })
    }

    /// 获取模板对应的 schema 内容，在 TemplateDataManager 串行队列中回调
    private func net_getTemplateSchema(
        schemaURL: String, templateId: String, currentRetryTimes: Int
    ) -> Observable<SchemaModel> {
        Self.logger.info("[Template.schema]: start request template schema", additionalData: [
            "schemaURL": schemaURL,
            "templateId": templateId,
            "currentRetryTimes": "\(currentRetryTimes)"
        ])

        let monitor = WPMonitor().timing()
        let trace = traceService.lazyGetTrace(for: .lowCode, with: templateId)
        guard let url = URL(string: schemaURL) else {
            let workplaceError = WorkplaceError(
                code: WPTemplateErrorCode.DownloadTemplate.bad_template.rawValue, originError: nil
            )
            monitor.timing()
                .setCode(WPMCode.workplace_download_template_fail)
                .setTrace(trace)
                .setNetworkStatus()
                .setTemplateResultFail(error: workplaceError)
                .setInfo([
                    "portal_id": templateId,
                    "retry_times": currentRetryTimes,
                    "cdn_url": schemaURL
                ])
                .flush()
            return .error(workplaceError)
        }
        let domain: String
        if #available(iOS 16.0, *) {
            domain = url.host() ?? ""
        } else {
            domain = url.host ?? ""
        }
        let path: String
        if #available(iOS 16.0, *) {
            path = url.path()
        } else {
            path = url.path
        }
        let port = url.port
        let injectInfo = WPRequestInjectInfo(headerAuthType: .session, customDomain: domain, path: path, port: port)
        let context = WPNetworkContext(injectInfo: injectInfo, trace: trace)
        let params: [String: String] = url.queryParameters
            .merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        return networkService.request(
            WPGetSchemaFileConfig.self,
            params: params,
            context: context
        )
        .asObservable()
        .observeOn(ConcurrentDispatchQueueScheduler(queue: Self.queue))
            .catchError({ error -> Observable<JSON> in  // 网络库错误
                let nsError = error as NSError
                let workplaceError = WorkplaceError(
                    code: WPTemplateErrorCode.server_error.rawValue, originError: nsError
                )
                monitor.timing()
                    .setCode(WPMCode.workplace_download_template_fail)
                    .setTrace(trace)
                    .setNetworkStatus()
                    .setTemplateResultFail(error: workplaceError)
                    .setInfo([
                        "portal_id": templateId,
                        "request_id": nsError.userInfo[WPNetworkConstants.requestId] as? String ?? "",
                        "retry_times": currentRetryTimes,
                        "cdn_url": schemaURL,
                        "log_id": nsError.userInfo[WPNetworkConstants.logId] as? String ?? "",
                        "rust_status": nsError.userInfo[WPNetworkConstants.rustStatus] as? String ?? ""
                    ])
                    .flush()
                throw workplaceError
            })
            // swiftlint:disable closure_body_length
            .flatMap({ json -> Observable<SchemaModel> in
                let requestId = json[WPNetworkConstants.requestId].string
                let logId = json[WPNetworkConstants.logId].string
                do {
                    let data = try json.rawData()
                    let root = try JSONDecoder().decode(SchemaModel.self, from: data)
                    monitor.setCode(WPMCode.workplace_download_template_success)
                        .setTrace(trace)
                        .setNetworkStatus()
                        .setInfo([
                            "portal_id": templateId,
                            "request_id": requestId ?? "",
                            "retry_times": currentRetryTimes,
                            "log_id": logId ?? ""
                        ])
                        .postSuccessMonitor(endTiming: true)
                    return Observable.just(root)
                } catch {
                    let workplaceError = WorkplaceError(
                        code: WPTemplateErrorCode.DownloadTemplate.json_decode_error.rawValue,
                        originError: nil
                    )
                    monitor.timing()
                        .setCode(WPMCode.workplace_download_template_fail)
                        .setTrace(trace)
                        .setNetworkStatus()
                        .setTemplateResultFail(error: workplaceError)
                        .setInfo([
                            "portal_id": templateId,
                            "request_id": requestId ?? "",
                            "retry_times": currentRetryTimes,
                            "cdn_url": schemaURL,
                            "log_id": logId ?? ""
                        ])
                        .flush()
                    throw workplaceError
                }
            })
            // swiftlint:enable closure_body_length
    }

    /// 批量获取 schema 组件的内容数据，在 TemplateDataManager 串行队列中回调
    private func net_getTemplateWorkplaceHome(
        params: [ComponentModuleReqParam],
        trace: OPTrace,
        completion: @escaping (
            Result<[ComponentModule], WorkplaceError>,
            String?, /* requestId */
            String?, /* logId */
            String? /*rustStatus*/
        ) -> Void
    ) {
        var requestObservable: Observable<JSON>?
        let context = WPNetworkContext(injectInfo: .session, trace: trace)
        var requestParams: [String: Any] = WPGeneralRequestConfig.legacyParameters
        if isPreview, let token = previewToken {
            requestParams["token"] = token
            do {
                let data = try JSONEncoder().encode(params)
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
                requestParams["moduleReqList"] = jsonObj
            } catch {
                Self.logger.error("generate GetTemplateWorkplaceHome params failed", error: error)
            }
            requestObservable = networkService.request(
                WPGetTemplateWorkplaceHomePreviewConfig.self,
                params: requestParams,
                context: context
            ).asObservable()
        } else {
            do {
                let data = try JSONEncoder().encode(params)
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
                requestParams["moduleReqList"] = jsonObj
            } catch {
                Self.logger.error("generate GetTemplateWorkplaceHome params failed", error: error)
            }
            requestObservable = networkService.request(
                WPGetTemplateWorkplaceHomeConfig.self,
                params: requestParams,
                context: context
            ).asObservable()
        }
        requestObservable?
            .observeOn(ConcurrentDispatchQueueScheduler(queue: Self.queue))
            .subscribe { (json) in
                let requestId = json[WPNetworkConstants.requestId].string
                let logId = json[WPNetworkConstants.logId].string
                if let error = WorkplaceError(response: json) {
                    completion(.failure(error), requestId, logId, nil)
                    return
                }
                
                do {
                    let arr = json["data"]["moduleDataList"]
                    let data = try arr.rawData()
                    let modules = try JSONDecoder().decode([ComponentModule].self, from: data)
                    completion(.success(modules), requestId, logId, nil)
                } catch {
                    let workplaceError = WorkplaceError(
                        code: WPTemplateErrorCode.GetPlatformComponent.json_decode_error.rawValue, originError: nil
                    )
                    completion(.failure(workplaceError), requestId, logId, nil)
                }
            } onError: { (error) in
                let nsError = error as NSError
                let workplaceError = WorkplaceError(
                    code: WPTemplateErrorCode.server_error.rawValue, originError: nsError
                )
                completion(
                    .failure(workplaceError),
                    nsError.userInfo[WPNetworkConstants.requestId] as? String,
                    nsError.userInfo[WPNetworkConstants.logId] as? String,
                    nsError.userInfo[WPNetworkConstants.rustStatus] as? String
                )
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - parse model

extension TemplateDataManager {

    /// 将 RootModel 解析成 [GroupComponent]
    private func parseGroupModels(root: RootModel) -> [GroupComponent] {
        var groups: [GroupComponent] = []
        for json in root.children {
            if json[ComponentNameKey].stringValue == PageConfig {
                /// 和安卓一致，在读取到header组件配置的时候上报
                WPEventReport(
                    name: WPNewEvent.openplatformWorkspaceMainPageComponentExpoView.rawValue,
                    userId: userId,
                    tenantId: tenantId
                )
                    .set(key: WPEventNewKey.type.rawValue, value: WPExposeUIType.header.rawValue)
                    .post()
                tempPageConfig = getPageConfig(from: root)
            } else {
                if let type = GroupComponentType(rawValue: json[ComponentNameKey].stringValue) {
                    let group = type.getComponent(userResolver: userResolver).parse(json: json)
                    groups.append(group)
                } else {
                    Self.logger.error("unknwon component parsed", additionalData: [
                        "type": json[ComponentNameKey].stringValue,
                        "componentId": json[ComponentIdKey].stringValue
                    ])
                }
            }
        }
        return groups
    }

    /// 提取 RootModel 中的背景信息，并设置内存
    /// - Parameter root: 根结点数据结构
    /// - Returns: 返回背景图 Model
    private func parseBackgroundPropsModel(root: RootModel) -> BackgroundPropsModel? {
        do {
            if let backgroundPropsData = try root.props?["backgroundProps"].rawData() {
                let backgroundModel = try JSONDecoder().decode(BackgroundPropsModel.self, from: backgroundPropsData)
                Self.logger.info("parse Background Config", additionalData: [
                    "backgroundModel.background.light?.key": backgroundModel.background.light?.key ?? "nil",
                    "backgroundModel.background.dark?.key": backgroundModel.background.dark?.key ?? "nil"
                ])
                return backgroundModel
            }
        } catch {
            Self.logger.error("parse Background Config failed", error: error)
        }
        Self.logger.info("parse background config nil")
        return nil
    }

    private func parsePreferProps(root: RootModel) -> PreferPropsModel? {
        do {
            if let preferProps = try root.props?["preferProps"].rawData() {
                let preferModel = try JSONDecoder().decode(PreferPropsModel.self, from: preferProps)
                Self.logger.info("parse preferModel Config", additionalData: [
                    "preferModel.isHideBlockForNoAuth": "\(preferModel.isHideBlockForNoAuth)"
                ])
                return preferModel
            }
        } catch {
            Self.logger.error("parse prefer config failed", error: error)
        }
        Self.logger.info("parse prefer config nil")
        return nil
    }
}

// MARK: - 通用方法

extension TemplateDataManager {
    /// 将json数据转化为指定类型的model
    /// - Parameters:
    ///   - json: json数据
    ///   - type: model类型
    static func buildDataModel<T: Codable>(with json: JSON, type: T.Type) -> T? {
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

// MARK: - cache
extension TemplateDataManager {
    /// 缓存门户 schema
    ///
    /// - Parameters:
    ///   - schema: schema 数据
    ///   - for: 门户信息
    func cacheTemplateSchema(_ schema: SchemaModel, for template: WPHomeVCInitData.LowCode) {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.workplace.child(template.id))
            .mmkv()
        store.set(schema, forKey: WPCacheKey.Portal.schema)
    }

    /// 从缓存中读取门户 schema
    ///
    /// - Parameter template: 门户信息
    func getTemplateSchemaFromCache(for template: WPHomeVCInitData.LowCode) -> SchemaModel? {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.workplace.child(template.id))
            .mmkv()
        WPMonitor()
            .setCode(EPMClientOpenPlatformAppCenterCacheCode.get_portal_cache)
            .setInfo("template_schema_cache", key: "cache_type")
            .setInfo(template.id, key: "current_template_id")
            .setInfo(store.contains(key: WPCacheKey.Portal.schema), key: "is_cached")
            .flush()
        return store.value(forKey: WPCacheKey.Portal.schema)
    }

    /// 缓存门户组件数据
    ///
    /// - Parameters:
    ///   - modules: 门户组件数据
    ///   - for: 门户信息
    func cacheTemplateModules(_ modules: [ComponentModule], for template: WPHomeVCInitData.LowCode) {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.workplace.child(template.id))
            .mmkv()
        store.set(modules, forKey: WPCacheKey.Portal.components)
    }

    /// 从缓存中读取门户组件数据
    ///
    /// - Parameter template: 门户信息
    func getTemplateModulesFromCache(for template: WPHomeVCInitData.LowCode) -> [ComponentModule]? {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.workplace.child(template.id))
            .mmkv()

        WPMonitor()
            .setCode(EPMClientOpenPlatformAppCenterCacheCode.get_portal_cache)
            .setInfo("components_data", key: "cache_type")
            .setInfo(template.id, key: "current_template_id")
            .setInfo(store.contains(key: WPCacheKey.Portal.components), key: "is_cached")
            .flush()
        return store.value(forKey: WPCacheKey.Portal.components)
    }

    /// 检查是否有门户 Schema 缓存
    ///
    /// - Parameter template: 门户信息
    func checkHasTemplateSchemaCache(for template: WPHomeVCInitData.LowCode) -> Bool {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.workplace.child(template.id))
            .mmkv()
        return store.contains(key: WPCacheKey.Portal.schema)
    }

    /// 检查是否有门户组件数据缓存
    ///
    /// - Parameter template: 门户信息
    func checkHasTemplateModulesCache(for template: WPHomeVCInitData.LowCode) -> Bool {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.workplace.child(template.id))
            .mmkv()
        return store.contains(key: WPCacheKey.Portal.components)
    }
}

/// 校验服务端响应的 code
private func WPCheckServerResponse(
    json: JSON,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
) -> WPTemplateError? {
    if json["code"].int == 0 {
        return nil
    } else {
        let code = json["code"].int
        let msg = json["msg"].string
        return .server(code: code, msg: msg)
    }
}
// swiftlint:enable file_length
