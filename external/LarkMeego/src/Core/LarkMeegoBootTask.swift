//
//  LarkMeegoBootTask.swift
//  LarkMeego
//
//  Created by bytedance on 2022/1/23.
//

import Foundation
import BootManager
import LarkContainer
import AppContainer
import LarkMeegoInterface
import LarkFlutterContainer
#if MessengerMod
import LarkMessageBase
#endif

public class LarkMeegoBootTask: UserFlowBootTask, Identifiable {
    public static var identify = "LarkMeegoBootTask"

    public override class var compatibleMode: Bool {
        return Meego.userScopeCompatibleMode
    }

    public override func execute(_ context: BootContext) {
        if let meegoService = try? userResolver.resolve(assert: LarkMeegoService.self) {
            (meegoService as? LarkMeegoServiceImpl)?.registerMeegoFlutterRoutes()
        }
        if let flutterContainerService = try? userResolver.resolve(assert: FlutterContainerService.self),
           let netClientHelper = try? LarkMeegoNetClientHelper(userResolver: userResolver),
           let meegoService = try? userResolver.resolve(assert: LarkMeegoService.self) {
            let biz = "meego"
            flutterContainerService.register(bizName: biz) { _ in
                return netClientHelper.getMeegoBaseURL().host ?? ""
            }
            flutterContainerService.register(bizName: biz, flutterWebInterceptor: { [weak meegoService] source in
                switch source {
                case .http: return meegoService?.enableMeegoURLHook() ?? false
                case .flutterInnerRoute: return true
                }
            })
        }
    }

#if MessengerMod
    @_silgen_name("Lark.ChatCellFactory.LarkMeegoAssembly")
    public static func chatCellFactoryRegister() {
        // TODO(shizhengyu): 推动 IM Team 对 cell 曝光机制进行 userResolver 的改造
        // 普通会话页面（非密聊）
        NormalChatCellLifeCycleObseverRegister.register {
            return MeegoCellLifeCycleObserver()
        }
        // 会话详情页
        NormalMessageDetailCellLifeCycleObseverRegister.register {
            return MeegoCellLifeCycleObserver()
        }
        // 合并转发详情页
        MergeForwardCellLifeCycleObseverRegister.register {
            return MeegoCellLifeCycleObserver()
        }
        // Thread页
        ThreadChatCellLifeCycleObseverRegister.register {
            return MeegoCellLifeCycleObserver()
        }
        // Thread详情页
        ThreadDetailCellLifeCycleObseverRegister.register {
            return MeegoCellLifeCycleObserver()
        }
        // Pin列表页
        PinCellLifeCycleObseverRegister.register {
            return MeegoCellLifeCycleObserver()
        }
    }
#endif
}
