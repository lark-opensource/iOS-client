//
//  RustSketch.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/11/25.
//

import Foundation
import CoreGraphics
import UIKit
import ByteViewCommon
import ByteViewNetwork

class RustSketch {

    let user: ParticipantId
    let settings: SketchSettings
    let instanceID: String
    let instanceIDPtr: UnsafePointer<CChar>
    var initialized: Bool = true
    var canEraseOthers: Bool = false

    init(deviceID: String,
         userID: String,
         userType: ParticipantType,
         logInstance: SketchLogInstance,
         settings: SketchSettings,
         currentStep: Int) {
        assert(Thread.isMainThread)

        self.user = ParticipantId(id: userID, type: userType, deviceId: deviceID)
        self.settings = settings

        let deviceIDPtr = strdup(deviceID); defer { free(deviceIDPtr) }
        let userIDPtr = strdup(userID); defer { free(userIDPtr) }
        let undoRedoInfo = UndoRedoInfo(undo_status: false, redo_status: false)
        let extInfo = ExtInfoFFI(device_id: deviceIDPtr,
                                 user_id: userIDPtr,
                                 user_type: UInt(userType.rawValue),
                                 current_step: UInt(currentStep),
                                 undo_redo_info: undoRedoInfo,
                                 visible: true)

        let pencilConfig = PencilConfig(min_distance: Float(settings.pencilConfig.minDistance),
                                        k: Float(settings.pencilConfig.k),
                                        error_gap: Float(settings.pencilConfig.errorGap),
                                        fitting_interval: settings.pencilConfig.fittingInterval,
                                        snippet_interval: settings.pencilConfig.snippetInterval)
        let cometConfig = CometConfig(weak_speed: Float(settings.cometConfig.weakSpeed),
                                      min_distance: Float(settings.cometConfig.minDistance),
                                      enable_webgl: settings.cometConfig.enableWebgl,
                                      reduce_times: settings.cometConfig.reduceTimes,
                                      fitting_interval: settings.cometConfig.fittingInterval,
                                      snippet_interval: settings.cometConfig.snippetInterval)

        let globalConfig = GlobalShapeConfig(pencil_config: pencilConfig,
                                             comet_config: cometConfig)
        instanceIDPtr = sketch_create_instance()
        instanceID = String(cString: instanceIDPtr)
        init_sketch(instanceIDPtr, logInstance, extInfo, globalConfig)
    }

    final func destroy() {
        assert(Thread.isMainThread)
        guard initialized else {
            return
        }
        sketch_destroy(instanceIDPtr)

        initialized = false
        sketch_switch_instance(instanceIDPtr)
    }

    deinit {
        destroy()
    }

    func setCurrentStep(_ step: Int) {
        assert(Thread.isMainThread)
        guard initialized else {
            return
        }
        set_current_step(instanceIDPtr, UInt(step))
    }

    func setPencilCubicFittingEnable(isEnable: Bool) {
        assert(Thread.isMainThread)
        guard initialized else {
            return
        }
        pencil_set_cubic_fitting_enable(instanceIDPtr, isEnable)
    }

    // MARK: - local action

    func addArrow(origin: CGPoint, end: CGPoint, style: ArrowPaintStyle) -> (SketchOperationUnit, ArrowDrawable) {
        assert(Thread.isMainThread)
        guard initialized else {
            return (SketchOperationUnit.newInstance(), ArrowDrawable(id: "", start: .zero, end: .zero, style: .default))
        }
        let fOrigin: [Float] = [Float(origin.x), Float(origin.y)]
        let fEnd: [Float] = [Float(end.x), Float(end.y)]
        let arrowData = arrow_finish(instanceIDPtr, fOrigin, fEnd, style.data)
        defer { arrow_finish_drop(arrowData) }
        var opUnit = SketchOperationUnit.newInstance()
        opUnit.cmd = .add
        opUnit.action = .draw
        opUnit.actionV2 = .drawV2
        opUnit.sketchUnits = [SketchDataUnit(data: arrowData)]
        return (opUnit, ArrowDrawable(data: arrowData))
    }

