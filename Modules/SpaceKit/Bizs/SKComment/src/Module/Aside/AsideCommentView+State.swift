//
//  AsideCommentView+State.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/26.
//  


import Foundation
import SKFoundation
import SKUIKit
import UniverseDesignToast
import SpaceInterface
import EENavigator
import SKCommon

extension AsideCommentView {
    
    // swiftlint:disable cyclomatic_complexity
    func handleState(_ state: CommentState) {
        switch state {
        case let .updateDocsInfo(info):
            self.docsInfo = info
            self.scrollFollowHandler?.updateDocsInfo(info)
            
        case let .updatePermission(permission):
            self.commentPermission = permission
            
        case let .loading(show):
            showLoading(show: show)
            
        case .reload:
            handleReload()
            
        case let .updateItems(idxs):
            handleUpdateItems(idxs)
            
        case let .updateSections(sections):
            handleUpdateSections(sections)
            
        case let .diffResult(data, indexPaths):
            updateDiff(data, indexPaths)
            
        case let .syncData(data):
            self.commentSections = data
            if commentSections.activeComment == nil {
                lastCallBackHeight = nil
            }
            
        case .locateReference:
            preReference = findReferenceVisibleRow()
            
        case .keepStill:
            tableView.layoutIfNeeded()
            recoverReferencePosition()
            
        case .batchUpdatesCompletion:
            tvReloading = false
            
        case let .keepInputVisiable(indexPath, force):
            if tableView.indexPathsForVisibleRows?.contains(indexPath) == false {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                if force {
                    tableView.layoutIfNeeded()
                }
            } else {
                DocsLogger.info("indexPath is visible now", component: LogComponents.comment)
            }
        case let .align(indexPath, position):
            handleAlign(indexPath, position)
            
        case let .ensureInScreen(indexPath):
            scrollInScreen(indexPath)
            
        case let .scrollAboveKeyboard(toIndexPath, keyboardFrame, inset, duration):
            handleScrollAboveKeyboard(toIndexPath, keyboardFrame, inset, duration)
            
        case .listenKeyboard:
            // 监听键盘快捷键
            becomeFirstResponder()
            
        case let .forceInputActiveIfNeed(at):
            handleForceInputActiveIfNeed(at)
            
        case let .refreshAtUserText(at):
            handleRefreshAtUserText(at)
            
        case let .updateTitle(title):
            headerView.commentLabel.text = title
            
        case let .toast(hud):
            handleToast(hud)
            
        case let .scrollToItem(indexPath, percent):
            handleScrollToItem(indexPath, percent)

        case let .showUserProfile(userId, from):
            if let nav = from { // 优先使用指定了的导航
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: nav))
            } else if let topMost = dependency?.browserVCTopMost{
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: topMost))
            }
            
        case let .openDocs(url):
            guard let topMost = dependency?.browserVCTopMost else {
                return
            }
            Navigator.shared.push(url, from: topMost)

        case let .setCopyAnchorLinkEnable(enable):
            self.copyAnchorLinkEnable = enable
            
        case let .setTranslateConfig(config):
            self.translateConfig = config

        default:
            break
        }
    }
    
    func handleToast(_ hud: CommentState.HUD) {
        let on: UIView = self.window ?? self
        switch hud {
        case .success(let msg):
            UDToast.showSuccess(with: msg, on: on)
        case .failure(let msg):
            UDToast.showFailure(with: msg, on: on)
        case .tips(let msg):
            UDToast.showTips(with: msg, on: on)
        }
    }
}

// MARK: - reload

extension AsideCommentView {
    func handleUpdateSections(_ sections: [Int]) {
        scrollFollowHandler?.stopMonitoring()
        tvReloading = true
        clearCellCache(sections: sections)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tableView.reloadSections(IndexSet(sections), with: .none)
        tableView.layoutIfNeeded()
        CATransaction.commit()
        tvReloading = false
    }
    
    func handleUpdateItems(_ idxs: [IndexPath]) {
        scrollFollowHandler?.stopMonitoring()
        tvReloading = true
        clearCellCache(indexPaths: idxs)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tableView.reloadRows(at: idxs, with: .none)
        tableView.layoutIfNeeded()
        CATransaction.commit()
        tvReloading = false
    }
    
    func handleReload() {
        scrollFollowHandler?.stopMonitoring()
        tvReloading = true
        tableView.clearHeightCache()
        newHeightCacheKey.removeAll()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tvReloading = false
    }
    
}

