//
//  WorkplacePrefetchService.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/27.
//

import Foundation
import RxSwift
import LarkContainer
import LKCommonsLogging
import RxRelay
import LarkSetting
import ECOProbe
import OPSDK
import OPFoundation
import LarkAccountInterface
import LarkStorage

/// 缓存类型，预加载埋点用
struct WPCacheType: OptionSet {
    let rawValue: Int
    static let portal = WPCacheType(rawValue: 1)
    static let template = WPCacheType(rawValue: 6)
    static let normal = WPCacheType(rawValue: 8)
}

struct WPNormalHomeData {
    let data: WorkPlaceDataModel
    let isFromCache: Bool
}

/// 数据预加载服务
protocol WorkplacePrefetchService: AnyObject {
    /// badge 预加载能力
    /// lark.open_platform.workplace.template.prefetch == false 时，badge 通过此接口预加载数据
    func preloadBadges() -> Observable<BadgeLoadType>

    func start()
}

final class WorkplacePrefetchServiceImpl: WorkplacePrefetchService {
    static let logger = Logger.log(WorkplacePrefetchService.self)

    /// 预拉取服务错误
    enum PrefetchError: Error {
        case weakSelf
        case homeError(WorkplaceError)
        case templateError(WPLoadTemplateError)
        case portalConvertError(WPPortal)
        case blockError(WorkplaceError)
        case normalWorkplaceError(NSError)
    }

    enum WorkplaceDataLoadType: CustomStringConvertible {
        case normal(WPNormalHomeData?)
        case template(WPTemplateHomeData)
        case web(BadgeLoadType.LoadData)

        var description: String {
            switch self {
            case .normal: return "normal"
            case .template: return "template"
            case .web: return "web"
            }
        }
    }

    private let root: WPRootDataMgr
    private let template: TemplateDataManager
    private let badgeServiceContainer: WPBadgeServiceContainer
    private let blockDataService: WPBlockDataService
    private let normalWorkplace: AppCenterDataManager
    private let badgeAPI: BadgeAPI
    private let context: WorkplaceContext

    /// 是否预加载block数据
    private var enablePrefetchBlock: Bool {
        return context.configService.fgValue(for: .enablePrefetchBlock)
    }

    /// 是否支持原生工作台预加载
    private var enableNativePrefetch: Bool {
        return context.configService.fgValue(for: .enableNativePrefetch)
    }
    
    /// Block 预加载的间隔时长配置
    private var preloadConfig: WidgetPreloadConfig {
        return context.configService.settingValue(WidgetPreloadConfig.self)
    }

    private let disposeBag = DisposeBag()

    init(
        root: WPRootDataMgr,
        template: TemplateDataManager,
        badgeServiceContainer: WPBadgeServiceContainer,
        blockDataService: WPBlockDataService,
        normalWorkplace: AppCenterDataManager,
        badgeAPI: BadgeAPI,
        context: WorkplaceContext
    ) {
        self.root = root
        self.template = template
        self.badgeServiceContainer = badgeServiceContainer
        self.blockDataService = blockDataService
        self.normalWorkplace = normalWorkplace
        self.badgeAPI = badgeAPI
        self.context = context
    }

