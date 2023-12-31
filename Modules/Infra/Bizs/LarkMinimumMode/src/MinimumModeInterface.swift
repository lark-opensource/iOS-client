//
//  MinimumModeInterface.swift
//  LarkMinimumMode
//
//  Created by zc09v on 2021/5/7.
//

import Foundation
public protocol MinimumModeInterface {
    // 设置是否进入基本功能模式，成功后内部处理逻辑，失败后给上层回调
    func putDeviceMinimumMode(_ inMinimumMode: Bool, fail: ((Error) -> Void)?)

    // 展示切换至基本功能模式提示(内部会去判断是否需要执行展示逻辑)
    // show：具体的展示逻辑
    func showMinimumModeChangeTip(show: () -> Void)

    // 强制切换至基本功能模式(如果用户切换到了基本模式，没有切会正常。删了应用重装，默认会进正常模式，但此时服务端状态仍是基本模式状态，状态不一致，要强制提示切到基本模式)
    // showTip: 切换提示，提示完成后外部调用finish告知
    func forceChangModeIfNeeded(showTip: @escaping (_ finish: @escaping () -> Void) -> Void)
}
