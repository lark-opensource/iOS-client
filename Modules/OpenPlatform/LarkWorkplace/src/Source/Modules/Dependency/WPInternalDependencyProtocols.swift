//
//  WPInternalDependencyProtocols.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/6/11.
//

import Foundation
import LarkSetting
import Photos
import WebBrowser

// MARK: - guide
protocol WorkPlaceDependencyGuide {
    /// 根据 key 判断是否应该进行 Onboarding 展示
    func shouldShow(key: String) -> Bool

    /// 将指定的 on boarding key 标记为展示完成
    func finishShow(key: String)
}

protocol WorkplaceInternalDependencyNavation {
    /// 给定的 nativeKey 对应的 Tab 是否在 mainTabs 或 quickTabs 当中
    func isInTabs(for nativeKey: String) -> Bool
}
