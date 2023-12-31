//
//  MessageImage.swift
//  Lark
//
//  Created by linlin on 2017/6/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import Photos
import Reachability
import MobileCoreServices
import ByteWebImage
import LarkSDKInterface
import LarkSetting
import LarkMessengerInterface
import LKCommonsLogging
import AppReciableSDK

extension UIImage {
    // NOTE: 表情支持压缩之后删除压缩逻辑
    func compressTo(_ sizeInBytes: Int) -> UIImage? {
        var needCompress: Bool = true
        var imgData: Data?
        var compressingValue: CGFloat = 1.0
        while needCompress && compressingValue > 0.0 {
            if let data: Data = self.jpegData(compressionQuality: compressingValue) {
                if data.count < sizeInBytes {
                    needCompress = false
                    imgData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }
        if let data = imgData {
            if data.count < sizeInBytes {
                return try? ByteImage(data)
            }
        }
        return nil
    }

    func compressImage(compressSize: Int? = nil) -> UIImage? {
        let wifi_file_size = 1024 * 1024 // wifi下压缩到1M
        let cellular_size = 500 * 1024   // 蜂窝网路压缩到0.5M
        let compressSize = compressSize ?? (((Reachability()?.connection ?? .none) == .wifi) ? wifi_file_size : cellular_size)
        return self.compressTo(compressSize)
    }

    func compressImageData(compressSize: Int? = nil) -> Data? {
        return compressImage(compressSize: compressSize).flatMap { $0.jpegData(compressionQuality: 1) }
    }
}
