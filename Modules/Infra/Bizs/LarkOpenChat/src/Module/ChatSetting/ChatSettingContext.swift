//
//  ChatSettingContext.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/24.
//

import UIKit
import Swinject
import Foundation
import LarkOpenIM
import LarkContainer

public typealias ChatSettingReloadTask = () -> Void
public typealias FirstSceentLoadFinishTask = () -> Void
public typealias ErrorTrackTask = (Error) -> Void

public final class ChatSettingContext: BaseModuleContext {
    public weak var currentVC: UIViewController?

    // 刷新方法
    public var reload: ChatSettingReloadTask?

    // 首屏加载完成
    public var firstSceentLoadFinish: FirstSceentLoadFinishTask?

    // 可感知错误上报
    public var errorTrackTask: ErrorTrackTask?
}
