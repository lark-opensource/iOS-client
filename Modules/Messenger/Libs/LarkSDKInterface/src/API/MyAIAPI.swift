//
//  MyAIAPI.swift
//  LarkSDKInterface
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import ServerPB
import RustPB
import RxSwift

public protocol MyAIAPI {
    func initMyAI(name: String, avatarKey: String) -> Observable<RustPB.Im_V1_InitMyAIResponse>
    func enterMyAIChat(chatID: Int64) -> Observable<ServerPB.ServerPB_Office_ai_EnterMyAIChatResponse>
    func pullOnboardInfo(chatID: Int64) -> Observable<ServerPB.ServerPB_Office_ai_PullOnboardInfoResponse>
    func putOnboard(chatID: Int64) -> Observable<ServerPB.ServerPB_Office_ai_PutOnboardResponse>
    func newMyAITopic(chatID: Int64, aiChatModeID: Int64?, sceneID: Int64?, chatContext: ServerPB_Entities_ChatContext?) -> Observable<ServerPB.ServerPB_Office_ai_AIChatNewTopicResponse>
    func updateAIProfile(name: String?, avatarKey: String?) -> Observable<RustPB.Contact_V2_UpdateAIProfileResponse>
    func getAIProfileInfomation(aiID: String?, forceServer: Bool) -> Observable<RustPB.Contact_V2_GetAIProfileResponse>
    func getThreadByAIChatModeID(aiChatModeID: Int64, chatID: Int64, chatContext: Basic_V1_ChatContext) -> Observable<RustPB.Im_V1_GetThreadByAIChatModeIDResponse>
    func getAIChatModeThreadState(aiChatModeID: String) -> Observable<ServerPB_Entities_ThreadState>
    func getAIChatModeId(appScene: String?, link: String?, appData: String?) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeInitResponse>
    func getChatMyAIInitInfo(scenarioChatID: Int64?, needRenew: Bool) -> Observable<ServerPB.ServerPB_Chats_GetChatMyAIInitInfoResponse>
    func closeChatMode(aiChatModeID: String) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseResponse>
    func transformMarkdownToRichText(markdown: String) -> Observable<Basic_V1_RichText>
    func getSummarizeQuickAction() -> Observable<ServerPB_Office_ai_QuickAction>
    func fetchQuickActionByID(actionID: String, myAIChatID: String, aiChatModeID: String, chatContextInfo: [String: String]) -> Observable<ServerPB_Office_ai_FetchQuickActionByIDResponse>
}
