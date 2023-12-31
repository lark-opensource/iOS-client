//
//  Debug.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/8.
//
#if DEBUG || ALPHA || BETA
import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import SuiteAppConfig
import LarkEMM
import UniverseDesignToast
import LarkMessengerInterface
import LarkStorage
import LarkContainer

/// 长按消息菜单，是否出现CopyMsgId选项，Debug使用
public final class DebugMessageActionSubModule: MessageActionSubModule {
    public static let debugKey: String = "message_menu_debug_key"

    public override var type: MessageActionType {
        return .debug
    }

    /// 这里始终设置为true，因为会话里面每个MessageActionSubModule只执行一次canInitialize，后续会多次执行canHandle
    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    /// 在canHandle判断开关，可以让用户不用退群重进，就可以享受实时开启debug功能
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return KVStores.Messenger.global().bool(forKey: DebugMessageActionSubModule.debugKey)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
            return MessageActionItem(text: "CopyMsgId",
                                     icon: BundleResources.Menu.menu_debug,
                                     trackExtraParams: [:]) { [weak self] in
                guard let targetVC = self?.context.pageAPI else { return }
                let info = "chatId: \(model.chat.id)\nmessageId: \(model.message.id)"
                SCPasteboard.generalPasteboard().string = info
                /// 有些场景剪贴板功能不可用，需要将信息直接外漏，方便用户截屏等查看id
                UDToast.showTips(with: "copy success\n\(info)", on: targetVC.view.window ?? targetVC.view)
            }
    }
}
#endif
