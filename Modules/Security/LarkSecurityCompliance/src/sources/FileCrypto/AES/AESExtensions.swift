//
//  AESExtensions.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/2/23.
//

import UIKit

extension Data {
    func convertToInteger<T: FixedWidthInteger>() -> T {
        withUnsafeBytes { $0.load(as: T.self) }.littleEndian
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

extension UInt64 {
    @_specialize(where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt64(bytes: bytes, fromIndex: bytes.startIndex)
    }

    @_specialize(where T == ArraySlice<UInt8>)
    @inlinable
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }

        let count = bytes.count
        // swiftlint:disable empty_count
        let val0 = count > 0 ? UInt64(bytes[index.advanced(by: 0)]) << 56 : 0
        let val1 = count > 1 ? UInt64(bytes[index.advanced(by: 1)]) << 48 : 0
        let val2 = count > 2 ? UInt64(bytes[index.advanced(by: 2)]) << 40 : 0
        let val3 = count > 3 ? UInt64(bytes[index.advanced(by: 3)]) << 32 : 0
        let val4 = count > 4 ? UInt64(bytes[index.advanced(by: 4)]) << 24 : 0
        let val5 = count > 5 ? UInt64(bytes[index.advanced(by: 5)]) << 16 : 0
        let val6 = count > 6 ? UInt64(bytes[index.advanced(by: 6)]) << 8 : 0
        let val7 = count > 7 ? UInt64(bytes[index.advanced(by: 7)]) : 0

        self = val0 | val1 | val2 | val3 | val4 | val5 | val6 | val7
        // swiftlint:enable empty_count
    }
}

extension FixedWidthInteger {
    @inlinable
    func bytes(totalBytes: Int = MemoryLayout<Self>.size) -> Array<UInt8> {
        arrayOfBytes(value: self.littleEndian, length: totalBytes)
        // TODO: adjust bytes order
        // var value = self.littleEndian
        // return withUnsafeBytes(of: &value, Array.init).reversed()
    }
}

/// Array of bytes. Caution: don't use directly because generic is slow.
///
/// - parameter value: integer value
/// - parameter length: length of output array. By default size of value type
///
/// - returns: Array of bytes
@_specialize(where T == Int)
@_specialize(where T == UInt)
@_specialize(where T == UInt8)
@_specialize(where T == UInt16)
@_specialize(where T == UInt32)
@_specialize(where T == UInt64)
@inlinable
func arrayOfBytes<T: FixedWidthInteger>(value: T, length totalBytes: Int = MemoryLayout<T>.size) -> Array<UInt8> {
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value

    let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
    var bytes = Array<UInt8>(repeating: 0, count: totalBytes)
    for j in 0..<min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }

    valuePointer.deinitialize(count: 1)
    valuePointer.deallocate()

    return bytes
}
