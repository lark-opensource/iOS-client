//
//  SecurityPolicyDebugFormHandler.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/30.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkContainer
import LarkAccountInterface
import EENavigator
import LarkSecurityCompliance
import LarkSecurityComplianceInfra

final class SecurityPolicyDebugFormHandler {
    static let storeKey = "security_policy_debug_form"
    let userResolver: UserResolver
    var result: ValidateResult?

    let configStr = "config"
    let policyModelStr = "基础参数"
    let ccmOrCalendarStr = "CCM/Calendar 场景需要参数"
    let imEntityStr = "IM 场景需要参数"

    let store: SCKeyValueStorage

    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        self.store = SCKeyValue.MMKV(userId: resolver.userID, business: .securityPolicy(subBiz: "debug"))
    }

    func generateVC() -> SCDebugFormViewController {
        let model = generateViewModel()
        let vc = SCDebugFormViewController(model: model)
        // 设置右上角的按键
        var items = vc.navigationItem.rightBarButtonItems ?? []
        items.append(UIBarButtonItem(title: "Action", style: .plain, target: self, action: #selector(handleAction)))
        items.append(UIBarButtonItem(title: "Report", style: .plain, target: self, action: #selector(report)))
        vc.navigationItem.rightBarButtonItems = items
        return vc
    }

    private func generateViewModel() -> SCDebugFormViewModel {
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        let fieldMap: [String: [SCDebugFieldViewModel]]? = store.value(forKey: Self.storeKey)
        let policyModel = fieldMap?[policyModelStr] ?? [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",key: "pointKey", valueType: .string, choiceList: PointKey.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",key: "entityDomain", valueType: .string, choiceList: EntityDomain.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",key: "entityType", valueType: .string, choiceList: EntityType.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",key: "entityOperate", valueType: .string, choiceList: EntityOperate.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "fileBizDomain", valueType: .string, choiceList: FileBizDomain.allCases.map({ $0.rawValue })),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "operatorTenantId", valueType: .int64, choiceList: [userService?.userTenant.tenantID ?? ""]),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "operatorUid", valueType: .int64, choiceList: [userService?.user.userID ?? ""]),
        ]

        let config = fieldMap?[configStr] ?? [
            SCDebugFieldViewModel(cellID: "SCDebugSwitchButtonViewCell", key: "ignoreAlert"),
            SCDebugFieldViewModel(cellID: "SCDebugSwitchButtonViewCell", key: "ignoreCache"),
            SCDebugFieldViewModel(cellID: "SCDebugSwitchButtonViewCell", key: "ignoreReport"),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "checkType", choiceList: ["cache", "async", "batch"]),
        ]

        let ccmOrCalendar = fieldMap?[ccmOrCalendarStr] ?? [
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "ownerTenantId", valueType: .int64, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "ownerUserId", valueType: .int64, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "token", valueType: .string, isRequired: false),
        ]

        let imEntity = fieldMap?[imEntityStr] ?? [
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "senderUserId", valueType: .int64, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "senderTenantId", valueType: .int64, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "msgId", valueType: .string, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "fileKey", valueType: .string, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "chatID", valueType: .int64, isRequired: false),
            SCDebugFieldViewModel(cellID: "SCDebugPasteButtonViewCell", key: "chatType", valueType: .int64, isRequired: false),
        ]

        let formModel = SCDebugFormViewModel(sectionList: [
            SCDebugSectionViewModel(sectionName: configStr, fieldList: config),
            SCDebugSectionViewModel(sectionName: policyModelStr, fieldList: policyModel),
            SCDebugSectionViewModel(sectionName: ccmOrCalendarStr, fieldList: ccmOrCalendar),
            SCDebugSectionViewModel(sectionName: imEntityStr, fieldList: imEntity)
        ])

        formModel.handler = self
        return formModel
    }

    private func generateFormHandler(field: [String : [SCDebugFieldViewModel]]) -> SecurityPolicyDebugValidateFormHandler {
        return SecurityPolicyDebugValidateFormHandler(resolver: userResolver,
                                                      config: field[configStr] ?? [],
                                                      policyModel: field[policyModelStr] ?? [],
                                                      ccmOrCalendar: field[ccmOrCalendarStr] ?? [],
                                                      imEntity: field[imEntityStr] ?? [])
    }

    @objc
    private func handleAction() {
        guard let result else {
            showErrorToast("无决策结果")
            return
        }
        result.handleAction()
    }

    @objc
    private func report() {
        guard let result else {
            showErrorToast("无决策结果")
            return
        }
        result.report()
    }
}

extension SecurityPolicyDebugFormHandler: SCDebugFormViewModelHandler {
    func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]],
                       completed: @escaping (String?) -> Void) {
        let handler = self.generateFormHandler(field: sectionContentMap)
        store.set(sectionContentMap, forKey: Self.storeKey)
        handler.check { [weak self] in
            guard let self else { return }
            self.result = $0
            completed("\(self.result, defaultValue: "nil")")
        }
    }
}

