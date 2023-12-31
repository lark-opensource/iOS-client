//
//  LarkMeegoService.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/8/26.
//

import Foundation
import LarkModel
import UIKit

/// Meego 创单页入口
public enum EntranceSource: String {
    case floatMenu = "float_menu"
    case keyboardMenu = "keyboard_menu"
    case mutiSelect = "muti_select"
    case shortcutMenu = "shortcut_menu"
}

/// Lark 中的 Meego Native 服务
public protocol LarkMeegoService: AnyObject {
    /// 检测是否存在 meego url
    func hasAnyMeegoURL(_ urls: [String]) -> Bool

    /// 返回符合 meego flutter 打开格式的 url
    func matchedMeegoUrls(_ urls: [String]) -> [URL]

    /// 是否是 meego 首页（也包括工作台） url
    func isMeegoHomeURL(_ url: String) -> Bool

    /// 判断开启拦截 meego url
    func enableMeegoURLHook() -> Bool

    /// 判断是否可以展示创建工作项的业务入口
    func canDisplayCreateWorkItemEntrance(chat: Chat, messages: [Message]?, from: EntranceSource) -> Bool

    /// 判断是否可以展示创建工作项的业务入口（跟 message 无关）
    func canDisplayCreateWorkItemEntrance(chat: Chat, from: EntranceSource) -> Bool

    /// 创建工作项
    /// 对于传了 Messages 的消息场景，会采集可以作为工作项描述的消息内容
    func createWorkItem(
        with chat: Chat,
        messages: [Message]?,
        sourceVc: UIViewController,
        from: EntranceSource
    )

    /// 处理开放平台 Meego 消息卡片曝光
    func handleMeegoCardExposed(message: Message)

    /// FG Post接口： 批量定制查询FG数据
    /// - Parameter keysString: 查询的FGkey拼接字符串
    /// - Parameter separatorString: keysString的分割符号
    /// - Parameter projectKey: 空间
    /// - Parameter userKey: 用户key
    /// - Parameter tenantKey: 租户key
    /// - Parameter callBack: 数据回调，接口返回的FG数据json字符串
    func queryLarkFeatureGatingData(keysString: String, separatorString: String, appName: String, projectKey: String, userKey: String, tenantKey: String, callBack: @escaping (String) -> Void)

    /// 判断一个 vc 是否属于 Meego 的
    func belongsToMeego(with vc: UIViewController) -> Bool
}
