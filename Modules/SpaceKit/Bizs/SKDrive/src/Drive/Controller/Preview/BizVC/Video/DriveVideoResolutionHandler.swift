//
//  DriveVideoResolutionHandler.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/1/14.
//

import Foundation
import SKCommon
import SKFoundation

class DriveVideoResolutionHandler {

    private let video: DriveVideo

    // 默认使用高分辨率，比如"1080P"；用于UI界面显示分辨率，需要使用大写
    var currentResolution: String?
    
    var currentUrl: String? {
        if let urlstr = self.video.info?.transcodeURLs?[currentResolution?.lowercased() ?? ""] {
            if let url = URL(string: urlstr), let extra = video.authExtra {
                let newURL = url.docs.addQuery(parameters: ["extra": extra])
                return newURL.absoluteString
            } else {
                return urlstr
            }
        } else {
            spaceAssertionFailure("should not run here")
            DocsLogger.warning("should not run here, no server transcode url: \(currentResolution ?? "")")
            return video.info?.transcodeURLs?.first?.value
        }
    }
    // https://bytedance.feishu.cn/wiki/wikcnBaAeswVCF0HiYJBlD3Fcne
    // 预加载时需要提供唯一 vid，目前 iOS 预加载时使用的 vid 格式如下，使用token、dataVersion、分辨率来唯一确定一个视频文件
    var taskKey: String {
        let cacheKey = video.cacheKey
        let resolutionKey = currentResolution ?? "default"
        return "\(cacheKey)_\(resolutionKey)"
    }

    init(video: DriveVideo) {
        self.video = video
        currentResolution = video.resolutionDatas.count > 0 ? video.resolutionDatas.last : nil
        DocsLogger.driveInfo("cur resolution: \(currentResolution ?? "")")
    }

    func handleResolutionDatas(event: (_ isSelected: Bool, _ resolution: String) -> Void) {
        for resolution in video.resolutionDatas {
            var isSelected: Bool = false
            if resolution == self.currentResolution {
                isSelected = true
            }
            event(isSelected, resolution)
        }
    }
}
