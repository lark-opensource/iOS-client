//
//  Notification.swift
//
//
//  Created by kef on 2022/2/15.
//

import Foundation

/// 用于通知用户主题色变化
public class ThemeChangeData {
    /// 主题变化对应的页码
    public let pageId: Int64
    /// 新的主题色
    public let theme: WbTheme
    
    init(cValue: CThemeChangeData) {
        self.pageId = cValue.page_id
        self.theme = WbTheme(cValue.theme)
    }
}

/// 用于通知用户绘制状态
///
/// 如需显示用户名牌`userId`, `deviceId`, `graphicId`三者可唯一确定一个用户正在绘制的图形
///
public class DrawingStateData {
    /// 用户id
    public let userId: String
    /// 设备id
    public let deviceId: String
    /// 图形id
    public let graphicId: String
    /// 用户类型
    public let userType: Int
    /// 当前绘制的位置
    public let position: Point
    
    init(cValue: CDrawingStateData) {
        self.userId = String.fromCValue(cValue.user_id)!
        self.deviceId = String.fromCValue(cValue.device_id)!
        self.graphicId = String.fromCValue(cValue.graphic_id)!
        self.userType = Int(cValue.user_type)
        self.position = Point(cValue: cValue.position.pointee)
    }
}

public class UndoRedoStatusData {
    /// 撤销状态可用
    public let canUndo: Bool
    /// 重做状态可用
    public let canRedo: Bool
    
    init(cValue: CUndoRedoStatusData) {
        self.canUndo = cValue.can_undo
        self.canRedo = cValue.can_redo
    }
}

public enum WbCursorStyle {
    case Default
    case Grab
    case Cross
    case Unknown
    
    init(cValue: C_WB_CURSOR_STYLE) {
        switch cValue {
        case C_WB_CURSOR_STYLE_DEFAULT:
            self = .Default
        case C_WB_CURSOR_STYLE_GRAB:
            self = .Grab
        case C_WB_CURSOR_STYLE_CROSS:
            self = .Cross
        default:
            self = .Unknown
        }
    }
}

public struct StartTextRecognitionData {
    public let id: String
    public let points: Array<Array<Point>>
    public let averageIntervalMs: Float
    
    init(cValue: CStartTextRecognitionData) {
        self.id = String.fromCValue(cValue.id)!
        self.points = cValue.points.pointee.toSwiftArray()
        self.averageIntervalMs = cValue.average_interval_ms
    }
}

public struct TextRecognitionUnexpectedData {
    public let id: String
    public let text: String
    
    init(cValue: CTextRecognitionUnexpectedData) {
        self.id = String.fromCValue(cValue.id)!
        self.text = String.fromCValue(cValue.text)!
    }
}

public enum WbNotification {
    /// 可撤销/重做状态发生变化
    case UndoRedoStatusChanged(UndoRedoStatusData)
    /// 画布绘制缩放比发生变化
    /// 需要将画布的所有图形按此比例缩放
    case ViewportScale(Float)
    /// 画布发生位移
    /// 需要将画布的所有图形按此位移绘制, 左上角为原点, 正值表示向右或向下
    case ViewportTranslation(Vector)
    /// 鼠标样式发生变化 (有鼠标的情况)
    case CursorStyle(WbCursorStyle)
    /// 有用户开始绘制 (显示名牌)
    case StartDrawing(DrawingStateData)
    /// 用户绘制的最新位置发生变化 (更新名牌位置)
    case Drawing(DrawingStateData)
    /// 用户结束绘制 (一定时间后撤销名牌显示)
    case EndDrawing(DrawingStateData)
    /// 用户绘制被取消
    case CancelDrawing(DrawingStateData)
    /// SDK内图形数据发生变化, 用来控制对`pullPendingGraphicCmds`接口的访问
    case HasPendingGraphicCmds(Bool)
    /// SDK内页面主题色发生变化
    case ThemeChange(ThemeChangeData)
    /// 开启循环定时器 (定时间隔 ms)
    case StartTicker(UInt32)
    /// 停止循环定时器
    case StopTicker
    /// 开始进行文字识别
    case StartTextRecognition(StartTextRecognitionData)
    /// 文字识别异常
    case TextRecognitionUnexpected(TextRecognitionUnexpectedData)
    
    /// 发生错误 或 该事件SDK内已支持但未在Swift侧封装
    case Unknown
    
    public init(name: C_WB_NOTIFICATION, dataPtr: UnsafeRawPointer?) {
        switch name {
        case C_WB_NOTIFICATION_UNDO_REDO_STATUS_CHANGED:
            let v = UndoRedoStatusData(cValue: dataPtr!.load(as: CUndoRedoStatusData.self))
            self = .UndoRedoStatusChanged(v)
        case C_WB_NOTIFICATION_VIEWPORT_SCALE:
            let v = dataPtr!.load(as: Float.self)
            self = .ViewportScale(v)
        case C_WB_NOTIFICATION_VIEWPORT_TRANSLATION:
            let v = Vector(cValue: dataPtr!.load(as: CVector.self))
            self = .ViewportTranslation(v)
        case C_WB_NOTIFICATION_CURSOR_STYLE:
            let v = WbCursorStyle(cValue: dataPtr!.load(as: C_WB_CURSOR_STYLE.self))
            self = .CursorStyle(v)
        case C_WB_NOTIFICATION_START_DRAWING:
            let v = DrawingStateData(cValue: dataPtr!.load(as: CDrawingStateData.self))
            self = .StartDrawing(v)
        case C_WB_NOTIFICATION_DRAWING:
            let v = DrawingStateData(cValue: dataPtr!.load(as: CDrawingStateData.self))
            self = .Drawing(v)
        case C_WB_NOTIFICATION_END_DRAWING:
            let v = DrawingStateData(cValue: dataPtr!.load(as: CDrawingStateData.self))
            self = .EndDrawing(v)
        case C_WB_NOTIFICATION_CANCEL_DRAWING:
            let v = DrawingStateData(cValue: dataPtr!.load(as: CDrawingStateData.self))
            self = .CancelDrawing(v)
        case C_WB_NOTIFICATION_THEME_CHANGE:
            let v = ThemeChangeData(cValue: dataPtr!.load(as: CThemeChangeData.self))
            self = .ThemeChange(v)
        case C_WB_NOTIFICATION_HAS_PENDING_GRAPHIC_CMDS:
            let v = dataPtr!.load(as: Bool.self)
            self = .HasPendingGraphicCmds(v)
        case C_WB_NOTIFICATION_START_TICKER:
            let v = dataPtr!.load(as: UInt32.self)
            self = .StartTicker(v)
        case C_WB_NOTIFICATION_STOP_TICKER:
            self = .StopTicker
        case C_WB_NOTIFICATION_START_TEXT_RECOGNITION:
            let v = StartTextRecognitionData(cValue: dataPtr!.load(as: CStartTextRecognitionData.self))
            self = .StartTextRecognition(v)
        case C_WB_NOTIFICATION_TEXT_RECOGNITION_UNEXPECTED:
            let v = TextRecognitionUnexpectedData(cValue: dataPtr!.load(as: CTextRecognitionUnexpectedData.self))
            self = .TextRecognitionUnexpected(v)
        default:
            self = .Unknown
        }
    }
}
