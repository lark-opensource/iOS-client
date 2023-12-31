//
//  RustSceneAPI.swift
//  LarkSDK
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import RxSwift // ImmediateSchedulerType
import LarkContainer // UserResolver
import LarkSDKInterface // SDKRustService
import LKCommonsLogging // Logger
import ServerPB // ServerPB
import LarkAccountInterface // PassportUserService

final class RustSceneAPI: LarkAPI, SceneAPI {
    private let logger = Logger.log(RustSceneAPI.self, category: "LarkSDK")

    private let userResolver: UserResolver
    init(userResolver: UserResolver, client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.userResolver = userResolver
        super.init(client: client, onScheduler: onScheduler)
    }

    /// 拉取场景列表
    public func fetchSceneList(pageOffset: Int64) -> Observable<ServerPB_Office_ai_ListUserScenesResponse> {
        var request = ServerPB_Office_ai_ListUserScenesRequest()
        request.pageOffset = pageOffset
        request.pageSize = 20
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneListUserScenes).subscribeOn(scheduler)
    }

    /// 停用/启用某个场景
    func switchScene(sceneId: Int64, active: Bool) -> Observable<Void> {
        var request = ServerPB_Office_ai_SwitchSceneRequest()
        request.sceneID = sceneId
        request.switchActive = active
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneSwitchScene).subscribeOn(scheduler).map({ _ in })
    }

    /// 移除某个场景
    public func removeScene(sceneId: Int64) -> Observable<Void> {
        var request = ServerPB_Office_ai_RemoveSceneRequest()
        request.sceneID = sceneId
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneRemoveScene).subscribeOn(scheduler).map({ _ in })
    }

    /// 分享某个场景
    public func shareScene(sceneId: Int64) -> Observable<String> {
        var request = ServerPB_Office_ai_ShareSceneLinkRequest()
        request.sceneID = sceneId
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneShareSceneLink).subscribeOn(scheduler)
            .map({ (response: ServerPB_Office_ai_ShareSceneLinkResponse) -> String in
                return response.link
            })
    }

    ///创建场景
    public func createScene(sceneName: String,
                            imageKey: String,
                            prologue: String,
                            guideQuestions: [String],
                            systemInstruction: String,
                            aiModel: String) -> Observable<ServerPB_Office_ai_CreateSceneResponse> {
        var request = ServerPB_Office_ai_CreateSceneRequest()
        request.cid = UUID().uuidString
        request.sceneName = sceneName
        request.imageKey = imageKey
        request.greeting = prologue
        request.description_p = prologue
        request.guideQuestions = guideQuestions.map { text in
            var question = ServerPB_Office_ai_GuideQuestion()
            question.text = text
            return question
        }
        request.systemInstruction = systemInstruction
        request.aiModelID = aiModel
        request.cid = UUID().uuidString
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneCreateScene).subscribeOn(scheduler)
    }

    /// 编辑场景
    public func putScene(sceneID: Int64,
                         sceneName: String,
                         imageKey: String,
                         prologue: String,
                         description_p: String,
                         guideQuestions: [String],
                         systemInstruction: String,
                         aiModel: String) -> Observable<ServerPB_Office_ai_PutSceneResponse> {
        var request = ServerPB_Office_ai_PutSceneRequest()
        request.sceneID = sceneID
        request.sceneName = sceneName
        request.imageKey = imageKey
        request.greeting = prologue
        request.description_p = description_p
        request.guideQuestions = guideQuestions.map { text in
            var question = ServerPB_Office_ai_GuideQuestion()
            question.text = text
            return question
        }
        request.systemInstruction = systemInstruction
        request.aiModelID = aiModel
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiScenePutScene).subscribeOn(scheduler)
    }

    /// 获取大模型列表
    public func getAgentModels() -> Observable<ServerPB_Office_ai_GetAgentModelResponse> {
        let request = ServerPB_Office_ai_GetAgentModelRequest()
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneGetAgentModel).subscribeOn(scheduler)
    }

    func getSceneDetail(sceneId: Int64) -> Observable<ServerPB_Office_ai_GetSceneDetailResponse> {
        var request = ServerPB_Office_ai_GetSceneDetailRequest()
        request.sceneID = sceneId
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneGetSceneDetail).subscribeOn(scheduler)
    }
}
