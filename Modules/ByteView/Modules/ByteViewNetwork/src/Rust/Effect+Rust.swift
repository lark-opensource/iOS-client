//
//  Effect+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBGetVcVirtualBackgroundResponse = Videoconference_V1_GetVcVirtualBackgroundResponse

extension PBGetVcVirtualBackgroundResponse.VirtualBackgroundInfo {
    var vcType: VirtualBackgroundInfo {
        .init(key: key, name: name, url: url, path: path, isVideo: isVideo, isCustom: isCustom, isMiss: isMiss,
              thumbnail: thumbnail, portraitPath: portraitPath,
              fileStatus: .init(rawValue: fileStatus.rawValue) ?? .unSyncServer,
              source: .init(rawValue: source.rawValue) ?? .unknown)
    }
}
