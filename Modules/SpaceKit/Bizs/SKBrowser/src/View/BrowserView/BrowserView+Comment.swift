//
//  BrowserView+Comment.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2022/2/18.
//

import SKFoundation
import SKCommon

extension BrowserView: CommentPadDisplayer {
    //forceVisible背景:
    //如果webview没有didfinish前，改版webview大小会导致webview的zoomscale变化，导致字体变小现象
    //所以这里增加个逻辑，如果webview还没didfinish前端被调用presentCommentView，那么先不visible，隐藏在最右边，等finish后通过makeCommentVisibleIfNeed的调用在变成visible
    public func presentCommentView(commentView: UIView, forceVisible: Bool, complete: @escaping () -> Void) -> Bool {
        if commentView != commentViewPad, commentViewPad?.superview != nil {
            commentViewPad?.removeFromSuperview()
        }
        commentViewPad = commentView
        let needPresent = commentView.isHidden || commentViewDismissing || forceVisible
        if commentViewPad?.superview != self {
            addSubview(commentView)
        }

        if needPresent == false {
            DocsLogger.info("isPresenting, return, commentViewDismissing=\(commentViewDismissing)", component: LogComponents.comment)
            complete()
            return false
        } else {
            commentView.isHidden = false
            
            editorWrapperView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(ipadCatalogContainWidth)
                make.right.top.bottom.equalToSuperview()
            }
            
            if let commentViewPadBottomView = commentViewPadBottomView {
                if commentViewPadBottomView.superview != self {
                    commentViewPadBottomView.removeFromSuperview()
                    addSubview(commentViewPadBottomView)
                }
                commentView.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview()
                    make.bottom.equalTo(commentViewPadBottomView.snp.top)
                    make.left.equalTo(editorWrapperView.snp.right)
                    make.width.equalTo(commentViewWidth)
                }
            } else {
                commentView.snp.remakeConstraints { (make) in
                    make.top.bottom.equalToSuperview()
                    make.left.equalTo(editorWrapperView.snp.right)
                    make.width.equalTo(commentViewWidth)
                }
            }
            self.layoutIfNeeded()

            if forceVisible || canCommentVisible {
                editorWrapperView.snp.remakeConstraints { (make) in
                    make.left.equalToSuperview().offset(ipadCatalogContainWidth)
                    make.right.equalTo(commentView.snp.left)
                    make.top.bottom.equalToSuperview()
                }
                if let commentViewPadBottomView = commentViewPadBottomView, commentViewPadBottomView.superview == commentView.superview {
                    commentView.snp.remakeConstraints { (make) in
                        make.top.right.equalToSuperview()
                        make.bottom.equalTo(commentViewPadBottomView.snp.top)
                        make.width.equalTo(commentViewWidth)
                    }
                } else {
                    commentView.snp.remakeConstraints { (make) in
                        make.top.bottom.right.equalToSuperview()
                        make.width.equalTo(commentViewWidth)
                    }
                }
                commentViewPresenting = true
                UIView.animate(withDuration: commentViewAnimationDuration, animations: {
                    self.layoutIfNeeded()
                }, completion: { _ in
                    self.commentViewPresenting = false
                    commentView.isHidden = false
                    self.simulateJSMessage(DocsJSService.simulateCommentStateChange.rawValue, params: [:])
                    complete()
                })
                return true
            } else {
                commentView.isHidden = false
                simulateJSMessage(DocsJSService.simulateCommentStateChange.rawValue, params: [:])
                complete()
                return false
            }
        }
    }

    public func dismissCommentView(animated: Bool, complete: @escaping () -> Void) {
        DocsLogger.info("\(editorIdentity) dismissPadCommentView", component: LogComponents.comment)
        if let commentView = commentViewPad,
           commentView.superview != nil,
           commentViewDismissing == false {

            commentView.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(editorWrapperView.snp.right)
                make.width.equalTo(commentViewWidth)
            }
            editorWrapperView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(ipadCatalogContainWidth)
                make.right.top.bottom.equalToSuperview()
            }

            commentViewDismissing = true
            let duration: TimeInterval = animated ? commentViewAnimationDuration : 0
            UIView.animate(withDuration: duration, animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.commentViewDismissing = false
                self.commentViewPad?.isHidden = true
                self.simulateJSMessage(DocsJSService.simulateCommentStateChange.rawValue, params: [:])
                complete()
           })
        }
    }

    public func resetCommentView() {
        if let commentView = commentViewPad,
           commentView.superview != nil {
            commentView.isHidden = true
            commentView.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(editorWrapperView.snp.right)
                make.width.equalTo(commentViewWidth)
            }
            editorWrapperView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(ipadCatalogContainWidth)
                make.right.top.bottom.equalToSuperview()
            }
            DocsLogger.info("\(editorIdentity) reset commentView", component: LogComponents.comment)
        }
    }

    public func removePadCommentView() {
        resetCommentView()
        commentViewPad?.removeFromSuperview()
        commentViewPad = nil
        commentViewPadBottomView?.removeFromSuperview()
        commentViewPadBottomView = nil
        DocsLogger.info("\(editorIdentity) remove commentView", component: LogComponents.comment)
    }

    // 尝试修改评论view的样式，如果比较窄，会采用覆盖的方式
    public func adjustCommentViewLayout() {
        if let commentView = commentViewPad,
           commentView.superview != nil,
           commentView.isHidden == false,
           commentViewDismissing == false,
           commentViewPresenting == false {
            commentView.snp.remakeConstraints { (make) in
                make.top.bottom.right.equalToSuperview()
                make.width.equalTo(commentViewWidth)
            }
            editorWrapperView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(ipadCatalogContainWidth)
                make.right.equalTo(commentView.snp.left)
                make.top.bottom.equalToSuperview()
            }
        }
    }

    func activeComment(by commentId: String) {
        if let jsService = self.jsServiceManager.fetchServiceInstance(CommentNative2JSService.self) {
            jsService.activeComment(commentId: commentId)
        }
        if let jsService = self.jsServiceManager.fetchServiceInstance(CommentShowCardsService.self) {
            jsService.canShowComment = true
        }
    }
}

extension BrowserView {
    private var canCommentVisible: Bool {
        return self.navigatorDidLoadEnd || disableCommentDelayFg
    }

    func makeCommentVisibleIfNeed() {
        if let commentViewPad = commentViewPad,
            commentViewPad.superview != nil,
            commentViewPad.isHidden == false,
           disableCommentDelayFg == false,
           commentViewDismissing == false {
            DocsLogger.info("try to make ipadComment visible")
            self.presentCommentView(commentView: commentViewPad, forceVisible: true) {
            }
        }
    }
}
