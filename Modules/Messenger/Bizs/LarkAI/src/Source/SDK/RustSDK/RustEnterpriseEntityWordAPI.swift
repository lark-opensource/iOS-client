//
//  RustEnterpriseEntityWordAPI.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/1/12.
//

import Foundation
import RxSwift
import LarkSDKInterface
import RustPB
import LKCommonsLogging
import ServerPB
import LarkLocalizations
import LarkRustClient
import LarkContainer

final class RustEnterpriseEntityWordAPI: EnterpriseEntityWordAPI, UserResolverWrapper {
    let userResolver: UserResolver
    let rustService: RustService?
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.rustService = try? userResolver.resolve(assert: RustService.self)
    }

    /// 用户点击了有帮助按钮
    func sendAbbreviationFeedbackRequet(cardId: String, actionType: ServerPB_Enterprise_entitiy_UserCardActionRequest.ActionType) -> Observable<ServerPB_Enterprise_entitiy_UserCardActionResponse> {
        var reqest = ServerPB.ServerPB_Enterprise_entitiy_UserCardActionRequest()
        reqest.cardID = cardId
        reqest.type = actionType
        return rustService?.sendPassThroughAsyncRequest(reqest, serCommand: .enterpriseTopicUserCardAction) ?? .empty()
    }

    /// 请求实体词内容
    func getAbbreviationInfomation(abbrId: String, query: String) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_GetEnterpriseTopicResponse> {
        var request = ServerPB.ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest()
        request.locale = LanguageManager.currentLanguage.localeIdentifier
        request.scene = .messenger
        request.method = .click
        request.abbrID = abbrId
        request.query = query
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .getEnterpriseTopic) ?? .empty()
    }

    /// 请求实体词卡片V2 https://bytedance.feishu.cn/docs/doccnjVV2eRbia2OpvIO7DUYE7e
    func getAbbreviationInfomationV2(abbrId: String, query: String, biz: String, scene: String) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_MGetEntityCardResponse> {
        var request = ServerPB.ServerPB_Enterprise_entitiy_MGetEntityCardRequest()
        request.key = query
        request.entityIds = [abbrId]
        request.biz = biz
        request.scene = scene
        request.renderType = .gecko
        request.isGroup = true
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .getAbbreviationCard) ?? .empty()
    }

    /// 查询整句是否有实体词
    func queryMessageAbbreviationInfomation(query: String) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_GetEnterpriseTopicResponse> {
        var request = ServerPB.ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest()
        request.locale = LanguageManager.currentLanguage.localeIdentifier
        request.scene = .messenger
        request.method = .query
        request.abbrID = ""
        request.query = query
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .getEnterpriseTopic) ?? .empty()
    }

    /// 查询输入框中企业百科的高亮信息
    func getLingoHighlight(texts: [String], chatId: String?, messageId: String?) -> Observable<ServerPB.ServerPB_Enterprise_entitiy_BatchRecallResponse> {
        var request = ServerPB.ServerPB_Enterprise_entitiy_BatchRecallRequest()
        request.texts = texts
        request.enterFrom = "im_input_box"
        if let messageId = messageId {
            request.spaceID = chatId ?? ""
            request.spaceSubID = messageId
        }
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .getBatchRecall) ?? .empty()
    }
}
