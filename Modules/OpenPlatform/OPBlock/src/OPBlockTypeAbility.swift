//
//  OPBlockTypeAbility.swift
//  OPBlock
//
//  Created by yinyuan on 2020/11/26.
//

import Foundation
import OPSDK
import OPBlockInterface
import ECOProbe
import LKCommonsLogging
import TTMicroApp
import LarkContainer

@objc public final class OPBlockTypeAbility: NSObject, OPAppTypeAbilityProtocol {

    private var metaProvider: (OPAppMetaLocalAccessor & OPAppMetaRemoteAccessor)?

    public func createContainer(
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID,
        containerConfig: OPContainerConfigProtocol
    ) throws -> OPContainerProtocol {
        // OPSDK 未完整适配用户态隔离
        let userResolver = Container.shared.getCurrentUserResolver()
        guard let containerConfig = containerConfig as? OPBlockContainerConfig else {
            throw OPSDKMonitorCode.unknown_error.error(message: "only accept initConfig as OPBlockContainerConfig for block type")
        }

        let trace = BlockTrace(trace: BDPTracing(traceId: containerConfig.trace.traceId), uniqueID: uniqueID)

        trace.info("OPBlockTypeAbility.createContainer")

        return OPBlockContainer(
            userResolver: userResolver,
            applicationContext: applicationContext,
            uniqueID: uniqueID,
            containerConfig: containerConfig,
            trace: trace
        )
    }

    public func generateBlockMetaProvider(containerContext: OPContainerContext) -> OPAppTypeAbilityProtocol.MetaProvider? {
        if let provider = metaProvider {
            return provider
        } else {
            metaProvider = OPBlockMetaProvider(builder: OPBlockMetaBuilder(), containerContext: containerContext)
            return metaProvider!
        }
    }
    
    public func fastCreateRenderSlot(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPRenderSlotProtocol {
        throw OPSDKMonitorCode.unknown_error.error()
    }
    
    public func fastCreateContainerConfig(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPContainerConfigProtocol {
        return OPBlockContainerConfig(uniqueID: uniqueID, blockLaunchMode: .default, previewToken: "", host: "")
    }
    
    public func fastCreateContainerMountData(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID) throws -> OPContainerMountDataProtocol {
        return OPBlockContainerMountData(scene: .undefined)
    }
}
