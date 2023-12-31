//
//  Reachability.swift
//  ByteView
//
//  Created by kiri on 2020/9/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Reachability
import ByteViewTracker

extension Reachability {
    static let shared: Reachability = Reachability.vc.shared
}
