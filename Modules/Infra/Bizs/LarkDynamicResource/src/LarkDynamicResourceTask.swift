//
//  LarkDynamicResourceTask.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/3/30.
//

import Foundation
import BootManager
import LarkResource
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import LarkSetting

final class LarkDynamicResourceTask: FlowBootTask, Identifiable {
    static var identify = "LarkDynamicResourceTask"

    static let logger = Logger.log(LarkDynamicResourceTask.self, category: "Module.LarkDynamicResource")

    // 索引文件的初始化需要确保在UI初始化之前，所以这里使用同步，资源下载会切换到异步线程
    override var scheduler: Scheduler { .main }

    override func execute(_ context: BootContext) {
        Self.logger.info("dynamic resource: new excute process")

        // 状态初始化，切换租户都会走这里逻辑
        DynamicResourceManager.shared.revert()
        DynamicBrandManager.reset()
        
        guard DynamicResourceHelper.shouldUseDynamicResource(),
              let userResolver = try? Container.shared.getUserResolver(userID: context.currentUserID) else { return }
        let identifier = DynamicResourceHelper.identifier()
        Self.logger.info("dynamic resource: current identifier:\(identifier)")
        DynamicResourceManager.shared.fetchValidResourceIfNeed(by: identifier)
        
        guard let featureGatingService = try? Container.shared.getUserResolver(userID: context.currentUserID).resolve(FeatureGatingService.self),
              let tenantID = userResolver.resolve(PassportUserService.self)?.userTenant.tenantID else { return }
        if featureGatingService.dynamicFeatureGatingValue(with: "lark.hobby.lark_resource_bundle_refactor") { DynamicBrandManager.setValidResource(with: tenantID) }
    }
}

final class LarkDynamicResourceSyncTask: FlowBootTask, Identifiable {
    static var identify = "LarkDynamicResourceSyncTask"

    static let logger = Logger.log(LarkDynamicResourceSyncTask.self, category: "Module.LarkDynamicResource")

    override var scheduler: Scheduler { .async }

    override func execute(_ context: BootContext) {
        Self.logger.info("dynamic resource: sync task new sync process")
        
        guard DynamicResourceHelper.shouldUseDynamicResource() else { return }
        
        let identifier = DynamicResourceHelper.identifier()
        Self.logger.info("dynamic resource: sync task current identifier:\(identifier)")
        DynamicResourceManager.shared.syncBackupIfNeed(by: identifier)
        DynamicResourceManager.shared.fetchResource(id: identifier)
        
        guard let userResolver = try? Container.shared.getUserResolver(userID: context.currentUserID),
              let tenantID = userResolver.resolve(PassportUserService.self)?.userTenant.tenantID else { return }
        DynamicBrandManager.fetchResourceConfig(with: userResolver, tenantID: tenantID)
        DynamicBrandManager.setupTimer(with: userResolver, tenantID: tenantID)
    }
}
