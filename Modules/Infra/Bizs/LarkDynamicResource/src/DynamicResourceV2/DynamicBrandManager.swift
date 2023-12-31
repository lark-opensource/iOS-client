//
//  DynamicBrandManager.swift
//  LarkDynamicResource
//
//  Created by wangyuanxun on 2023/4/3.
//

import LarkStorage
import ServerPB
import LarkContainer
import LarkRustClient
import LarkCombine
import LKCommonsLogging
import LarkResource
import LarkSetting

enum DynamicBrandManager {
    private static let logger = Logger.log(DynamicBrandManager.self, category: "Module.LarkDynamicResource")
    private static let globalStore = KVStores.udkv(space: .global, domain: DynamicBrandStorage.domain)
    private static let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
    private static let defaultPullInterval = 43200
    
    @KVConfig(key: "currentResource", default: [String: String](), store: globalStore)
    private static var currentResourceID
    private static var disposeBag = Set<AnyCancellable>()
    private(set) static var featureSwitch = [String: Any]()
}

// MARK: Internal interfaces
extension DynamicBrandManager {
    static func fetchResource(with url: String, taskID: String, tenantID: String) {
        guard let url = URL(string: url), taskID > DynamicBrandStorage.latestTaskID(of: tenantID) ?? "" else { return }
        
        URLSession.shared.dataTask(with: .init(url: url), completionHandler: {
            $2 != nil ? logger.error("[DynamicBrand] download resource failed: \(String(describing: $2))")
            : DynamicBrandStorage.copyResource(with: $0, taskID: taskID, tenantID: tenantID)
        }).resume()
    }
    
    static func fetchResourceConfig(with resolver: UserResolver, tenantID: String) {
        var request = ServerPB_Brand_PullTenantBuildResourceRequest()
        request.platform = .ios
        resolver.resolve(RustService.self)?.sendPassThroughAsyncRequestWithCombine(request, serCommand: .pullTenantBuildResource)
            .sink { if case .failure(let error) = $0 { logger.error("[DynamicBrand] fetch config failed: \(error)") } }
            receiveValue: { (resp: ServerPB_Brand_PullTenantBuildResourceResponse) in
                logger.info("[DynamicBrand] receive id: \(resp.taskID) url: \(resp.resourceURL)")
                
                fetchResource(with: resp.resourceURL, taskID: resp.taskID, tenantID: tenantID)
            }.store(in: &disposeBag)
    }
    
    static func reset() {
        ResourceManager.remove(indexTableIDs: currentResourceID.keys.map { "ka_\($0)" })
        
        guard let backupResourceIndexTable = DynamicBrandStorage.defaultResourceIndexTable else { return }
        ResourceManager.insertOrUpdate(indexTables: [backupResourceIndexTable])
    }
    
    static func setValidResource(with tenantID: String) {
        guard let taskID = DynamicBrandStorage.latestTaskID(of: tenantID),
              let latestIndexTable = DynamicBrandStorage.resourceIndexTable(of: tenantID, and: taskID) else { return }
        
        logger.info("[DynamicBrand] set valid resource of: \(tenantID) latest: \(taskID)")
        ResourceManager.insertOrUpdate(indexTables: [latestIndexTable])
        featureSwitch = DynamicBrandStorage.latestFeatureSwitch
        currentResourceID[tenantID] = taskID
        DispatchQueue.global(qos: .background).async { DynamicBrandStorage.deleteResource(of: tenantID, current: taskID) }
    }
    
    static func setupTimer(with resolver: UserResolver, tenantID: String) {
        let interval = (try? resolver.resolve(SettingService.self)?.setting(with: UserSettingKey.make(userKeyLiteral: "client_dynamic_brand"))
                        as? [String: Int])?["pull_interval"] ?? defaultPullInterval
        logger.info("[DynamicBrand] set timer interval of: \(tenantID) interval: \(interval)")
        
        timer.setEventHandler { fetchResourceConfig(with: resolver, tenantID: tenantID) }
        timer.schedule(deadline: .now() + TimeInterval(interval), repeating: .seconds(interval))
        timer.activate()
    }
}
