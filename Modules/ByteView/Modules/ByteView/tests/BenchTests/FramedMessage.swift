//
//  FramedMessage.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/9/13.
//

import Foundation

public struct FrameHeader {
    public var payloadSize: UInt32
    public var cmd: Int
    public var elapsedMS: UInt64
}

extension FileHandle {

    func readIntBE<T: FixedWidthInteger>(_ type: T.Type) throws -> T? {
        let len = MemoryLayout<T>.size
        var data: Data?
        if #available(iOS 13.4, *) {
            data = try self.read(upToCount: len)
        } else {
            data = self.readData(ofLength: len)
        }
        guard let data = data, data.count == len else {
            return nil
        }
        var v = T()
        _ = withUnsafeMutableBytes(of: &v) { ptr in
            data.copyBytes(to: ptr, count: len)
        }
        return T(bigEndian: v)
    }

    func readIntLE<T: FixedWidthInteger>(_ type: T.Type) throws -> T? {
        let len = MemoryLayout<T>.size
        var data: Data?
        if #available(iOS 13.4, *) {
            data = try self.read(upToCount: len)
        } else {
            data = self.readData(ofLength: len)
        }
        guard let data = data, data.count == len else {
            return nil
        }
        var v = T()
        _ = withUnsafeMutableBytes(of: &v) { ptr in
            data.copyBytes(to: ptr, count: len)
        }
        return T(littleEndian: v)
    }

    func writeIntBE<T: FixedWidthInteger>(_ v: T) throws {
        try withUnsafeBytes(of: v.bigEndian) { bytes in
            if #available(iOS 13.4, *) {
                try self.write(contentsOf: bytes)
            } else {
                self.write(Data(bytes))
            }
        }
    }

    func writeIntLE<T: FixedWidthInteger>(_ v: T) throws {
        try withUnsafeBytes(of: v.littleEndian) { bytes in
            if #available(iOS 13.4, *) {
                try self.write(contentsOf: bytes)
            } else {
                self.write(Data(bytes))
            }
        }
    }
}

public struct FramedMessage {
    public var header: FrameHeader
    public var payload: Data
}

extension FrameHeader {
    public func writeTo(_ fileHandle: FileHandle) throws {
        try fileHandle.writeIntBE(self.payloadSize)
        try fileHandle.writeIntBE(self.cmd)
        try fileHandle.writeIntBE(self.elapsedMS)
    }

    public static func from(_ fileHandle: FileHandle) throws -> FrameHeader? {
        guard let payloadSize = try fileHandle.readIntBE(UInt32.self),
              let cmd = try fileHandle.readIntBE(Int.self),
              let elapsedMS = try fileHandle.readIntBE(UInt64.self) else {
            return nil
        }
        return FrameHeader(payloadSize: payloadSize, cmd: cmd, elapsedMS: elapsedMS)
    }
}

extension FramedMessage {
    public func writeTo(_ fileHandle: FileHandle) throws {
        try self.header.writeTo(fileHandle)
        if #available(iOS 13.4, *) {
            try fileHandle.write(contentsOf: self.payload)
        } else {
            fileHandle.write(self.payload)
        }
    }

    public static func from(_ fileHandle: FileHandle) throws -> FramedMessage? {
        guard let header = try FrameHeader.from(fileHandle) else {
            return nil
        }
        let payload: Data?
        if #available(iOS 13.4, *) {
            payload = try fileHandle.read(upToCount: Int(header.payloadSize))
        } else {
            payload = fileHandle.readData(ofLength: Int(header.payloadSize))
        }
        guard let payload = payload,
              payload.count == Int(header.payloadSize) else {
            return nil
        }
        return FramedMessage(header: header, payload: payload)
    }
}

public class FramedWriter {
    let fileHandle: FileHandle
    private lazy var startTime = Date()
    public init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    public func appendMessage(cmd: Int, payload: Data) {
        let elapsed = -startTime.timeIntervalSinceNow
        let msg = FramedMessage(header: FrameHeader(payloadSize: UInt32(payload.count),
                                                    cmd: cmd,
                                                    elapsedMS: UInt64(elapsed * 1000)),
                                payload: payload)
        try? msg.writeTo(fileHandle)
    }
}
