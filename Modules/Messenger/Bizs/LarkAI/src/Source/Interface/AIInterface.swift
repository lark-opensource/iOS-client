//
//  AIInterface.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2020/11/12.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkSDKInterface
import LarkEnv

// MARK: - Smart Reply

/// 正在展示的item的类型
public enum ShownSmartReplyItemSource: Int {
    /// 接口请求，主要用于AI的Smart Reply业务
    case remote
    /// 本地数据，目前主要用于todo任务
    case local
}

/// item的类型，类型可用来区分事件类型 和 事件参数
public enum SmartReplyItemType: Int {
    case unknown
    /// 文本
    case text
    /// 小程序
    case appAction
    case attachment
    /// 文档
    case docs
    /// 投票
    case vote
    /// 红包
    case hongbao
    /// 定位
    case location
    case profile
    /// 日历
    case calendar
    /// TODO
    case todo
}
/// icon
public enum SmartReplyItemIconSource {
    /// 本地图片
    case local(image: UIImage)
    /// 远端图片
    case remote(urlString: String)
}

/// 智能回复item 协议
/// note: 业务实现该协议，可根据需求扩展自己需要的字段
public protocol SmartReplyItemProtocol: AnyObject {
    /// 是否显示icon
    var showIcon: Bool { get set }
    /// icon
    var icon: SmartReplyItemIconSource { get set }
    /// title
    var title: String { get set }
    /// 类型；详见：SmartReplyItemType
    var type: SmartReplyItemType { get set }
}

/// Smart Reply delegate
public protocol SmartReplyVCDelegate: AnyObject {
    func getMessage() -> (message: Message?, isReply: Bool)
    func isEditTextEmpty() -> Bool
    func inSmartReplyView(didClick item: SmartReplyItemProtocol, envType: LarkEnv.Env.TypeEnum)
    func onSmartViewHiddenChange(isHidden: Bool, source: ShownSmartReplyItemSource)
    func getViewController() -> UIViewController?
    func getIsTableLocked() -> Bool
    func isKeyboardEnable() -> Bool
}

/// Smart Reply navigator delegate
public protocol SmartActionNavigatorDelegate: AnyObject {
    func goToDoc()
}

public func getMicroUrlString(key startpage: String, envType: LarkEnv.Env.TypeEnum) -> String? {
    var appid: String?
    // choice different appid by different channel
    switch envType {
    case .release:
        appid = "cli_9d0efd483037d108"
    case .staging:
        appid = "cli_9d230f08c66b5101"
//    case .oversea:
//        appid = "cli_9d3bb7fdac38d106"
    case .preRelease:
        break
    @unknown default:
        assert(false, "new value")
        break
    }
    guard let appID = appid else { return nil }
    let urlString = "sslocal://microapp?app_id=\(appID)&start_page=" + startpage
    return urlString
}