    func startPencilWith(style: PencilPaintStyle) {
        assert(Thread.isMainThread)
        guard initialized else {
            return
        }
        pencil_start(instanceIDPtr, style.data)
    }

    func appendPencil(drawable: inout PencilPathDrawable?, points: [CGPoint]) {
        assert(Thread.isMainThread)
        guard initialized else {
            return
        }
        let data = points.withFFIArray { ffi in
            pencil_append(instanceIDPtr, ffi)
        }
        defer { pencil_append_drop(data) }

        if data.points.len == 0 {
            return
        }

        if drawable != nil {
            drawable?.points.append(contentsOf: data.points.points.dropFirst())
        } else {
            drawable = PencilPathDrawable(data: data)
        }
    }

    func startEraser(point: CGPoint) -> SketchOperationUnit? {
        assert(Thread.isMainThread)
        guard initialized else {
            return nil
        }
        sketch_eraser_set_target_shape(instanceIDPtr, canEraseOthers ? 0 : 1)
        let removeData = sketch_eraser_start(instanceIDPtr, Float(point.x), Float(point.y))
        var op = SketchOperationUnit.newInstance()
        op.cmd = .remove
        op.action = .undo
        op.actionV2 = .eraserV2
        op.removeData = SketchRemoveData(data: removeData)
        return op.removeData.ids.isEmpty ? nil : op
    }

    func appendEraser(points: [CGPoint]) -> SketchOperationUnit? {
        assert(Thread.isMainThread)
        guard initialized else {
            return nil
        }
        let data = points.withFFIArray { ffi in
            let removeData = sketch_eraser_move(instanceIDPtr, ffi)
            var op = SketchOperationUnit.newInstance()
            op.cmd = .remove
            op.action = .undo
            op.actionV2 = .eraserV2
            op.removeData = SketchRemoveData(data: removeData)
            return op
        }
        return data.removeData.ids.isEmpty ? nil : data
    }

    func endEraser() {
        assert(Thread.isMainThread)
        guard initialized else {
            return
        }
        sketch_eraser_finish(instanceIDPtr)
    }

    func finishPencil() -> (SketchOperationUnit, PencilPathDrawable)? {
        assert(Thread.isMainThread)
        guard initialized else {
            return nil
        }
        let data = pencil_finish(instanceIDPtr)
        defer { pencil_finish_drop(data) }
        if data.transport_data.points.len == 0 {
            return nil
        }
        var opUnit = SketchOperationUnit.newInstance()
        opUnit.cmd = .add
        opUnit.action = .draw
        opUnit.actionV2 = .drawV2
        opUnit.sketchUnits = [SketchDataUnit(data: data.transport_data)]

        return (opUnit, PencilPathDrawable(data: data.transport_data))

    }

    func fitPencil() -> SketchOperationUnit? {
        assert(Thread.isMainThread)
        guard initialized else {
            return nil
        }
        let data = pencil_fitting(instanceIDPtr)
        defer { pencil_fitting_drop(data) }
        if data.points.len == 0 {
            return nil
        }
        var opUnit = SketchOperationUnit.newInstance()
        opUnit.cmd = .add
        opUnit.action = .draw
        opUnit.actionV2 = .drawV2
        opUnit.sketchUnits = [SketchDataUnit(data: data)]

        return opUnit
    }

    func getUndoStatus() -> Bool {
        return get_undo_stack_len(instanceIDPtr) > 0
    }

    func undoShape() -> (SketchOperationUnit, [ShapeID], [SketchShape])? {
        assert(Thread.isMainThread)
        guard initialized else {
            return nil
        }
        let data = sketch_undo(instanceIDPtr)
        defer { sketch_undo_drop(data) }

        let noRemoveData = (data.remove_data.remove_type.pbType == .removeByShapeID
            || data.remove_data.remove_type.pbType == .removeByDeviceID)
            && data.remove_data.ids_len == 0
        // 既没有增加也没有删除
        if noRemoveData && !data.add_data.hasAddData {
            return nil
        }

        var op = SketchOperationUnit.newInstance()
        op.cmd = data.undo_type.cmdType
        if op.cmd == .remove {
            op.action = .undo
            op.actionV2 = .undoV2
        } else {
            op.action = .draw
            op.actionV2 = .undoV2
        }
        op.clearType_p = .self_
        var removeData = SketchRemoveData()
        removeData.removeType = data.remove_data.remove_type.pbType
        removeData.currentStep = Int32(data.remove_data.current_step)
        let bufPtr = UnsafeBufferPointer<UnsafePointer<Int8>?>(start: data.remove_data.ids_ptr,
                                                               count: Int(data.remove_data.ids_len))
        let removedIds = bufPtr.filter({ $0 != nil })
            .map({ String(cString: $0!) })
        removeData.ids = removedIds
        op.removeData = removeData

        op.sketchUnits = data.add_data.sketchUnits
        return (op, removedIds, data.add_data.drawables)
    }

