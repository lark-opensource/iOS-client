//
//  OpenPlatformDependency.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/9/27.
//

import Foundation
import RxSwift
//import RxRelay
import LarkModel
import RustPB
import EENavigator
import LarkShareContainer
import LarkOPInterface
import LarkMessengerInterface
import LarkQuickLaunchInterface
import LarkQuickLaunchBar
import LarkAIInfra

/// OpenPlatform 对外依赖
public protocol OpenPlatformDependency {
    /// 查询消息的内容
    func getMessageContent(messageIds: [String]) -> Observable<[String: Message]>?
    
    /// 发送分享消息富文本卡片消息
    func sendShareAppRichTextCardMessage(
        type: ShareAppCardType,
        chatContexts: [ShareViaChooseChatMaterial.SelectContext],
        input: RustPB.Basic_V1_RichText?
    ) -> Observable<Void>
    
    /// 发送分享消息富文本纯文案消息
    func sendShareTextMessage(
        text: String,
        chatContexts: [ShareViaChooseChatMaterial.SelectContext],
        input: RustPB.Basic_V1_RichText?
    ) -> Observable<Void>

    func canOpenDocs(url: String) -> Bool
    
    // MARK: LauncherBar + MyAI
    func isQuickLaunchBarEnable() -> Bool
    
    func createAIQuickLaunchBar(items: [QuickLaunchBarItem],
                                enableTitle: Bool,
                                enableAIItem: Bool,
                                quickLaunchBarEventHandler: OPMyAIQuickLaunchBarEventHandler?) -> MyAIQuickLaunchBarInterface?

    func isTemporaryEnabled() -> Bool
    
    func showTabVC(_ vc: UIViewController)
    
    func updateTabVC(_ vc: UIViewController)
    
    func removeTabVC(_ vc: UIViewController)
}
