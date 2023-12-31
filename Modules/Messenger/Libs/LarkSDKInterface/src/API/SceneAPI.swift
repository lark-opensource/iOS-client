//
//  SceneAPI.swift
//  LarkSDKInterface
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import ServerPB
import RxSwift

/// MyAI场景API，存放SDK、透传请求
public protocol SceneAPI {
    /// 拉取场景列表
    func fetchSceneList(pageOffset: Int64) -> Observable<ServerPB_Office_ai_ListUserScenesResponse>
    /// 停用/启用某个场景
    func switchScene(sceneId: Int64, active: Bool) -> Observable<Void>
    /// 移除某个场景
    func removeScene(sceneId: Int64) -> Observable<Void>
    /// 分享某个场景
    func shareScene(sceneId: Int64) -> Observable<String>
    /// 编辑场景
    func putScene(sceneID: Int64,
                  sceneName: String,
                  imageKey: String,
                  prologue: String,
                  description_p: String,
                  guideQuestions: [String],
                  systemInstruction: String,
                  aiModel: String) -> Observable<ServerPB_Office_ai_PutSceneResponse>
    /// 创建场景
    func createScene(sceneName: String,
                     imageKey: String,
                     prologue: String,
                     guideQuestions: [String],
                     systemInstruction: String,
                     aiModel: String) -> Observable<ServerPB_Office_ai_CreateSceneResponse>
    /// 获取大模型列表
    func getAgentModels() -> Observable<ServerPB_Office_ai_GetAgentModelResponse>
    /// 获取某场景的具体信息
    func getSceneDetail(sceneId: Int64) -> Observable<ServerPB_Office_ai_GetSceneDetailResponse>
}
