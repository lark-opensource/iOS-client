//
//  InlineAINetworkSession.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/17.
//  


import UIKit
import RustPB
import RxSwift
import RxCocoa
import LarkRustClient
import LarkContainer
import ServerPB
import LarkModel

class InlineAIResolverWrapper {
    
    var userResolver: LarkContainer.UserResolver
    
    var rustService: RustService? {
        return try? userResolver.resolve(type: RustService.self)
    }
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}

class InlineAIDataProvider {
    
    enum AIAPIError: Error {
        case scenarioNotSupported
    }

    var resolverWrapper: InlineAIResolverWrapper
    
    let disposeBag = DisposeBag()

    init(userResolver: LarkContainer.UserResolver) {
        self.resolverWrapper = InlineAIResolverWrapper(userResolver: userResolver)
    }
    
    func requestQuickActionsList(scenario: Int, triggerParamsMap: [String: String]) -> Observable<QuickActionResponse> {
        guard let pbScenario = ServerPB_Office_ai_inline_Scenario(rawValue: scenario) else {
            return .create { ob in
                let msg = "[api] actions List scenario:\(scenario) is not supported"
                LarkInlineAILogger.error(msg)
                ob.onError(NSError(domain: msg, code: -1))
                return Disposables.create {}
            }
        }
        guard let service = resolverWrapper.rustService else {
            return .create { ob in
                let msg = "[api] rustService is nil"
                ob.onError(NSError(domain: msg, code: -1))
                return Disposables.create {}
            }
        }
        var request = ServerPB_Office_ai_inline_FetchQuickActionRequest()
        request.scenario = pbScenario
        request.triggerParamsMap = triggerParamsMap
        return service.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiInlineFetchQuickAction)
    }

    /// 指令调用
    /// - Parameters:
    ///   - sectionID: 会话 ID, 第一次不传
    ///   - uniqueTaskID: task唯一id
    ///   - scenario: 场景类型
    ///   - actionID: 快捷指令ID
    ///   - actionType: 指令类型。
    ///   - userPrompt: 自由指令参数
    ///   - displayContent: 用户看到的指令内容
    ///   - params: 快捷指令参数
    func sendPrompt(sectionID: String?,
                    uniqueTaskID: String,
                    scenario: Int,
                    actionID: String?,
                    actionType: PromptActionType,
                    userPrompt: String?,
                    displayContent: String,
                    params: [String: String]) -> Observable<CreateTaskResponse> {
        guard let service = resolverWrapper.rustService else {
            return .create { ob in
                ob.onError(NSError(domain: "[api] rustService is nil", code: -1))
                return Disposables.create {}
            }
        }
        var request = Space_Doc_V1_InlineAICreateTaskRequest()
        request.uniqueTaskID = uniqueTaskID
        if let scenarioValue =  Space_Doc_V1_Scenario(rawValue: scenario) {
            request.scenario = scenarioValue
        } else {
            LarkInlineAILogger.error("[api] scenario:\(scenario) is not supported")
        }
        if let sId = sectionID, !sId.isEmpty {
            request.sessionID = sId
        }
        if let aId = actionID {
            request.actionID = aId
        }
        if let userInput = userPrompt {
            request.userPrompt = userInput
        }
        request.actionType = actionType.rawValue
        request.displayContent = displayContent
        request.params = params
        LarkInlineAILogger.info("[api] scenario:\(scenario) actionType:\(actionType) userPrompt:\(userPrompt) taskID: \(uniqueTaskID)")
        return service.sendAsyncRequest(request) { (resp: CreateTaskResponse) -> CreateTaskResponse in
            return resp
        }
    }
    
    
    func cancelTask(taskId: String) {
        guard let service = resolverWrapper.rustService else {
            return
        }
        
        var request = Space_Doc_V1_InlineAICancelTaskRequest()
        request.uniqueTaskID = taskId
        service.sendAsyncRequest(request).subscribe({ _ in
            LarkInlineAILogger.info("cencel taskId:\(taskId) success")
        }).disposed(by: disposeBag)
    }
    
    func sendLikeFeedback(aiMessageId: String,
                          scenario: String,
                          queryRawdata: String,
                          answerRawdata: String,
                          completion: @escaping (Swift.Result<(), Error>) -> Void) {
        
        guard let service = resolverWrapper.rustService else {
            completion(.failure(NSError(domain: "[api] rustService is nil", code: -1)))
            return
        }
        
        var request = ServerPB_Ai_engine_FeedsbackRequest()
        request.queryMessageRawdata = queryRawdata
        request.ansMessageRawdata = answerRawdata
        request.mode = .inline
        request.aiMessageID = aiMessageId
        request.data.like = true
        request.scenario = scenario
        
        service.sendPassThroughAsyncRequest(request, serCommand: .larkAiFeedbackReasonSubmit).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            LarkInlineAILogger.info("my ai feedback `LIKE` send click success")
            completion(.success(()))
        }, onError: { error in
            LarkInlineAILogger.info("my ai feedback `LIKE` send click error, error: \(error)")
            completion(.failure(error))
        }).disposed(by: disposeBag)
    }
    
    func getDebugInfo(aiMessageId: String, completion: @escaping (Swift.Result<String, Error>) -> Void) {
        
        guard let service = resolverWrapper.rustService else {
            completion(.failure(NSError(domain: "[api] rustService is nil", code: -1)))
            return
        }
        
        var request = ServerPB_Ai_engine_DebugInfoRequest()
        request.messageID = aiMessageId
        request.mode = .inline
        // 透传请求
        service.sendPassThroughAsyncRequest(request, serCommand: .larkAiGetDebugInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (res: ServerPB_Ai_engine_DebugInfoResponse) in
                completion(.success(res.debugInfo))
            }, onError: { error in
                completion(.failure(error))
            }).disposed(by: self.disposeBag)
    }
    
    /// 获取picker推荐人列表(空搜)
    func getMentionRecommendUsers() -> Observable<PickerRecommendResult> {
        
        guard let service = resolverWrapper.rustService else {
            return .create { ob in
                ob.onError(NSError(domain: "[api] rustService is nil", code: -1))
                return Disposables.create {}
            }
        }
        
        var request = ServerPB_Office_ai_inline_MentionRecommendRequest()
        request.scenario = .calendar
        request.objToken = "" // 空搜传空字符
        request.content = "" // 空搜传空字符
        request.type = "0" // 0表示user, 参考SKCommon.AtDataSource.RequestType
        // 透传请求
        let obs: Observable<ServerPB_Office_ai_inline_MentionRecommendResponse> =
        service.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiInlineMentionRecommend)
            .observeOn(MainScheduler.instance)
        
        obs.subscribe(onError: { error in
            LarkInlineAILogger.info("\(#function) error: \(error)")
        }).disposed(by: self.disposeBag)
        
        let pickerObs = obs.map { result in
            let string = result.data
            let models = InlineAIMentionModel.parseUsersFrom(rawString: string)
            let pickerItems = models.map {
                let chatter = $0.asPickerChatter()
                var pickerItem = PickerItem(meta: .chatter(chatter), category: .emptySearch)
                var renderData = PickerItem.RenderData()
                renderData.title = $0.name // 姓名
                renderData.summary = $0.department // 部门
                pickerItem.renderData = renderData
                return pickerItem
            }
            return PickerRecommendResult(items: pickerItems, hasMore: false, isPage: true)
        }
        return pickerObs
    }
}