    func start() {
        Self.logger.info("start preload template & block data")
        prefetchCacheLastPortal()
            .flatMap({ [weak self]portal -> Observable<WPPortal> in
                guard let `self` = self else { throw PrefetchError.weakSelf }
                if let portal = portal {
                    return .just(portal)
                } else {
                    return self.prefetchRemotePortal()
                }
            })
            .flatMap({ [weak self] portal -> Observable<WorkplaceDataLoadType> in
                Self.logger.info("preloaded portal success", additionalData: [
                    "portalType": "\(portal.type.rawValue)"
                ])
                guard let `self` = self else { throw PrefetchError.weakSelf }
                self.root.updateCurrentPortal(portal)
                return try self.prefetchWorkplaceData(portal: portal)
            })
            // swiftlint:disable closure_body_length
            .flatMap({ [weak self] workplaceLoadType -> Single<[String: WPBlockPrefetchData]?> in
                Self.logger.info("preloaded workplace load type success", additionalData: [
                    "loadType": "\(workplaceLoadType)"
                ])
                guard let `self` = self else { throw PrefetchError.weakSelf }
                let badgeLoadType = self.convertToBadgeLoadType(from: workplaceLoadType)
                self.badgeServiceContainer.reload(to: badgeLoadType)

                if !self.checkShouldPreloadWidget() {
                    /// 与上次预加载间隔时间小于配置的时间，不进行组件预加载
                    return .just(nil)
                }
                switch workplaceLoadType {
                case .template(let homedata):
                    return try self.prefetchTemplateBlockData(templateHomeData: homedata)
                case .normal(let homeModel):
                    return try self.prefetchNormalBlockData(workplaceDataModel: homeModel)
                case .web:
                    return .just(nil)
                }
            })
            .do(onNext: { [weak self] blockData in
                guard let `self` = self else { throw PrefetchError.weakSelf }
                Self.logger.info("preload block entity & guide info success")
                self.blockDataService.update(with: blockData)

                Self.logger.info("start prefetch meta&pkg")
                if blockData != nil {
                    self.blockDataService.preloadMetaPkg()
                }
            })
            .subscribe(onNext: { _ in
                Self.logger.info("preload data success")
            }, onError: { error in
                let logInfo = (error as? PrefetchError)?.wp.logInfo ?? [:]
                Self.logger.error("preload data failed", additionalData: logInfo, error: error)
            })
            .disposed(by: disposeBag)
    }

    func preloadBadges() -> Observable<BadgeLoadType> {
        Self.logger.info("start preload template home data")
        return prefetchCacheLastPortal()
            .flatMap({ [weak self]portal -> Observable<WPPortal> in
                guard let `self` = self else { throw PrefetchError.weakSelf }
                if let portal = portal {
                    return .just(portal)
                } else {
                    return self.prefetchRemotePortal()
                }
            })
            .flatMap({ [weak self]portal -> Observable<BadgeLoadType> in
                guard let `self` = self else { throw PrefetchError.weakSelf }
                return try self.prefetchPortalBadge(portal: portal)
            }).do(onNext: { reloadType in
                Self.logger.info("preloaded badge reload type success", additionalData: [
                    "reloadType": "\(reloadType)"
                ])
            }, onError: { error in
                let logInfo = (error as? PrefetchError)?.wp.logInfo ?? [:]
                Self.logger.error("preload badge reload type failed", additionalData: logInfo, error: error)
            })
    }