    // MARK: - receive remote

    @discardableResult
    func receive(comet: SketchDataUnit) -> Bool {
        assert(Thread.isMainThread)
        guard initialized else {
            return false
        }
        return comet.withCometData { data in
            comet_receive_remote_data(instanceIDPtr, data)
        }
    }

    func getCometSnippet() -> CometSnippetDrawable {
        assert(Thread.isMainThread)
        guard initialized else {
            return CometSnippetDrawable(id: "", points: [], radius: [], pause: true, exit: true, minDistance: 0, cometStyle: .default, userIdentifier: "")
        }
        let data = comet_get_remote_snippet(instanceIDPtr)
        defer {
            comet_get_remote_snippet_drop(data)
        }
        return CometSnippetDrawable(data: data, minDistance: self.settings.cometConfig.minDistance)
    }

    @discardableResult
    func receive(pencil: SketchDataUnit) -> Bool {
        assert(Thread.isMainThread)
        guard initialized else {
            return false
        }
        return pencil.withPencilData { data in
            return pencil_receive_remote_data(instanceIDPtr, data)
        }
    }

    func getPencilSnippet() -> [PencilPathDrawable] {
        assert(Thread.isMainThread)
        guard initialized else {
            return []
        }
        let data = pencil_get_remote_snippet(instanceIDPtr)
        defer {
            pencil_get_remote_snippet_drop(data)
        }
        let bufferPtr = UnsafeBufferPointer<PencilDrawableData>(start: data.ptr,
                                                                count: Int(data.len))
        return bufferPtr.map({ pencilData in
            PencilPathDrawable(data: pencilData)
        })
    }

    func getPencilBy(id: ShapeID) -> PencilPathDrawable {
        assert(Thread.isMainThread)
        guard initialized else {
            return PencilPathDrawable(id: "", points: [], pause: true, finish: true, style: .default)
        }
        return id.withCString { id -> PencilPathDrawable in
            let data = pencil_get_drawable_data_by_id(instanceIDPtr, id)
            defer {
                pencil_get_drawable_data_by_id_drop(data)
            }
            return PencilPathDrawable(data: data)
        }
    }

    func receive(oval: SketchDataUnit) -> OvalDrawable? {
        assert(Thread.isMainThread)
        guard initialized else {
            return OvalDrawable(id: "", frame: .zero, style: .default)
        }
        return oval.withOvalData { data in
            let shouldDraw = oval_receive_remote_data(instanceIDPtr, data)
            return shouldDraw ? OvalDrawable(data: data) : nil
        }
    }

    func receive(arrow: SketchDataUnit) -> ArrowDrawable? {
        assert(Thread.isMainThread)
        guard initialized else {
            return ArrowDrawable(id: "", start: .zero, end: .zero, style: .default)
        }
        return arrow.withArrowData { data in
            let shouldDraw = arrow_receive_remote_data(instanceIDPtr, data)
            return shouldDraw ? ArrowDrawable(data: data) : nil
        }
    }

    func receive(rectangle: SketchDataUnit) -> RectangleDrawable? {
        assert(Thread.isMainThread)
        guard initialized else {
            return RectangleDrawable(id: "", frame: .zero, style: .default)
        }
        return rectangle.withRectangleData { data in
            let shouldDraw = rectangle_receive_remote_data(instanceIDPtr, data)
            return shouldDraw ? RectangleDrawable(data: data) : nil
        }
    }

