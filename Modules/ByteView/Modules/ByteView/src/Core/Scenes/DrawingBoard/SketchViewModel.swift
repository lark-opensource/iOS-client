//
//  SketchViewModel.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/15.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewRtcBridge

protocol SketchViewModelDelegate: AnyObject {
    func stopButtonLoading()
    func showOtherCannotSketchTip()
    func showMenuView(shareScreenID: String, animated: Bool)
    func changeUndoState(canUndo: Bool)
    func changeCanvasSize(newSize: CGSize)
    func didChangeSketchData()
}

class SketchViewModel {
    private let layerBuilder = LayerBuilder()
    private var activeLayer: CALayer? {
        willSet {
            self.activeLayer?.removeFromSuperlayer()
        }
        didSet {
            if let layer = self.activeLayer {
                drawboard.rootLayer.addSublayer(layer)
            }
        }
    }
    private let remoteHandler: SketchRemoteHandler
    private let sketch: RustSketch
    private let sketchService: SketchService
    private let undoTool: UndoShapeTool
    private let logger = Logger.sketch
    private var timer: Timer?
    private let meeting: InMeetMeeting
    private var shouldShowMenu: Bool = false
    private var shareScreenData: ScreenSharedData?
    private var currentTool: ActionType = .pen
    private var currentColor: UIColor = UIColor.sketchRed
    var drawboard: DrawBoard
    weak var delegate: SketchViewModelDelegate?

    // 自己绘制的图形 (包含离会之后又入会，从后端拉回来的图形)
    private(set) var selfShapeIDs = Set<String>()

    var paintTool: PaintTool {
        didSet {
            paintTool.delegate = self
        }
    }

    var canUndo: Bool = false {
        didSet {
            guard oldValue != canUndo else { return }
            delegate?.changeUndoState(canUndo: canUndo)
        }
    }

    var canvasSize: CGSize {
        didSet {
            guard oldValue != canvasSize else { return }
            delegate?.changeCanvasSize(newSize: canvasSize)
        }
    }

    var selfNeedAdjustAnnotate: Bool {
        didSet {
            guard oldValue != selfNeedAdjustAnnotate else { return }
            configRustSketchAdjustAnnotate()
        }
    }

    var sharerNeedAdjustAnnotate: Bool {
        didSet {
            guard oldValue != sharerNeedAdjustAnnotate else { return }
            configRustSketchAdjustAnnotate()
        }
    }

    var transferMode: SketchTransferMode = .byData {
        didSet {
            guard oldValue != transferMode else { return }
            configRustSketchAdjustAnnotate()
        }
    }

    var decorateLayers: [CALayer] {
        remoteHandler.decorateLayers
    }

    var currentStatus: SketchStatus {
        sketchService.currentStatus
    }

    init(sketch: RustSketch,
         sketchService: SketchService,
         meeting: InMeetMeeting,
         selfNeedAdjustAnnotate: Bool,
         sharerNeedAdjustAnnotate: Bool,
         canvasSize: CGSize) {
        self.sketch = sketch
        self.sketchService = sketchService
        self.meeting = meeting
        self.selfNeedAdjustAnnotate = selfNeedAdjustAnnotate
        self.sharerNeedAdjustAnnotate = sharerNeedAdjustAnnotate
        self.paintTool = PencilPathPaintTool(sketch: sketch)
        self.undoTool = UndoShapeTool(sketch: sketch)
        self.canvasSize = canvasSize
        drawboard = DrawBoard(renderer: SketchHybridRenderer(canvasSize: canvasSize))
        remoteHandler = SketchRemoteHandler(drawboard: drawboard, sketch: sketch, meeting: meeting)
        undoTool.delegate = self
        remoteHandler.delegate = self
        self.sketchService.delegate = self
        meeting.rtc.engine.addMetadataListener(self)
        self.configRustSketchAdjustAnnotate()
    }

    private func newShapeTrack() {
        var draw = ""
        switch currentTool {
        case .pen:
            draw = "pen"
        case .highlighter:
            draw = "highlighter"
        case .arrow:
            draw = "arrow"
        case .eraser, .undo, .exit, .save:
           break
        }
        SketchTracks.trackDraw(draw, color: currentColor.sketchName)
    }

