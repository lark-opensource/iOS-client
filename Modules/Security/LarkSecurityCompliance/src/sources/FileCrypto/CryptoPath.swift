//
//  CryptoPath.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/8/2.
//

import Foundation
import LarkContainer
import LarkFileKit

public final class CryptoPath {

    private let rustClient: CryptoRustService?

    public init(userResolver: UserResolver) {
        rustClient = try? userResolver.resolve(type: CryptoRustService.self)
    }

    @discardableResult
    public func encrypt(_ path: String) throws -> String {
        let path = Path(path)
        guard path.exists else {
            throw CryptoFileError.customError("path not exists")
        }
        guard let rustClient else {
            throw CryptoFileError.customError("rust client is nil")
        }
        if path.isDirectory {
            return try rustClient.encryptDir(path.rawValue)
        } else {
            return try rustClient.encryptFile(path.rawValue)
        }
    }

    public func decrypt(_ path: String) throws -> String {
        let path = Path(path)
        guard path.exists else {
            throw CryptoFileError.customError("path not exists")
        }
        guard let rustClient else {
            throw CryptoFileError.customError("rust client is nil")
        }
        if path.isDirectory {
            return try rustClient.decryptDir(path.rawValue)
        } else {
            return try rustClient.decryptFile(path.rawValue)
        }
    }

    public func writeBackPath(_ stagePath: String) throws -> String {
        guard let rustClient else {
            throw CryptoFileError.customError("rust client is nil")
        }
        return try rustClient.writeBackPath(stagePath)
    }
}
