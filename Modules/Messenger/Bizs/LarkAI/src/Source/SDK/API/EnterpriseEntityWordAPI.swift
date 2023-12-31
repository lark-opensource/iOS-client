//
//  EnterpriseEntityWordAPI.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/1/12.
//

import Foundation
import RxSwift
import ServerPB

public protocol EnterpriseEntityWordAPI {

    /// 用户点击了有帮助按钮
    /// - Parameters:
    ///   - cardId: 实体词id
    ///   - actionType: 用户操作，详见：ServerPB_Enterprise_entitiy_UserCardActionRequest.ActionType
    func sendAbbreviationFeedbackRequet(cardId: String, actionType: ServerPB_Enterprise_entitiy_UserCardActionRequest.ActionType) -> Observable<ServerPB_Enterprise_entitiy_UserCardActionResponse>

    /// 查询企业实体词内容
    /// - Parameters:
    ///   - abbrId: 实体词id
    ///   - query: 实体词
    func getAbbreviationInfomation(abbrId: String, query: String) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_GetEnterpriseTopicResponse>

    func getAbbreviationInfomationV2(abbrId: String, query: String, biz: String, scene: String) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_MGetEntityCardResponse>

    /// 查询整句是否有实体词
    /// - Parameter query: 消息内容
    func queryMessageAbbreviationInfomation(query: String) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_GetEnterpriseTopicResponse>

    /// 查询输入框内企业百科的高亮信息
    /// - Parameters:
    ///   - texts: 输入的内容
    ///   - chatId: 实体词id
    ///   - messageId: 会话Id
    ///   后两个字段是为了实现已发送消息二次编辑时候忽略高亮信息的查询
    func getLingoHighlight(texts: [String], chatId: String?, messageId: String?) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_BatchRecallResponse>
}
