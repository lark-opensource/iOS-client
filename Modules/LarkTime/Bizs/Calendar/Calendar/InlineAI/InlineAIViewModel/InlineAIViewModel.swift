//
//  InlineAIViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/9/25.
//

import Foundation
import CalendarFoundation
import LarkContainer
import LKCommonsLogging
import UniverseDesignTheme
import LarkAIInfra
import ServerPB
import RxSwift
import RxCocoa

final class InlineAIViewModel: UserResolverWrapper {
    let logger = Logger.log(InlineAIViewModel.self, category: "Calendar.InlineAIViewModel")

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var serverPushService: ServerPushService?
    @ScopedInjectedLazy var rustPushService: RustPushService?
    @ScopedInjectedLazy var calendarMyAIService: CalendarMyAIService?
    
    let disposeBag: DisposeBag = DisposeBag()
    let rxToast = PublishRelay<ToastStatus>()
    let rxRoute = PublishRelay<Route>()
    let rxAction = PublishRelay<Action>()
    let rxStatus = PublishRelay<Status>()
    
    var quickActionList: [Server.AIInlineQuickAction] = []
    var isInAdjustMode: Bool = false
    /// 原始日程信息
    var originalEventInfo: InlineAIEventFullInfo?
    /// 当前的日程信息
    var currentEventInfo: InlineAIEventFullInfo?
    /// 当前正在执行的任务
    var currentTask: CalendarAITask?
    /// 当前唯一的task ID，用来标识当前执行的AI Task
    var uniqueTaskID: String = ""
    /// 当前AITask的状态
    var aiTaskStatus: AiTaskStatus = .unknown
    /// 上屏阶段的起点
    var eventqueueStage: Server.CalendarMyAIInlineStage = .stage0
    /// 判断内容是否生成
    var eventContentGenStage: Server.CalendarMyAIInlineStage = .stage0

    /// 当前Server推送的stage
    var _currentStage: SafeAtomic<Server.CalendarMyAIInlineStage> = .stage0 + .readWriteLock
    var currentStage: Server.CalendarMyAIInlineStage {
        get { _currentStage.value }
        set { _currentStage.value = newValue }
    }

    /// 历史记录 当前页Index [1.....total]
    var currentHistoryIndex: Int = 0
    /// 历史记录
    var historyMap: [InlineAIEventFullInfo] = []
    /// 数据更新任务队列
    var eventInfoDataQueue: [InlineAIEventInfo] = []
    
    let userResolver: UserResolver
    let editType: EventEditViewController.EditType
    
    var timer: Timer?
    var upScreenTimer: Timer?
    
    var isUpScreening: Bool = false
    var aiTaskNeedEnd: Bool = false
    var isSendClick: Bool = false
    let timeOutCounter: Int = 4
    var aiTaskNeedEndCounter: Int = 0
    var inlineNavItemStatus: InlineNavItemStatus?

    private let throttler = Throttler(delay: 1)
    private let debounce = Debouncer(delay: 0.5)

    lazy var meetingNotesLoader: MeetingNotesLoader = {
        MeetingNotesLoader(userResolver: self.userResolver)
    }()
    
    init(userResolver: UserResolver, editType: EventEditViewController.EditType) {
        self.userResolver = userResolver
        self.editType = editType
        
        registerAiInlineStageNotification()
        registerInlineAiTaskStatusNotification()
    }
    
    func getMyAINickName() -> String {
        return calendarMyAIService?.myAIInfo().name ?? ""
    }
}

// .MARK: - Panel状态轮转
extension InlineAIViewModel {

    func transferToInitalStatus() {
        aiTaskStatus = .initial
        
        rxRoute.accept(.panel(panel: getInitialInlineAIPanelModel()))
        rxStatus.accept(.initial)
    }

    func transferToInitalSearch(text: String) {
        debounce.call { [weak self] in
            guard let self = self else { return }
            if self.isSendClick { return }
            self.rxRoute.accept(.panel(panel: getSearchInlineAIPanelModel(text: text)))
        }
    }

    func transferToWorkingOnStatus() {
        aiTaskStatus = .processing
        
        resetEventqueueStage()

        rxRoute.accept(.panel(panel: getWorkingOnItAIPanelModel()))
        rxStatus.accept(.working)
    }
    