    func setNewToolOrColor(tool: ActionType, color: UIColor) {
        currentColor = color
        switch tool {
        case .pen:
            let tool = PencilPathPaintTool(sketch: self.sketch)
            tool.paintStyle = PencilPaintStyle(color: color,
                                               pencilType: .default)
            self.paintTool = tool
            self.currentTool = .pen
        case .highlighter:
            let tool = PencilPathPaintTool(sketch: self.sketch)
            tool.paintStyle = PencilPaintStyle(color: color,
                                               pencilType: .marker)
            self.paintTool = tool
            self.currentTool = .highlighter
        case .arrow:
            let tool = ArrowPaintTool(sketch: self.sketch)
            tool.style = ArrowPaintStyle(color: color,
                                         size: 3.0)
            self.paintTool = tool
            self.currentTool = .arrow
        case .eraser:
            let tool = EraserTool(sketch: self.sketch)
            tool.canEraserOthers = { [weak self] in
                guard let self = self else { return false }
                return self.meeting.setting.hasCohostAuthority
            }
            self.paintTool = tool
            self.currentTool = .eraser
        default:
            break
        }
    }

    func didTapUndo() {
        let meetingRole = self.meeting.myself.meetingRole.rawValue
        SketchTracks.trackClickUndo(isHost: meetingRole)
        self.undoTool.undoShape()
    }

    func setFetchedData(_ units: [SketchDataUnit]) {
        remoteHandler.handle(fetchedUnits: units)
        canUndo = sketch.getUndoStatus()
    }

    func startSketch(isActive: Bool, shouldShowMenu: Bool, shareScreenData: ScreenSharedData, animated: Bool = false) {
        self.shouldShowMenu = shouldShowMenu
        self.shareScreenData = shareScreenData
        sketchService.startSketch(isActive: isActive)
    }

    func updateSketch(oldData: ScreenSharedData, newData: ScreenSharedData) -> Bool {
        assert(oldData.shareScreenID == newData.shareScreenID)
        if oldData.width != newData.width ||
            oldData.height != newData.height {
            paintTool.interrupt(saveDrawingShape: true)
            drawboard.canvasSize = CGSize(width: CGFloat(newData.width),
                                          height: CGFloat(newData.height))
            self.canvasSize = drawboard.canvasSize
            return true
        }
        return false
    }

    func configRustSketchAdjustAnnotate() {
        let cubicFittingEnable: Bool
        if transferMode == .byVideo && sharerNeedAdjustAnnotate {
            cubicFittingEnable = true
        } else {
            cubicFittingEnable = selfNeedAdjustAnnotate
        }
        self.logger.info("configRustSketchAdjustAnnotate, transferMode: \(transferMode), sharerNeedAdjustAnnotate: \(sharerNeedAdjustAnnotate), selfNeedAdjustAnnotate: \(selfNeedAdjustAnnotate), cubicFittingEnable: \(cubicFittingEnable)")
        Util.runInMainThread { [weak self] in
            guard let self = self else {
                return
            }
            self.sketch.setPencilCubicFittingEnable(isEnable: cubicFittingEnable)
        }
    }

    func getDefaultColor() -> UIColor {
        return sketch.getDefaultColor()
    }

    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        invalidateTimer()
    }
}

extension SketchViewModel: RtcMetadataListener {
    func didReceiveScreenMetadata(_ data: Data, uid: RtcUID) {
        do {
            let metadata = try ByteMetadata(serializedData: data)
            let sketchData = metadata.sketchData
            let mode = sketchData.sketchTransferMode
            Util.runInMainThread {
                if mode != self.transferMode {
                    self.logger.info("transferMode changed from: \(self.transferMode) to: \(mode)")
                    self.transferMode = mode
                    switch mode {
                    case .byData:
                        let drawables = self.sketch.getAllDrawables()
                        self.invalidateTimer()
                        self.drawboard.addAllDrawables(drawables: drawables)
                    case .byVideo:
                        self.drawboard.removeAllDrawables()
                        self.remoteHandler.clearComet()
                    @unknown default:
                        assertionFailure("transferMode error")
                    }
                } else if mode == .byVideo {
                    let delay = self.sketch.settings.guestReceiveSeiAutoDisappearTime / 1000
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self,
                              self.transferMode == .byVideo else { return }
                        sketchData.ackDatas.forEach { self.drawboard.remove(byShapeID: $0.shapeID) }
                    }
                }
            }
        } catch {
            self.logger.error("sketch metadata 消息解析失败", error: error)
        }
    }
}

extension SketchViewModel: PaintToolDelegate {

    func transport(operationUnits: [SketchOperationUnit]) {
        self.sketchService.send(units: operationUnits)
        self.delegate?.didChangeSketchData()
    }

    func shapesRemoved(with shapeIDs: [ShapeID]) {
        for id in shapeIDs {
            drawboard.remove(byShapeID: id)
            if selfShapeIDs.contains(id) {
                selfShapeIDs.remove(id)
            }
        }
    }

    func changeUndoStatus(canUndo: Bool) {
        self.canUndo = canUndo
    }

