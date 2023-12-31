//
//  AbsPath+NotStrictly.swift
//  LarkStorage
//
//  Created by 7Up on 2022/9/14.
//

import Foundation

extension AbsPath: NotStrictlyExtensionCompatible { }

extension NotStrictlyExtension where BaseType == AbsPath {
    public func removeItem() throws {
        try base.sandbox.removeItem(atPath: base)
    }

    public func copyItem(to toPath: AbsPath) throws {
        try base.sandbox.copyItem(atPath: base, toPath: toPath)
    }

    public func copyItem(from fromPath: AbsPath) throws {
        try base.sandbox.copyItem(atPath: fromPath, toPath: base)
    }

    public func createDirectoryIfNeeded() throws {
        guard !base.exists else { return }
        try base.sandbox.createDirectory(
            atPath: base,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public func moveItem(to toPath: AbsPath) throws {
        try base.sandbox.moveItem(atPath: base, toPath: toPath)
    }

    public func forceMoveItem(to toPath: AbsPath) throws {
        if toPath.isAny {
            try toPath.notStrictly.removeItem()
        }
        try base.sandbox.moveItem(atPath: base, toPath: toPath)
    }
}