fileprivate struct SecurityPolicyDebugValidateFormHandler {
    enum CheckType: String {
        case cache
        case async
        case batch
    }
    let userResolver: UserResolver

    let config: [SCDebugFieldViewModel]
    let policyModel: [SCDebugFieldViewModel]
    let ccmOrCalendar: [SCDebugFieldViewModel]
    let imEntity: [SCDebugFieldViewModel]

    init(resolver: UserResolver,
         config: [SCDebugFieldViewModel],
         policyModel: [SCDebugFieldViewModel],
         ccmOrCalendar: [SCDebugFieldViewModel],
         imEntity: [SCDebugFieldViewModel]) {
        self.userResolver = resolver
        self.config = config
        self.policyModel = policyModel
        self.ccmOrCalendar = ccmOrCalendar
        self.imEntity = imEntity
    }

    private func getPolicyModel() -> PolicyModel? {
        guard let pointKeyString = policyModel[safeAccess: 0]?.realValue as? String, let pointKey = PointKey(rawValue: pointKeyString) else {
            showErrorToast("PointKey 无效")
            return nil
        }

        guard let entityDomainString = policyModel[safeAccess: 1]?.realValue as? String, let entityDomain = EntityDomain(rawValue: entityDomainString) else {
            showErrorToast("entityDomain 无效")
            return nil
        }

        guard let entityTypeString = policyModel[safeAccess: 2]?.realValue as? String, let entityType = EntityType(rawValue: entityTypeString) else {
            showErrorToast("entityType 无效")
            return nil
        }

        guard let entityOperateString = policyModel[safeAccess: 3]?.realValue as? String, let entityOperate = EntityOperate(rawValue: entityOperateString) else {
            showErrorToast("entityOperate 无效")
            return nil
        }

        guard let fileBizDomainString = policyModel[safeAccess: 4]?.realValue as? String, let fileBizDomain = FileBizDomain(rawValue: fileBizDomainString) else {
            showErrorToast("fileBizDomain 无效")
            return nil
        }

        guard let operateTenantId = policyModel[safeAccess: 5]?.realValue as? Int64 else {
            showErrorToast("operateTenantId 无效")
            return nil
        }

        guard let operateUserId = policyModel[safeAccess: 6]?.realValue as? Int64 else {
            showErrorToast("operateUserId 无效")
            return nil
        }

        var policyModel: PolicyModel? = nil
        switch entityDomain {
        case .ccm:
            let ownerTenantId = ccmOrCalendar[safeAccess: 0]?.realValue as? Int64
            let ownerUserId = ccmOrCalendar[safeAccess: 1]?.realValue as? Int64
            let token = ccmOrCalendar[safeAccess: 2]?.realValue as? String
            policyModel = PolicyModel(pointKey,
                                      CCMEntity(entityType: entityType,
                                                entityDomain: entityDomain,
                                                entityOperate: entityOperate,
                                                operatorTenantId: operateTenantId,
                                                operatorUid: operateUserId,
                                                fileBizDomain: fileBizDomain,
                                                token: token,
                                                ownerTenantId: ownerTenantId,
                                                ownerUserId: ownerUserId
                                               ))
        case .im:
            let senderUserId = imEntity[safeAccess: 0]?.realValue as? Int64
            let senderTenantId = imEntity[safeAccess: 1]?.realValue as? Int64
            let msgId = imEntity[safeAccess: 2]?.realValue as? String
            let fileKey = imEntity[safeAccess: 3]?.realValue as? String
            let chatID = imEntity[safeAccess: 4]?.realValue as? Int64
            let chatType = imEntity[safeAccess: 5]?.realValue as? Int64
            policyModel = PolicyModel(pointKey,
                                      IMFileEntity(entityType: entityType,
                                                   entityDomain: entityDomain,
                                                   entityOperate: entityOperate,
                                                   operatorTenantId: operateTenantId,
                                                   operatorUid: operateUserId,
                                                   fileBizDomain: fileBizDomain,
                                                   senderUserId: senderUserId,
                                                   senderTenantId: senderTenantId,
                                                   msgId: msgId,
                                                   fileKey: fileKey,
                                                   chatID: chatID,
                                                   chatType: chatType
                                                  ))
        case .calendar:
            let ownerTenantId = ccmOrCalendar[safeAccess: 0]?.realValue as? Int64
            let ownerUserId = ccmOrCalendar[safeAccess: 1]?.realValue as? Int64
            let token = ccmOrCalendar[safeAccess: 2]?.realValue as? String
            policyModel = PolicyModel(pointKey,
                                      CalendarEntity(entityType: entityType,
                                                     entityDomain: entityDomain,
                                                     entityOperate: entityOperate,
                                                     operatorTenantId: operateTenantId,
                                                     operatorUid: operateUserId,
                                                     fileBizDomain: fileBizDomain,
                                                     token: token,
                                                     ownerTenantId: ownerTenantId,
                                                     ownerUserId: ownerUserId
                                                    ))

        default:
            showErrorToast("当前未支持")
            break
        }
        return policyModel
    }

    private func getConfig() -> ValidateConfig {
        let ignoreSecurityOperate = config[safeAccess: 0]?.realValue as? String == "true"
        let ignoreReport = config[safeAccess: 1]?.realValue as? String == "true"
        let ignoreCache = config[safeAccess: 2]?.realValue as? String == "true"
        return ValidateConfig(ignoreSecurityOperate: ignoreSecurityOperate, ignoreCache: ignoreCache, ignoreReport: ignoreReport)
    }

    func check(completed: ((ValidateResult?) -> Void)?) {
        guard let policyModel = getPolicyModel() else { return }

        guard let rawValue = config[3].realValue as? String, let checkType = CheckType(rawValue: rawValue) else {
            showErrorToast("校验方式错误")
            return
        }

        let service = try? self.userResolver.resolve(assert: SecurityPolicyService.self)
        switch checkType {
        case .cache:
            let result = service?.cacheValidate(policyModel: policyModel, authEntity: nil, config: getConfig())
            completed?(result)
        case .async:
            service?.asyncValidate(policyModel: policyModel, authEntity: nil, config: getConfig(), complete: { result in
                completed?(result)
            })
        case .batch:
            service?.asyncValidate(policyModels: [policyModel], config: getConfig(), complete: { results in
                completed?(results.first?.value)
            })
        }
    }
}

fileprivate func showErrorToast(_ msg: String) {
    guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
    let dialog = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
    Navigator.shared.present(dialog, from: fromVC)
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
        dialog.dismiss(animated: true)
    }
}
