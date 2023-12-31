//
//  CommentShowCardsService+iPhone.swift
//  SKBrowser
//
//  Created by huayufan on 2021/7/4.
//  
//  swiftlint:disable: file_length function_body_length


import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface


extension CommentShowCardsService {
    
    var isPhoneCommmentShowing: Bool {
        return _floatCommentModule?.isVisiable ?? false
    }
}

extension CommentShowCardsService {
    
    func closeFeedIfNeed(_ complete: @escaping () -> Void) {
        if let feedVC = self.navigator?.presentedVC as? FeedPanelViewControllerType {
            DocsLogger.info("close feed panel", component: LogComponents.comment)
            notificateFrontendToHideFeed()
            feedVC.dismiss(animated: false) {
                DocsLogger.info("present comment after dismissing", component: LogComponents.comment)
                complete()
            }
        } else {
            complete()
        }
    }
    
    func showFloatComment(with commentData: CommentData) {
        NotificationCenter.default.post(name: Notification.Name.DismissPanelBeforeShowComment, object: self.editorIdentity)
        if commentData.statsExtra == nil,
        var statsExtra = self.commentStatsExtra {
            statsExtra.generateReceiveTime()
            commentData.statsExtra = statsExtra
            let callback = DocsJSService.simulateClearCommentEntrance.rawValue
            self.model?.jsEngine.simulateJSMessage(callback, params: [:])
        }
        commentData.statsExtra?.markRecordedEdit()
        if canShowComment {
            closeFeedIfNeed { [weak self] in
                guard let self = self else { return }
                let isVisiable = self.floatCommentModule?.isVisiable ?? false
                if !isVisiable {
                    self.topMostOfBrowserVCWithoutDismissing { [weak self] topMost in
                        guard let topMostVC = topMost,
                              let self = self else {
                            DocsLogger.error("topMost is nil",
                                             component: LogComponents.comment)
                            return
                        }
                        self.floatCommentModule?.show(with: topMostVC)
                        if let templateUrl = self.commentTemplateUrl {
                            self.floatCommentModule?.updateCopyTemplateURL(urlString: templateUrl)
                        }
                        self._floatCommentModule?.canPresentingDismiss = !commentData.isInPicture
                        self.floatCommentModule?.update(commentData)
                        let hostCaptureAllowed = self.model?.permissionConfig.hostCaptureAllowed ?? false
                        self.floatCommentModule?.setCaptureAllowed(hostCaptureAllowed)
                    }
                } else {
                    self.floatCommentModule?.update(commentData)
                }
            }
        } else {
            DocsLogger.error("fail to present comment vc canShowComment:\(canShowComment)",
                            component: LogComponents.comment)
        }
    }

    func innerShowCommentViewiPhone(commentData: CommentData, params: [String: Any]) {
        // 评论传的评论数为0则收起评论
        guard !commentData.comments.isEmpty else {
            DocsLogger.info("comments.isEmpty=\(commentData.comments.count), params=\(params)", component: LogComponents.comment)
            self.dismissCommentView(completion: nil)
            return
        }
        showFloatComment(with: commentData)
    }

    func hidePhoneCommentView(_ needCancel: Bool = true, animated: Bool, completion: ((Bool) -> Void)?) {
        floatCommentModule?.hide()
        clearSuspendCommentVC()
    }
}
    
extension CommentShowCardsService {
    
    var isCommentSuspendable: Bool {
        return isInVideoConference
    }
    
    func suspendPhoneCommentVC() {
//        guard isCommentSuspendable else {
//            return
//        }
//        suppendCommentNav = self.commentNavigationController
    }
    
    func resumePhoneCommentVC() {
        guard isCommentSuspendable else {
            self.clearSuspendCommentVC()
            return
        }
        // 确保正在dimissing的topMostVC关闭之后再弹
        self.topMostOfBrowserVCWithoutDismissing {[weak self] topMost in
            guard let self = self else { return }
            guard let topMostVC = topMost else {
                DocsLogger.error("topMost is nil", component: LogComponents.comment)
                return
            }
            DocsLogger.info("presenter by topMostVC: \(topMostVC)", component: LogComponents.comment)
            if let suppendCommentNav = self.suppendCommentNav,
               !suppendCommentNav.isBeingPresented,
                suppendCommentNav.presentingViewController == nil {
                topMostVC.present(suppendCommentNav, animated: false, completion: nil)
            }
            
        }
    }
    
    func clearSuspendCommentVC() {
        self.suppendCommentNav = nil
    }
}


extension CommentShowCardsService: CommentConferenceSource {
    
    var commentConference: CommentConference {
        return conferenceInfo
    }
}
