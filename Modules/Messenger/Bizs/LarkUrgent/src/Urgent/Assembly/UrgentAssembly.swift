//
//  LarkUrgent+component.swift
//  Lark
//
//  Created by ChalrieSu on 2018/7/18.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import LarkMessengerInterface
import LarkModel
import Swinject
import EENavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import BootManager
import RustPB
import LarkRustClient
import LarkAssembler
import LarkSetting
import LarkOpenSetting

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
enum Urgent {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") //Global
        return v
    }
    static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class UrgentAssembly: LarkAssemblyInterface {

    public let config: UrgentAssemblyConfig

    public init(config: UrgentAssemblyConfig) {
        self.config = config
    }

    public func registContainer(container: Container) {

        let user = container.inObjectScope(Urgent.userScope)

        user.register(UrgencyCenter.self) { (r) -> UrgencyCenter in
            let modelService = try r.resolve(assert: ModelService.self)
            let pushCenter = try r.userPushCenter
            let urgentPush = pushCenter.observable(for: PushUrgent.self)
                .map({ (push) -> UrgentMessageModel in
                    return UrgentMessageModel(
                        urgent: push.urgentInfo.urgent,
                        message: push.urgentInfo.message,
                        chat: push.urgentInfo.chat,
                        summerize: { modelService.messageSummerize($0) }
                    )
                })

            let ackPush = pushCenter.observable(for: PushUrgentAck.self)
                .map({ (push) -> UrgentAck in
                    return (push.messageId, push.ackId)
                })

            let pushUrgentFail = pushCenter.observable(for: PushUrgentFail.self)
            let networkStatusPush = pushCenter.observable(for: PushWebSocketStatus.self)
            let fgService = try r.resolve(assert: FeatureGatingService.self)
            let enableDocCustomIcon = fgService.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.docCustomAvatarEnable.rawValue))

            return UrgencyCenterImpl(userResolver: r,
                                     urgentAPI: try r.resolve(assert: UrgentAPI.self),
                                     messageAPI: try r.resolve(assert: MessageAPI.self),
                                     chatAPI: try r.resolve(assert: ChatAPI.self),
                                     modelService: modelService,
                                     messagePacker: try r.resolve(assert: MessagePacker.self),
                                     currentChatterId: (try r.resolve(assert: PassportUserService.self)).user.userID,
                                     newUrgencyPush: urgentPush,
                                     confirmUrgencyPush: ackPush,
                                     networkStatusPush: networkStatusPush,
                                     urgentFailPush: pushUrgentFail,
                                     enableDocCustomIcon: enableDocCustomIcon)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(NewLoadUrgentTask.self)
        NewBootManager.register(UpdateUrgentNumTask.self)
        #if(IS_EM_ENABLE)
        NewBootManager.register(EMTask.self)
        #endif
    }

    public func registRouter(container: Container) {
        /// 单聊加急
        Navigator.shared.registerRoute.type(UrgentChatterBody.self).factory(cache: true, UrgentChatterHandler.init(resolver:))
        Navigator.shared.registerRoute.type(UrgentBody.self).factory(cache: true, UrgentHandler.init(resolver:))
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushUrgent, UrgentPushHandler.init(resolver:))
        (Command.pushUrgentFailed, UrgentFailPushHandler.init(resolver:))
    }

    @_silgen_name("Lark.OpenSetting.UrgentAssembly")
    public static func registMineSettingForNotification() {
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.addUrgentNum.moduleKey, provider: { userResolver in
            guard let fgService = try? userResolver.resolve(assert: FeatureGatingService.self),
                  fgService.staticFeatureGatingValue(with: "messenger.buzzcall.numsetting") else {
                return nil
            }
            return NotificationSettingAddUrgentNumModule(userResolver: userResolver)
        })
    }
}