    func transferToFinishStatus(errorTips: String = "", createTaskFailed: Bool = false) {
        if isUpScreening || !eventInfoDataQueue.isEmpty { return }
        aiTaskStatus = .finish
        stopTimer()
        stopUpScreenTimer()
        turnToFinishStatus(errorTips: errorTips,createTaskFailed: createTaskFailed)
    }
    
    func transferToFinishStatusByStop() {
        aiTaskStatus = .finish
        stopTimer()
        stopUpScreenTimer()
        turnToFinishStatus()
    }
    
    private func turnToFinishStatus(errorTips: String = "", createTaskFailed: Bool = false) {
        if aiTaskStatus != .finish { return }

        historyDealer()
        let hasHistory: Bool = historyMap.count > 1
        currentHistoryIndex = historyMap.count > 1 ? historyMap.count - 1 : 1
        /// 有生成
        if eventContentGenStage != .stage0 {
            rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: hasHistory)))
            rxStatus.accept(.finsish)
            return
        }

        /// 从未生成过任何内容
        if historyMap.isEmpty {
            if errorTips.isEmpty {
                rxToast.accept(.tips(I18n.Calendar_G_EventInfoNotUpdated_Toast, fromWindow: true))
            } else {
                rxToast.accept(.failure(I18n.Calendar_G_SomethingWentWrong, fromWindow: true))
            }

            rxRoute.accept(.panel(panel: getInitialInlineAIPanelModel()))
            aiTaskStatus = .initial
            rxStatus.accept(.initial)
            return
        }

        /// 有历史记录
        if hasHistory {
            if errorTips.isEmpty {
                /// 无错误
                rxToast.accept(.tips(I18n.Calendar_G_EventInfoNotUpdated_Toast, fromWindow: true))
            } else {
                /// 有错误
                if createTaskFailed {
                    rxToast.accept(.failure(I18n.Calendar_G_SomethingWentWrong, fromWindow: true))
                } else {
                    rxToast.accept(.tips(errorTips, fromWindow: true))
                }
            }

            backToRecentHistory()
            rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: hasHistory)))
            rxStatus.accept(.finsish)
            return
        }

        /// 无历史，仅有当前屏上的数据
        if errorTips.isEmpty {
            /// 无错误
            rxToast.accept(.tips(I18n.Calendar_G_EventInfoNotUpdated_Toast, fromWindow: true))
            rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: hasHistory)))

        } else {
            /// 有错误
            if createTaskFailed {
                rxToast.accept(.failure(I18n.Calendar_G_SomethingWentWrong, fromWindow: true))
                rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: hasHistory)))
            } else {
                rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: hasHistory,
                                                                     errorTips: historyMap.isEmpty ? errorTips : "")))
            }
        }

        backToRecentHistory()
        rxStatus.accept(.finsish)
    }
    
    private func backToRecentHistory() {
        if let info = historyMap[safeIndex: historyMap.count - 1] {
            rxAction.accept(.eventInfoFull(data: info))
        }
    }
    
    private func stageUpdater(stage: Server.CalendarMyAIInlineStage) -> Bool {
        if stage.rawValue > currentStage.rawValue {
            currentStage = stage
            return true
        }
        return false
    }
    
    /// 重置所有状态
    private func resetAllStatus() {
        stopUpScreenTimer()
        stopTimer()
        originalEventInfo = nil
        currentEventInfo = nil
        isInAdjustMode = false
        isSendClick = false
        historyMap = []
        aiTaskStatus = .unknown
        eventInfoDataQueue = []
        resetEventqueueStage()
        rxStatus.accept(.unknown)
    }
    
    /// 用于编辑页 获取当前任务状态
    func handleAiTaskStatusGetter(_ needConfirm: Bool = false) -> AiTaskStatus {
        if aiTaskStatus == .finish, needConfirm {
            confirmActionHandler()
        }
        return self.aiTaskStatus
    }

    func showFinishPanelFromSecondVCBack() {
        rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: historyMap.count > 1)))
    }
}

// MARK: - Panel Action 处理
extension InlineAIViewModel {

