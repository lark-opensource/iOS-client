//
//  BlockitParam.swift
//  Blockit
//
//  Created by xiangyuanyuan on 2022/7/17.
//

import Foundation
import OPSDK
import OPBlockInterface

// 相关技术文档: https://bytedance.feishu.cn/docx/doxcnHJolsGtW7dmXEiTlmStF2g
public enum BlockitParamBuildError: Error {
    case slotViewParamError
    case delegateParamError
    case configParamError
    case dataParamError
    case mountTypeParamError
}

public enum OPBlockMountType: String {
    case entity
    case blockID
}

public final class BlockitParam {
    private(set) var mountType: OPBlockMountType
    private(set) var blockID: String?
    private(set) var blockTypeID: String?
    private(set) var slot: OPRenderSlotProtocol
    private(set) var data: OPBlockContainerMountDataProtocol
    private(set) var config: OPBlockContainerConfigProtocol
    private(set) var plugins: [OPPluginProtocol]
    private(set) var delegate: BlockitDelegate
    private(set) var dataProviders: BlockProviderSet
    
    fileprivate init(mountType: OPBlockMountType,
                     blockID: String?,
                     blockTypeID: String?,
                     slot: OPRenderSlotProtocol,
                     data: OPBlockContainerMountDataProtocol,
                     config: OPBlockContainerConfigProtocol,
                     plugins: [OPPluginProtocol],
                     delegate: BlockitDelegate,
                     dataProviders: BlockProviderSet) {
        self.mountType = mountType
        self.blockID = blockID
        self.blockTypeID = blockTypeID
        self.slot = slot
        self.data = data
        self.config = config
        self.plugins = plugins
        self.delegate = delegate
        self.dataProviders = dataProviders
    }
}

public final class BlockitParamBuilder {
    
    private var mountType: OPBlockMountType?
    private var blockID: String?
    private var blockTypeID: String?
    private var slot: OPRenderSlotProtocol?
    private var data: OPBlockContainerMountDataProtocol?
    private var config: OPBlockContainerConfigProtocol?
    private var delegate: BlockitDelegate?
    private var plugins: [OPPluginProtocol] = []
    private var dataProviders: BlockProviderSet = BlockProviderSet()
    
    public init() {}
    
    public func setMountType(mountType: OPBlockMountType) -> BlockitParamBuilder {
        self.mountType = mountType
        return self
    }
    
    public func setBlockID(blockID: String) -> BlockitParamBuilder {
        self.blockID = blockID
        return self
    }
    
    public func setBlockTypeID(blockTypeID: String) -> BlockitParamBuilder {
        self.blockTypeID = blockTypeID
        return self
    }
    
    public func setSlotView(slot: OPRenderSlotProtocol) -> BlockitParamBuilder {
        self.slot = slot
        return self
    }
    
    public func setData(data: OPBlockContainerMountDataProtocol) -> BlockitParamBuilder {
        self.data = data
        return self
    }
    
    public func setConfig(config: OPBlockContainerConfigProtocol) -> BlockitParamBuilder {
        self.config = config
        return self
    }
    
    public func setPlugins(plugins: [OPPluginProtocol]) -> BlockitParamBuilder {
        self.plugins = plugins
        return self
    }
    
    public func setDelegate(delegate: BlockitDelegate) -> BlockitParamBuilder {
        self.delegate = delegate
        return self
    }
    
    public func addDataProvider<P, T: OPBlockDataProvider<P>>(dataProvider: T) -> BlockitParamBuilder where P: BaseBlockInfo {
        self.dataProviders.add(provider: dataProvider)
        return self
    }
    
    public func build() throws -> BlockitParam {
        
        guard let mountType = mountType else {
            throw BlockitParamBuildError.mountTypeParamError
        }
        guard let slot = slot else {
            throw BlockitParamBuildError.slotViewParamError
        }
        guard let delegate = delegate else {
            throw BlockitParamBuildError.delegateParamError
        }
        guard let config = config else {
            throw BlockitParamBuildError.configParamError
        }
        guard let data = data else {
            throw BlockitParamBuildError.dataParamError
        }
        
        return BlockitParam(mountType: mountType,
                            blockID: blockID,
                            blockTypeID: blockTypeID,
                            slot: slot,
                            data: data,
                            config: config,
                            plugins: plugins,
                            delegate: delegate,
                            dataProviders: dataProviders)
    }
}
