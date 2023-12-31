//
//  MicrophoneCameraToastConfig.swift
//  ByteView
//
//  Created by Prontera on 2021/12/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会议共享屏幕是否开启共享音频配置，https://cloud.bytedance.net/appSettings/config/124305/detail/status
/// vc_show_mic_camera_mute_toast_config https://cloud.bytedance.net/appSettings-v2/detail/config/154425/detail/status
// disable-lint: magic number
public struct MicrophoneCameraToastConfig {
    public let needShowLoadingToast: Bool
    public let showLoadingToastMS: Int
    public let loadingToastDurationMS: Int
    public let needCheckNetworkDisconnected: Bool

    static let `default` = MicrophoneCameraToastConfig(needShowLoadingToast: true,
                                                       showLoadingToastMS: 1000,
                                                       loadingToastDurationMS: 2000,
                                                       needCheckNetworkDisconnected: true)
}

extension MicrophoneCameraToastConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case needShowLoadingToast
        case showLoadingToastMs
        case loadingToastDurationMs
        case needCheckNetworkDisconnected
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        needShowLoadingToast = try values.decode(Int.self, forKey: .needShowLoadingToast) > 0
        showLoadingToastMS = try values.decode(Int.self, forKey: .showLoadingToastMs)
        loadingToastDurationMS = try values.decode(Int.self, forKey: .loadingToastDurationMs)
        needCheckNetworkDisconnected = try values.decode(Int.self, forKey: .needCheckNetworkDisconnected) > 0
    }
}
