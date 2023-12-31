//
//  OPBlockDataProvider.swift
//  OPBlockInterface
//
//  Created by xiangyuanyuan on 2022/7/17.
//

import Foundation
import OPSDK

public enum BlockDataFrom: String {
    case cache
    case network
    case host
}

open class OPBlockDataProvider<ResultType: BaseBlockInfo> {
    public init() {}
    open func generateData() -> ResultType? {
        assertionFailure("please implement in subclass")
        return nil
    }
    open func getDataType() -> BlockDataSourceType {
        assertionFailure("please implement in subclass")
        return .unknown
    }
}

public final class BlockProviderSet {

    private var dict: [BlockDataSourceType: Any] = [:]
    
    public init() {}

    public func add<P, T: OPBlockDataProvider<P>>(provider: T) where P: BaseBlockInfo {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        dict[provider.getDataType()] = provider
    }

    public func getProvider<P, T: OPBlockDataProvider<P>>(with dataType: BlockDataSourceType) -> T? where P: BaseBlockInfo {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return dict[dataType] as? T
    }
}
