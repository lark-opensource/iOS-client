//
//  WhiteboardDependencies.swift
//  Whiteboard
//
//  Created by Prontera on 2022/3/25.
//

import Foundation

public protocol Dependencies: ParticipantsDependency, TrackDependency, ViewChangeDependency, UIDependency {}

/// 外部依赖： 获取用户信息
public protocol ParticipantsDependency {
    func nicknameBy(userID: String, deviceID: String, userType: Int, completion: @escaping (String) -> Void)
}

/// 外部依赖： UI
public protocol UIDependency {
    func getWatermarkView(completion: @escaping (UIView?) -> Void)
    func showToast(_ text: String)
}

/// 埋点相关
public protocol TrackDependency {
    func didFinishRenderCmds()
    func didTimerPaused(fps: Int, shapeCount: Int, cmdsCount: Int)
}

public extension TrackDependency {
    func didFinishRenderCmds() {}
    func didTimerPaused(fps: Int, shapeCount: Int, cmdsCount: Int) {}
}

// MARK: - 会中视图变化

public protocol ViewChangeDependency {
    /// 编辑白板菜单是否正在展示
    func setWhiteboardMenuDisplayStatus(to newState: Bool, isUpdate: Bool)
    func setNeedChangeAlphaOfSuspensionComponent(isOpaque: Bool)
    func didChangePenBrush(brush: BrushType)
    func didChangePenColor(color: ColorType)
    func didChangeHighlighterBrush(brush: BrushType)
    func didChangeHighlighterColor(color: ColorType)
    func didChangeShapeType(shape: ActionToolType)
    func didChangeShapeColor(color: ColorType)
}

public extension ViewChangeDependency {
    func setWhiteboardMenuDisplayStatus(to newState: Bool, isUpdate: Bool) {}
    func setNeedChangeAlphaOfSuspensionComponent(isOpaque: Bool) {}
    func didChangePenBrush(brush: BrushType) {}
    func didChangePenColor(color: ColorType) {}
    func didChangeHighlighterBrush(brush: BrushType) {}
    func didChangeHighlighterColor(color: ColorType) {}
    func didChangeShapeType(shape: ActionToolType) {}
    func didChangeShapeColor(color: ColorType) {}
}
