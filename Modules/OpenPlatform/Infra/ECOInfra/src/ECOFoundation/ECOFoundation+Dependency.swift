//
//  ECOFoundation+Dependency.swift
//  ECOInfra
//
//  Created by Meng on 2021/4/11.
//

import Foundation
import LarkContainer

public protocol ECOFoundationDependency: AnyObject {
    /// 桥接 BDPLog
    func _BDPLog(
        level: BDPLogLevel,
        tag: String?,
        tracing: String?,
        fileName: String?,
        funcName: String?,
        line: Int32,
        content: String?
    )
}

@objc(ECOFoundationDependency)
@objcMembers
public final class ECOFoundationDependnecyForObjc: NSObject {
    private class var dependency: ECOFoundationDependency? {
        // TODO: 等待主端提供 Optional Provider
        return implicitResolver?.resolve(ECOFoundationDependency.self) // Global
    }

    public class func _BDPLog(level: BDPLogLevel, tag: String?, tracing: String?, fileName: String?, funcName: String?, line: Int32, content: String?) {
        Self.dependency?._BDPLog(
            level: level,
            tag: tag,
            tracing: tracing,
            fileName: fileName,
            funcName: funcName,
            line: line,
            content: content
        )
    }
}

