//
//  TabBadgeService.swift
//  ByteViewInterface
//
//  Created by liurundong.henry on 2021/2/22.
//

import Foundation

public protocol TabBadgeService: AnyObject {

    /// 通知VC_Tab已启用
    func notifyTabEnabled()

    // 通知VC Context已经初始化完成
    func notifyTabContextEnabled()

    /// 清除VC_Tab的未读会议消息红点计数
    func clearTabBadge()

    /// 预留接口，刷新未读会议消息红点计数
    func refreshTabUnreadCount()

    /// 红点计数改变时，回调给外部
    func registerUnreadCountDidChangedCallback(_ callBack: @escaping ((Int64) -> Void))
}
