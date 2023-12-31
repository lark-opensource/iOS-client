//
//  PolicyModelFactory.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/15.
//

import Foundation
import LarkContainer
import LarkPolicyEngine
import LarkAccountInterface
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

protocol PolicyModelFactory {
    var staticModels: [PolicyModel] { get }
    var ipModels: [PolicyModel] { get }
}

extension SecurityPolicyV2 {
    class PolicyModelFactoryImp: PolicyModelFactory {
        private let updateFrequencyManager: LarkSecurityComplianceInfra.Debouncer// 用于控制 ip 点位更新
        private let policyEngine: PolicyEngineService
        private let userService: PassportUserService
        private(set) var staticModels: [PolicyModel] = []
        let localCache: LocalCache
        @SafeWrapper private(set) var ipModels: [PolicyModel] = []

        init(resolver: UserResolver) throws {
            userService = try resolver.resolve(assert: PassportUserService.self)
            localCache = LocalCache(cacheKey: SecurityPolicyConstKey.ipPolicyList,
                                                     userID: userService.user.userID)
            let settings = try resolver.resolve(assert: SCSettingService.self)
            let interval = settings.int(.fileStrategyUpdateFrequencyControl)
            updateFrequencyManager = LarkSecurityComplianceInfra.Debouncer(interval: TimeInterval(interval))
            policyEngine = try resolver.resolve(assert: PolicyEngineService.self)
            staticModels = generateStaticPolicyModels()
            let ipTaskIDList: [String] = localCache.readCache() ?? []
            // taskID 无法反序列化成原本的 PolicyModel
            ipModels = staticModels.filter { policyModel in
                ipTaskIDList.contains { $0 == policyModel.taskID }
            }
            let notificationCenter = try resolver.resolve(assert: SecurityUpdateNotificationCenterService.self)
            notificationCenter.registeObserver(observer: self)
        }

        private func checkPointcutIsControlledByFactors(policyModels: [PolicyModel], factor: [String]) {
            var requestMap: [String: CheckPointcutRequest] = [:]
            policyModels.forEach { element in
                requestMap.updateValue(wrapPolicyModel(policyModel: element, factor: factor), forKey: element.taskID)
            }
            policyEngine.checkPointcutIsControlledByFactors(requestMap: requestMap) { [weak self] retMap in
                guard let self else { return }
                DispatchQueue.runOnMainQueue {
                    SecurityPolicy.logger.info("security policy: check pointcut is controlled: get result: \(retMap)")
                    policyModels.forEach { policyModel in
                        guard let isControlled = retMap[policyModel.taskID] else { return }
                        if isControlled {
                            if self.ipModels.contains(where: { $0 == policyModel }) {
                                return
                            } else {
                                self.ipModels.append(policyModel)
                            }
                        } else {
                            self.ipModels.removeAll(where: { $0 == policyModel })
                        }
                    }
                    self.localCache.writeCache(value: self.ipModels.map { $0.taskID })
                }
            }
        }

        private func wrapPolicyModel(policyModel: PolicyModel, factor: [String]) -> CheckPointcutRequest {
            return CheckPointcutRequest(pointKey: policyModel.pointKey.rawValue, entityJSONObject: policyModel.entity.asParams(), factors: factor)
        }

        private func generateStaticPolicyModels() -> [PolicyModel] {
            guard let userID = Int64(userService.user.userID),
                  let tenantID = Int64(userService.userTenant.tenantID) else {
                SecurityPolicy.logger.info("security policy: cannot get user_id or tennant_id in int64")
                return []
            }

            var ccmStaticFilepolicyEntitys: [PolicyModel] = [
                PolicyModel(.ccmContentPreview,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmContentPreview, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmCopy,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmCopy, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmFileDownload,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFileDownload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmFilePreView,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFilePreView, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmAttachmentDownload,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmAttachmentDownload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmFileUpload,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFileUpload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmAttachmentUpload,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmAttachmentUpload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmCreateCopy,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmCreateCopy, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)),
                PolicyModel(.ccmMoveRecycleBin,
                            CCMEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmMoveRecycleBin, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm))
            ]

            SecurityPolicyConstKey.ccmCloudOperateType.forEach { operateType in
                guard let pointKey = SecurityPolicyConstKey.ccmOperateToPointKey[operateType] else { return }
                ccmStaticFilepolicyEntitys.append(
                    PolicyModel(pointKey, CCMEntity(entityType: .doc, entityDomain: .ccm, entityOperate: operateType, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .ccm)))
            }

            let imStaticFilepolicyEntitys: [PolicyModel] = [
                PolicyModel(.imFilePreview,
                            IMFileEntity(entityType: .imMsgFile, entityDomain: .im, entityOperate: .imFilePreview, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .im)),
                PolicyModel(.imFileCopy,
                            IMFileEntity(entityType: .imMsgFile, entityDomain: .im, entityOperate: .imFileCopy, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .im))
            ]

            let calendarStaticFilepolicyEntitys: [PolicyModel] = [
                PolicyModel(.ccmFileDownload,
                            CalendarEntity(entityType: .file, entityDomain: .ccm, entityOperate: .ccmFileDownload, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: .calendar))
            ]

            return ccmStaticFilepolicyEntitys + imStaticFilepolicyEntitys + calendarStaticFilepolicyEntitys
        }
    }
}

extension SecurityPolicyV2.PolicyModelFactoryImp: SecurityUpdateObserver {
    func notify(trigger: SecurityPolicyV2.UpdateTrigger) {
        notifyPolicyEngine(trigger: trigger)
        updateFrequencyManager.callback = { [weak self] in
            guard let self else { return }
            self.checkPointcutIsControlledByFactors(policyModels: self.staticModels, factor: ["SOURCE_IP_V4"])
        }
        updateFrequencyManager.call()
    }

    func notifyPolicyEngine(trigger: SecurityPolicyV2.UpdateTrigger) {
        switch trigger {
        case .networkChange:
            policyEngine.postEvent(event: .networkChanged)
        case .becomeActive:
            policyEngine.postEvent(event: .becomeActive)
        default:
            break
        }
    }
}
