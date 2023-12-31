//
//  VideoPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct VideoPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .video, "type unmatched!")

        var video = base?.video ?? .init()
        let baseVideo = base?.video ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .site: video.site = .init(rawValue: Int(value.i32)) ?? baseVideo.site
            case .coverImage: video.coverImage = value.imageSet
            case .coverImageURL: video.coverImageURL = value.str
            case .duration: video.duration = value.i64
            case .srcURL: video.srcURL = value.str
            case .vid: video.vid = value.str
            case .iframeURL: video.iframeURL = value.str
            @unknown default: return
            }
        }
        return .video(video)
    }
}