    private func prefetchCacheLastPortal() -> Observable<WPPortal?> {
        Self.logger.info("start prefetch last portal cache")
        return Observable.create { [weak self]observer in
            guard let `self` = self else {
                observer.onError(PrefetchError.weakSelf)
                return Disposables.create()
            }
            self.root.fetchLastPortal { portal in
                Self.logger.info("fetched last protal cache", additionalData: [
                    "hasPortal": "\(portal != nil)",
                    "portalId": portal?.template?.id ?? "",
                    "portalType": "\(portal?.type.rawValue ?? "")"
                ])
                observer.onNext(portal)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    private func prefetchPortalBadge(portal: WPPortal) throws -> Observable<BadgeLoadType> {
        switch portal.type {
        case .normal:
            return .just(.appCenter)
        case .lowCode:
            guard let lowCode = WPHomeVCInitData.LowCode(portal) else {
                throw PrefetchError.portalConvertError(portal)
            }
            return self.prefetchTemplateHomeData(for: lowCode)
                .map({ homeData in
                    let templateData = BadgeLoadType.LoadData.TemplateData(
                        portalId: homeData.portalId,
                        scene: homeData.isFromCache ? .fromCache : .fromNetwork,
                        components: homeData.components
                    )
                    return .workplace(.template(templateData))
                })
        case .web:
            guard let web = WPHomeVCInitData.Web(portal) else {
                throw PrefetchError.portalConvertError(portal)
            }
            return self.badgeAPI
                .pullWorkplaceWebBadgeData(for: web)
                .map({ return .workplace($0) })
        }
    }

    private func prefetchRemotePortal() -> Observable<WPPortal> {
        Self.logger.info("start prefetch remote portal")
        return Observable.create { [weak self]observer in
            guard let `self` = self else {
                observer.onError(PrefetchError.weakSelf)
                return Disposables.create()
            }
            self.root.fetchHomePortals { result in
                switch result {
                case .success(let portalList):
                    Self.logger.info("fetched remote protal list", additionalData: [
                        "portals": "\(portalList.map({ ($0.template?.id ?? "", $0.type) }))",
                        "portalCount": "\(portalList.count)"
                    ])
                    observer.onNext(portalList.first ?? WPPortal.normalPortal())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(PrefetchError.homeError(error))
                }
            }
            return Disposables.create()
        }
    }

    private func prefetchTemplateHomeData(for template: WPHomeVCInitData.LowCode) -> Observable<WPTemplateHomeData> {
        Self.logger.info("start prefetch template home data")
        return Observable.create { [weak self]observer in
            guard let `self` = self else {
                observer.onError(PrefetchError.weakSelf)
                return Disposables.create()
            }
            self.template.getHomeComponents(template: template, useCache: true) { result in
                switch result {
                case .success(let homeData):
                    Self.logger.info("fetched template home data", additionalData: [
                        "components": "\(homeData.components.map({ ($0.componentID, $0.groupType.rawValue) }))",
                        "components.count": "\(homeData.components.count)"
                    ])
                    // 不能 complete, cache == true 会有两次(一次cache，一次remote)
                    observer.onNext(homeData)
                case .failure(let error):
                    observer.onError(PrefetchError.templateError(error))
                }
            }
            return Disposables.create()
        }
    }

    private func prefetchTemplateBlockData(
        templateHomeData: WPTemplateHomeData
    ) throws -> Single<[String: WPBlockPrefetchData]?> {
        Self.logger.info("start prefetch template block", additionalData: [
            "enablePrefetchBlock": "\(enablePrefetchBlock)"
        ])
        guard enablePrefetchBlock else {
            return .just(nil)
        }
        var blockIds: [String] = []
        var blockTypeIds: [String] = []
        var blockTypeInfoDic: [String: BlockModel] = [:]
        var blockUniqueIds: [OPAppUniqueID] = []
        templateHomeData.components.forEach { groupComponent in
            if groupComponent.groupType != .Block && groupComponent.groupType != .CommonAndRecommend {
                return
            }
            // 由于标准小组件不会去请求 GetBlockEntity，进而 Response 不会有该组件的 BlockEntity， 因此需要自行进行 BlockEntity 的封装
            groupComponent.nodeComponents.forEach { nodeComponent in
                guard let blockComponent = nodeComponent as? BlockComponent,
                      let blockModel = blockComponent.blockModel else {
                    return
                }
                if blockModel.isStandardBlock {
                    blockTypeIds.append(blockModel.blockTypeId)
                    blockTypeInfoDic[blockModel.blockTypeId] = blockModel
                } else {
                    blockIds.append(blockModel.blockId)
                }

                if !templateHomeData.isFromCache {
                    // 只有从网络获取到的数据才能预加载meta&pkg，
                    // 因此缓存获取到的数据不需要加到预安装列表
                    blockUniqueIds.append(blockModel.uniqueId)
                }
            }
        }
        self.cachePreloadTimestamp()
        self.blockDataService.update(with: blockUniqueIds)
        return self.blockDataService.getBlockInfo(
            blockIds: blockIds,
            blockTypeIds: blockTypeIds,
            blockTypeInfoDic: blockTypeInfoDic,
            portalType: .lowCode,
            templateId: templateHomeData.portalId
        ).catchError({ error in
            if let workplaceError = error as? WorkplaceError {
                throw PrefetchError.blockError(workplaceError)
            } else {
                throw error
            }
        })
    }

    private func prefetchNormalWorkplaceHomeData() -> Observable<WPNormalHomeData> {
        Self.logger.info("start prefetch normal workplace home data")
        return Observable.create { [weak self]observer in
            guard let `self` = self else {
                observer.onError(PrefetchError.weakSelf)
                return Disposables.create()
            }
            self.normalWorkplace.fetchItemInfoWith(success: { model, isCache in
                Self.logger.info("fetched normal workpalce home data success", additionalData: [
                    "groupCount": "\(model.groups.count)"
                ])
                // 不能 complete, 有缓存的情况下会有两次(一次cache，一次remote)
                let dataModel = WPNormalHomeData(
                    data: model,
                    isFromCache: isCache
                )
                observer.onNext(dataModel)
            }, failure: { error in
                observer.onError(PrefetchError.normalWorkplaceError(error as NSError))
            })
            return Disposables.create()
        }
    }

    private func prefetchWorkplaceData(portal: WPPortal) throws -> Observable<WorkplaceDataLoadType> {
        Self.logger.info("start prefetch workplace data", additionalData: [
            "portalType": "\(portal.type.rawValue)",
            "enableNativePrefetch": "\(enableNativePrefetch)"
        ])
        switch portal.type {
        case .normal:
            if enableNativePrefetch {
                return prefetchNormalWorkplaceHomeData()
                    .map({ workplaceDataModel in
                        return .normal(workplaceDataModel)
                    })
            }
            // fg关的情况下，返回空数据，不影响后续流程
            return .just(.normal(nil))
        case .lowCode:
            guard let lowCode = WPHomeVCInitData.LowCode(portal) else {
                throw PrefetchError.portalConvertError(portal)
            }
            return self.prefetchTemplateHomeData(for: lowCode)
                .map({ return .template($0) })
        case .web:
            guard let webPortal = WPHomeVCInitData.Web(portal) else {
                throw PrefetchError.portalConvertError(portal)
            }
            return self.badgeAPI
                .pullWorkplaceWebBadgeData(for: webPortal)
                .map({ return .web($0) })
        }
    }

    private func convertToBadgeLoadType(from workplaceType: WorkplaceDataLoadType) -> BadgeLoadType {
        Self.logger.info("start convert workplace data to badge load type")
        switch workplaceType {
        case .normal:
            return .appCenter
        case .template(let homeData):
            let templateData = BadgeLoadType.LoadData.TemplateData(
                portalId: homeData.portalId,
                scene: homeData.isFromCache ? .fromCache : .fromNetwork,
                components: homeData.components
            )
            return .workplace(.template(templateData))
        case .web(let badgeLoadData):
            return .workplace(badgeLoadData)
        }
    }

    private func prefetchNormalBlockData(
        workplaceDataModel: WPNormalHomeData?
    ) throws -> Single<[String: WPBlockPrefetchData]?> {
        Self.logger.info("start prefetch normal block", additionalData: [
            "enablePrefetchBlock": "\(enablePrefetchBlock)",
            "hasWorkplaceData": "\(workplaceDataModel != nil)"
        ])
        // 用guard的方式判断workplaceDataModel是否为空不起作用
        if !enablePrefetchBlock || workplaceDataModel == nil {
            return .just(nil)
        }
        var blockIds: [String] = []
        var blockTypeIds: [String] = []
        var blockTypeInfoDic: [String: BlockModel] = [:]
        var blockUniqueIds: [OPAppUniqueID] = []
        workplaceDataModel?.data.groups.forEach { groupUnit in
            groupUnit.itemUnits.forEach { itemUnit in
                guard itemUnit.type == .block else {
                    return
                }
                var itemModel = ItemModel(dataItem: itemUnit, isAddRect: false)
                itemModel.sectionCanDisplayWidget = groupUnit.category.tag.canDisplayWidget()
                guard let blockModel = itemModel.getBlockModel() else {
                    Self.logger.error("parse block preload data fail, block data missing", additionalData: [
                        "itemId": "\(itemUnit.itemID)",
                        "itemName": "\(itemUnit.item.name)"
                    ])
                    return
                }
                // 由于标准小组件不会去请求 GetBlockEntity，进而 Response 不会有该组件的 BlockEntity， 因此需要自行进行 BlockEntity 的封装
                if blockModel.isStandardBlock {
                    blockTypeIds.append(blockModel.blockTypeId)
                    blockTypeInfoDic[blockModel.blockTypeId] = blockModel
                } else {
                    blockIds.append(blockModel.blockId)
                }
                if let model = workplaceDataModel,
                   !model.isFromCache {
                    // 只有从网络获取到的数据才能预加载meta&pkg，
                    // 因此缓存获取到的数据不需要加到预安装列表
                    blockUniqueIds.append(blockModel.uniqueId)
                }
            }
        }
        self.cachePreloadTimestamp()
        self.blockDataService.update(with: blockUniqueIds)
        return self.blockDataService.getBlockInfo(
            blockIds: blockIds,
            blockTypeIds: blockTypeIds,
            blockTypeInfoDic: blockTypeInfoDic,
            portalType: .normal,
            templateId: nil
        ).catchError({ error in
            if let workplaceError = error as? WorkplaceError {
                throw PrefetchError.blockError(workplaceError)
            } else {
                throw error
            }
        })
    }
    
    private func cachePreloadTimestamp() {
        let store = KVStores.in(space: .user(id: context.userId), domain: Domain.biz.workplace).mmkv()
        let timestamp = Int(Date().timeIntervalSince1970)
        store.set(timestamp, forKey: WPCacheKey.lastPreloadWidgetTimestamp)
    }

    private func checkShouldPreloadWidget() -> Bool {
        let store = KVStores.in(space: .user(id: context.userId), domain: Domain.biz.workplace).mmkv()
        let lastPreloadWidgetTimestamp = store.integer(forKey: WPCacheKey.lastPreloadWidgetTimestamp)
        return lastPreloadWidgetTimestamp + preloadConfig.minTimeSinceLastPrefetch < Int(Date().timeIntervalSince1970)
    }
}

extension WorkplacePrefetchServiceImpl.PrefetchError: WorkplaceCompatible {}
extension WorkplaceExtension where BaseType == WorkplacePrefetchServiceImpl.PrefetchError {
    var logInfo: [String: String] {
        switch base {
        case .weakSelf:
            return ["dataServiceError": "weakSelf"]
        case .homeError(let error):
            return [
                "dataServiceError": "rootError",
                "error_code": "\(error.code)",
                "http_code": "\(error.httpCode)",
                "error_message": error.errorMessage ?? "",
                "server_error": "\(error.serverCode.map(String.init) ?? "")"
            ]
        case .templateError(let error):
            return [
                "dataServiceError": "templateError",
                "from": "\(error.failFrom)",
                "templateError": "\(error.error)"
            ]
        case .portalConvertError(let portal):
            return [
                "portal.id": portal.template?.id ?? "",
                "portal.tplType": portal.template?.tplType ?? "",
                "portal.data": portal.template?.data ?? ""
            ]
        case .blockError(let error):
            return [
                "dataServiceError": "blockError",
                "error_code": "\(error.code)",
                "http_code": "\(error.httpCode)",
                "error_message": error.errorMessage ?? "",
                "server_error": "\(error.serverCode.map(String.init) ?? "")"
            ]
        case .normalWorkplaceError(let error):
            return [
                "dataServiceError": "normalWorkplaceError",
                "error_domain": error.domain,
                "error_message": error.localizedDescription,
                "error_code": "\(error.code)"
            ]
        }
    }
}
