//
//  NativeAppTypeAbility.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/28.
//

import Foundation
import OPSDK

@objc public class NativeAppTypeAbility: NSObject, OPAppTypeAbilityProtocol {
    
    private var metaProvider: (OPAppMetaLocalAccessor & OPAppMetaRemoteAccessor)?
    
    public func fastCreateContainerConfig(applicationContext: OPSDK.OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPSDK.OPContainerConfigProtocol {
        return NativeAppContainerConfig()
    }
    
    public func fastCreateRenderSlot(applicationContext: OPSDK.OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPSDK.OPRenderSlotProtocol {
        throw OPSDKMonitorCode.unknown_error.error()
    }
    
    public func fastCreateContainerMountData(applicationContext: OPSDK.OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPSDK.OPContainerMountDataProtocol {
        return NativeAppContainerMountData(scene: .undefined)
    }
    
    
    public func createContainer(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID,
        containerConfig: OPContainerConfigProtocol
    ) throws -> OPContainerProtocol {
        return NativeAppContainer(applicationContext: applicationContext, uniqueID: uniqueID, containerConfig: containerConfig)
    }
}