// MARK: - align

extension AsideCommentView {
    
    func recoverReferencePosition() {
        // 如果没有调整位置，但是因为增删改导致当前显示的评论发生移动，则需要重制保持原位
        if let reference = preReference {
            DocsLogger.info("resetCellPosition after adjustCommentToPosision", component: LogComponents.comment)
            resetCellPosition(commentId: reference.0, bottom: reference.1)
            tableView.layoutIfNeeded()
        }
    }
    
    func handleAlign(_ indexPath: IndexPath, _ position: CGFloat?) {
        guard let comment = commentSections[CommentIndex(indexPath.section)] else {
            return
        }
        scrollFollowHandler?.commentBecomActivated(comment: comment)
        adjustToPosision(indexPath, position) { [weak self] callBackHeight in
            self?.lastCallBackHeight = callBackHeight
            self?.viewInteraction?.emit(action: .switchCard(commentId: comment.commentID, height: callBackHeight))
        }
        scrollFollowHandler?.updateActiveComment(comment)
    }
    
    func adjustToPosision(_ page: IndexPath, _ position: CGFloat?, complete: @escaping (CGFloat) -> Void) {
        guard page.section >= 0,
              page.section < commentSections.count else {
            DocsLogger.error("adjustPosision page =\(page) count=\(commentSections.count)", component: LogComponents.comment)
            return
        }
        let destCellPath = IndexPath(row: 0, section: page.section)
        let visibleRows = tableView.indexPathsForVisibleRows ?? []
        if !visibleRows.contains(destCellPath) {
            DocsLogger.info("[set contentOffset] make sure cell visible", component: LogComponents.comment)
            tableView.scrollToRow(at: destCellPath, at: .top, animated: false)
            tableView.layoutIfNeeded()
        }
        // 前端告诉我们卡片应该定位到那个位置
        if let position = position {
            let destOffset = alignCommentCell(indexPath: destCellPath, bottom: position)
            DocsLogger.info("[set contentOffset] [self adjust 1] adjustPosision offset:\(destOffset)", component: LogComponents.comment)
        }

        let selfHeight = self.frame.size.height

        // 前端告诉我们位置之后，卡片如果超出顶部或者超出底部太多， 需要调整卡片的位置到可视范围
        // 调整了之后也需要告诉前端当前卡片的位置(正文高亮的位置也需要做相应的调整)
        let groupCellRect = self.tableView.rect(forSection: page.section)
        let groupCellInSelf = self.tableView.convert(groupCellRect, to: self)
        let bottomOffset = groupCellInSelf.maxY - selfHeight // 超出底部的高度
        let topOffset = -(groupCellInSelf.origin.y - Layout.topHeaderHeight) // 超出顶部的高度
        let unVisableInTop = (groupCellInSelf.maxY - Layout.topHeaderHeight) <= 0
        let unVisableInBottom = groupCellInSelf.origin.y >= selfHeight

        let currentOffsetY = self.tableView.contentOffset.y
        
        let defaultPositionFromTop = selfHeight * ratioAnchorPosition
        let defaultOffsetY: CGFloat = groupCellRect.origin.y - defaultPositionFromTop
        
        DocsLogger.info("frame=\(self.frame), groupCellInSelf=\(groupCellInSelf), currentOffsetY=\(currentOffsetY)", component: LogComponents.comment)
        var destiOffsetY: CGFloat = currentOffsetY
        if unVisableInTop || unVisableInBottom { // 完全在屏幕外不可见，定位到中间靠上的默认位置
            DocsLogger.info("adjustPosision total invisible, unVisableInTop=\(unVisableInTop), unVisableInBottom=\(unVisableInBottom) willTo=\(defaultOffsetY)", component: LogComponents.comment)
            destiOffsetY = defaultOffsetY
        } else if bottomOffset > 0 || topOffset > 0 { // 漏一半
            DocsLogger.info("adjustPosision half invisible, topOffset=\(topOffset), bottomOffset=\(bottomOffset), willTo=\(defaultOffsetY), page=\(page.section)", component: LogComponents.comment)
            if topOffset > 0 && (topOffset < 40 || page.section == 0) {
                destiOffsetY = currentOffsetY - topOffset - initContentOffsetY
                DocsLogger.info("top invisible", component: LogComponents.comment)
            } else if bottomOffset > 0 && bottomOffset < 40 {
                // 底部被遮挡，往上移动时候顶部也不会显示不全
                if topOffset < 0, // 上面还有位置
                   bottomOffset < -topOffset {
                    destiOffsetY = currentOffsetY + bottomOffset
                    DocsLogger.info("bottom invisible", component: LogComponents.comment)
                } else {
                    DocsLogger.info("no space for bottom", component: LogComponents.comment)
                }
            } else {
                destiOffsetY = defaultOffsetY
                DocsLogger.info("adjust default position", component: LogComponents.comment)
            }
        } else {
            DocsLogger.info("adjustPosision current position is legal", component: LogComponents.comment)
        }
             
        debounce.endDebounce()
        if destiOffsetY <= -initContentOffsetY {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            destiOffsetY = -initContentOffsetY
            DocsLogger.info("[set contentOffset] [self adjust 2]  offset:\(destiOffsetY)", component: LogComponents.comment)
        } else {
            self.tableView.setContentOffset(CGPoint(x: 0, y: destiOffsetY), animated: false)
            DocsLogger.info("[set contentOffset] [self adjust 2]  offset:\(destiOffsetY)", component: LogComponents.comment)
        }
        self.tableView.layoutIfNeeded()
        
        // 刷新后还需要判断是否准确定位到相应的位置
        
        let realOffset = self.tableView.contentOffset.y
        let offsetDelta = abs((realOffset - destiOffsetY))
        if offsetDelta > 10 {
            // delta 误差太大需要再矫正
            DocsLogger.error("[set contentOffset] setOffset error offset target:\(destiOffsetY) real:\(realOffset)", component: LogComponents.comment)
            self.tableView.setContentOffset(CGPoint(x: 0, y: destiOffsetY), animated: false)
            self.tableView.layoutIfNeeded()
        }
        // 回调高度
        let groupCellInSelfAfter = self.tableView.convert(groupCellRect, to: self)
        let callBackHeight = selfHeight - groupCellInSelfAfter.minY
        let msg = "adjustPosision done callBackHeight =\(callBackHeight), offset=\(self.tableView.contentOffset)"
        DocsLogger.info(msg, component: LogComponents.comment)
        CommentDebugModule.log(msg)
        complete(callBackHeight)
    }
}