    func shapesAdded(with shapes: [SketchShape]) {
        guard transferMode == .byData else { return }
        shapes.forEach { shape in
            if shape.userIdentifier == meeting.account.identifier {
                onNewShape(shape: shape)
            } else {
                _ = drawboard.addRemote(drawable: shape)
            }
        }
    }

    func onNewShape(shape: SketchShape) {
        if !selfShapeIDs.contains(shape.id) {
            selfShapeIDs.insert(shape.id)
        }
        drawboard.addLocal(drawable: shape)
        newShapeTrack()
        if transferMode == .byVideo {
            let delay = sketch.settings.guestLocalShapeAutoDisappearTime / 1000
            timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { [weak self] _ in
                guard let self = self,
                      self.transferMode == .byVideo else {
                    return
                }
                self.logger.info("sketch auto disappear, current drawables count:\(self.drawboard.renderer.drawables.count)")
                self.drawboard.removeAllDrawables()
                self.invalidateTimer()
            })
        }
    }

    func activeShapeChanged(tool: PaintTool) {
        if let shape = tool.activeShape {
            self.activeLayer = layerBuilder.buildLayer(drawable: shape)
        } else {
            self.activeLayer = nil
        }
    }

    var needsFitting: Bool {
        transferMode == .byData
    }
}

extension SketchViewModel: SketchRemoteHandlerDelegate {
    func didRemoveShape(id: ShapeID) {
        if selfShapeIDs.contains(id) {
            selfShapeIDs.remove(id)
        }
    }

    func didAddSelfShape(id: ShapeID) {
        if !selfShapeIDs.contains(id) {
            selfShapeIDs.insert(id)
        }
    }

    func selfShapeContains(id: ShapeID) -> Bool {
        return selfShapeIDs.contains(id)
    }

    var drawRemoteShapeEnable: Bool {
        transferMode == .byData
    }
}

extension SketchViewModel: SketchServiceDelegate {
    func receiveGrootCell(cells: [ByteViewNetwork.SketchGrootCell]) {
        DispatchQueue.main.async {
            cells.forEach { cell in
                cell.units.forEach { op in
                    if op.cmd == .remove {
                        let identifier = self.sketch.user.identifier
                        if op.removeData.removeType == .removeAll {
                            self.paintTool.interrupt(saveDrawingShape: false)
                        } else if op.removeData.removeType == .removeByDeviceID,
                                  op.removeData.users.map({ $0.identifier }).contains(identifier) {
                            self.paintTool.interrupt(saveDrawingShape: false)
                        } else if op.removeData.removeType == .storeByDeviceID,
                                  !op.removeData.users.map({ $0.identifier }).contains(identifier) {
                            self.paintTool.interrupt(saveDrawingShape: false)
                        } else if let shapeID = self.paintTool.activeShape?.id,
                                  op.removeData.removeType == .removeByShapeID,
                                  op.removeData.ids.contains(shapeID) {
                            self.paintTool.interrupt(saveDrawingShape: false)
                        }
                    }
                    self.remoteHandler.handle(sketchOperation: op)
                    self.delegate?.didChangeSketchData()
                }
            }
        }
    }

    // 标注开启过程中，每个阶段的逻辑处理
    func sketchStatusDidChange(currentStatus: SketchStatus, preStatus: SketchStatus) {
        self.logger.info("sketchStatusDidChange isActivity: \(sketchService.isActive)")
        switch currentStatus {
        case .requestStartFailed, .connecting:
            if sketchService.isActive {
                Toast.showOnVCScene(VCError.startSketchFailed.description)
            }
        case .fetchFailed:
            if sketchService.isActive {
                Toast.showOnVCScene(VCError.fetchAllSketchDataFailed.description)
            }
        case .openFailed:
            if sketchService.isActive {
                Toast.showOnVCScene(VCError.startSketchFailed.description)
            }
        case .connected:
            if sketchService.isActive {
                delegate?.stopButtonLoading()
                if let shareScreenID = self.shareScreenData?.shareScreenID {
                    delegate?.showMenuView(shareScreenID: shareScreenID, animated: true)
                }
            } else if shouldShowMenu {
                if let shareScreenID = self.shareScreenData?.shareScreenID {
                    delegate?.showMenuView(shareScreenID: shareScreenID, animated: false)
                }
            }
        case .fetchSuccess(version: _, currentStep: let currentStep, units: let units):
            DispatchQueue.main.async {
                // 顺序不能反，必须是先setCurrentStep，然后setFetchedData，否则SDK无法对数据做有效性的判定。
                self.sketch.setCurrentStep(Int(currentStep))
                self.setFetchedData(units)
            }
        default:
            break
        }
    }

    func showOtherCannotSketchTip() {
        delegate?.showOtherCannotSketchTip()
    }
}
