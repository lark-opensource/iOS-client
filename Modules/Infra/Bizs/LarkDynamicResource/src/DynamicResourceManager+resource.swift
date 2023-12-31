//
//  DynamicResourceManager+resource.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/4/1.
//

import UIKit
import Foundation
import LarkLocalizations
import LarkResource
import LarkSetting

extension DynamicResourceManager {
    private var useHobby: Bool { FeatureGatingManager.realTimeManager.featureGatingValue(with: "lark.hobby.lark_resource_bundle_refactor") }
    
    private func jsonString(with value: Any) -> String? {
        var result: String?
        if let string = value as? String {
            result = string.isEmpty ? nil : string
        } else if let data = try? JSONSerialization.data(withJSONObject: value, options: []) {
            result = String(data: data, encoding: String.Encoding.utf8)
        }
        
        return result
    }
    
    public func getFeatureConfig(key: String) -> String? {
        if useHobby, let value = DynamicBrandManager.featureSwitch[key] { return jsonString(with: value) }
        else if couldUseDynamicResource(), let value = featureConfig[key] { return jsonString(with: value) }
        
        return nil
    }

    public func getFeatureConfig(reletivePath: String) -> String? {
        var featureString: String?
        if useHobby { featureString = DynamicBrandStorage.fetchFeatureConfig(relativePath: reletivePath) }
        else if couldUseDynamicResource() {
            let identifier = DynamicResourceHelper.identifier()
            // lint:disable lark_storage_check - 读资源文件，不涉及加解密，不进行统一存储检查
            if let path = DynamicResourceManager.shared.fetchValidResourcePath(by: identifier),
               let data = NSData(contentsOfFile: path.appending(reletivePath)) as Data? {
                featureString = String(data: data, encoding: String.Encoding.utf8)
            } else if let data = NSData(contentsOfFile: Bundle.main.bundleURL.appendingPathComponent("dynamic_resource.bundle").path.appending(reletivePath)) as Data? {
                featureString = String(data: data, encoding: String.Encoding.utf8)
            }
            // lint:enable lark_storage_check
        }
        return featureString
    }
}

extension DynamicResourceManager {
    func couldUseDynamicResource() -> Bool {
        return
            DynamicResourceHelper.shouldUseDynamicResource() &&
            DynamicResourceManager.shared.ready
    }
}
