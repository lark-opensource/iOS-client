//
//  SecurityPolicyActionDecision.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/4/12.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import UniverseDesignToast
import EENavigator

extension SecurityPolicyV2 {
    internal class SecurityPolicyActionDecisionImp: SecurityPolicyActionDecision, UserResolverWrapper {
        @ScopedProvider private var securityPolicyinterceptor: SecurityPolicyInterceptService?
        @ScopedProvider private var noPermissionService: NoPermissionService?
        @ScopedProvider private var settings: SCSettingService?
        private var registedHandlerType: [SecurityPolicyActionStyle: SecurityPolicyActionHandlerProtocol.Type] = [:]
        private var handlerMap: [SecurityPolicyActionStyle: SecurityPolicyActionHandlerProtocol] = [:]
        let userResolver: UserResolver

        init(resolver: UserResolver) {
            userResolver = resolver
            register(style: .commonDialog, handlerType: CommonDialogActionHandler.self)
        }

        func register(style: SecurityPolicyActionStyle, handlerType: SecurityPolicyActionHandlerProtocol.Type) {
            if let type = registedHandlerType[style] {
                SecurityPolicy.logger.info("security policy: security policy action decision imp redundant registe of key \(type)")
                return
            }
            registedHandlerType[style] = handlerType
        }
        // 对外部业务提供，目前的主要应用是IM DLP场景
        func handleAction(_ action: SecurityActionProtocol) {
            guard let actionsData = action.rawActions.data(using: .utf8),
                  let actionsModel = try? JSONDecoder().decode(ActionsModel.self, from: actionsData),
                  // 目前所有业务场景都只需要处理一个actions，如果后续有处理多个的场景，需要修改
                  let actionModel = actionsModel.actions.first else {
                SecurityPolicy.logger.info("security policy: security policy action decision imp serialization fail, msg: \(action.rawActions)")
                SecurityPolicyEventTrack.larkSCSHandleActionError(actionSource: .business,
                                                                  errorType: .deserialization)
#if DEBUG || ALPHA
                if let mainWindow = userResolver.navigator.mainSceneWindow {
                    UDToast().showTips(with: "serialization fail", on: mainWindow)
                }
#endif
                return
            }
            SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .business,
                                                         actionName: actionModel.name,
                                                         actionStyle: actionModel.style.rawValue)
            if settings?.bool(.disableHandleSecurityAction) ?? false {
                SecurityPolicy.logger.info("security policy: disable action execute by style is open")
                return
            }
            if (noPermissionService?.isInNoPermision).isTrue {
                SecurityPolicy.logger.info("security policy: security policy action decision imp is in nopermission")
                return
            }
            let params = actionModel.params
            if params?[ActionParamsKey.operation]?.stringValue == nil ||
                params?[ActionParamsKey.style]?.stringValue == nil {
                SecurityPolicyEventTrack.larkSCSHandleActionError(actionSource: .business,
                                                                  errorType: .requiredFieldNotFound)
            }

            let handler = getHandlerWithAction(action: action, actionModel: actionModel)
            handler.execute(action: action, actionModel: actionModel)
        }
        // 对安全SDK内部提供，目前的主要应用是安全SDK策略校验拦截
        func handleNoPermissionAction(_ action: LarkSecurityComplianceInterface.SecurityActionProtocol) {
            guard let actionsData = action.rawActions.data(using: .utf8) else {
                SecurityPolicy.logger.info("security policy: security policy action decision imp serialization fail, msg: \(action.rawActions)")
                return
            }
            do {
                let actionModel = try JSONDecoder().decode(NoPermissionRustActionModel.self, from: actionsData)
                SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .sdkInternal,
                                                             actionName: actionModel.model?.name ?? "NO_ACTION")
                DispatchQueue.runOnMainQueue {
                    let decision = try? self.userResolver.resolve(assert: NoPermissionRustActionDecision.self)
                    decision?.handleAction(actionModel)
                }
            } catch {
                SecurityPolicy.logger.error("decode fail, error: \(error)")
            }
        }

        private func getHandlerWithAction(action: SecurityActionProtocol,
                                          actionModel: ActionModel) -> SecurityPolicyActionHandlerProtocol {
            let style = actionModel.style
            if let handler = handlerMap[style] {
                return handler
            } else {
                let handler = registedHandlerType[style]?.init(resolver: userResolver) ?? DefaultHandler(resolver: userResolver)
                handlerMap[style] = handler
                return handler
            }
        }
    }
}
