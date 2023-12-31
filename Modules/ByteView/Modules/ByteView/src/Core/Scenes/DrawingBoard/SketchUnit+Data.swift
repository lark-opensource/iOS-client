//
//  SketchUnit+Data.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/5.
//

import Foundation

fileprivate extension FFIArrayFloat2 {
    var coords: [SketchDataUnit.Coord] {
        let ptr = UnsafeBufferPointer<(Float, Float)>(start: self.ptr, count: Int(self.len))
        return ptr.map({
            var coord = SketchDataUnit.Coord()
            coord.x = $0.0
            coord.y = $0.1
            return coord
        })
    }
}

fileprivate extension SketchDataUnit.Coord {
    init(data: UnsafePointer<Float>) {
        self.init()
        self.x = data.pointee
        self.y = data.advanced(by: 1).pointee
    }
}

extension Optional where Wrapped == UnsafePointer<Int8> {
    var stringVal: String {
        self != nil ? String(cString: self!) : ""
    }
}

extension SketchDataUnit {
    init(data: PencilDrawableData) {
        self.init()
        let id: String = data.id != nil ? String(cString: data.id!) : ""
        self.shapeID = id
        self.shapeType = .pencil
        self.currentStep = Int32(data.ext_info.current_step)
        self.user = .init()
        user.userID = data.ext_info.user_id.stringVal
        user.deviceID = data.ext_info.device_id.stringVal
        user.userType = .init(rawValue: Int(data.ext_info.user_type)) ?? .unknow

        var pencil = SketchDataUnit.Pencil()
        pencil.coords = data.need_compatible ? data.compatible_points.coords : data.points.coords
        pencil.duration = data.duration
        pencil.finish = data.finish
        pencil.dimension = data.need_compatible ? data.compatible_dimension : data.dimension
        pencil.size = data.style.size
        pencil.color = Int64(data.style.color)
        pencil.pencilType = SketchDataUnit.Pencil.PencilType(rawValue: Int(data.style.pencil_type.rawValue)) ?? .default
        if data.need_compatible {
            pencil.coordsV2 = data.points.coords
            pencil.dimensionV2 = data.dimension
        }
        self.pencil = pencil
    }

    init(data: RectangleDrawableData) {
        self.init()
        let id: String = data.id != nil ? String(cString: data.id!) : ""
        self.shapeID = id
        self.shapeType = .rectangle
        self.currentStep = Int32(data.ext_info.current_step)
        self.user = .init()
        user.userID = data.ext_info.user_id.stringVal
        user.deviceID = data.ext_info.device_id.stringVal
        user.userType = .init(rawValue: Int(data.ext_info.user_type)) ?? .unknow

        var rectangle = SketchDataUnit.Rect()
        rectangle.leftTop = SketchDataUnit.Coord(data: data.left_top)
        rectangle.rightBottom = SketchDataUnit.Coord(data: data.right_bottom)
        rectangle.color = Int64(data.style.color)
        rectangle.size = data.style.size

        self.rect = rectangle
    }

    init(data: CometDrawableData) {
        self.init()
        let id: String = data.id != nil ? String(cString: data.id!) : ""
        self.shapeID = id
        self.shapeType = .comet
        self.currentStep = Int32(data.ext_info.current_step)
        self.user = .init()
        user.userID = data.ext_info.user_id.stringVal
        user.deviceID = data.ext_info.device_id.stringVal
        user.userType = .init(rawValue: Int(data.ext_info.user_type)) ?? .unknow

        var comet = SketchDataUnit.Comet()
        comet.coords = data.points.coords
        comet.duration = data.duration
        comet.size = data.style.size
        comet.color = Int64(data.style.color)
        comet.exit = data.pause

        self.comet = comet

    }

    init(data: OvalDrawableData) {
        self.init()
        let id: String = data.id != nil ? String(cString: data.id!) : ""
        self.shapeID = id
        self.shapeType = .oval
        self.currentStep = Int32(data.ext_info.current_step)
        self.user = .init()
        user.userID = data.ext_info.user_id.stringVal
        user.deviceID = data.ext_info.device_id.stringVal
        user.userType = .init(rawValue: Int(data.ext_info.user_type)) ?? .unknow

        var oval = SketchDataUnit.Oval()
        oval.origin = SketchDataUnit.Coord(data: data.origin)
        oval.longAxis = data.long_axis
        oval.shortAxis = data.short_axis
        oval.color = Int64(data.style.color)
        oval.size = data.style.size

        self.oval = oval

    }

