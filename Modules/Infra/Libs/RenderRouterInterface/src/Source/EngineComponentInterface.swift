//
//  EngineComponentInterface.swift
//  RenderRouterInterface
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import TangramComponent

/// 集成进RenderRouter需要满足的协议
public protocol EngineComponentInterface {
    var tcComponent: BaseRenderComponent { get }

    /// 数据更新
    func update(previewID: String, componentID: String, engineEntity: Basic_V1_EngineEntity)

    /// Cell将要出现的时候
    func willDisplay()

    /// Cell不再显示的时候
    func didEndDisplay()

    /// Size发生变化
    func onResize()
}
