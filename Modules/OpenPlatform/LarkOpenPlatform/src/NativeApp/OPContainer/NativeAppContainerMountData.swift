//
//  NativeAppContainerMountData.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/28.
//

import Foundation
import OPSDK

@objcMembers public class NativeAppContainerMountData: NSObject, OPContainerMountDataProtocol {
    public var launcherFrom: String?
    
    
    public let scene: OPAppScene
    
    public required init(scene: OPAppScene) {
        self.scene = scene
    }
    
}
