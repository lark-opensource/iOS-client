//
//  CommentShowCardsService+Pad.swift
//  SKBrowser
//
//  Created by huayufan on 2021/7/4.
//  


import SKCommon
import SKFoundation
import RxSwift
import SKUIKit
import SpaceInterface
import SKInfra

extension CommentShowCardsService {
    
    var isPadCommmentShowing: Bool {
        return _asideCommentModule?.isVisiable ?? false
    }
    
    var iPadUseNewCommment: Bool {
        return SKDisplay.pad && commentStyle == .embed
    }
}

extension CommentShowCardsService {
    
    func hidePadCommentView(_ needCancel: Bool = true) {
        dismissDebounce.debounce(debounceInterval) { [weak self] in
            self?.ui?.commentPadDisplayer?.dismissCommentView(animated: true, complete: {})
            self?.asideCommentModule?.hide()
        }
    }
    
    func innerShowCommentViewiPad(commentData: CommentData, params: [String: Any]) {
        var fromFeed = false
        if let from = params["from"] as? String,
           from == "feed" {
            fromFeed = true
        }
        let showCommentViewBlock = { [weak self] in
            self?.showAsideComment(commentData: commentData)
        }

        if fromFeed,
            let feedVC = self.navigator?.presentedVC as? FeedPanelViewControllerType,
            feedVC.isShowing {
            DocsLogger.info("CommentShowCardsService, fromFeed, pad", component: LogComponents.comment)
            notificateFrontendToHideFeed()
            feedVC.gapState = .bottom
            UIView.animate(withDuration: 0.2, animations: {
                feedVC.view.layoutIfNeeded()
            }, completion: { suc in
                DocsLogger.info("CommentShowCardsService, willShow commentVC =\(suc), isBeingDismissed=\(feedVC.isBeingDismissed)", component: LogComponents.comment)
                if feedVC.isBeingDismissed || feedVC.presentingViewController == nil {
                    showCommentViewBlock()
                } else {
                    feedVC.dismiss(animated: false) {
                        showCommentViewBlock()
                    }
                }
            })
        } else {
            DocsLogger.info("CommentShowCardsService, normal show, pad", component: LogComponents.comment)
            showCommentViewBlock()
        }
    }
}

// MARK: - 视图切换逻辑

extension CommentShowCardsService {
    
    func switchStyleIfNeed(to: CGSize = .zero, floatCheck: Bool = true) {
        if SKDisplay.pad, !appIsResignActive {
            let style = checkCurrentCommentStyle(to: to)
            switchCommentStyle(style: style, floatCheck: floatCheck)
        } else {
            DocsLogger.warning("switchStyle isResignActive:\(appIsResignActive)", component: LogComponents.comment)
        }
    }
    
    
    /// 通知前端当前UI样式
    /// - Parameters:
    ///   - floatCheck: 是否需要检查当前是否在VC浮窗状态
    func switchCommentStyle(style: CommentUIStyle, floatCheck: Bool = true) {
        if floatCheck {
            guard !isWindowFloating else {
                DocsLogger.info("switchStyle fail window is floating", component: LogComponents.comment)
                return
            }
        }
        // 状态未改变以及非iPad 不切换
        guard commentStyle != style, SKDisplay.pad else {
            DocsLogger.info("Docs Comment Service callFunction switchStyle fail, isPad: \(SKDisplay.pad) current: \(commentStyle.rawValue) to \(style.rawValue)", component: LogComponents.comment)
            return
        }
        DocsLogger.info("\(editorIdentity) Docs Comment Service callFunction switchStyle current: \(commentStyle.rawValue) to \(style.rawValue)", component: LogComponents.comment)
        self.commentStyle = style
        self.callFunction(for: .switchStyle,
                          params: ["style": style.rawValue])
       
    }
    
    func checkCurrentCommentStyle(to: CGSize = .zero) -> CommentUIStyle {
        let debugSet = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.ipadCommentUseOldDebug)
        let isUsePadCommment = debugSet ? false : SKDisplay.pad
        guard let ui = ui else {
            return isUsePadCommment ? .embed : .card
        }
        var contentWidth = ui.hostView.bounds.width
        if  to != .zero,
            to.width > 100 { // 传过来的to有时不准确😰
            contentWidth = to.width
        }
        if isUsePadCommment, contentWidth >= 630 {
            return .embed
        } else {
            return .card
        }
    }
}

// MARK: notification

extension CommentShowCardsService {
    
