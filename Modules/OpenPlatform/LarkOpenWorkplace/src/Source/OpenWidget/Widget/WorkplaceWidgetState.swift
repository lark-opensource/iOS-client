//
//  WorkplaceWidgetState.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/6.
//

import Foundation

/// Widget 组件状态
public enum WorkplaceWidgetState {
    /// 加载中，UI 上表现为 loading UI
    case loading
    /// 加载成功（宿主容器去掉其他蒙层 UI，展示业务 View）
    case success
    /// 加载失败（宿主容器覆盖错误页，并显示相应的错误信息）
    /// 业务需要自定义映射好内部错误到宿主 UI 展示的 code 和 message（注意需要已经处理好 i18n)
    case failed(code: Int, message: String)
}
