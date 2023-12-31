//
//  MessageCardModel.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/5/1.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import OPSDK

final class OpenAPISendMessageCardParams: OpenAPIBaseParams {
    /// 卡片内容必须传
    @OpenAPIOptionalParam(jsonKey: "cardContent")
    public var cardContent: [AnyHashable: Any]?
    /// 是否走选人发卡片流程
    @OpenAPIRequiredParam(userOptionWithJsonKey: "shouldChooseChat", defaultValue: false)
    public var shouldChooseChat: Bool
    /// 选人发卡片的选人过滤参数
    @OpenAPIOptionalParam(jsonKey: "chooseChatParams")
    public var chooseChatParams: [AnyHashable: Any]?
    /// 指定人发卡片人的 openChatIDs
    @OpenAPIOptionalParam(jsonKey: "openChatIDs")
    public var openChatIDs: [String]?
    /// 指定人发卡片人的 openIDs
    @OpenAPIOptionalParam(jsonKey: "openIDs")
    public var openIDs: [String]?
    /// 不指定和triggerCode绑定当前会话
    @OpenAPIOptionalParam(jsonKey: "triggerCode")
    public var triggerCode: String?
    /// withAdditionalMessage 则可以开启附带留言能力
    @OpenAPIOptionalParam(jsonKey: "withAdditionalMessage")
    public var withAdditionalMessage: Bool?
    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_cardContent, _shouldChooseChat, _chooseChatParams, _openChatIDs, _openIDs, _triggerCode, _withAdditionalMessage]
    }
}
/// https://open.feishu.cn/document/uYjL24iN/uUjN5UjL1YTO14SN2kTN
final class OpenAPISendMessageCardResult: OpenAPIBaseResult {
    /// 错误码
    public let errCode: Int
    /// 错误描述
    public let errMsg: String
    /// 发送失败的会话的openChatID列表
    public let failedOpenChatIDs: [String]
    /// 发送消息卡片的message信息
    public let sendCardInfo: [[AnyHashable: Any]]?
    /// 发送消息卡片的留言信息
    public let additionalMessageInfo: [[AnyHashable: Any]]?
    /// 初始化方法
    public init(errCode: Int,
                errMsg: String,
                failedOpenChatIDs: [String],
                sendCardInfo: [[AnyHashable: Any]]?) {
        self.errCode = errCode
        self.errMsg = errMsg
        self.failedOpenChatIDs = failedOpenChatIDs
        self.sendCardInfo = sendCardInfo
        self.additionalMessageInfo = nil
        super.init()
    }
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        var result: [AnyHashable: Any] = [:]
        if errCode != 0 {
            result["errCode"] = errCode
            result["errMsg"] = errMsg
            result["failedOpenChatIDs"] = failedOpenChatIDs
            if let _sendInfo = sendCardInfo {
                result["sendCardInfo"] = _sendInfo
            }
        } else {
            if let _sendInfo = sendCardInfo {
                result["sendCardInfo"] = _sendInfo
            }
        }
        return result
    }
    /// 构造失败的返回结果
    public static func toJSONDict(sendCardInfo: [EMASendCardInfo]?,
                                  sendTextInfo: [EMASendCardAditionalTextInfo]?) -> [AnyHashable : Any]? {
        var result: [AnyHashable: Any] = [:]
        if let cardInfos = sendCardInfo {
            result["sendCardInfo"] = cardInfos.map({ info in
                return info.toJsonObject()
            })
        }
        if let textInfos = sendTextInfo {
            result["additionalMessageInfo"] = textInfos.map({ info in
                return info.toJsonObject()
            })
        }
        return result.isEmpty ? nil : result
    }
}
