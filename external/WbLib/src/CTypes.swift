//
//  CTypes.swift
//
// Created by kef on 2022/3/3.
//

import Foundation

extension UnsafeMutablePointer where Pointee == CWbInlineGlyphSpecs {
    public static func fromSwift(_ input: InlineGlyphSpecs) -> Self {
        let ptr = UnsafeMutablePointer<CWbInlineGlyphSpecs>.allocate(capacity: 1)
        ptr.pointee.height = input.height
        ptr.pointee.widths = UnsafePointer(UnsafeMutablePointer<CArray_f32>.fromSwift(input.widths))
        ptr.pointee.origin_offset_x = input.originOffsetX
        ptr.pointee.origin_offset_y = input.originOffsetY
        
        return ptr
    }

    public func freeUnsafeMemory() {
        UnsafeMutablePointer<CArray_f32>(mutating: self.pointee.widths).freeUnsafeMemory()
        self.deallocate()
    }
}

extension CArray_u8 {
    func toSwiftArray() -> [UInt8] {
        return UnsafeBufferPointer(start: data_ptr, count: Int(size))
                .compactMap { $0 }
                .map { UInt8($0) }
    }
}

extension CArray_CPoint {
    func toSwiftArray() -> [Point] {
        return UnsafeBufferPointer(start: data_ptr, count: Int(size))
            .compactMap { $0 }
            .map { Point(cValue: $0) }
    }
}

extension CArray_CArray_CPoint {
    func toSwiftArray() -> [[Point]] {
        return UnsafeBufferPointer(start: data_ptr, count: Int(size))
            .compactMap { $0 }
            .map { $0.toSwiftArray()}
    }
}

extension CArray_C_WB_PATH_ACTION {
    func toSwiftArray() -> [PathAction] {
        return UnsafeBufferPointer(start: data_ptr, count: Int(size))
            .compactMap { $0 }
            .map { PathAction(cValue: $0) }
    }
}

extension CArray_CWbGraphic {
    public func toSwiftArray() -> [WbGraphic] {
        return UnsafeBufferPointer(start: data_ptr, count: Int(size))
            .compactMap { $0 }
            .map { WbGraphic(cValue: $0) }
    }
}

extension CArray_CEnum_C_WB_RENDER_CMD {
    func toSwiftArray() -> [WbRenderCmd] {
        return UnsafeBufferPointer(start: data_ptr, count: Int(size))
            .compactMap { $0 }
            .map { WbRenderCmd(cmd: $0.ty, dataPtr: $0.data) }
    }
}
