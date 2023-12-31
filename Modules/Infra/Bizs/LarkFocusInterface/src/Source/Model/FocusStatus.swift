//
//  FocusStatusDependency.swift
//  LarkFocusInterface
//
//  Created by 白镜吾 on 2023/1/6.
//

import Foundation
import RustPB

public protocol FocusStatus {
    var title: String { get }
    var iconKey: String { get }
    var effectiveInterval: FocusEffectiveTime { get }
}
