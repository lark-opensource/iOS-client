//
//  WPRootDataMgr.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/15.
//

import Foundation
import RxSwift
import ECOInfra
import LarkContainer
import LarkSetting
import LarkStorage
import LarkAccountInterface
import LKCommonsLogging

enum PortalUseCacheErrorCode: Int {
    case cacheDecodeError = 1
}

final class WPRootDataMgr {
    static let logger = Logger.log(WPRootDataMgr.self)

    enum MgrError: Error {
        case common(_ opError: OPError)
    }

    private let context: WorkplaceContext
    private let store: KVStore
    private let networkService: WPNetworkService

    private(set) var currentPortal: WPPortal?
    private let disposeBag = DisposeBag()

    // MARK: - init
    init(context: WorkplaceContext, networkService: WPNetworkService) {
        self.context = context
        self.networkService = networkService
        self.store = KVStores
            .in(space: .user(id: context.userId))
            .in(domain: Domain.biz.workplace)
            .mmkv()
    }

    // MARK: - public funcs
    func updateCurrentPortal(_ portal: WPPortal?) {
        if let updatePortal = portal {
            Self.logger.info("[protal] update portal")
            currentPortal = updatePortal
        }
    }

    /// 获取工作台门户列表，主线程回调
    func fetchHomePortals(completion: @escaping (Result<[WPPortal], WorkplaceError>) -> Void) {
        Self.logger.info("[protal] list get start!")

        // 如果有缓存且非空，优先返回一次缓存
        if let cachedList = getCachePortalList(),
           case let cachedTemplateList = cachedList.compactMap({ WPPortal.templatePortal(with: $0) }),
           !cachedTemplateList.isEmpty {
            Self.logger.info("[portal] get portal list cache success", additionalData: ["list_id": "\(cachedList.map(\.id))"])
            completion(.success(cachedTemplateList))
        }

        let monitorSuccess = context.monitor
            .start(.workplace_get_template_list_success)
            .timing()
        let monitorFailed = context.monitor
            .start(.workplace_get_template_list_fail)
            .timing()
        // swiftlint:disable closure_body_length
        net_getMultiTypeTemplates { [weak self] (result, requestId, logId, rustStatus) in
            switch result {
            case .success(let list):
                monitorSuccess
                    .timing()
                    .setResultTypeSuccess()
                    .setValue(requestId, for: .request_id)
                    .setValue(logId, for: .log_id)
                    .setValue(list.count, for: .portals_size)
                    .flush()
                Self.logger.info("[protal] list get success: \(list)")
                self?.cachePortalList(list)
                var portals = list.compactMap({ WPPortal.templatePortal(with: $0) })
                if portals.isEmpty {
                    Self.logger.warn("[portal] list empty, add normal portal")
                    /// 如果没有模板门户，添加一个普通的默认门户
                    portals.append(WPPortal.normalPortal())
                }
                completion(.success(portals))
            case .failure(let error):
                monitorFailed
                    .timing()
                    .setResultTypeFail()
                    .setWorkplaceError(error)
                    .setValue(requestId, for: .request_id)
                    .setValue(logId, for: .log_id)
                    .setValue(rustStatus, for: .rust_status)
                    .flush()
                Self.logger.warn("[portal] list fetch error: \(error)")
                completion(.failure(error))
            }
        }
        // swiftlint:enable closure_body_length
    }

    // MARK: - private funcs

    /// 获取可用模板列表
    private func net_getMultiTypeTemplates(
        completion: @escaping (
            Result<[WPPortalTemplate], WorkplaceError>,
            // 这块什么时候能改ToT
            String?, /* requestId */ 
            String?, /*logId */
            String? /*rust_status*/
        ) -> Void
    ) {
        let context = WPNetworkContext(injectInfo: .session, trace: context.trace)
        let params: [String: Any] = WPGeneralRequestConfig.legacyParameters
        networkService.request(
            WPGetMultiTemplatesConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.main))
        .subscribe(onSuccess: { (json) in
            let requestId = json[WPNetworkConstants.requestId].string
            let logId = json[WPNetworkConstants.logId].string
            if OPError.wp_serverCode(response: json) != nil, let error = WorkplaceError(response: json) {
                completion(.failure(error), requestId, logId, nil)
                return
            }
            
            do {
                let list = try JSONDecoder().decode(
                    [WPPortalTemplate].self,
                    from: json["data"]["templates"].rawData()
                )
                completion(.success(list), requestId, logId, nil)
            } catch {
                let workplaceError = WorkplaceError(
                    code: WPTemplateErrorCode.GetTemplateList.json_decode_error.rawValue, originError: nil
                )
                completion(.failure(workplaceError), requestId, logId, nil)
                _ = OPError.wp_jsonDecode(error)
            }
        }, onError: { (error) in
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
            _ = OPError.wp_network(error)
        })
        .disposed(by: disposeBag)
    }
}

// MARK: - cache

extension WPRootDataMgr {
    /// 异步缓存最后展示的门户
    func cacheLastPortal(_ portal: WPPortal) {
        store.set(portal.template?.id, forKey: WPCacheKey.lastPortalId)
        store.set(portal.type.rawValue, forKey: WPCacheKey.lastPortalType)
    }

    func cachePortalList(_ portals: [WPPortalTemplate]) {
        store.set(portals, forKey: WPCacheKey.lastPortalList)
    }

    func getCachePortalList() -> [WPPortalTemplate]? {
        return store.value(forKey: WPCacheKey.lastPortalList)
    }

    /// 异步获取最后展示的门户，主线程回调
    func fetchLastPortal(completion: @escaping (WPPortal?) -> Void) {
        /// 拿不到上次缓存的门户类型，则认为门户为空。
        guard let portalType: String = store.value(forKey: WPCacheKey.lastPortalType) else {
            completion(nil)
            return
        }

        let monitor = context.monitor
            .start(.get_portal_cache)
            .setValue("template_list_cache", for: .cache_type)

        // 根据门户类型加载缓存
        if portalType == WPPortal.PortalType.normal.rawValue {
            completion(WPPortal.normalPortal())
        } else {
            if let lastPortalId = store.string(forKey: WPCacheKey.lastPortalId),
               let portalList: [WPPortalTemplate] = store.value(forKey: WPCacheKey.lastPortalList),
               let lastPortal = portalList.first(where: { $0.id == lastPortalId }),
               let lastTemplatePortal = WPPortal.templatePortal(with: lastPortal) {
                monitor
                    .setValue(lastPortalId, for: .current_template_id)
                    .setValue(true, for: .is_cached)
                    .flush()
                completion(lastTemplatePortal)
            } else {
                monitor
                    .setValue(false, for: .is_cached)
                    .flush()
                completion(nil)
            }
        }
    }

    func checkHasCache() -> Bool {
        return store.contains(key: WPCacheKey.lastPortalId)
    }
}
