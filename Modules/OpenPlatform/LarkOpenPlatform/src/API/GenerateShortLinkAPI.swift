//
//  GenerateShortLinkAPI.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2021/1/8.
//

import Foundation
import LarkContainer

/// [Applink长短链API文档](https://bytedance.feishu.cn/docs/doccns3cLqIGRuJ27qdS8r4SS7d)

extension OpenPlatformAPI {
    /// applink 长链换短链 API 组装
    /// - Parameters:
    ///   - link: 原始的applink长链，必填，需要符合applink协议
    ///   - businessTag: 请求的业务方来源标识，必填，字符串，业务方自定义自己的来源名称，用于业务后续跟踪投放效果使用、主动失效时需校验
    ///   - token: 指定的最终短链的key，可不填
    ///   - expiration: 短链有效期，单位：秒，0表示永久
    static func generateShortLinkAPI(
        link: String, businessTag: String, token: String? = nil, expiration: Int64, resolver: UserResolver
    ) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .generateShortAppLink, resolver: resolver)
            .setScope(.parseApplink)
            .appendParam(key: .link, value: link)
            .appendParam(key: .businessTag, value: businessTag)
            .appendParam(key: .token, value: token)
            .appendParam(key: .expiration, value: String(expiration) /* 实际格式为 string */)
    }
}

class GenerateShortAppLinkResponse: APIResponse {
    /// 生成的短链
    var shortLink: String? {
        return json["data"]["shortLink"].string
    }

    /// 传入的长链
    var link: String? {
        return json["data"]["link"].string
    }

    /// 传入的业务方来源标识
    var businessTag: String? {
        return json["data"]["businessTag"].string
    }

    /// 传入的token/生成的短链key
    var token: String? {
        return json["data"]["token"].string
    }

    /// 短链有效期，单位：秒
    var expiration: Int64? {
        if let expirationStr = json["data"]["expiration"].string {
            return Int64(expirationStr)
        }
        return nil
    }
}