    func remove(removeData: SketchRemoveData) -> [ShapeID] {
        assert(Thread.isMainThread)
        guard initialized else {
            return []
        }
        let storedData = removeData.withTransportData { data in
            sketch_remove(instanceIDPtr, data)
        }
        let orderBufPtr = UnsafeBufferPointer(start: storedData.order_list,
                                              count: Int(storedData.order_list_len))
        var ids: [ShapeID] = []
        ids.reserveCapacity(Int(storedData.pencil_len
                                + storedData.rectangle_len
                                + storedData.oval_len
                                + storedData.arrow_len))
        var pencilPtr = storedData.pencil
        var rectanglePtr = storedData.rectangle
        var ovalPtr = storedData.oval
        var arrowPtr = storedData.arrow
        for shapeType in orderBufPtr {
            switch shapeType {
            case .pencil:
                if let ptr = pencilPtr {
                    let id = String(cString: ptr.pointee.id)
                    ids.append(id)
                    pencilPtr = ptr.advanced(by: 1)
                }
            case .rectangle:
                if let ptr = rectanglePtr {
                    let id = String(cString: ptr.pointee.id)
                    ids.append(id)
                    rectanglePtr = ptr.advanced(by: 1)
                }
            case .oval:
                if let ptr = ovalPtr {
                    let id = String(cString: ptr.pointee.id)
                    ids.append(id)
                    ovalPtr = ptr.advanced(by: 1)
                }
            case .arrow:
                if let ptr = arrowPtr {
                    let id = String(cString: ptr.pointee.id)
                    ids.append(id)
                    arrowPtr = ptr.advanced(by: 1)
                }
            default:
                break
            }
        }
        return ids
    }

    // MARK: - query

    func getDefaultColor() -> UIColor {
        assert(Thread.isMainThread)
        guard initialized else {
            return .white
        }
        return get_sketch_default_color(instanceIDPtr).rgbaColor
    }

    func getAllDrawables() -> [SketchShape] {
        assert(Thread.isMainThread)
        guard initialized else {
            return []
        }
        return get_all_drawable_data(instanceIDPtr).drawables
    }
}

fileprivate extension StoreDrawableData {
    var drawables: [SketchShape] {
        var values: [SketchShape] = []
        values.reserveCapacity(Int(pencil_len + rectangle_len + oval_len + arrow_len))
        for offset in 0..<Int(pencil_len) {
            values.append(PencilPathDrawable(data: pencil.advanced(by: offset).pointee))
        }
        for offset in 0..<Int(rectangle_len) {
            values.append(RectangleDrawable(data: rectangle.advanced(by: offset).pointee))
        }
        for offset in 0..<Int(oval_len) {
            values.append(OvalDrawable(data: oval.advanced(by: offset).pointee))
        }
        for offset in 0..<Int(arrow_len) {
            values.append(ArrowDrawable(data: arrow.advanced(by: offset).pointee))
        }
        return values
    }

    var hasAddData: Bool {
        return Int(pencil_len + rectangle_len + oval_len + arrow_len) > 0
    }

    var sketchUnits: [SketchDataUnit] {
        var values: [SketchDataUnit] = []
        values.reserveCapacity(Int(pencil_len + rectangle_len + oval_len + arrow_len))
        for offset in 0..<Int(pencil_len) {
            values.append(SketchDataUnit(data: pencil.advanced(by: offset).pointee))
        }
        for offset in 0..<Int(rectangle_len) {
            values.append(SketchDataUnit(data: rectangle.advanced(by: offset).pointee))
        }
        for offset in 0..<Int(oval_len) {
            values.append(SketchDataUnit(data: oval.advanced(by: offset).pointee))
        }
        for offset in 0..<Int(arrow_len) {
            values.append(SketchDataUnit(data: arrow.advanced(by: offset).pointee))
        }
        return values
    }
}

// 注意SDK和Rust的rawValue不一样
fileprivate extension UndoType {
    var cmdType: SketchOperationUnit.SketchCommand {
        let value = Int(self.rawValue)
        if value == 1 {
            return .remove
        }
        if value == 2 {
            return .add
        }
        return .update
    }
}
