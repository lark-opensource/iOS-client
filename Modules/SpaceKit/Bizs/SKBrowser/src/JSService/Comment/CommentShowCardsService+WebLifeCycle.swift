//
//  CommentShowCardsService+WebLifeCricle.swift
//  SKBrowser
//
//  Created by huayufan on 2021/7/4.
//  


import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface
import SKInfra

// MARK: - BrowserViewLifeCycleEvent

extension CommentShowCardsService: BrowserViewLifeCycleEvent {
    
    public func browserWillClear() {
        if iPadUseNewCommment == false {
            dismissCommentView(needCancel: true, animated: false, completion: nil)
            DocsContainer.shared.resolve(CommentTranslationToolsInterface.self)?.clear()
        }
        DocsLogger.info("\(editorIdentity) CommentShowCardsService browserWillClear", component: LogComponents.comment)
    }

    public func browserWillDismiss() {
        canShowComment = false
        DocsLogger.info("\(editorIdentity) CommentShowCardsService browserWillDismiss", component: LogComponents.comment)
    }
    
    public func browserDidDismiss() {
        DocsLogger.info("\(editorIdentity) CommentShowCardsService browserDidDismiss", component: LogComponents.comment)
        // MS场景，偶现跳转文档时由于文档控制器内存泄漏，不触发上面browserWillClear回调
        // 导致跳到下一篇文档后，上一篇文档的评论尚未关闭，需要在browserDidDismiss关闭一下
        if SKDisplay.phone,
           isInVideoConference,
           conferenceInfo.followRole != .presenter {
            dismissCommentView(needCancel: true, animated: false, completion: nil)
            DocsContainer.shared.resolve(CommentTranslationToolsInterface.self)?.clear()
        }
    }
    
    public func browserDidAppear() {
        canShowComment = true
        DocsLogger.info("\(editorIdentity) CommentShowCardsService browserDidAppear", component: LogComponents.comment)
        // 当以子窗口的方式打开时，biz.comment.getInitialStyle时机，获取不到窗口的真实宽度
        // 需要在这个时机再去检查真实的窗口大小
        switchStyleIfNeed(floatCheck: false)
    }
    
    func browserDidTransition(from: CGSize, to: CGSize) {
        delayToCheckStyle()
    }
    
    func browserDidSplitModeChange() {
        delayToCheckStyle()
    }
    
    func browserDidLayoutSubviews() {
        delayToCheckStyle()
    }
    
    /// 这些生命周期时机不太准确！需要延后处理
    func delayToCheckStyle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
            self?.switchStyleIfNeed()
        }
    }
    
    func browserWillRerender() {
        // 重新渲染之前要去掉评论高亮态，正文渲染完成后状态才能保持一致
        if iPadUseNewCommment {
            DocsLogger.info("\(editorIdentity) browserWillRerender cancelNewInput", component: LogComponents.comment)
            _asideCommentModule?.resetActive()
        }
    }
}
