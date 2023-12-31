//
//  MineAppLink.swift
//  LarkMine
//
//  Created by 白镜吾 on 2022/6/28.
//

import Foundation
import EENavigator
import LarkMessengerInterface

enum MineAppLinkPage: String {
    // https://bytedance.feishu.cn/docx/doxcn6zNMwG1QHSpMPQqyugjge8
    // MARK: 通用
    /// 通用设置页
    case general = "general"
    /// 通用 - 字体大小
    case fontSize = "font_size"
    /// 通用 - 网络诊断
    case netDiagnose = "net_diagnose"

    // MARK: 通知
    /// 通知 - 通知设置页
    case notification = "notification"
    /// 通知 - 消息通知故障诊断
    case pushDiagnose = "push_diagnose"

    // MARK: 内部设置
    /// 内部设置
    case innerSetting = "internal"
    // MARK: 关于飞书
    /// 关于飞书
    case about = "about"

    /// 参数映射对应枚举值
    static func mapping(url: String, param: String = "key") -> MineAppLinkPage? {
        guard let url = URLComponents(string: url) else { return nil }

        guard let key = url.queryItems?.first(where: { $0.name == param })?.value else { return nil }

        return MineAppLinkPage(rawValue: key)
    }
}
