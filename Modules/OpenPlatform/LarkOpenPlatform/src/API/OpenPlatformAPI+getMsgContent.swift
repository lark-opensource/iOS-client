//
//  OpenPlatformAPI+getMsgContent.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/10/12.
//

import Foundation
import LarkFoundation
import LarkAccountInterface
import LKCommonsLogging
import SwiftyJSON
import EEMicroAppSDK
import LarkContainer

/// 获取Message Action对应的消息内容
extension OpenPlatformAPI {
    public static func getMessageContentAPI(triggerCode: String,
                                            messageIds: [String],
                                            appid: String,
                                            resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getMsgListContent, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .useSessionKey(sessionKey: .Cookie)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .appendParam(key: .trigger_code, value: triggerCode)
            .appendParam(key: .message_ids, value: messageIds)
            .appendParam(key: .app_id, value: appid)
            .useLocale()
            .useEncrypt()
            .setScope(.messageActionContent)
    }
}
final class GetMessageDetailAPIResponse: APIResponse {
    /// 对参数加密
    var cipher: EMANetworkCipher?

    /// 重写初始化方法，记录原始的密钥cipher
    /// - Parameters:
    ///   - json: 后端返回的json
    ///   - api: 原始请求
    required init(json: JSON, api: OpenPlatformAPI) {
        super.init(json: json, api: api)
        cipher = api.cipher
    }
}
