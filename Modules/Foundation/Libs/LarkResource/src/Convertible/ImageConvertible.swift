//
//  ImageConvertible.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import UIKit
import Foundation

extension UIImage: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<UIImage> { (result: MetaResource, _: OptionsInfoSet) throws -> UIImage in
        switch result.index.value {
        case .string(let value):
            switch result.index.type {
            case .assetPath:
                if let image = UIImage(named: value, in: result.index.bundle, compatibleWith: nil) {
                    return image
                }
            case .bundlePath:
                var filePath = result.index.bundle.bundlePath.appending("/\(value)")
                // lint:disable:next lark_storage_check - 读 bundle 数据
                if let data = NSData(contentsOfFile: filePath) as Data? {
                    // 图片倍率处理
                    var scale = 1.0
                    if let index = value.lastIndex(of: "@") {
                        if let i = value.index(index, offsetBy: 1, limitedBy: value.endIndex) {
                            var s = String(value[i])
                            scale = Double(s) ?? scale
                        }
                    }

                    if let image = UIImage(data: data, scale: CGFloat(scale)) {
                        return image
                    }
                }
            default:
                break
            }
        case .data(let data):
            if let image = UIImage(data: data) {
                return image
            }
        default:
            break
        }
        throw ResourceError.transformFailed
    }
}
