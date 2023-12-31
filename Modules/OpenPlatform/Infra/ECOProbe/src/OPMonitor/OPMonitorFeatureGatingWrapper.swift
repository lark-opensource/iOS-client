//
//  OPMonitorFeatureGatingWrapper.swift
//  ECOProbe
//
//  Created by qsc on 2021/8/25.
//

import Foundation
import LarkContainer

@objcMembers
public final class OPMonitorFeatureGatingWrapper: NSObject {
    private class var dependency: OPProbeConfigDependency? {
        return InjectedOptional<OPProbeConfigDependency>().wrappedValue// user:global
    }

    public class var defaultReportToTea: Bool {
        return Self.dependency?.getFeatureGatingBoolValue(for: "openplatform.upload.monitor.tea") ?? false
    }
}