    /// 点击发送
    func promptClickSendHandler(content: RichTextContent) {
        isSendClick = true
        rxAction.accept(.eventCurInfoGet)

        switch content.data {
        case .quickAction(let data):
            self.logger.info("promptClickSendHandler: template prompt")
            
            let params = getTemplatePomptParams(data: data)
            createAITask(content: data, params: params, fullInput: content.encodedStringWithMentionedUser())
            
        case .freeInput(let data):
            self.logger.info("promptClickSendHandler: free prompt")
            
            createFreePromptRequest(inputType: .create, userInput: content.encodedStringWithMentionedUser(), freeParams: data )
            transferToWorkingOnStatus()
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("trigger_ai")
                $0.task_type = "self_defined"
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: currentEventInfo?.model?.getPBModel()))
            }
        }
    }
    
    /// 点击指令
    func promptClickHandler(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        rxAction.accept(.eventCurInfoGet)

        switch prompt.groupType {
        case .template:
            self.logger.info("promptClickHandler: template ")
            rxRoute.accept(.panel(panel: getTempleteInputPanel(prompt: prompt)))
        case .basic:
            self.logger.info("promptClickHandler: basic")
            let params = getQuickPomptParams(prompt: prompt)
            switch prompt.promptType {
            case .bookRooms:
                createAITask(prompt: prompt, params: params)
            case .completeEvent:
                createAITask(prompt: prompt, params: params)
            case .recommendTime:
                createAITask(prompt: prompt, params: params)
            case .createMeetingNotes:
                throttler.call { [weak self] in
                    self?.rxRoute.accept(.createMeetingNotes)
                    self?.hideInlinePanel()
                }
            default:
                self.logger.info("promptHandler: shouldn't in Basic")
            }
        case .adjust:
            self.logger.info("promptClickHandler: adjust shouldn't happen in this path")
        }
        
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("trigger_ai")
            $0.task_type = getTaskTypeParamsForTracker(type: prompt.promptType)
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: currentEventInfo?.model?.getPBModel()))
        }
    }
    
    /// 点击调整
    func adjustPromptClickHandler(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        self.logger.info("promptClickHandler: adjust")
        rxAction.accept(.eventCurInfoGet)
        let params = getAdjustPomptParams(prompt: prompt)
        isInAdjustMode = true
        createAITask(prompt: prompt, params: params)
        
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("trigger_ai")
            $0.task_type = getTaskTypeParamsForTracker(type: prompt.promptType)
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: currentEventInfo?.model?.getPBModel()))
        }
    }
    
    ///完成态按钮处理逻辑
    func operationClickHandler(operate: InlineAIPanelModel.Operate) {
        self.logger.info("operationClickHandler: opType: \(operate.opType)")

        switch operate.opType {
        case .confirm:
            confirmActionHandler()
        case .adjust:
            rxRoute.accept(.subPanel(panel: genSubPanelModel()))
        case .retry:
            retryActionHandler()
        case .cancel:
            cancelActionHandler()
        case .debuginfo:
            debugInfoActionHandler()
        default: break
        }

        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click(operate.opType.rawValue)
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: currentEventInfo?.model?.getPBModel()))
        }
    }
    
    func stopTaskClickHandler() {
        /// check content already generate
        if eventContentGenStage == .stage0 && historyMap.isEmpty {
            transferToInitalStatus()
        } else {
            transferToFinishStatusByStop()
        }
    }
    
    func feedBackClickHandler(like: Bool, callback: ((LarkAIInfra.LarkInlineAIFeedbackConfig) -> Void)?) {
        if let feedback = historyMap[safeIndex: currentHistoryIndex]?.feedback {
            switch feedback {
            case .like:
                historyMap[currentHistoryIndex].feedback = like ? .unknown : .like
            case .unlike:
                historyMap[currentHistoryIndex].feedback = like ? .like : .unknown
            case .unknown:
                historyMap[currentHistoryIndex].feedback = like ? .like : .unlike
            }
        }

        let config = LarkInlineAIFeedbackConfig(isLike: like,
                                                aiMessageId: uniqueTaskID,
                                                scenario: "Calendar",
                                                queryRawdata: currentTask?.fullInput ?? "",
                                                answerRawdata: "")
        if let callback = callback {
            callback(config)
        }
    }
    
    func workingOnQuit() {
        resetToOriginalEventInfo()
        hideInlinePanel()
    }
    
    func hideInlinePanel(_ isFromConfirm: Bool = false) {
        deleteNoUseMeetingNotes(isFromConfirm: isFromConfirm)
        resetAllStatus()
        rxRoute.accept(.hide)
    }
    
    func confirmActionHandler() {
        isInAdjustMode = false
        confirmCurrentEventInfo()
        hideInlinePanel(true)
    }
    
    private func retryActionHandler() {
        transferToWorkingOnStatus()
        resetToOriginalEventInfo()
        createFreePromptRequest(inputType: .again, userInput: currentTask?.fullInput ?? "", freeParams: [])
        isInAdjustMode = true
        rxAction.accept(.eventCurInfoGet)
    }
    
    private func cancelActionHandler() {
        resetToOriginalEventInfo()
        hideInlinePanel()
    }
    
    private func debugInfoActionHandler() {
        let currentTaskInfo = currentTask.debugDescription
        let historyMapInfo = historyMap.debugDescription
        let debugInfo = "currentTaskInfo: \(currentTaskInfo) \n historyMapInfo: \(historyMapInfo)"
        rxRoute.accept(.debugInfo(info: debugInfo))
    }
}

