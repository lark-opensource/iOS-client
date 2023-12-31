//
//  MagicShareTrackDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/12/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// MS加载结束的原因
enum MagicShareInitFinishedReason: Int {
    /// 成功
    case success = 0
    /// 初始化未完成时，用户手动刷新
    case refreshAbort = 1
    /// 文档加载失败
    case docLoadFail = 2
    /// mobile不使用
    case jssdkInjectFail = 3
    /// mobile不使用
    case stgInjectFail = 4
    /// mobile不使用
    case webviewCrash = 5
    /// mobile不使用
    case startFailed = 6
    /// mobile不使用
    case stgPullFail = 7
    /// mobile不使用
    case webviewTimeout = 8
    /// 未加载成功时，当前MS结束或发起新的一篇MS
    case stopBeforeInitialized = 9
    /// 用户处于自由浏览
    case unfollow = 10
    /// 收到followInfo时发现share_id有变化, 但是文档的doc_token等于当前正在浏览的文档, 所以不需要加载 (当前正在浏览的文档 = 自由浏览时当前正在浏览的文档或跟随中时分享的文档)
    case samePage = 11
    /// 收到followInfo时处于小窗状态
    case isFloating = 12
    /// 收到followInfo时处于后台状态
    case isBackground = 13

    /// 描述，打印使用
    var desString: String {
        switch self {
        case .success:
            return "success(0)"
        case .refreshAbort:
            return "refreshAbort(1)"
        case .docLoadFail:
            return "docLaodFail(2)"
        case .jssdkInjectFail:
            return "jssdkInjectFail(3)"
        case .stgInjectFail:
            return "stgInjectFail(4)"
        case .webviewCrash:
            return "webviewCrash(5)"
        case .startFailed:
            return "startFailed(6)"
        case .stgPullFail:
            return "stgPullFail(7)"
        case .webviewTimeout:
            return "webviewTimeout(8)"
        case .stopBeforeInitialized:
            return "stopBeforeInitialized(9)"
        case .unfollow:
            return "unfollow(10)"
        case .samePage:
            return "samePage(11)"
        case .isFloating:
            return "isFloating(12)"
        case .isBackground:
            return "isBackground(13)"
        }
    }
}
