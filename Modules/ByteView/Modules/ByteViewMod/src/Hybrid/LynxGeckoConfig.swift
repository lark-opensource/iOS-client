//
//  LynxTemplateIdentity.swift
//  ByteViewHybrid
//
//  Created by Tobb Huang on 2022/11/3.
//

import Foundation
import LarkEnv

struct LynxGeckoConfig: Equatable {
    let accessKey: String
    let channel: String
}

extension LynxGeckoConfig {
    static let feishu: LynxGeckoConfig = {
        switch EnvManager.env.type {
        case .staging:
            return .init(accessKey: "75f440d6ecd50b053b702b7fa9c826d3", channel: "test-lynx")
        case .preRelease:
            return .init(accessKey: "9cbd99f179aa96e5430a0c4c39c83c6a", channel: "vc-lynx")
        default: // release
            return .init(accessKey: "35402f72cf2f73fa4afbc5fccaa53f73", channel: "vc-lynx")
        }
    }()

    static let lark: LynxGeckoConfig = {
        switch EnvManager.env.type {
        case .staging:
            return .init(accessKey: "75f440d6ecd50b053b702b7fa9c826d3", channel: "test-lynx")
        case .preRelease:
            return .init(accessKey: "ca337d79779315d04ca9f84f690456d1", channel: "vc-lynx")
        default: // release
            return .init(accessKey: "94148ce4f6a8531f106763d2fd835e66", channel: "vc-lynx")
        }
    }()
}
