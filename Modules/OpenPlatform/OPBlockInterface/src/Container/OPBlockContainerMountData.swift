//
//  OPBlockContainerMountData.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/18.
//

import Foundation
import OPSDK

@objc public protocol OPBlockContainerMountDataProtocol: OPContainerMountDataProtocol {
    
}

@objcMembers public final class OPBlockContainerMountData: NSObject, OPBlockContainerMountDataProtocol {
    public var launcherFrom: String?
    
    public let scene: OPAppScene
    
    public required init(scene: OPAppScene) {
        self.scene = scene
    }
    
}
