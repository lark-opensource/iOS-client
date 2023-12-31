//
//  RenderCmd.swift
//
//
//  Created by kef on 2022/2/28.
//

import Foundation

public enum WbRenderCmd {
    /// 添加一个图形
    ///
    /// # 参数
    /// - `isTemp`: 区分该图形是否为辅助线
    case Add(id: String, graphic: WbGraphic)
    case Update(id: String, graphic: WbGraphic)
    /// 更新`WbGraphic`中的`path`
    /// # 参数
    /// - `isIncremental`: 是否为增量数据
    ///     false: 替换目标字段
    ///     true: 在目标字段数据后连接新的`path`数据
    case UpdatePath(id: String, isIncremental: Bool, path: Path)
    case UpdateStroke(id: String, stroke: Stroke?)
    case UpdateFill(id: String, fill: Fill?)
    case UpdateTransform(id: String, transform: Transform?)
    case Remove(id: String)
    case Clear
    case Unknown
    
    public init(cmd: C_WB_RENDER_CMD, dataPtr: UnsafeRawPointer?) {
        switch cmd {
        case C_WB_RENDER_CMD_ADD:
            let cValue = dataPtr!.load(as: CWbAddCmd.self)
            self = .Add(id: String.fromCValue(cValue.id)!, graphic: WbGraphic(cValue: cValue.graphic.pointee))
        case C_WB_RENDER_CMD_UPDATE:
            let cValue = dataPtr!.load(as: CWbUpdateCmd.self)
            self = .Update(id: String.fromCValue(cValue.id)!, graphic: WbGraphic(cValue: cValue.graphic.pointee))
        case C_WB_RENDER_CMD_UPDATE_PATH:
            let cValue = dataPtr!.load(as: CWbUpdatePathCmd.self)
            self = .UpdatePath(id: String.fromCValue(cValue.id)!, isIncremental: cValue.is_incremental, path: Path(cValue: cValue.path.pointee))
        case C_WB_RENDER_CMD_UPDATE_STROKE:
            let cValue = dataPtr!.load(as: CWbUpdateStrokeCmd.self)
            
            if let cStroke = cValue.stroke?.pointee {
                self = .UpdateStroke(id: String.fromCValue(cValue.id)!, stroke: Stroke(cValue: cStroke))
            } else {
                self = .UpdateStroke(id: String.fromCValue(cValue.id)!, stroke: nil)
            }
        case C_WB_RENDER_CMD_UPDATE_FILL:
            let cValue = dataPtr!.load(as: CWbUpdateFillCmd.self)
            
            if let cFill = cValue.fill?.pointee {
                self = .UpdateFill(id: String.fromCValue(cValue.id)!, fill: Fill(cValue: cFill))
            } else {
                self = .UpdateFill(id: String.fromCValue(cValue.id)!, fill: nil)
            }
        case C_WB_RENDER_CMD_UPDATE_TRANSFORM:
            let cValue = dataPtr!.load(as: CWbUpdateTransformCmd.self)
            
            if let cTransform = cValue.transform?.pointee {
                self = .UpdateTransform(id: String.fromCValue(cValue.id)!, transform: Transform(cValue: cTransform))
            } else {
                self = .UpdateTransform(id: String.fromCValue(cValue.id)!, transform: nil)
            }
        case C_WB_RENDER_CMD_REMOVE:
            let cValue = dataPtr!.load(as: CWbRemoveCmd.self)
            self = .Remove(id: String.fromCValue(cValue.id)!)
            
        case C_WB_RENDER_CMD_CLEAR:
            self = .Clear
            
        default:
            self = .Unknown
        }
    }
    
}
