//
//  ViewDeviceSetting.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_ViewDeviceSetting
public struct ViewDeviceSetting: Equatable {
    public init() {}

    public var video: Video = Video()

    public struct Video: Equatable {
        public init() { }

        public var mirror: Bool = false

        /// 背景虚化
        public var backgroundBlur: Bool = false

        /// 背景虚化选中图片的id
        public var virtualBackground: String = ""

        public var advancedBeauty: String = ""
    }
}

extension ViewDeviceSetting: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_ViewDeviceSetting

    init(pb: Videoconference_V1_ViewDeviceSetting) {
        self.video.mirror = pb.video.mirror
        self.video.backgroundBlur = pb.video.backgroundBlur
        self.video.advancedBeauty = pb.video.advancedBeauty
        self.video.virtualBackground = pb.video.virtualBackground
    }
}

extension ViewDeviceSetting.Video: CustomStringConvertible {
    public var description: String {
        String(
            indent: "Video",
            "mirror=\(mirror.toInt)",
            "bgBlur=\(backgroundBlur.toInt)",
            "bg=\(virtualBackground)",
            "beauty=\(advancedBeauty)"
        )
    }
}