// .MARK: - Panel 网络请求 & Push监听 & 轮询
extension InlineAIViewModel {
    func showPanel() {
        aiTaskStatus = .initial

        rxToast.accept(.loading(info: I18n.Calendar_Common_Loading, disableUserInteraction: true))
        /// 获取指令推荐参数
        let triggerParams = getTriggerParams()
        calendarApi?.fetchQuickActionList(triggerParamsMap: triggerParams)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.logger.info("INLINE_CALENDAR: fetchQuickActionList success with: \(res.actions.count)")
                self.rxToast.accept(.remove)

                self.quickActionList = res.actions
                self.transferToInitalStatus()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.logger.error("INLINE_CALENDAR: fetchQuickActionList failed with:\(error)")
                self.rxToast.accept(.remove)
                self.quickActionList = []
                self.transferToInitalStatus()
            })
            .disposed(by: disposeBag)
    }
    
    func createFreePromptRequest(inputType: Server.MyAIInlineInputType, userInput: String, freeParams: [InlineAIPanelModel.ParamContentComponent]) {
        guard let calendarApi = calendarApi else { return }
        
        var params = getFreePomptParams(freeParams: freeParams)
        let isMeetingRoomEmpty: Bool = currentEventInfo?.model?.aiStyleInfo.meetingRoom.isEmpty ?? true
        let calendarIDs: [String] = isMeetingRoomEmpty ? currentEventInfo?.model?.meetingRooms.map { $0.uniqueId } ?? [] : currentEventInfo?.model?.aiStyleInfo.meetingRoom.map { $0.resourceID } ?? []
        /// 自由指令: 特殊处理，需要拉取roomID，是否拉到 不阻塞执行
        calendarApi.loadResourcesByCalendarIdsRequest(calendarIDs: calendarIDs)
            .flatMap {[weak self] res -> Observable<Server.MyAIUserQueryResponse> in
                self?.logger.info("loadResourcesByCalendarIdsRequest with resources: \(res.resources.count)")

                let roomIds = res.resources.map { item in
                     item.value.id
                }
                let roomParams = roomIds.map { AIFreeParamsRoom(room_id: $0, name: "")}
                params["resource_ids"] = self?.encodeParamsToJson(rooms: roomParams)
                
                return calendarApi.getCalendarMyAIUserQueryRequest(inputType: inputType, userInput: userInput)
            }.subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.logger.info("getCalendarMyAIUserQuery success with: \(res.outputContent.count)")

                self.createAITask(userPrompt: res.outputContent, params: params, fullInput: userInput)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("getCalendarMyAIUserQuery error with: \(error)")

                self.createAITask(userPrompt: userInput, params: params, fullInput: userInput)
            }).disposed(by: disposeBag)
    }
    
    func createAITask(prompt: LarkAIInfra.InlineAIPanelModel.Prompt? = nil, userPrompt: String? = nil, content: InlineAIPanelModel.QuickAction? = nil, params: [String: String] = [:], fullInput: String? = nil) {
        /// 1. 获取最新日程信息
        rxAction.accept(.eventCurInfoGet)
        
        /// 2. 重置任务状态标记
        currentStage = .stage0
        eventContentGenStage = .stage0
        
        /// 3. 缓存当前Task
        var promptID: String?
        if let prompt = prompt {
            /// 基础、调整
            switch prompt.groupType {
            case .basic, .adjust:
                currentTask = CalendarAITask(taskID: uniqueTaskID,
                                             promptID: prompt.id ,
                                             params: params,
                                             userPrompt: userPrompt,
                                             fullInput: prompt.text)
                promptID = prompt.id
            default:break
                
            }
        } else if let content = content {
            ///模版
            for item in quickActionList {
                guard item.name == content.displayName else {
                    continue
                }
                
                promptID = item.id
            }
            currentTask = CalendarAITask(taskID: uniqueTaskID,
                                         promptID: promptID ,
                                         params: params,
                                         userPrompt: userPrompt,
                                         fullInput: fullInput ?? "")
        } else {
            /// 自由
            currentTask = CalendarAITask(taskID: uniqueTaskID,
                                         promptID: "" ,
                                         params: params,
                                         userPrompt: userPrompt,
                                         fullInput: fullInput ?? "")
        }
        
        throttler.call{[weak self] in
            /// 4. 执行Task
            guard let self = self else { return }
            self.createAITaskRequest(taskID: self.currentTask?.taskID ?? self.uniqueTaskID,
                                     promptID: promptID,
                                     userPrompt: userPrompt,
                                     params: params )
        }
    }
    
    func createAITaskRequest(taskID: String, promptID: String? = nil, userPrompt: String? = nil, params: [String: String] = [:]) {
        if userPrompt == nil {
            /// 进入处理态
            transferToWorkingOnStatus()
        }
        /// 执行 Task
        calendarApi?.createTaskRequest(sectionID: nil,
                                       uniqueTaskID: taskID,
                                       scenario: InlineAIConfig.ScenarioType.calendar.rawValue,
                                       actionID: promptID,
                                       actionType: userPrompt.isNil ? .quickAction : .userPrompt,
                                       userPrompt: userPrompt,
                                       displayContent: "",
                                       params: params)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext:{ [weak self] _ in
            self?.logger.info("INLINE_CALENDAR: createTaskRequest success")
            self?.startTimer()
        }, onError: { [weak self] error in
            self?.logger.error("INLINE_CALENDAR: createTaskRequest error with: \(error)")
            self?.transferToFinishStatus(errorTips: "\(error)" , createTaskFailed: true)
        }).disposed(by: disposeBag)
    }
    
    private func registerInlineAiTaskStatusNotification() {
        rustPushService?
            .rxInlineAiTaskStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.logger.info("INLINE_CALENDAR: AI Push Content: \(res.inlineAiTaskStatus)")
                /// AI 非处理态
                if self.aiTaskStatus != .processing || self.currentStage == .stageErr { return }
                
                let status = AiTaskStatus(rawValue: res.inlineAiTaskStatus.taskStatus)

                switch status {
                case .failed, .offline, .timeOut, .tnsBlock:
                    self.logger.error("rxInlineAiTaskStatus failed with: \(res.inlineAiTaskStatus.content)")
                    
                    self.startStageEventDataGetter(errorTips: res.inlineAiTaskStatus.content)
                    self.aiTaskNeedEnd = true

                case .success:
                    self.logger.info("rxInlineAiTaskStatus success")
                    self.startStageEventDataGetter()
                    self.aiTaskNeedEnd = true
                default: break
                }
            }).disposed(by: disposeBag)
    }
    
    private func registerAiInlineStageNotification() {
        serverPushService?
            .rxMyAiInlineStage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.logger.info("INLINE_CALENDAR: Calendar Stage Push : \(res), currentStage: \(currentStage)")
                /// AI 非处理态
                if self.aiTaskStatus != .processing { return }
                ///taskID 不合法
                if res.aiTaskID != self.uniqueTaskID {
                    self.logger.error("INLINE_CALENDAR: Calendar Stage Push aiTaskID not illeg res.aiTaskID \(res.aiTaskID) self.uniqueTaskID \(self.uniqueTaskID)")
                    return
                }

                let needUpdate = self.stageUpdater(stage: res.stage)
                if !needUpdate {
                    self.logger.info("rxMyAiInlineStage Push stage needUpdate: \(needUpdate)")
                    return
                }
                
                switch self.currentStage {
                case .stageErr:
                    self.transferToFinishStatus()
                default:
                    self.handleEventInfo(eventInfo: res.eventInfo)
                }
            }).disposed(by: disposeBag)
    }
    
    /// 定时轮询 4s周期，指令执行期间执行
    private func startStageEventDataGetter(errorTips: String = "") {
        self.logger.info("INLINE_CALENDAR: DataGetter aiTaskEnd \(aiTaskNeedEnd) errorTips: \(errorTips)")
        calendarApi?.getCalendarMyAIInlineEventRequest(aiTaskID: uniqueTaskID, aiTaskEnd: aiTaskNeedEnd)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.aiTaskNeedEndCounter = 0
                self.logger.info("INLINE_CALENDAR: DataGetter : \(res), currentStage: \(currentStage)")
                /// AI 非处理态
                if self.aiTaskStatus != .processing { return }

                if res.aiTaskID != self.uniqueTaskID {
                    self.logger.error("INLINE_CALENDAR: DataGetter aiTaskID not illeg res.aiTaskID\(res.aiTaskID): current taskid\(self.uniqueTaskID)")
                    return
                }

                let needUpdate = self.stageUpdater(stage: res.stage)
                if !needUpdate {
                    self.logger.info("INLINE_CALENDAR: StageEventDataGetter needUpdate: \(needUpdate)")
                    if !errorTips.isEmpty {
                        self.transferToFinishStatus(errorTips: errorTips)
                    } else {
                        if aiTaskNeedEnd {
                            self.transferToFinishStatus()
                        }
                    }
                    return
                }
                
                switch self.currentStage {
                case .stageErr:
                    self.transferToFinishStatus()
                default:
                    self.handleEventInfo(eventInfo: res.eventInfo)
                }
         }, onError: { [weak self] error in
             guard let self = self else { return }
             self.logger.error("INLINE_CALENDAR: DataGetter error with: \(error)")
             /// 连错4次，直接结束
             if self.aiTaskNeedEndCounter > self.timeOutCounter {
                 self.transferToFinishStatusByStop()
                 self.aiTaskNeedEndCounter = Int(-INT16_MAX)
             }
             self.aiTaskNeedEndCounter += 1
        }).disposed(by: disposeBag)
    }
    
    /// 用于删除无用会议纪要
    private func deleteNoUseMeetingNotes(isFromConfirm: Bool) {
        logger.info("INLINE_CALENDAR: deleteMeetingNotes isFromConfirm\(isFromConfirm)")
        let tmpHistoryMap = historyMap
        let tmpIndex = currentHistoryIndex
        var notesDocInfoList: [Server.NotesDocInfo] = []
        for item in tmpHistoryMap {
            if item.meetingNotesModel?.token == tmpHistoryMap[safeIndex: tmpIndex]?.meetingNotesModel?.token,
               isFromConfirm { continue }
            if item.meetingNotesModel?.token == originalEventInfo?.meetingNotesModel?.token { continue }
            if let model = item.meetingNotesModel {
                var info = Server.NotesDocInfo()
                info.docToken = model.token
                info.docType = ServerPB_Entities_DocType(rawValue: model.type) ?? ServerPB_Entities_DocType()
                info.docOwnerID = model.docOwnerId ?? 0
                notesDocInfoList.append(info)
            }
        }

        calendarApi?.batchDelNotesDocRequest(notesDocInfo: notesDocInfoList)
            .subscribe(onNext: {[weak self] _ in
                self?.logger.info("INLINE_CALENDAR: deleteMeetingNotes success with （\(notesDocInfoList.count)）")
            }, onError: {[weak self] error in
                self?.logger.error("INLINE_CALENDAR: deleteMeetingNotes error with: \(error)")
            }).disposed(by: disposeBag)
    }
    
    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true, block: { [weak self] (_) in
            guard let self = self else { return }
            self.startStageEventDataGetter()
        })
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// .MARK: - 路由
extension InlineAIViewModel {

    enum Route {
        case panel(panel: LarkAIInfra.InlineAIPanelModel)
        case subPanel(panel: LarkAIInfra.InlineAISubPromptsModel)
        case hide
        case createMeetingNotes
        case debugInfo(info: String)
    }
    
    enum Action {
        case eventInfoStage(data: InlineAIEventInfo)
        case eventInfoFull(data: InlineAIEventFullInfo)
        case eventCurInfoGet
    }
    
    enum Status {
        case working
        case finsish
        case initial
        case unknown
    }
}
