//
//  Model.swift
//  LarkAssertConfig
//
//  Created by ByteDance on 2023/2/16.
//

import Foundation
import EEAtomic


enum AssertDirResult {
    case notConfig    
    case shouldAssert(Bool)
}

func assertResult(file: StaticString) -> AssertDirResult {
    guard let assertConfig = configReader.assetConfig() else { return .notConfig }
    if assertConfig.contains("all") {
        return .shouldAssert(true)
    } else if assertConfig.contains("none") {
        return .shouldAssert(false)
    } else if assertConfig.contains("disable") {
        return .notConfig
    } else {
        return .shouldAssert(assertConfig.contains(where: { file.description.contains($0) }))
    }
}

let configReader = ConfigReader()

class ConfigReader {
    @AtomicObject private var assert_config: [String]?
    func assetConfig() -> [String]? {
        if let assert_config { return assert_config }

        // lint:disable lark_storage_check - bundle 读场景，无需检查
        guard let configPath = BundleConfig.LarkAssertConfigBundle.path(forResource: "assert_dir_config", ofType: nil),
              let config = try? String(contentsOfFile: configPath) else {
            return nil
        }
        // lint:enable lark_storage_check
        
        let result = config.trimmingCharacters(in: .whitespacesAndNewlines).filter { !["[", "]", " "].contains($0) }.split(separator: ",").map(String.init)
        assert_config = result
        return assert_config
    }
}
