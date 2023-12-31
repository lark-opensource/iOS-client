//
//  RustMyAIAPI.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import LarkSDKInterface
import ServerPB
import RustPB
import RxSwift
import LarkRustClient
import LarkContainer

final class RustMyAIAPI: MyAIAPI {
    /// SDKRustService才会把error通过transformToAPIError转为APIError，RustService并不会：SDKRustService封装了一层RustService
    private let rustService: SDKRustService?

    init(userResolver: UserResolver) {
        self.rustService = try? userResolver.resolve(assert: SDKRustService.self)
    }

    func initMyAI(name: String, avatarKey: String) -> Observable<RustPB.Im_V1_InitMyAIResponse> {
        guard let rustService = self.rustService else { return .just(Im_V1_InitMyAIResponse()) }

        var request = RustPB.Im_V1_InitMyAIRequest()
        request.avatarKey = avatarKey
        request.name = name
        return rustService.sendAsyncRequest(request)
    }

    func enterMyAIChat(chatID: Int64) -> Observable<ServerPB.ServerPB_Office_ai_EnterMyAIChatResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_EnterMyAIChatResponse()) }
        var request = ServerPB.ServerPB_Office_ai_EnterMyAIChatRequest()
        request.chatID = chatID

        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiEnterMyAiChat)
    }

    func pullOnboardInfo(chatID: Int64) -> Observable<ServerPB.ServerPB_Office_ai_PullOnboardInfoResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_PullOnboardInfoResponse()) }
        var request = ServerPB.ServerPB_Office_ai_PullOnboardInfoRequest()
        request.chatID = chatID
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiPullOnboardInfo)
    }

    func putOnboard(chatID: Int64) -> Observable<ServerPB.ServerPB_Office_ai_PutOnboardResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_PutOnboardResponse()) }
        var request = ServerPB.ServerPB_Office_ai_PutOnboardRequest()
        request.chatID = chatID
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiPutOnboard)
    }

    func newMyAITopic(chatID: Int64, aiChatModeID: Int64?, sceneID: Int64?, chatContext: ServerPB_Entities_ChatContext?) -> Observable<ServerPB.ServerPB_Office_ai_AIChatNewTopicResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_AIChatNewTopicResponse()) }
        var request = ServerPB.ServerPB_Office_ai_AIChatNewTopicRequest()
        request.chatID = chatID
        if let aiChatModeID = aiChatModeID { request.aiChatModeID = aiChatModeID }
        if let sceneID = sceneID { request.sceneID = sceneID }
        if let chatContext = chatContext { request.chatContext = chatContext }
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImNewTopic)
    }

    func updateAIProfile(name: String?, avatarKey: String?) -> Observable<RustPB.Contact_V2_UpdateAIProfileResponse> {
        guard let rustService = self.rustService else { return .just(Contact_V2_UpdateAIProfileResponse()) }

        if name == nil && avatarKey == nil {
            assertionFailure("all params are nil")
        }
        var request = RustPB.Contact_V2_UpdateAIProfileRequest()
        if let name = name {
            request.name = name
        }
        if let avatarKey = avatarKey {
            request.avatarKey = avatarKey
        }
        return rustService.sendAsyncRequest(request)
    }

    public func getAIProfileInfomation(aiID: String?, forceServer: Bool) -> Observable<RustPB.Contact_V2_GetAIProfileResponse> {
        guard let rustService = self.rustService else { return .just(Contact_V2_GetAIProfileResponse()) }

        var request = RustPB.Contact_V2_GetAIProfileRequest()
        request.syncDataStrategy = forceServer ? .forceServer : .local
        if let aiID = aiID {
            request.aiID = aiID //aiID不传的时候默认拉自己的myAI
        }
        return rustService.sendAsyncRequest(request)
    }

    func getThreadByAIChatModeID(aiChatModeID: Int64, chatID: Int64, chatContext: Basic_V1_ChatContext) -> Observable<RustPB.Im_V1_GetThreadByAIChatModeIDResponse> {
        guard let rustService = self.rustService else { return .just(Im_V1_GetThreadByAIChatModeIDResponse()) }

        var request = RustPB.Im_V1_GetThreadByAIChatModeIDRequest()
        request.aiChatModeID = aiChatModeID
        request.chatID = chatID
        request.chatContext = chatContext
        return rustService.sendAsyncRequest(request)
    }

    func getAIChatModeThreadState(aiChatModeID: String) -> Observable<ServerPB_Entities_ThreadState> {
        guard let rustService = self.rustService else { return .just(ServerPB_Entities_ThreadState()) }

        var request = ServerPB_Office_ai_PullAIChatModeThreadRequest()
        request.aiChatModeID = aiChatModeID
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiPullChatModeThread)
            .map { (response: ServerPB_Office_ai_PullAIChatModeThreadResponse) -> ServerPB_Entities_ThreadState in
                return response.status
            }
    }

    func getAIChatModeId(appScene: String?, link: String?, appData: String?) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeInitResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_AIChatModeInitResponse()) }

        var request = ServerPB.ServerPB_Office_ai_AIChatModeInitRequest()
        if let appScene = appScene {
            request.appScene = appScene
        }
        if let link = link {
            request.link = link
        }
        if let appData = appData {
            request.appData = appData
        }
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiChatModeInit)
    }

    func getChatMyAIInitInfo(scenarioChatID: Int64?, needRenew: Bool) -> Observable<ServerPB.ServerPB_Chats_GetChatMyAIInitInfoResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Chats_GetChatMyAIInitInfoResponse()) }
        var request = ServerPB_Chats_GetChatMyAIInitInfoRequest()
        request.scenarioChatID = scenarioChatID ?? 0
        request.needRenew = needRenew
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getChatMyAiInitInfo)
    }

    func closeChatMode(aiChatModeID: String) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseResponse()) }

        var request = ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseRequest()
        request.aiChatModeID = aiChatModeID
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiChatModeThreadClose)
    }

    func transformMarkdownToRichText(markdown: String) -> Observable<Basic_V1_RichText> {
        guard let rustService = self.rustService else { return .just(Basic_V1_RichText()) }
        var request = RustPB.Im_V1_TransformMarkdownToRichTextRequest()
        request.markdown = markdown
        return rustService.sendAsyncRequest(request).map { (response: RustPB.Im_V1_TransformMarkdownToRichTextResponse) -> Basic_V1_RichText in
            return response.richText
        }
    }

    func getSummarizeQuickAction() -> Observable<ServerPB_Office_ai_QuickAction> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_QuickAction()) }
        let request = ServerPB.ServerPB_Office_ai_GetSummarizeQuickActionRequest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiGetSummarizeAction)
            .map { (response: ServerPB.ServerPB_Office_ai_GetSummarizeQuickActionResponse) -> ServerPB_Office_ai_QuickAction in
                return response.quickAction
            }
    }

    func fetchQuickActionByID(actionID: String, myAIChatID: String, aiChatModeID: String, chatContextInfo: [String: String]) -> Observable<ServerPB_Office_ai_FetchQuickActionByIDResponse> {
        guard let rustService = self.rustService else { return .just(ServerPB.ServerPB_Office_ai_FetchQuickActionByIDResponse()) }
        var quickActionRequest = ServerPB_Office_ai_FetchQuickActionByIDRequest()
        quickActionRequest.actionID = actionID
        quickActionRequest.chatID = myAIChatID // MyAi的主会场ID
        quickActionRequest.aiChatModeID = aiChatModeID
        quickActionRequest.chatContext.extraMap = chatContextInfo
        return rustService.sendPassThroughAsyncRequest(quickActionRequest, serCommand: .larkOfficeAiFetchQuickActionByID)
    }
}
