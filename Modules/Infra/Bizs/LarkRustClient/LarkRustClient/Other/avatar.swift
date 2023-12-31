//
//  Avatar.swift
//  LarkRustClient
//
//  Created by SolaWing on 2022/5/6.
//

import UIKit
import Foundation
import RustPB

extension Rust {
    /// injected stat hook
    public static var avatarInvalidUserIDReport: (((client: UInt64, sdk: UInt64, entityID: Int64, key: String)) -> Void)? // swiftlint:disable:this all
    enum GetAvatarError: Error {
        case rust(code: Int32)
        case invalidUser
    }
    /// - Parameters:
    ///   - entityID: 实体对应的唯一ID, chatID/chatterID/tenantID
    ///   - key: avatarkey
    ///   - size: 头像 dp 尺寸, avatar view dp size: max(width, height)
    ///   - dpr: 设备 dpr, UIScreen.main.scale
    ///   - format: 头像格式。可选值为 "webp" 和 "jpeg", "webp" 各端都需要，"jpeg" 只有 PC 需要。
    /// - throws: GetAvatarError
    /// - Returns:
    public static func getAvatar(userID: UInt64, entityID: Int64, key: String, size: Int32, dpr: Float, format: String) throws -> Data? { // swiftlint:disable:this all
        fatalError("unreachable code!!")

        // 该代码没有正式上线，先不实现
        // var length = 0
        // var buffer: UnsafeMutablePointer<UInt8>?
        // let errorCode = get_avatar_v2(entityID, key, size, dpr, format, userID, &length, &buffer)
        // var data: Data?
        // if let buffer = buffer {
        //     if length > 8 {
        //         // 转移Buffer所有权给data, 避免copy, data会自动释放
        //         data = Data(bytesNoCopy: buffer, count: length,
        //                     deallocator: .custom { free_rust($0.bindMemory(to: UInt8.self, capacity: $1), UInt32($1)) }
        //                     )[8...]
        //         let rustUserID = UnsafeRawPointer(buffer).load(as: UInt64.self).bigEndian
        //         if userID != rustUserID {
        //             avatarInvalidUserIDReport?((client: userID, sdk: rustUserID, entityID: entityID, key: key))
        //             throw GetAvatarError.invalidUser
        //         }
        //     } else {
        //         free_rust(buffer, UInt32(length))
        //     }
        // }
        // guard errorCode == 0 else {
        //     throw GetAvatarError.rust(code: errorCode)
        // }
        // return data
    }
}
