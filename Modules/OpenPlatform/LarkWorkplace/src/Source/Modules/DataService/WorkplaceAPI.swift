//
//  WorkplaceAPI.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/7/8.
//

import Foundation
import LarkRustClient
import LarkContainer

/// 工作台 Rust API 基类
class WorkplaceAPI {

    let rustService: RustService

    init(rustService: RustService) {
        self.rustService = rustService
    }
}
