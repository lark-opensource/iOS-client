//
//  MessageRestrictedInterceptor.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/5.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMenuController
import LarkSDKInterface
import LarkContainer
import LarkSearchCore
import LarkUIKit
import LarkGuide
import LarkSetting
import RustPB
import LKCommonsLogging
import UniverseDesignToast

public final class ServerRestrictedInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .server }
    private typealias InterceptorReason = MessageActionServerInterceptor.InterceptorReason

    /// 根据被禁用原因生成对应的报错toast文案
    private static func generateToastString(errCode: Int32, type: MessageActionType) -> String {
        switch InterceptorReason(errCode) {
        case .messageRestricted:
            switch type {
            case .copy, .cardCopy, .messageLink:
                return BundleI18n.LarkMessageCore.Lark_IM_MessageRestrictedCantCopy_Hover
            case .forward, .forwardThread:
                return BundleI18n.LarkMessageCore.Lark_IM_MessageRestrictedCantForward_Hover
            case .addToSticker:
                return BundleI18n.LarkMessageCore.Lark_IM_MessageRestrictedCantAddSticker_Toast
            case .imageEdit:
                return BundleI18n.LarkMessageCore.Lark_IM_MessageRestrictedCantEdit_Hover
            default:
                break
            }
        case .unkown:
            break
        }
        return BundleI18n.LarkMessageCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
    }

    private static func generateInterceptedType(behavior: Basic_V1_Message.DisabledAction.Behavior,
                                         menuType: MessageActionType) -> [MessageActionType: MessageActionInterceptedType] {
        switch behavior.displayMode {
        case .invisible:
            return [menuType: .hidden]
        case .disable:
            return [menuType: .disable(generateToastString(errCode: behavior.code, type: menuType))]
        @unknown default:
            return [:]
        }
    }

    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        /// 合并转发权限需要与父消息权限取并集
        if let fatherMfDisableAction = context.message.fatherMFMessage?.disabledAction {
            fatherMfDisableAction.actions.map { (actionType, behavior) in
                let action = MessageDisabledAction.Action(rawValue: Int(actionType))
                for menuType in action?.clientMenuActionMap ?? [] {
                    interceptedActions.merge(ServerRestrictedInterceptor.generateInterceptedType(behavior: behavior, menuType: menuType)) { $1 }
                }
            }
        }
        context.message.disabledAction.actions.map { (actionType, behavior) in
            let action = MessageDisabledAction.Action(rawValue: Int(actionType))
            for menuType in action?.clientMenuActionMap ?? [] {
                interceptedActions.merge(ServerRestrictedInterceptor.generateInterceptedType(behavior: behavior, menuType: menuType)) { $1 }
            }
        }
        return interceptedActions
    }
}

private extension MessageDisabledAction.Action {
    var clientMenuActionMap: [MessageActionType] {
        switch self {
        case .allAction:
            return MessageActionType.allCases
        case .addSticker:
            return [.addToSticker]
        case .transmit:
            return [.forward]
        case .download:
            return [.imageEdit]
        case .copy:
            return [.copy, .cardCopy]
        case .saveToLocal, .saveToSpace:
            return []
        case .reaction:
            return [.reaction]
        case .reply:
            return [.reply]
        case .replyInThread:
            return [.createThread]
        case .sendUrgent:
            return [.urgent]
        case .recall:
            return [.recall]
        case .editMessage:
            return [.multiEdit]
        case .multiSelect:
            return [.multiSelect]
        case .flag:
            return [.flag]
        case .pin:
            return [.pin]
        case .chatPin:
            return [.chatPin]
        case .clipToTop:
            return [.topMessage]
        case .addTask:
            return [.todo]
        case .translate:
            return [.translate, .selectTranslate]
        case .delete:
            return [.delete]
        case .copyMessageLink:
            return [.messageLink]
        case .favorite:
            return [.favorite]
        case .widgets:
            return [.takeActionV2]
        case .unspecified:
            return []
        default:
            return []
        }
    }
}

public struct MessageActionServerInterceptor {
    public enum InterceptorReason {
        case unkown
        case messageRestricted
        public init(_ errCode: Int32) {
            switch errCode {
            case 311_150:
                self = .messageRestricted
            default:
                self = .unkown
            }
        }
    }
}
