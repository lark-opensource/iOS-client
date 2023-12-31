//
//  MetaContext.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/22.
//

import Foundation
import LarkOPInterface

/// 请求Meta应当传入的上下文，会被用于生成请求，生产meta对象，存储
@objcMembers
public final class MetaContext: NSObject {

    /// 应用ID，如对于卡片则是它归属的应用ID
    public let uniqueID: BDPUniqueID

    /// preview token
    public let token: String?
    
    /// 扩展参数，用于类似批量拉取的场景
    public let extra: [String: Any]?
    
    /// 用于标记 MetaContext 的Trace，如果当前在小程序上下文周期中，则使用。否则创建一个。
    public lazy var trace: BDPTracing = {
        if let trace = BDPTracingManager.sharedInstance().getTracingBy(self.uniqueID) {
            return trace
        }
        return BDPTracingManager.sharedInstance().generateTracing()
    }()

    /// 初始化meta模块上下文
    /// - Parameters:
    ///   - uniqueID: 应用ID，如对于卡片则是它归属的应用ID
    ///   - versionType: 应用版本类型，默认 "current" 代表线上版本 “preview”预览版本
    ///   - token: preview token
    public init(
        uniqueID: BDPUniqueID,
        token: String?,
        extra: [String: Any]? =  nil
    ) {
        self.uniqueID = uniqueID
        self.token = token
        self.extra = extra
        super.init()
    }
    
    /// 初始化meta模块上下文
    /// - Parameters:
    ///   - uniqueID: 应用ID，如对于卡片则是它归属的应用ID
    ///   - versionType: 应用版本类型，默认 "current" 代表线上版本 “preview”预览版本
    ///   - token: preview token
    public init(
        uniqueID: BDPUniqueID,
        token: String?
    ) {
        self.uniqueID = uniqueID
        self.token = token
        self.extra = nil
        super.init()
    }

    /// 检查Meta上下文是否合法
    /// - Returns: 不合法返回一个错误对象
    public func isVaild() -> OPError? {
        if !uniqueID.isValid() {
            return OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "invalid meta context, appID is empty")
        }
        if uniqueID.identifier.isEmpty {
            return OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "invalid meta context, identifier is empty")
        }
        return nil
    }
}
