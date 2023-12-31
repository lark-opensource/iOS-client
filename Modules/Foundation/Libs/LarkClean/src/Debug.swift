//
//  Debug.swift
//  LarkClean
//
//  Created by 7Up on 2023/6/28.
//

#if !LARK_NO_DEBUG

import Foundation
import LarkStorage
import CommonCrypto

public struct DebugCleanError: Swift.Error, CustomStringConvertible {
    public var description: String
    public init(_ description: String) {
        self.description = description
    }
}

/// Debug 开关
public enum DebugSwitches {
    static let store = KVStores.udkv(space: .global, domain: Domain.biz.infra.child("LarkClean").child("Debug"))

    /// 模拟「退登 -> 擦除」失败
    public static var logoutCleanFail: Bool {
        get { store.bool(forKey: "logoutCleanFail") }
        set { store.set(newValue, forKey: "logoutCleanFail") }
    }

    /// 模拟「重启 -> 重试」失败
    public static var resumeCleanFail: Bool {
        get { store.bool(forKey: "resumeCleanFail") }
        set { store.set(newValue, forKey: "resumeCleanFail") }
    }

    /// 模拟「重启 -> 重置」失败
    public static var resumeResetFail: Bool {
        get { store.bool(forKey: "resumeResetFail") }
        set { store.set(newValue, forKey: "resumeResetFail") }
    }

    /// 模拟「Rust 擦除」失败
    public static var rustCleanFail: Bool {
        get { store.bool(forKey: "rustCleanFail") }
        set { store.set(newValue, forKey: "rustCleanFail") }
    }

    /// 最后的 cleanIdentifier
    public static var lastCleanIdentifier: String? {
        get { store.string(forKey: "lastCleanIdentifier") }
        set { store.set(newValue, forKey: "lastCleanIdentifier") }
    }
}

public class PathDebugItem {
    public var path: AbsPath { inner.absPath }

    let inner: CleanPathItem
    let executor: CleanPathExecutor

    init(inner: CleanPathItem, executor: CleanPathExecutor) {
        self.inner = inner
        self.executor = executor
    }

    public func clean(completion: @escaping (Bool) -> Void) {
        executor.stepState(inner, rescueMode: true, terminate: .auto)
        completion(true)
    }
}

public func lastCleanContext() -> CleanContext? {
    guard let lastIdentifier = DebugSwitches.lastCleanIdentifier, !lastIdentifier.isEmpty else {
        return nil
    }
    let params = ExecutorParams.resume(with: lastIdentifier)
    return params?.context
}

public func allPaths(for context: CleanContext) -> [String: [PathDebugItem]] {
    let params = ExecutorParams.create(identifier: makeIdentifier(), context: context, retryCount: 3)
    let pathExecutor = CleanPathExecutor(params: params)
    var ret = CleanRegistry.allIndexes(with: context)
        .mapValues { indexes in
            return indexes.compactMap { index -> PathDebugItem? in
                guard case .path(let pIndex) = index else {
                    return nil
                }
                let item = CleanPathItem(absPath: pIndex.asAbsPath(), state: .idle, store: nil)
                return PathDebugItem(inner: item, executor: pathExecutor)
            }
        }
    ret["RustSdk"] = context.userList.map { user in
        let inner: CleanPathItem = .init(
            absPath: AbsPath.document + "sdk_storage/\(genMD5(text: user.userId))",
            state: .idle,
            store: nil
        )
        return PathDebugItem(inner: inner, executor: pathExecutor)
    }
    return ret
}

public func allVkeys(for context: CleanContext) -> [String: [CleanIndex.Vkey]] {
    return CleanRegistry.allIndexes(with: context)
        .mapValues { indexes in
            return indexes.compactMap { index -> CleanIndex.Vkey? in
                guard case .vkey(let pIndex) = index else {
                    return nil
                }
                return pIndex
            }
        }
        .filter { ele in
            !ele.value.isEmpty
        }
}

public func allTaskHandlers() -> [String: CleanTaskHandler] {
    return CleanRegistry.taskHandlers
}

private func genMD5(text: String) -> String {
    guard let str = text.cString(using: .utf8) else {
        return text
    }
    let strLen = CC_LONG(text.lengthOfBytes(using: .utf8))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
    // swiftlint:disable ForceUnwrapping
    CC_MD5(str, strLen, result)
    // swiftlint:enable ForceUnwrapping
    let hash = NSMutableString()
    for i in 0..<digestLen {
        hash.appendFormat("%02x", result[i])
    }
    result.deallocate()

    return String(format: hash as String)
}

#endif
