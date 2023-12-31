//
//  WhiteboardTracks.swift
//  ByteView
//
//  Created by Prontera on 2022/5/6.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

public enum StartWhiteboardType {
    case newBoard
    case joinBoard

    var typeName: String {
        switch self {
        case .joinBoard:
            return "join_board"
        case .newBoard:
            return "new_board"
        }
    }
}

public enum StopWhiteboardType {
    case quiteFromShare
    case quiteLeaveMeeting

    var typeName: String {
        switch self {
        case .quiteFromShare:
            return "quite_from_share"
        case .quiteLeaveMeeting:
            return "quite_leave_meeting"
        }
    }
}

enum BoardClickType {
    case draw
    case drawSelection(penOrBrush: ActionToolType)
    case shape
    case shapeSelection(shape: ActionToolType)
    case colorSelection(color: ColorType)
    case undo
    case redo
    case clear
    case clearSelection(eraserType: EraserType)
    case multiBoard
    case newBoard
    case multiBoardSelectPage(pageNum: Int)
    case multiBoardDeletePage(pageNum: Int)
    case save
    case saveCurrent
    case saveAll
}

public final class WhiteboardTracks {

    /// 白板首帧渲染时长
    public static func trackSnapshotPaint(pullCost: CFTimeInterval,
                                          renderCost: CFTimeInterval,
                                          bytesize: Int,
                                          whiteboardID: Int64) {
        VCTracker.post(name: .vc_whiteboard_first_frame_paint_dev,
                       params: ["first_pull_snapshot_cost_ms": "\(Int(pullCost))",
                                "first_render_snapshot_cost_ms": "\(Int(renderCost))",
                                "first_snapshot_bytesize": "\(bytesize)",
                                "whiteboard_id": "\(whiteboardID)"])
    }

    /// 一次绘制的平均fps
    public static func trackRenderFps(_ fps: Int,
                                      shapeCount: Int,
                                      cmdsCount: Int,
                                      whiteboardID: Int64) {
        VCTracker.post(name: .vc_whiteboard_fps_dev,
                       params: ["render_fps": "\(fps)",
                                "page_shape_count": "\(shapeCount)",
                                "pull_cmds_action_count": "\(cmdsCount)",
                                "whiteboard_id": "\(whiteboardID)"])
    }

    /// 白板开启/关闭
    public static func trackStartWhiteboard(type: StartWhiteboardType, isSharing: Bool, isSharer: Bool, participantNum: Int, isOnthecall: Bool) {
        VCTracker.post(name: .vc_whiteboard_status,
                       params: ["status": "open",
                                "start_type": type.typeName,
                                "is_sharing": isSharing,
                                "is_sharer": isSharer,
                                "participant_num": participantNum,
                                "is_onthecall": isOnthecall])
    }

    public static func trackStopWhiteboard(type: StopWhiteboardType, duration: Double, whiteboardId: Int64, isSharing: Bool, isSharer: Bool, participantNum: Int, isOnthecall: Bool) {
        VCTracker.post(name: .vc_whiteboard_status,
                       params: ["status": "stop",
                                "quite_type": type.typeName,
                                "board_duration": duration,
                                "whiteboard_id": whiteboardId,
                                "is_sharing": isSharing,
                                "is_sharer": isSharer,
                                "participant_num": participantNum,
                                "is_onthecall": isOnthecall])
    }

    static func trackBoardClick(_ clickType: BoardClickType, whiteboardId: Int64, isSharer: Bool? = nil) {
        var click: String = ""
        var option: String?
        var pageNum: Int?
        switch clickType {
        case .draw:
            click = "draw"
        case .drawSelection(let penOrBrush):
            click = "draw_selection"
            option = penOrBrush.trackOptionName
        case .shape:
            click = "shape"
        case .shapeSelection(let shape):
            click = "shape_selection"
            option = shape.trackOptionName
        case .colorSelection(let color):
            click = "color_selection"
            option = color.rawValue
        case .undo:
            click = "undo"
        case .redo:
            click = "redo"
        case .clear:
            click = "clear"
        case .clearSelection(let eraserType):
            click = "clear_selection"
            option = eraserType.trackEraserName
        case .multiBoard:
            click = "multi_board"
        case .newBoard:
            click = "new_board"
        case .multiBoardSelectPage(let num):
            click = "multi_board_select_page"
            pageNum = num
        case .multiBoardDeletePage(let num):
            click = "multi_board_delete_page"
            pageNum = num
        case .save:
            click = "save"
        case .saveCurrent:
            click = "save_current"
        case .saveAll:
            click = "save_all"
        }
        var params: [String: Any] = [:]
        if let option = option {
            params["click"] = click
            params["option"] = option
        } else if let pageNum = pageNum {
            params["click"] = click
            params["page_num"] = pageNum
        } else {
            params["click"] = click
        }
        if let isSharer = isSharer {
            params["is_sharer"] = isSharer ? 1 : 0
        }
        params["whiteboardId"] = whiteboardId
        VCTracker.post(name: .vc_board_click,
                       params: TrackParams(params))
    }

    public static func trackStopButtonClick(whiteboardId: Int64) {
        VCTracker.post(name: .vc_board_click,
                       params: ["click": "quite_sharing_board",
                                "whiteboard_id": whiteboardId])
    }
}
