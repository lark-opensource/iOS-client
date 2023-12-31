//
//  OPAppTypeAbilityProtocol.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/26.
//

import Foundation
import OPFoundation

/// 与应用类型相关的一些能力的协议
public protocol OPAppTypeAbilityProtocol {
    typealias MetaProvider = OPAppMetaLocalAccessor & OPAppMetaRemoteAccessor
    
    func createContainer(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID,
        containerConfig: OPContainerConfigProtocol
    ) throws -> OPContainerProtocol
    
    func fastCreateContainerConfig(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID
    ) throws -> OPContainerConfigProtocol
    
    func fastCreateRenderSlot(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID
    ) throws -> OPRenderSlotProtocol
    
    func fastCreateContainerMountData(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID
    ) throws -> OPContainerMountDataProtocol

    func generateMetaProvider() -> MetaProvider?
}

public extension OPAppTypeAbilityProtocol {
    func generateMetaProvider() -> MetaProvider? { nil }
}
