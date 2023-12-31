//
//  LarkImagePerformancePlugin.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/28.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging

final class LarkImagePerformancePlugin: PerformancePlugin {

    private static let logger = Logger.log(LarkImagePerformancePlugin.self, category: "ByteWebImage")

    let identifier: String = "com.bytedance.lark.image.performance"

    func receivedRecord(_ record: PerformanceRecorder) {
        guard let newRecord = record.copy() as? PerformanceRecorder else { return }
        let totalTime = NSNumber(value: newRecord.endTime - newRecord.startTime)
        let cacheSeekTime = NSNumber(value: newRecord.cacheSeekEnd - newRecord.cacheSeekBegin)
        let cacheTime = NSNumber(value: newRecord.cacheEnd - newRecord.cacheBegin)
        let downloadTime = NSNumber(value: newRecord.downloadEnd - newRecord.downloadBegin)
        let decryptTime = NSNumber(value: newRecord.decryptEnd - newRecord.decryptBegin)
        let decodeTime = NSNumber(value: newRecord.decodeEnd - newRecord.decodeBegin)
        let logId = newRecord.contexID ?? newRecord.identifier
        let logInfo: [String: String] = [
            "image_type": newRecord.imageType.description,
            "context_id": newRecord.contexID ?? "",
            "image_key": newRecord.imageKey,
            "cache_type": newRecord.cacheType.description,
            "total_time": totalTime.stringValue,
            "cache_seek_ime": cacheSeekTime.stringValue,
            "cache_time": cacheTime.stringValue,
            "download_time": downloadTime.stringValue,
            "decrypt_time": decryptTime.stringValue,
            "decode_time": decodeTime.stringValue,
            "sdk_time": "\(newRecord.rustCost ?? [:])",
            "source_file_info": newRecord.sourceFileInfo?.description ?? ""
         ]
        // 打印log
        if newRecord.error == nil || newRecord.error?.code == 0 {
            // disable-lint: magic number
            if totalTime.doubleValue > 0.5 {
                // 总耗时大于500ms
                Self.logger.info(logId: logId,
                                 "load image success",
                                 params: logInfo)
            }
            // enable-lint: magic number
            // 异常大图监控
            if [.none, .disk].contains(newRecord.cacheType),
               // 原图大小大于等于 normalImage.pxValue，就算是大图
               newRecord.originSize.width * newRecord.originSize.height >=
                CGFloat(LarkImageService.shared.imageSetting.downsample.normalImage.pxValue) {
                let metric: [String: Any] = [
                    "resourcePixelProduct": newRecord.originSize.width * newRecord.originSize.height,
                    "resourceWidth": newRecord.originSize.width,
                    "resourceHeight": newRecord.originSize.height,
                    "loadPixelProduct": newRecord.loadSize.width * newRecord.loadSize.height,
                    "loadWidth": newRecord.loadSize.width,
                    "loadHeight": newRecord.loadSize.height,
                    "resourceLength": newRecord.receiveSize,
                ]
                let category: [String: Any] = [
                    "imageType": newRecord.imageType.description,
                ]
                let extra: [String: Any] = [
                    "imageKey": newRecord.imageKey,
                    "sourceFileInfo": newRecord.sourceFileInfo?.description ?? "",
                ]
                let eventName = "bytewebimage_huge_image"
                let event = SlardarEvent(name: eventName, metric: metric, category: category, extra: extra)
                Tracker.post(event)
                Self.logger.info("load huge image \(eventName): \(metric) \(category) \(extra)")
            }
        } else if newRecord.error?.code == ByteWebImageErrorUserCancelled {
            // 逻辑上需要cancel的不要记录
        } else {
            var errorInfo = logInfo
            errorInfo["errorCode"] = NSNumber(value: newRecord.error?.code ?? 0).stringValue
            errorInfo["errorMsg"] = newRecord.error?.localizedDescription ?? ""
            newRecord.error?.userInfo.forEach({ key, value in
                errorInfo[key] = value
            })
            Self.logger.error(logId: logId, "load image failed", params: errorInfo)
        }
    }

    func receiveDownloadInfo(key: String, downloadInfo: ImageDownloadInfo) {
        Self.logger.info("load image procedure [Download] key: \(key), downloadInfo: \(downloadInfo)")
    }

    func receiveDecodeInfo(key: String, decodeInfo: ImageDecodeInfo) {
        Self.logger.info("load image procedure [Decode] key: \(key), decodeInfo: \(decodeInfo)")
    }
}
