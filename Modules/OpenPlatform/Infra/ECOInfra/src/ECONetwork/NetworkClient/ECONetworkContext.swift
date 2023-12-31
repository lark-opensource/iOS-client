//
//  ECONetworkContext.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/14.
//

import Foundation
import ECOProbe

/// ECONetworkContext, 仅网络内部使用的 context
/// 从外层 context 创建, 在 ECONetwork 回调给外部时, 会将外部的 context 重新返回给外界
@objcMembers
open class ECONetworkContext: NSObject, ECONetworkContextProtocol {
    public weak var previousContext: AnyObject?

    public let trace: OPTrace

    public let source: String?
    
    public init(from context: AnyObject?, trace: OPTrace, source: String? = nil) {
        self.previousContext = context
        self.trace = trace
        self.source = source
    }
}
