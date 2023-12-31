//
//  IsoPath+NotStrictly.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/27.
//

import Foundation

extension IsoPath: NotStrictlyExtensionCompatible { }

/// 一些非严格模式下的接口，非特殊场景不要使用
extension NotStrictlyExtension where BaseType == IsoPath {
    public func copyItem(from path: AbsPath) throws {
        try base.copyItem(from: path)
    }

    public func moveItem(from path: AbsPath) throws {
        try FileManager().moveItem(atPath: path.absoluteString, toPath: base.absoluteString)
        if let suite = base.context[IsoPath.ContextKeys.cryptoSuite.rawValue] as? SBCipherSuite,
           case .default = suite
        {
            let cipher = SBCipherManager.shared.cipher(for: suite, mode: .space(base.base.config.space))
            _ = try cipher?.encryptPath(base.absoluteString)
        }
    }
}
