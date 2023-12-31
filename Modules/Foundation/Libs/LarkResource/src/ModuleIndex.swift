//
//  ModuleIndex.swift
//  LarkResource
//
//  Created by 李晨 on 2020/3/6.
//

import Foundation
import EEAtomic

final class Module {
    static let autoBundleSuffix: String = "Auto.bundle"

    static func indexTable(_ moduleName: String, _ bundleURL: URL) -> IndexTable? {
        let bundlePath = bundleURL.path
        let indexPath = bundleURL
            .appendingPathComponent(ResourceManager.indexFileName)
            .path
        return ResourceIndexTable(
            name: moduleName,
            indexFilePath: indexPath,
            bundlePath: bundlePath
        )
    }
}