    init(data: ArrowDrawableData) {
        self.init()
        let id: String = data.id != nil ? String(cString: data.id!) : ""
        self.shapeID = id
        self.shapeType = .arrow
        self.currentStep = Int32(data.ext_info.current_step)
        self.user = .init()
        user.userID = data.ext_info.user_id.stringVal
        user.deviceID = data.ext_info.device_id.stringVal
        user.userType = .init(rawValue: Int(data.ext_info.user_type)) ?? .unknow

        var arrow = SketchDataUnit.Arrow()
        arrow.origin = SketchDataUnit.Coord(data: data.origin)
        arrow.end = SketchDataUnit.Coord(data: data.end)
        arrow.color = Int64(data.style.color)
        arrow.size = data.style.size

        self.arrow = arrow
    }

    func withPencilData<R>(body: (PencilDrawableData) throws -> R) rethrows -> R {
        let pencil = self.pencil
        let style = PencilStyle(color: pencil.color,
                                size: pencil.size,
                                pencil_type: PencilType(UInt32(pencil.pencilType.rawValue)))
        let coords = pencil.hasDimensionV2 ? pencil.coordsV2 : pencil.coords
        let dimension = pencil.hasDimensionV2 ? pencil.dimensionV2 : pencil.dimension
        return try coords.map({
            ($0.x, $0.y)
        }).withUnsafeBufferPointer { ptr -> R in
            let ffi = FFIArrayFloat2(ptr: ptr.baseAddress, len: UInt(ptr.count))
            let shapeID = strdup(self.shapeID)
            defer { free(shapeID) }
            let deviceID = strdup(self.user.deviceID)
            defer { free(deviceID) }
            let userID = strdup(self.user.userID)
            defer { free(userID) }
            let undoRedoInfo = UndoRedoInfo(undo_status: false, redo_status: false)
            let data = PencilDrawableData(id: shapeID,
                                          style: style,
                                          points: ffi,
                                          duration: pencil.duration,
                                          ext_info: ExtInfoFFI(device_id: deviceID,
                                                               user_id: userID,
                                                               user_type: UInt(self.user.userType.rawValue),
                                                               current_step: UInt(self.currentStep),
                                                               undo_redo_info: undoRedoInfo,
                                                               visible: true),
                                          finish: pencil.finish,
                                          dimension: dimension,
                                          pause: false,
                                          need_compatible: true,
                                          compatible_points: FFIArrayFloat2(ptr: nil, len: 0),
                                          compatible_dimension: dimension)
            return try body(data)
        }
    }

    func withRectangleData<R>(body: (RectangleDrawableData) throws -> R) rethrows -> R {
        let rect = self.rect
        let style = RectangleStyle(color: rect.color,
                                   size: rect.size)
        let leftTop: [Float] = [rect.leftTop.x, rect.leftTop.y]
        let rightBottom: [Float] = [rect.rightBottom.x, rect.rightBottom.y]
        let shapeID = strdup(self.shapeID)
        defer { free(shapeID) }
        let deviceID = strdup(self.user.deviceID)
        defer { free(deviceID) }
        let userID = strdup(self.user.userID)
        defer { free(userID) }
        let undoRedoInfo = UndoRedoInfo(undo_status: false, redo_status: false)
        let data = leftTop.withUnsafeBufferPointer { leftTopPtr in
            return rightBottom.withUnsafeBufferPointer { rightBottomPtr in
                return RectangleDrawableData(
                    id: shapeID,
                    left_top: leftTopPtr.baseAddress,
                    right_bottom: rightBottomPtr.baseAddress,
                    style: style,
                    ext_info: ExtInfoFFI(device_id: deviceID,
                                         user_id: userID,
                                         user_type: UInt(self.user.userType.rawValue),
                                         current_step: UInt(self.currentStep),
                                         undo_redo_info: undoRedoInfo,
                                         visible: true))
            }
        }
        return try body(data)
    }

