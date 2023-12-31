//
//  WhiteboardViewModel+client.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/1.
//

import Foundation
import WbLib
import ByteViewNetwork
import ByteViewCommon

protocol WhiteboardViewDelegate: AnyObject {
    func changeDrawingState(isDrawing: Bool)
    func changeUndoState(canUndo: Bool)
    func changeRedoState(canRedo: Bool)
    func shouldReloadSnapshot(item: WhiteboardSnapshotItem)
    func changeMultiPageInfo(currentPageNum: Int32, totalPages: Int)
    func shouldReloadTotalSnapshot()
}

extension WhiteboardViewDelegate {
    func changeDrawingState(isDrawing: Bool) {}
    func changeUndoState(canUndo: Bool) {}
    func changeRedoState(canRedo: Bool) {}
    func shouldReloadSnapshot(item: WhiteboardSnapshotItem) {}
    // 切换页面（本地切换也以推送为主，本地点击逻辑不响应）
    func changeMultiPageInfo(currentPageNum: Int32, totalPages: Int) {}
    // reload 多白板页面
    func shouldReloadTotalSnapshot() {}
}

public protocol WhiteboardDataDelegate: AnyObject {
    func didChangeSnapshotSaveState(isSaved: Bool)
}

extension WhiteboardDataDelegate {
    func didChangeSnapshotSaveState(isSaved: Bool) {}
}

extension WhiteboardViewModel: WbClientNotificationDelegate {

    func didChangeUndoState(canUndo: Bool) {
        delegate?.changeUndoState(canUndo: canUndo)
    }
    func didChangeRedoState(canRedo: Bool) {
        delegate?.changeRedoState(canRedo: canRedo)
    }
    func didChangeViewportScale(_ scale: Float) {}
    func didChangeViewportTranslation(vector: Vector) {}
    func didGraphicStartDrawing(graphicInfo: DrawingStateData) {
    }
    func didGraphicDrawing(graphicInfo: DrawingStateData) {
        changeNameTagPosition(graphicInfo: graphicInfo, shouldFade: false)
    }

    func didGraphicEndDrawing(graphicInfo: DrawingStateData) {
        changeNameTagPosition(graphicInfo: graphicInfo, shouldFade: true)
    }

    func didChangeRenderCmds(_ cmds: [WbRenderCmd]) {
        guard !cmds.isEmpty else { return }
        for cmd in cmds {
            switch cmd {
            case .Add(let id, let graphic):
                if let wbShape = getWhiteboardShapeAndType(id: id, graphic, shouldRecordPath: true) {
                    drawBoard.add(drawable: wbShape.0, isTemp: false, drawableType: wbShape.1)
                }
            case .Update(let id, let graphic):
                if let wbShape = getWhiteboardShapeAndType(id: id, graphic, shouldRecordPath: false) {
                    drawBoard.update(wbShape: wbShape.0, cmdUpdateType: .graphic, drawableType: wbShape.1)
                }
            case .UpdatePath(let id, _, let path):
                if let lastPath = lastPaths[id] {
                    let newSubPath = path.makeCGPath(id, path: lastPath)
                    drawBoard.updatePath(id: id, path: newSubPath)
                }
            case .Remove(let id):
                drawBoard.remove(byShapeID: id)
            case .Clear:
                drawBoard.removeAllDrawables()
            default:
                break
            }
        }
        didFinishRenderCmds()
    }

    func didGraphicCancelDrawing(graphicInfo: DrawingStateData) {
        drawBoard.remove(byShapeID: graphicInfo.graphicId)
    }

    private func getWhiteboardShapeAndType(id: ShapeID, _ wbGraphic: WbGraphic, shouldRecordPath: Bool = false) -> (WhiteboardShape, DrawableType)? {
        switch wbGraphic.primitive {
        case .Path:
            let shape = VectorShape(id: id, wbGraphic: wbGraphic)
            if isEnableIncrementalPath {
                if shouldRecordPath {
                    lastPaths[id] = shape.path
                } else {
                    lastPaths.removeValue(forKey: id)
                }
            }
            return (shape, .vector)
        case .Image:
            return nil
        case .Text:
            return (TextDrawable(id: id, wbGraphic: wbGraphic), .text)
        case .Unknown:
            return nil
        }
    }

    func onSyncData(_ type: WbSyncDataType, _ bytes: [UInt8]) {
        guard let grootSession = grootSession else { return }
        var dataType: GrootCell.DataType
        switch type {
        case .DrawData:
            dataType = .whiteboardDrawData
        case .SyncData:
            dataType = .whiteboardSyncData
        }
        upVersion += 1
        let cell = GrootCell(action: .clientReq, payload: Data(bytes), sender: account, upVersion: upVersion, pageID: currentPageID ?? 0, dataType: dataType)
        grootSession.sendCells([cell])
        resetPageSave()
    }

    private func changeNameTagPosition(graphicInfo: DrawingStateData, shouldFade: Bool) {
        if graphicInfo.userId == account.id, graphicInfo.deviceId == account.deviceId { return }
        dependencies?.nicknameBy(graphicInfo: graphicInfo) { [weak self] nickname in
            guard let self = self else { return }
            let id = graphicInfo.userId + "_\(graphicInfo.userType)_" + graphicInfo.deviceId
            let nicknameDrawable = NicknameDrawable(id: id,
                                                    text: nickname,
                                                    style: TextStyle(textColor: UIColor.ud.primaryOnPrimaryFill,
                                                                     font: UIFont.systemFont(ofSize: 12),
                                                                     backgroundColor: UIColor.ud.staticBlack.withAlphaComponent(0.6),
                                                                     cornerRadius: 2),
                                                    position: CGPoint(x: graphicInfo.position.x, y: graphicInfo.position.y))
            self.drawBoard.updateNickname(drawable: nicknameDrawable, shouldFade: shouldFade)
        }
    }
}
