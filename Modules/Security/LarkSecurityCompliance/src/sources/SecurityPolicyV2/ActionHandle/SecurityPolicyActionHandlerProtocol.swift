//
//  SecurityPolicyActionHandlerProtocol.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/4/14.
//

import Foundation
import LarkContainer
import UniverseDesignDialog
import LarkSecurityComplianceInterface
import SwiftyJSON

protocol SecurityPolicyActionHandlerProtocol {
    init(resolver: UserResolver)
    func execute(action: SecurityActionProtocol, actionModel: SecurityPolicyV2.ActionModel)
}

extension SecurityPolicyV2 {
    internal struct DefaultHandler: SecurityPolicyActionHandlerProtocol {
        let userResolver: UserResolver

        init(resolver: UserResolver) {
            userResolver = resolver
        }

        func execute(action: SecurityActionProtocol, actionModel: ActionModel) {
            SecurityPolicy.logger.info("cant find style handler")
        }
    }

    internal struct CommonDialogActionHandler: SecurityPolicyActionHandlerProtocol {

        let userResolver: UserResolver

        init(resolver: UserResolver) {
            userResolver = resolver
        }
        func execute(action: SecurityActionProtocol, actionModel: ActionModel) {
            let dialog = CommonDialog(resolver: userResolver, action: action, actionModel: actionModel)
            let interceptor = try? userResolver.resolve(assert: SecurityPolicyInterceptService.self)
            interceptor?.showDialog(dialog: dialog)
        }
    }

    final private class CommonDialog: UDDialog, UserResolverWrapper {
        @ScopedProvider var securityPolicyInterceptor: SecurityPolicyInterceptService?
        private let action: SecurityActionProtocol
        private let actionModel: ActionModel
        let userResolver: UserResolver

        init(resolver: UserResolver, action: SecurityActionProtocol, actionModel: ActionModel) {
            self.userResolver = resolver
            self.actionModel = actionModel
            self.action = action
            super.init()
            setBasicUI()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setBasicUI() {
            let operation = actionModel.operation
            let title = operation.dialogTitle
            let content = operation.dialogContent
            let primaryButtonText = operation.primaryButtonText
            setTitle(text: title)
            setContent(text: content)
            // swiftLint:disable:next
            addButton(text: primaryButtonText, dismissCompletion: { [weak self] in
                guard let self else { return }
                self.securityPolicyInterceptor?.dismissDialog(dialog: self)
            })
        }
    }
}

extension SecurityPolicyV2.SecurityPolicyActionOperation {
    var dialogTitle: String {
        switch self {
        case .dlpIMSave:
            return BundleI18n.LarkSecurityCompliance.Lark_DLPSDK_Title_UnableToSave
        case .dlpIMChatCreate:
            return BundleI18n.LarkSecurityCompliance.Lark_DLPSDK_Title_UnableToCreate
        default:
            return BundleI18n.LarkSecurityCompliance.Lark_SecureDowngrade_Others_UnableToManage
        }
    }

    var dialogContent: String {
        switch self {
        case .dlpIMSave:
            return BundleI18n.LarkSecurityCompliance.Lark_DLPSDK_Tooltip_UnableToSaveForPolicyReasons
        case .dlpIMChatCreate:
            return BundleI18n.LarkSecurityCompliance.Lark_DLPSDK_Descrip_UnableToCreateForSensitive
        default:
            return BundleI18n.LarkSecurityCompliance.Lark_SecureDowngrade_Others_UnableToManageDetails
        }
    }

    var primaryButtonText: String {
        switch self {
        case .dlpIMSave:
            return BundleI18n.LarkSecurityCompliance.Lark_DLPSDK_Button_IUnderstand
        default:
            return BundleI18n.LarkSecurityCompliance.Lark_Conditions_GotIt
        }
    }
}

extension SecurityPolicyV2 {
    struct ActionsModel: Codable {
        let actions: [ActionModel]
        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case actions
        }
    }

    enum SecurityPolicyActionOperation: String {
        case unknown
        case dlpIMSave = "DLP_IM_SAVE"
        case dlpIMChatCreate = "DLP_IM_CHAT_CREATE"
    }

    enum SecurityPolicyActionStyle: String {
        case unknown
        case commonDialog = "CommonDialog"
        case commonToast = "CommonToast"
    }

    class ActionParamsKey {
        static var style = "style"
        static var operation = "operation"
    }
}