    func withCometData<R>(body: (CometDrawableData) throws -> R) rethrows -> R {
        let comet = self.comet
        let style = CometStyle(color: comet.color,
                               size: comet.size,
                               opacity: 1.0)
        return try comet.coords.map({
            ($0.x, $0.y)
        }).withUnsafeBufferPointer { ptr -> R in
            let shapeID = strdup(self.shapeID)
            defer { free(shapeID) }
            let deviceID = strdup(self.user.deviceID)
            defer { free(deviceID) }
            let userID = strdup(self.user.userID)
            defer { free(userID) }
            let ffi = FFIArrayFloat2(ptr: ptr.baseAddress, len: UInt(ptr.count))
            let undoRedoInfo = UndoRedoInfo(undo_status: false, redo_status: false)
            let data = CometDrawableData(
                id: shapeID,
                style: style,
                points: ffi,
                radii: FFIArrayFloat1(ptr: nil, len: 0),
                duration: comet.duration,
                ext_info: ExtInfoFFI(device_id: deviceID,
                                     user_id: userID,
                                     user_type: UInt(self.user.userType.rawValue),
                                     current_step: UInt(self.currentStep),
                                     undo_redo_info: undoRedoInfo,
                                     visible: true),
                pause: false,
                exit: comet.exit)
            return try body(data)
        }
    }

    func withOvalData<R>(body: (OvalDrawableData) throws -> R) rethrows -> R {
        let oval = self.oval
        let style = OvalStyle(color: oval.color,
                              size: oval.size)
        let origin: [Float] = [oval.origin.x, oval.origin.y]
        let shapeID = strdup(self.shapeID)
        defer { free(shapeID) }
        let deviceID = strdup(self.user.deviceID)
        defer { free(deviceID) }
        let userID = strdup(self.user.userID)
        defer { free(userID) }
        let undoRedoInfo = UndoRedoInfo(undo_status: false, redo_status: false)
        let data = origin.withUnsafeBufferPointer { originPtr in
            OvalDrawableData(
                id: shapeID,
                origin: originPtr.baseAddress,
                long_axis: oval.longAxis,
                short_axis: oval.shortAxis,
                style: style,
                ext_info: ExtInfoFFI(device_id: deviceID,
                                     user_id: userID,
                                     user_type: UInt(self.user.userType.rawValue),
                                     current_step: UInt(self.currentStep),
                                     undo_redo_info: undoRedoInfo,
                                     visible: true))
        }
        return try body(data)
    }

    func withArrowData<R>(body: (ArrowDrawableData) throws -> R) rethrows -> R {
        let arrow = self.arrow
        let style = ArrowStyle(color: arrow.color,
                               size: arrow.size)
        let origin: [Float] = [arrow.origin.x, arrow.origin.y]
        let end: [Float] = [arrow.end.x, arrow.end.y]
        let shapeID = strdup(self.shapeID)
        defer { free(shapeID) }
        let deviceID = strdup(self.user.deviceID)
        defer { free(deviceID) }
        let userID = strdup(self.user.userID)
        defer { free(userID) }
        let undoRedoInfo = UndoRedoInfo(undo_status: false, redo_status: false)
        let data = origin.withUnsafeBufferPointer { originPtr in
            return end.withUnsafeBufferPointer { endPtr in
                return ArrowDrawableData(
                    id: shapeID,
                    origin: originPtr.baseAddress,
                    end: endPtr.baseAddress,
                    style: style,
                    ext_info: ExtInfoFFI(device_id: deviceID,
                                         user_id: userID,
                                         user_type: UInt(self.user.userType.rawValue),
                                         current_step: UInt(self.currentStep),
                                         undo_redo_info: undoRedoInfo,
                                         visible: true))
            }
        }
        return try body(data)
    }

}

extension SketchRemoveData {
    init(data: RemoveTransportData) {
        self.init()
        self.removeType = data.remove_type.pbType
        self.currentStep = Int32(data.current_step)
        let bufPtr = UnsafeBufferPointer<UnsafePointer<Int8>?>(start: data.ids_ptr,
                                                               count: Int(data.ids_len))
        let ids = bufPtr.compactMap({ $0 }).map({ String(cString: $0) })
        self.ids = ids
    }
}