    func addNotification() {
        // 锁屏的时候，会触发browserDidAppear，这时获取的View宽度不正确，导致告知前端的style不准确
        // 需要在解锁屏幕的时候再调用一次 😰
        // block方式的通知需要手动移除
        let activeNoti = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.appIsResignActive = false
            self.switchStyleIfNeed()
        }
        
        let resignActiveNoti = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.appIsResignActive = true
        }
        notiTables.add(activeNoti)
        notiTables.add(resignActiveNoti)
    }
}

// MARK: - 重构后走这里

extension CommentShowCardsService {
    
    func showAsideComment(commentData: CommentData) {
        if asideDataQueue.actionClosure == nil {
            asideDataQueue.actionClosure = { [weak self] node in
                self?.handleShowAsideCommentTask(node: node)
            }
        }
        asideDataQueue.appendAction(.showCard(commentData))
    }
    
    private func handleShowAsideCommentTask(node: CommentDataQueueNode<DataAction>) {
        guard let commentPadDisplayer = self.ui?.commentPadDisplayer else {
            return
        }
        switch node.action {
        case let .showCard(commentData):
            
            var animateComplete: (() -> Void)?
            let animated = commentPadDisplayer.presentCommentView(commentView: asideCommentModule?.commentPluginView ?? UIView(), forceVisible: false) {
                animateComplete?()
            }
            let comment = commentData.comments.first { $0.isNewInput }
            if animated,
               let newInputComment = comment { // 新增需要等动画完成再激活输入框，否则无法显示焦点
                DocsLogger.info("show asideComment delay newInput data", component: LogComponents.comment)
                newInputComment.permission.insert(.disableAutoActiveKeyboard)
                animateComplete = { [weak self] in
                    let otherCommentData = self?.parseCommentModel(params: commentData.paylod)
                    otherCommentData?.currentCommentPos = nil // 只是为了刷新输入框，不需要传入高度
                    otherCommentData?.currentReplyID = nil
                    if !commentData.paylod.isEmpty,
                       let data = otherCommentData {
                        self?.setupAsideTimestamp(commentData: data, isNewInput: true)
                        self?.asideCommentModule?.update(data)
                    }
                    node.markFulfill()
                }
                setupAsideTimestamp(commentData: commentData, isNewInput: false)
                _showAsideComment(commentData: commentData)
            } else {
                setupAsideTimestamp(commentData: commentData, isNewInput: comment != nil)
                DocsLogger.info("show asideComment update directyly", component: LogComponents.comment)
                _showAsideComment(commentData: commentData)
                node.markFulfill()
            }
        }
    }

    private func _showAsideComment(commentData: CommentData) {
        if let templateUrl = self.commentTemplateUrl {
            self.asideCommentModule?.updateCopyTemplateURL(urlString: templateUrl)
        }
        asideCommentModule?.update(commentData)
        let hostCaptureAllowed = model?.permissionConfig.hostCaptureAllowed ?? false
        asideCommentModule?.setCaptureAllowed(hostCaptureAllowed)
    }
    
    private func setupAsideTimestamp(commentData: CommentData, isNewInput: Bool) {
        // 前端会返回多次，只有高亮的评论才需要主动加时间戳
        let loadEnable = SettingConfig.commentPerformanceConfig?.loadEnable == true
        guard commentData.currentCommentID != nil, loadEnable else { return }
        
        let recordedEdit = commentStatsExtra?.recordedEdit == true
        if commentData.statsExtra == nil,
           var statsExtra = self.commentStatsExtra,
           !recordedEdit {
            if statsExtra.receiveTime == nil {
                statsExtra.generateReceiveTime()
            }
            if statsExtra.keepUtilEdit == true { // 不仅仅要上报加载耗时，也要上报可编辑耗时
                if !isNewInput { // 可能只需要上报render或者不需要上报
                    if statsExtra.recordedRender == nil || statsExtra.recordedRender == false {
                        commentData.statsExtra = statsExtra
                        self.commentStatsExtra?.markRecordedRender()
                    }
                } else {
                    commentData.statsExtra = statsExtra
                    let callback = DocsJSService.simulateClearCommentEntrance.rawValue
                    self.model?.jsEngine.simulateJSMessage(callback, params: [:])
                }
            } else { // 仅上报加载耗时
                commentData.statsExtra = statsExtra
                commentData.statsExtra?.markRecordedEdit()
                let callback = DocsJSService.simulateClearCommentEntrance.rawValue
                self.model?.jsEngine.simulateJSMessage(callback, params: [:])
            }
        }
    }
}
