//
//  OPMonitor+AppLoad.swift
//  TTMicroApp
//
//  Created by justin on 2022/12/29.
//

import Foundation
import OPFoundation
import ECOProbe

/// FROM: OPMonitor+Extension.swift
public extension OPMonitor {

    public func setLoadType(_ loadType: CommonAppLoadType) -> OPMonitor {
        addCategoryValue(kEventKey_load_type, loadType.rawValue)
    }
    
    public func setAppLoadInfo(_ context: MetaContext, _ loadType: CommonAppLoadType) -> OPMonitor {
        addTag(.appLoad)
            .setUniqueID(context.uniqueID)
            .addCategoryValue(kEventKey_load_type, loadType.rawValue)
    }
}
