//
//  CommentMonitorPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2023/2/21.
//  

import SKUIKit
import SKFoundation
import SpaceInterface
import SKCommon

class CommentMonitorPlugin: CommentPluginType {

    weak var context: CommentServiceContext?
    
    static let identifier: String = "MonitorPlugin"
    
    lazy var fpsMonitor = DocsFPSMonitor(mode: .accumulate)
    
    /// replyId: count
    lazy var imagesRecord: [String: Int] = [:]

    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .interaction(uiAction):
            handleUIAction(action: uiAction)
        default:
            break
        }
    }
    
    init() {}
}


extension CommentMonitorPlugin {
    
    var fpsEnable: Bool {
        return context?.businessDependency?.businessConfig.monitorConfig?.fpsEnable == true
    }
    
    var editEnable: Bool {
        return context?.businessDependency?.businessConfig.monitorConfig?.editEnable == true
    }
    
    var loadedEnable: Bool {
        return context?.businessDependency?.businessConfig.monitorConfig?.loadedEnable == true
    }

    func handleUIAction(action: CommentAction.UI) {
        switch action {
        case .edit, .reply, .clickInputBarView:
            guard editEnable == true else { return }
            let now = Date().timeIntervalSince1970 * 1000
            var clickFrom: CommentStatsExtra.From = .reactionMenu
            if case .clickInputBarView = action {
                clickFrom = .replyArea
            }
            var statsExtra = CommentStatsExtra(clickTime: now,
                                                clickFrom: clickFrom,
                                                receiveTime: now)
            statsExtra.markRecordedRender()
            context?.scheduler?.dispatch(action: .ipc(.resetDataCache(statsExtra, .edit), nil))
         /* FPS  */
        case let .willBeginDragging(items):
            guard fpsEnable else { return }
            fpsMonitor.resume()
            if context?.pattern == .aside {
                storeImageCount(items, isMonitoring: fpsMonitor.isMonitoring)
            }
        case .didEndDragging, .didEndDecelerating:
            guard fpsEnable else { return }
            fpsRecordEnd()
        case let .willDisplay(item):
            guard fpsEnable else { return }
            if context?.pattern == .aside {
                storeImageCount([item], isMonitoring: fpsMonitor.isMonitoring)
            }
        
        /* render  */
        case .renderEnd:
            guard loadedEnable else { return }
            handleRenderEnd()
    
        /* edit  */
        case let .keyboardChange(options):
            guard editEnable else { return }
            handleKeyBoardChange(options: options, item: nil)
        case let .asideKeyboardChange(options, item):
            guard editEnable else { return }
            handleKeyBoardChange(options: options, item: item)
        default:
            break
        }
    }
    
    func handleKeyBoardChange(options: Keyboard.KeyboardOptions, item: CommentItem?) {
        guard let context = context,
              let fastState = context.scheduler?.fastState,
              options.event == .didShow else { return }
        let pattern = context.pattern
        var params = self.baseParams
        context.scheduler?.dispatch(action: .ipc(.fetchCommentDataDesction, { [weak context] response, _ in
            if let description = response as? CommentDiffDataPlugin.CommentDescription,
               let duration = description.statsExtra?.calculateDuration() {
                if description.statsExtra?.recordedEdit == true {
                    context?.scheduler?.dispatch(action: .ipc(.resetDataCache(nil, .edit), nil))
                    return
                }
                params[.commentId] = fastState.activeCommentId ?? ""
                if pattern == .aside {
                    params[.commentCount] = description.commentCount
                    params[.totalReplyCount] = description.replyCount
                } else {
                    guard let activeComment = fastState.activeComment else { return }
                    let realItems = activeComment.commentList.filter { $0.interactionType == .comment || $0.interactionType == .reaction }
                    params[.replyCount] = realItems.count
                }
                params[.cost] = duration.renderTime
                params[.webStageCost] = duration.bridgeTime
                params[.nativeStageCost] = duration.renderTime
                params[.domain] = "part_comment"
                switch fastState.mode {
                case let .newInput(model):
                    params[.domain] = model.isWhole ? "full_comment" : "part_comment"
                    params[.type] = model.type == .new ? "create" : "edit"
                case .edit:
                    params[.type] = "edit"
                case .reply:
                    params[.type] = "reply"
                default:
                    break
                }
                params[.from] = description.statsExtra?.clickFrom?.rawValue ?? ""
                context?.scheduler?.dispatch(action: .tea(.editPerformance(params: params)))
                context?.scheduler?.dispatch(action: .ipc(.resetDataCache(nil, .edit), nil))
            }
        }))
    }

