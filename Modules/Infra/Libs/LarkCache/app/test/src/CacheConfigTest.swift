//
//  CacheConfigTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/8/17.
//

import Foundation
import XCTest
@testable import LarkCache

extension CacheConfig {
    init(biz: Biz.Type, cacheDirectory: CacheDirectory, cleanIdentifier: String) {
        self.init(relativePath: biz.fullPath, cacheDirectory: cacheDirectory, cleanIdentifier: cleanIdentifier)
    }
}
