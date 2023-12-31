//
//  LongPicTrackHelper.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/4/1.
//
import SKCommon
import SKUIKit
import EENavigator

struct LongPicMakeTracksParams {
    var device: String {
        return UIDevice.modelName
    }
    
    var systemVersion: String {
        return UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }
    
    var totalElaspedTime: TimeInterval = 0
    
    var imageCount: UInt32 = 0
    var widthPerImage: UInt32 = 0
    var heightPerImage: UInt32 = 0
    var imageWidth: UInt32 = 0
    var imageHeight: UInt32 = 0
    var fileSize: UInt64 = 0 //kb
    
    private var writeElaspedTimes: [TimeInterval] = []
    private var pixelsElaspedTimes: [TimeInterval] = []
    
    var elaspedTimePerImage: TimeInterval {
        guard imageCount != 0 else {
            return 0
        }
        return totalElaspedTime / TimeInterval(imageCount)
    }
    var writeElaspedTimePerImage: TimeInterval {
        guard imageCount != 0 else {
            return 0
        }
        
        let totalTimeinterval = writeElaspedTimes.reduce(0) { (result, next) -> TimeInterval in
            return result + next
        }
        
        return totalTimeinterval / TimeInterval(imageCount)
    }
    var pixelsElaspedTime: TimeInterval {
        guard imageCount != 0 else {
            return 0
        }
        
        let totalTimeinterval = pixelsElaspedTimes.reduce(0) { (result, next) -> TimeInterval in
            return result + next
        }
        
        return totalTimeinterval / TimeInterval(imageCount)
    }
    
    var retryCount: Int = 0
    
    mutating func increaseRetryCount() {
        retryCount += 1
    }
    
    mutating func insertWriteElaspedTime(_ time: TimeInterval) {
        writeElaspedTimes.append(time)
    }
    
    mutating func insertExportPixelsElaspedTime(_ time: TimeInterval) {
        pixelsElaspedTimes.append(time)
    }
    
    var params: [String: Any] {
        let param = ["device": device,
                     "systemVersion": systemVersion,
                     "totalElaspedTime": totalElaspedTime,
                     "imageCount": imageCount,
                     "widthPerImage": widthPerImage,
                     "heightPerImage": heightPerImage,
                     "imageWidth": imageWidth,
                     "imageHeight": imageHeight,
                     "fileSize": fileSize,
                     "elaspedTimePerImage": elaspedTimePerImage,
                     "pixelsElaspedTimes": pixelsElaspedTime,
                     "writeElaspedTimePerImage": writeElaspedTimePerImage,
                     "retryCount": retryCount] as [String: Any]
        return param
    }
}
