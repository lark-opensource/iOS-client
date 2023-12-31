//
//  Dependency.swift
//  UGContainerDev
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation
import UGContainer

class Dependency: PluginContainerDependency {
    func reportEvent(event: ReachPointEvent) {
        print("XXXXXXXX Dependency reportEvent \(event)")
    }
}
