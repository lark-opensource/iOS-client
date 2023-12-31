//
//  NativeAppGuideInfoListModel.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/5/16.
//

import Foundation
import NativeAppPublicKit

public struct NativeAppGuideInfoListModel: Codable {
    let guideInfos: [String: NativeGuideInfo]

    private enum CodingKeys: String, CodingKey {
        case guideInfos = "guide_infos"
    }
}

public struct NativeGuideInfo: Codable {
    let code: NativeAppGuideInfoType
    let tip: [String: [String: String]]

    private enum CodingKeys: String, CodingKey {
        case code = "code"
        case tip = "tip"
    }
}
