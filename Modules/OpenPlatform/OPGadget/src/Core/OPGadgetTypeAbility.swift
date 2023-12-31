//
//  OPGadgetTypeAbility.swift
//  OPGadget
//
//  Created by yinyuan on 2020/11/27.
//

import Foundation
import OPSDK
import OPFoundation

@objc public final class OPGadgetTypeAbility: NSObject, OPAppTypeAbilityProtocol {
    
    public func createContainer(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID,
        containerConfig: OPContainerConfigProtocol
    ) throws -> OPContainerProtocol {
        guard let containerConfig = containerConfig as? OPGadgetContainerConfig else {
            throw OPSDKMonitorCode.invalid_params.error(message: "only accept containerConfig as OPBlockContainerConfig for block type")
        }
        return OPGadgetContainer(
            applicationContext: applicationContext,
            uniqueID: uniqueID,
            containerConfig: containerConfig
        )
    }
    
    public func fastCreateRenderSlot(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPRenderSlotProtocol {
        throw OPSDKMonitorCode.unknown_error.error()
    }
    
    public func fastCreateContainerConfig(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPContainerConfigProtocol {
        return OPGadgetContainerConfig(previewToken: nil, enableAutoDestroy: true)
    }
    
    public func fastCreateContainerMountData(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPContainerMountDataProtocol {
        return OPGadgetContainerMountData(scene: .undefined, startPage: nil)
    }
}
