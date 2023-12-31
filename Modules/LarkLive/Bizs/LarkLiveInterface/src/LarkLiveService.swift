//
//  LarkLiveService.swift
//  LarkLive
//
//  Created by yangyao on 2021/6/16.
//

import Foundation

public protocol LarkLiveService: AnyObject {
    /// 设置live
    func setupLive(url: URL?)
    /// 直播页面
    func startLive(url: URL?, context: [String:Any]?)

    /// 判断直播链接
    func isLiveURL(url: URL?) -> Bool

    /// 判断直播是否在小窗
    func isLiving() -> Bool

    /// 停止直播
    func startVoip()

    /// 直播小窗冲突埋点
    func trackFloatWindow(isConfirm: Bool)
}
