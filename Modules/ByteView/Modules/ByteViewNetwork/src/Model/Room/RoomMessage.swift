//
//  RoomMessage.swift
//  ByteView
//
//  Created by fakegourmet on 2023/1/17.
//

import Foundation

public enum RoomMessageContext: UInt8 {
    case unknown = 0
    case cursorShare
}

public enum RoomMessageType: UInt8 {
    case unknown = 0
    case singleFrame
}

/// 格式文档
/// https://bytedance.feishu.cn/wiki/wikcnZYVbumG70u5g7LeqthdRke#FsE4Rk
public struct RoomMessageHeader {
    public var context: RoomMessageContext
    public var type: RoomMessageType
    public var body: Data

    public init?(data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count > 2 else {
            return nil
        }
        context = RoomMessageContext(rawValue: bytes[0]) ?? .unknown
        type = RoomMessageType(rawValue: bytes[1]) ?? .unknown
        let length = bytes.count
        let dataBytes = [UInt8](bytes.suffix(length - 2))
        body = Data(bytes: dataBytes, count: dataBytes.count)
    }
}