// MARK: - keyboard & Text
extension AsideCommentView {
    
    func keyboard(change option: Keyboard.KeyboardOptions, textView: AtInputTextView, item: CommentItem) {
        viewInteraction?.emit(action: .asideKeyboardChange(options: option, item: item))
        let event = option.event
        guard let commentEvent = CommentKeyboardOptions.KeyboardEvent.convertKeyboardEvent(event) else {
            return
        }
        let commentOption = CommentKeyboardOptions(event: commentEvent,
                                              beginFrame: option.beginFrame,
                                              endFrame: option.endFrame,
                                              animationCurve: option.animationCurve,
                                              animationDuration: option.animationDuration)
        if event == .didShow {
            showKeyBoardBlankView()
            dependency?.keyboardChange(didTrigger: commentEvent, options: commentOption, textViewHeight: textView.contentHeight)
        } else if event == .willHide || event == .didHide {
            hideKeyBoardBlankView()
            dependency?.keyboardChange(didTrigger: commentEvent, options: commentOption, textViewHeight: textView.contentHeight)
        }
    }
    
    func textViewDidBeginEditing(_ textView: AtInputTextView) {
        viewInteraction?.emit(action: .textViewDidBeginEditing(textView))
    }
    
    func textViewDidEndEditing(_ textView: AtInputTextView) {
        hideKeyBoardBlankView()
        viewInteraction?.emit(action: .textViewDidEndEditing(textView))
    }

    /// 滚动屏幕外输入框到可视范围
    func scrollInScreen(_ indexPath: IndexPath) {
        let visibleRows = self.tableView.indexPathsForVisibleRows ?? []
        let rows = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        var desIndexPath = indexPath
        if indexPath.row == -1 { // 传过来的只有section
            desIndexPath = IndexPath(row: rows - 1, section: indexPath.section)
        }
        guard visibleRows.contains(desIndexPath) == false else {
            return
        }
        DocsLogger.info("scroll tableView to: \(desIndexPath)", component: LogComponents.comment)
        UIView.animate(withDuration: 0.2) {
            self.tableView.scrollToRow(at: desIndexPath, at: .bottom, animated: false)
        }
    }
    
