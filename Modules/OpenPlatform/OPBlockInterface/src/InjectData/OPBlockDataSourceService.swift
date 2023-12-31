//
//  OPBlockDataSourceService.swift
//  OPBlockInterface
//
//  Created by xiangyuanyuan on 2022/7/17.
//

import Foundation
import OPSDK

public enum BlockDataInitMode {
    case lazyOnce
    case lazyEvery
}

public final class BlockDataSourceService<T>: OPBlockDataSourceServiceProtocol where T: BaseBlockInfo {
    
    public typealias DataType = T

    public let dataProvider: OPBlockDataProvider<T>?
    
    public var provideData: T? = nil
    
    public let dataInitMode: BlockDataInitMode

    public init(dataProvider: OPBlockDataProvider<T>?, dataInitMode: BlockDataInitMode) {
        self.dataProvider = dataProvider
        self.dataInitMode = dataInitMode
    }

    public func fetchData(dataType: BlockDataSourceType) -> T? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if dataInitMode == .lazyOnce {
            if let provideData = provideData {
                return provideData
            } else {
                return dataProvider?.generateData()
            }
        } else {
            return dataProvider?.generateData()
        }
    }
}

public protocol OPBlockDataSourceServiceProtocol {

    associatedtype DataType: BaseBlockInfo
    
    var dataProvider: OPBlockDataProvider<DataType>? { get }

    func fetchData(dataType: BlockDataSourceType) -> DataType?

}
