//
//  LarkSecurityComplianceAssembly.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/7.
//

import RxSwift
import RxCocoa
import Swinject
import LarkAssembler
import LarkContainer
import BootManager
import LarkDebugExtensionPoint
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import LarkEMM
import LarkPolicyEngine
import LarkWaterMark
import LarkAccountInterface

public final class SCDebugServiceLoader {
    public static var currentClass: AnyClass?
}

public final class LarkSecurityComplianceAssembly: LarkAssemblyInterface {

    public init() { }

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(NoPermissionActionInterceptor.self) { _ in
            NoPermissionActionInterceptorImp()
        }
        userContainer.register(SecurityComplianceService.self) { resolver in
            SecurityComplianceServiceImp(resolver: resolver)
        }
        userContainer.register(LarkEMMInternalService.self) { resolver in
            InternalServiceImp(resolver: resolver)
        }
        /// 文件加解密相关
        userContainer.register(FileCryptoService.self) { resolver in
            try FileCryptoServiceImpl(resolver: resolver)
        }
        userContainer.register(CryptoRustService.self) { resolver in
            CryptoRustService(userResolver: resolver)
        }
        userContainer.register(FileMigrationPool.self) { resolver in
            let fg = try resolver.resolve(type: SCFGService.self)
            // 开启迁移池功能，则返回对应的迁移池
            if fg.staticValue(.enableFileMigrationPool) {
                return FileMigrationPoolImp(userResolver: resolver)
            }
            // 未开启迁移池功能，返回空的对象
            return FileMigrationPoolEmpty()
        }
        userContainer.register(FileMigrationRecord.self) { resolver in
            try resolver.resolve(type: FileMigrationPool.self)
        }
        userContainer.register(FileCryptoWriteBackService.self) { resolver in
            try FileCryptoWriteBackServiceImpl(resolver: resolver)
        }
        /// 文件加解密相关
        userContainer.register(NoPermissionRustActionDecision.self) { resolver in
            return NoPermissionRustActionDecisionImp(resolver: resolver)
        }
        container.register(SensitivityControlSnCService.self) { _ in
            LarkPSDAServiceImpl(category: "sensitivity-control")
        }
        userContainer.register(WindowService.self) { resolver in
            WindowFactory(resolver: resolver)
        }
        userContainer.register(ExternalDependencyService.self) { resolver in
            try ExternalDependencyImp(resolver: resolver)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkSecurityComplianceSyncTask.self)
        NewBootManager.register(SimulatorAndJailBreakCheckTask.self)
        NewBootManager.register(SensitivityControlTask.self)
        NewBootManager.register(PrivacyMonitorTask.self)
        NewBootManager.register(PrivacyMonitorColdLaunchTask.self)
        NewBootManager.register(FileCryptoCleanTmpFileTask.self)
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        return subAssemblies
    }

    private lazy var subAssemblies: [LarkAssemblyInterface] = {
        var assemblies = [LarkAssemblyInterface]()
        if !Self.conditionAccessDisabled {
            assemblies.append(NoPermissionAssembly())
        }
        if let debugClass = SCDebugServiceLoader.currentClass as? NSObject.Type,
           let instance = debugClass.init() as? LarkAssemblyInterface {
            assemblies.append(instance)
            Logger.info("init SCDebugAssembly")
        }
        // Sensitivity Control
        assemblies.append(FileAppealAssembly())
        assemblies.append(LarkEMMAssembly())
        assemblies.append(PolicyEngineAssembly())
        assemblies.append(SecurityComplianceInfraAssembly())
        assemblies.append(FileCryptoAssembly())
        assemblies.append(TenantLoginAssembly())
        // 密钥升级
        assemblies.append(EncryptionUpgradeAssembly())
        // 水印
        assemblies.append(WaterMarkAssembly())
        // 安全SDK
        assemblies.append(SecurityPolicyAssembly())
        return assemblies
    }()
}

extension LarkSecurityComplianceAssembly {
    static var conditionAccessDisabled: Bool {
        // lint:disable:next lark_storage_check
        UserDefaults.standard.bool(forKey: SCSettingKey.conditionAccessDisabled.rawValue)
    }
}

final class LarkSecurityComplianceSyncTask: UserFlowBootTask, Identifiable {

    static var identify = "LarkSecurityComplianceSyncTask"
    override class var compatibleMode: Bool { SCContainerSettings.userScopeCompatibleMode }

    @ScopedProvider private var settings: Settings?

    override func execute() throws {
        syncConditionAccessDisabled()
        let storage = SCKeyValue.globalMMKV(business: .securityPolicy())
        storage.set(settings?.enableSecurityV2 ?? false, forKey: SettingsImp.CodingKeys.enableSecurityV2.rawValue)
        if SecurityPolicyAssembly.enableSecurityPolicyV2 {
            migrateSecurityPolicyData()
        }
        let passportService = try? userResolver.resolve(assert: LarkAccountInterface.PassportService.self)
        passportService?.register(interruptOperation: PolicyEngineInterruptOperationImp(resolver: userResolver))
        let engine = try userResolver.resolve(assert: PolicyEngineService.self)
        engine.postEvent(event: .initCompletion)
        let securityPolicy = try userResolver.resolve(assert: SecurityPolicyService.self)
        securityPolicy.config()
        if (settings?.enableSecuritySettingsV2).isTrue {
            SCLogger.info("Settings V2 is open", tag: SCSetting.logTag)
        }
    }

    func syncConditionAccessDisabled() {
        guard (settings?.enableSecuritySettingsV2).isTrue else {
            let value = settings?.conditionAccessDisabled ?? false
            // lint:disable:next lark_storage_check
            UserDefaults.standard.set(value, forKey: SettingsImp.CodingKeys.conditionAccessDisabled.rawValue)
            SCLogger.info("\(SettingsImp.CodingKeys.conditionAccessDisabled.rawValue) sync settings conditionAccessDisabled value: \(value)", tag: SettingsImp.logTag)
            return
        }
        let value = SCSetting.staticBool(scKey: .conditionAccessDisabled, userResolver: userResolver)
        // lint:disable:next lark_storage_check
        UserDefaults.standard.set(value, forKey: SCSettingKey.conditionAccessDisabled.rawValue)
        Logger.info("sync settings conditionAccessDisabled value: \(value)")
    }
    
    func migrateSecurityPolicyData() {
        guard let service = try? self.userResolver.resolve(assert: SCSettingService.self),
              service.bool(.disableSecurityPolicyMigrate) else { return }
        SecurityPolicyV2.SecurityPolicyCacheMigrator.queue.async { [weak self] in
            guard let self else { return }
            let migrator = try? userResolver.resolve(assert: SecurityPolicyV2.SecurityPolicyCacheMigrator.self)
            migrator?.migrateData(to: SecurityPolicyV2.UnorderedCache(userID: userResolver.userID,
                                                                     maxSize: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheMaxCapacity,
                                                                     cacheKey: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheKey))
        }
    }
}

final class PolicyEngineInterruptOperationImp: InterruptOperation {

    let userResolver: UserResolver

    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func getInterruptObservable(type: LarkAccountInterface.InterruptOperationType) -> RxSwift.Single<Bool> {
        return Single<Bool>.create {(single) -> Disposable in
            if type == .sessionInvalid {
                let engine = try? self.userResolver.resolve(assert: PolicyEngineService.self)
                engine?.postEvent(event: .sessionInvalid)
            }
            single(.success(true))
            return Disposables.create()
        }
    }
}
