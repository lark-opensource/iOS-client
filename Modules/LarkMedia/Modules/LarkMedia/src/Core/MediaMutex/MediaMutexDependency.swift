//
//  MediaMutexDependency.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/3.
//

import Foundation

public protocol MediaMutexDependency {
    /// 生成通用错误文案
    /// - Parameter scene: 当前使用中的媒体业务场景
    /// - Parameter type: 当前使用中的媒体类型
    func makeErrorMsg(scene: MediaMutexScene, type: MediaMutexType) -> String
    /// 拉取 LarkSettings 配置
    func fetchSettings(block: (([MediaMutexScene: SceneMediaConfig]) -> Void)?)
    /// 支持 runtime 调用
    var enableRuntime: Bool { get }
}
