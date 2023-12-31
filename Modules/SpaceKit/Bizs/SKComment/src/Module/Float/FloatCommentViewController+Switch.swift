//
//  FloatCommentViewController+Switch.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/12.
//  


import SKFoundation

// 评论翻页切换逻辑

extension FloatCommentViewController {
    
    func preloadComment() {
        prepareLoadNextTableView()
        prepareLoadPreTableView()
    }
    
    func prepareLoadPreTableView() {
        if let pre = commentSections[CommentIndex(page - 1)] {
            preCommentView.update(pre)
            preCommentView.reloadView(force: false)
        }
    }
    
    func prepareLoadNextTableView() {
        if let next = commentSections[CommentIndex(page + 1)] {
            nextCommentView.update(next)
            nextCommentView.reloadView(force: false)
        }
    }
    
    func goPre(page: Int) {
        guard let comment = commentSections[CommentIndex(page)] else {
            DocsLogger.error("goPre error currentPage:\(page) out of rangge", component: LogComponents.comment)
            return
        }
        currentCommentView.readyForPrePage()
        preCommentView.update(comment)
        preCommentView.reloadView()
        _switchPage(currentCommentView, preCommentView, .pre) { [weak self] in
            guard let self = self else { return }
            self.viewInteraction?.emit(action: .didEndDragging)
            DocsLogger.info("goPre complete currentPage:\(page)", component: LogComponents.comment)
            let temp = self.currentCommentView
            self.currentCommentView = self.preCommentView
            self.preCommentView = temp
            let viewHeight = self.view.frame.size.height
            let height = viewHeight - self.currentCommentView.topInset
            self.viewInteraction?.emit(action: .switchCard(commentId: comment.commentID, height: height))
            self.preloadComment()
        }
    }
    
    func goNext(page: Int) {
        guard let nextComment = commentSections[CommentIndex(page)] else {
            DocsLogger.error("goNext error currentPage:\(page) out of rangge", component: LogComponents.comment)
            return
        }
        currentCommentView.readyForNextPage()
        nextCommentView.update(nextComment)
        nextCommentView.reloadView()
        _switchPage(currentCommentView, nextCommentView, .next) { [weak self] in
            guard let self = self else { return }
            self.viewInteraction?.emit(action: .didEndDragging)
            DocsLogger.info("goNext complete currentPage:\(page)", component: LogComponents.comment)
            let temp = self.currentCommentView
            self.currentCommentView = self.nextCommentView
            self.nextCommentView = temp
            let viewHeight = self.view.frame.size.height
            let height = viewHeight - self.currentCommentView.topInset
            self.viewInteraction?.emit(action: .switchCard(commentId: nextComment.commentID, height: height))
            self.preloadComment()
        }
    }
    
    enum SwitchDireaction {
        case pre
        case next
    }
    
    private func _switchPage(_ from: FloatCommentView, _ to: FloatCommentView, _ direction: SwitchDireaction, _ completion: @escaping (() -> Void)) {
        var contentHeight: CGFloat = self.commentContainerView.frame.size.height
        contentHeight = contentHeight > 0 ? contentHeight : self.view.frame.size.height

        from.isActive = false
        to.isActive = false
        
        from.isUserInteractionEnabled = false
        to.isUserInteractionEnabled = false
        
        // 确保滚动前to在正确的位置
        to.alpha = 0
        to.resetPosition()
        to.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(direction == .next ? contentHeight : -contentHeight)
        }
        self.view.layoutIfNeeded()
        
        // 动画的位置
        
        from.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(direction == .next ? -contentHeight : contentHeight)
        }

        to.clipsToBounds = true
        to.snp.updateConstraints { (make) in
            make.top.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.4, animations: {
            from.alpha = 0
            to.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: {_ in
            from.resetPosition()
            to.resetPosition()
            to.switchComplete()
            from.snp.updateConstraints { (make) in
                if from.superview != nil { // 防止异步crash
                    make.top.equalToSuperview()
                }
            }
            to.isActive = true
            to.isUserInteractionEnabled = true
            to.clipsToBounds = false
            completion()
        })
    }
}
