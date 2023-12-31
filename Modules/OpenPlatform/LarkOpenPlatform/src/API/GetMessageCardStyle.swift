//
//  GetMessageCardStyle.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/5/27.
//

import Foundation
import SwiftyJSON
import LarkContainer

/// [消息卡片样式获取文档](https://bytedance.feishu.cn/docs/doccngzVVqULcLy1NA18nzl2UFP#)

class OpenPlatformAPICustomURL: OpenPlatformAPI {
    /// 原始URL
    var customUrl: String
    required init(path: APIUrlPath, customUrl: String, resolver: UserResolver) {
        self.customUrl = customUrl
        super.init(path: path, resolver: resolver)
        let url = URL(string: customUrl)
        let _ = setScope(.customURL(url?.host ?? "", url?.path ?? ""))
    }
    override func getParameters() -> [String : Any]? {
        return parameters.isEmpty ? nil : parameters
    }
}

extension OpenPlatformAPI {
    /// 获取消息卡片样式信息
    static func getMessageCardStyleAPI(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getMessageCardStyle, resolver: resolver)
            .setScope(.messageCardStyle)
            .useSession()
    }
}

class GetMessageCardStyleResponse: APIResponse {
    /// 窄版样式
    var narrow: JSON? {
        return json["narrow"]
    }

    /// 宽版样式
    var wide: JSON? {
        return json["wide"]
    }
}
