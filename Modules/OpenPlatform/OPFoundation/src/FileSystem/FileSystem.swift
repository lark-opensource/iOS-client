//
//  FileSystem.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/2.
//

import Foundation
import ECOProbe

/// Ecosystem 标准化文件系统
///
/// 实现了一套无状态标准化 API
///
public final class FileSystem {
    public static let ioQueue = DispatchQueue(label: "com.bytedance.ecosystem.filesystem.ioQueue", attributes: .concurrent)

    /// 标准化 API 上下文信息
    public struct Context {
        /// uniqueId
        public let uniqueId: OPAppUniqueID

        /// trace 必须传，只有实在无法处理的老业务可以暂时不用传，内部会默认生成一个
        public let trace: OPTrace

        /// 业务标识，用于业务画像，不传则为 unknow
        public private(set) var tag: String

        /// 包路径一些资源文件在 PkgReader 有读取缓存，用这个来标识是否优先从读取缓存获取。历史业务直接从 PkgReader 显示调用不同 API 读取，此处用标识做兼容。
        /// 长期看，需要 PkgReader 提供一致性接口，而不是业务调用时感知。
        public let isAuxiliary: Bool

        public init(uniqueId: OPAppUniqueID, trace: OPTrace?, tag: String = "unknown", isAuxiliary: Bool = false) {
            self.uniqueId = uniqueId
            if let originTrace = trace {
                self.trace = originTrace
            } else {
                let uniqueIdTrace = BDPTracingManager.sharedInstance().getTracingBy(uniqueId)
                self.trace = uniqueIdTrace ?? OPTraceService.default().generateTrace()
            }
            self.tag = tag
            self.isAuxiliary = isAuxiliary
        }

        internal func taggingAPI(_ api: PrimitiveAPI) -> Context {
            var tagContext = self
            tagContext.tag = api.internalTag
            return tagContext
        }
    }
    
    public struct Constant {
        static let maxFileNameLength = 255
    }
}