    private func setupTableViewBootimInset(inset: CGFloat, duration: Double, completion: @escaping (() -> Void)) {
        if self.tableView.contentInset.bottom == inset {
            completion()
        } else {
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions.curveLinear) { [weak self] in
                guard let self = self else { return }
                var changeInset = self.tableView.contentInset
                changeInset.bottom = inset
                self.tableView.contentInset = changeInset
            } completion: { _ in
                completion()
            }
        }
        
    }
    private func handleScrollAboveKeyboard(_ toIndexPath: IndexPath,
                                           _ endFrame: CGRect,
                                           _ inset: CGFloat,
                                           _ duration: Double) {
        
        setupTableViewBootimInset(inset: inset, duration: duration) { [weak self] in
            guard let self = self else { return }
            guard self.commentSections[toIndexPath] != nil else {
                DocsLogger.warning("toIndexPath:\(toIndexPath) is overflow", component: LogComponents.comment)
                return
            }
            let pointKeyboardInWindow = CGPoint(x: endFrame.origin.x, y: endFrame.origin.y)
            let pointInSelfView = self.convert(pointKeyboardInWindow, from: self.window)
            let rectOfPath = self.tableView.rectForRow(at: toIndexPath)
            let rectOfPathInSelf = self.tableView.convert(rectOfPath, to: self)
            let cellAndKeyBoardDistance = pointInSelfView.y - rectOfPathInSelf.maxY
            DocsLogger.info("curOffset:\(self.tableView.contentOffset.y) cell-KeyBoard distance: \(cellAndKeyBoardDistance) endFrame: \(endFrame)", component: LogComponents.comment)
            if cellAndKeyBoardDistance > 10, rectOfPathInSelf.minY > 10 {
                // 不需要处理
            } else {
                // 激活的cell超出顶部过多
                self.tableView.scrollToRow(at: toIndexPath, at: .bottom, animated: false)
                DocsLogger.info("scrollTabaleView setOffset:\(self.tableView.contentOffset.y)", component: LogComponents.comment)
            }
        }
    }
    
    private func handleForceInputActiveIfNeed(_ at: IndexPath) {
        guard let cell = textInputCell(at) else {
            DocsLogger.info("textInputCell at:\(at) not found", component: LogComponents.comment)
            return
        }
        cell.textViewActiveWorkItem?.cancel()
        cell.textView?.textviewBecomeFirstResponder()
    }
    
    private func handleRefreshAtUserText(_ at: IndexPath) {
        guard let cell = textInputCell(at) else {
            DocsLogger.info("textInputCell at:\(at) not found", component: LogComponents.comment)
            return
        }
        cell.textView?.refreshAtUserTextPermission(needToastFor: nil)
    }
    
    private func textInputCell(_ at: IndexPath) -> CommentTextInputCellType? {
        guard let cell = tableView.cellForRow(at: at) else {
            DocsLogger.info("cellForRow is nil", component: LogComponents.comment)
            return nil
        }
        if let cell = cell as? CommentTextInputCellType {
            return cell
        } else {
            DocsLogger.error("cell convert fail", component: LogComponents.comment)
            return nil
        }
    }
}

// MARK: - 点击空白下掉键盘
extension AsideCommentView {
    
    func showKeyBoardBlankView() {
        DocsLogger.info("show keyBoard blankView", component: LogComponents.comment)
        keyboardBlankView.removeFromSuperview()
        keyboardBlankView.isHidden = false
        let rootView = findRootContentView()
        if let rootView = rootView {
            rootView.addSubview(keyboardBlankView)
            rootView.bringSubviewToFront(keyboardBlankView)
            keyboardBlankView.snp.makeConstraints { make in
                make.top.left.bottom.equalToSuperview()
                make.right.equalToSuperview().inset(self.bounds.size.width)
            }
        }
    }
    
    func hideKeyBoardBlankView() {
        DocsLogger.info("hide keyBoard blankView", component: LogComponents.comment)
        keyboardBlankView.removeFromSuperview()
        keyboardBlankView.isHidden = true
    }
    
    @objc
    func tapBlankView(_ gesture: UIGestureRecognizer) {
        hideKeyBoardBlankView()
        viewInteraction?.emit(action: .tapBlank)
    }
    
    @objc
    func panBlankView(_ gesture: UIGestureRecognizer) {
        hideKeyBoardBlankView()
        viewInteraction?.emit(action: .tapBlank)
    }
    
    private func findRootContentView() -> UIView? {
        var targetView: UIView? = self.superview
        while targetView != nil {
            if targetView is CommentPadDisplayer {
                return targetView
            }
            targetView = targetView?.superview
        }
        return nil
    }
}