    func handleRenderEnd() {
        guard let context = context, let fastState = context.scheduler?.fastState else { return }
        let pattern = context.pattern
        var params = self.baseParams
        context.scheduler?.dispatch(action: .ipc(.fetchCommentDataDesction, { [weak context] response, _ in
            if var description = response as? CommentDiffDataPlugin.CommentDescription,
               let duration = description.statsExtra?.calculateDuration() {
                if description.statsExtra?.recordedRender == true {
                    context?.scheduler?.dispatch(action: .ipc(.resetDataCache(nil, .render), nil))
                    return
                }
                params[.commentId] = fastState.activeCommentId ?? ""
                if pattern == .aside {
                    params[.commentCount] = description.commentCount
                    params[.totalReplyCount] = description.replyCount
                } else {
                    guard let activeComment = fastState.activeComment else { return }
                    let realItems = activeComment.commentList.filter { $0.interactionType == .comment || $0.interactionType == .reaction }
                    params[.replyCount] = realItems.count
                }
                params[.cost] = duration.renderTime
                params[.webStageCost] = duration.bridgeTime
                params[.nativeStageCost] = duration.renderTime
                params[.from] = description.statsExtra?.clickFrom?.rawValue ?? ""
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    if JSONSerialization.isValidJSONObject(description.paylod) {
                        if let data = try? JSONSerialization.data(withJSONObject: description.paylod) {
                            let rawString = String(data: data, encoding: .utf8) ?? ""
                            params[.dataLength] = rawString.utf16.count
                        }
                    }
                    self.context?.scheduler?.dispatch(action: .tea(.renderPerformance(params: params)))
                }
                description.statsExtra?.markRecordedRender()
                context?.scheduler?.dispatch(action: .ipc(.resetDataCache(description.statsExtra, .render), nil))
            }
        }))
    }

    func dispatchTEA(_ action: CommentAction) {
        context?.scheduler?.dispatch(action: action)
    }

    var baseParams: [CommentTracker.PerformanceKey: Any] {
        var params: [CommentTracker.PerformanceKey: Any] = [:]
        params[.fileType] = context?.docsInfo?.inherentType.name ?? ""
        params[.fileId] = context?.docsInfo?.token.encryptToken ?? ""
        params[.isVC] = context?.docsInfo?.isInVideoConference ?? false
        params[.commentStyle] = context?.pattern.rawValue ?? ""
        return params
    }

    func fpsRecordEnd() {
        guard let context = context, let fastState = context.scheduler?.fastState else { return }
        guard fpsMonitor.isMonitoring else {
            return
        }
        let endFps = fpsMonitor.stop()
        var isBeingTest = false
#if DEBUG
        isBeingTest = DocsSDK.isBeingTest
#endif
        if !isBeingTest {
            guard endFps > 0 else {
                DocsLogger.error("[comment monitor] fps is 0", component: LogComponents.comment)
                return
            }
        }
        var params = baseParams
        params[.fps] = endFps
        params[.refreshRate] = UIScreen.main.maximumFramesPerSecond
        switch context.pattern {
        case .aside:
            params[.commentId] = fastState.activeCommentId ?? ""
           // 评论总数，回复总数
            context.scheduler?.dispatch(action: .ipc(.fetchCommentDataDesction, { response, _ in
                if let description = response as? CommentDiffDataPlugin.CommentDescription {
                    params[.commentCount] = description.commentCount
                    params[.totalReplyCount] = description.replyCount
                }
            }))
            params[.imageCount] = calculateImage()
        case .float:
           if let activeComment = fastState.activeComment {
               params[.commentId] = activeComment.commentID
               let realItems = activeComment.commentList.filter { $0.interactionType == .comment || $0.interactionType == .reaction }
               params[.replyCount] = realItems.count
               params[.imageCount] = realItems.reduce(0) { $0 + $1.imageList.count }
           } else {
               DocsLogger.error("[comment monitor] float comment found no active comment", component: LogComponents.comment)
           }

        case .drive:
            DocsLogger.error("drive didn't support fps record", component: LogComponents.comment)
        }
        imagesRecord.removeAll()
        context.scheduler?.dispatch(action: .tea(.fpsPerformance(params: params)))
    }
    
    func storeImageCount(_ items: [CommentItem], isMonitoring: Bool) {
        if isMonitoring {
            for item in items where !item.imageList.isEmpty {
                imagesRecord[item.replyID] = item.imageList.count
            }
        }
    }
    
    func calculateImage() -> Int {
        return imagesRecord.reduce(0) { $0 + $1.value }
    }
}