// MARK: - history prompt

extension InlineAIDataProvider {
    
    func getRecentActions(scenario: Int, count: Int64 = 100) -> Observable<RecentPromptResponse> {
        guard let service = resolverWrapper.rustService else {
            return createDefaultObservable(msg: "[api] rustService is nil")
        }
        var request = ServerPB_Office_ai_inline_GetRecentActionsRequest()
        if let pbScenario = ServerPB_Office_ai_inline_Scenario(rawValue: scenario) {
            request.scenario = pbScenario
        } else {
            LarkInlineAILogger.error("[api] scenario is nil")
        }
        request.count = count
        LarkInlineAILogger.info("[api] request recentActions count:\(count)")
        return service.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiInlineGetRecentActions)
    }
    
    func deleteRecentAction(scenario: Int, id: String) -> Observable<DeleteActionResponse> {
        guard let service = resolverWrapper.rustService else {
            return createDefaultObservable(msg: "[api] rustService is nil")
        }
        var request = ServerPB_Office_ai_inline_DeleteActionRequest()
        if let pbScenario = ServerPB_Office_ai_inline_Scenario(rawValue: scenario) {
           request.scenario = pbScenario
        } else {
           LarkInlineAILogger.error("[api] scenario is nil")
        }
        request.id = id
        LarkInlineAILogger.info("[api] delete recentAction id: \(id)")
        return service.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiInlineDeleteAction)
    }
    
    func createDefaultObservable<T>(msg: String) -> Observable<T> {
        return .create { ob in
            ob.onError(NSError(domain: msg, code: -1))
            return Disposables.create {}
        }
    }
}
