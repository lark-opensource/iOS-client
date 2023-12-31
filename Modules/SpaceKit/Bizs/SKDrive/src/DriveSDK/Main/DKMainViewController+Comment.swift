//
//  DKMainViewController+Comment.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/24.
//

import Foundation
import LarkSuspendable
import SKCommon
import SKFoundation
import SKUIKit

extension DKMainViewController {

    enum Const {
        static let animateDuration = 0.25
        static let resizeContentAsyncAfterTime = 0.3
    }

    func setupBottomView() {
        if commentBar.superview != nil { return }
        view.addSubview(commentBar)
        view.addSubview(bottomPlaceHolderView)
        commentBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.bottomPlaceHolderView.snp.top)
            make.height.equalTo(self.commentBar.preferHeight)
        }
        let bottomOffset = self.view.safeAreaInsets.bottom + commentBar.preferHeight
        bottomPlaceHolderView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(self.view.safeAreaInsets.bottom)
            // 初始化时将commentBar 和 底部占位 view 移出屏幕范围
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(bottomOffset)
        }
        fileView?.mainViewController = self
        if let cell = collectionView?.cellForItem(at: IndexPath(item: self.viewModel.curIndex, section: 0)) as? DKFileCell {
            cell.fileView.mainViewController = self
        }
    }

    func updateCommentBar(hiddenByPermission: Bool) {
        bottomBarHideByPermission = hiddenByPermission
    }
    
    func showCommentBar(_ shouldShow: Bool, animate: Bool) {
        // 现在非space文件不会setupBottomView，所以需要判断是否已经添加了commentBar
        guard commentBar.superview != nil, bottomPlaceHolderView.superview != nil else {
            DocsLogger.driveInfo("DKMainViewController --: commentBar not show")
            return
        }
        let canShow = canShowCommentBar()
        let isShow = shouldShow && !isInFullScreen && canShow
        DocsLogger.driveInfo("uiState: showCommentBar: \(isShow)",
                             extraInfo: ["shouldShow": shouldShow, "isInFullScreen": isInFullScreen])
        // 如果当前状态没改变，则不再reset
        if commentBarIsShow == isShow {
            return
        }
        self.commentBarIsShow = isShow
        let bottomOffset: CGFloat
        if isShow {
            bottomOffset = 0
        } else {
            bottomOffset = view.safeAreaInsets.bottom + commentBar.preferHeight
        }
        bottomPlaceHolderView.snp.updateConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(bottomOffset)
            make.height.equalTo(self.view.safeAreaInsets.bottom)
        }
        commentBar.snp.updateConstraints { (make) in
            make.height.equalTo(self.commentBar.preferHeight)
        }
        // 先展示再开始动画
        if isShow {
            self.commentBar.isHidden = !isShow
        }
        let duration = animate ? Const.animateDuration : 0.0
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (_) in
            self.commentBar.isHidden = !isShow
        })
    }
    
    func updateCommentBarForSafeAreaUpdated() {
        // 没有展示commenbar时不需要处理bottomPlaceHolderView
        guard bottomPlaceHolderView.superview != nil else { return }
        let bottomOffset: CGFloat
        if commentBarIsShow {
            bottomOffset = 0
        } else {
            bottomOffset = view.safeAreaInsets.bottom + commentBar.preferHeight
        }
        // 更新底部安全区域高度
        bottomPlaceHolderView.snp.updateConstraints { make in
            make.height.equalTo(self.view.safeAreaInsets.bottom)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(bottomOffset)
        }
    }
    
    func dismissCommentVCIfNeeded() {
        let commentModule = viewModel.hostModule?.commentManager?.commentModule
        commentModule?.hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + Const.resizeContentAsyncAfterTime) {[weak self] in
            self?.resizeContentViewIfNeed(nil)
        }
    }
    
    func dismissMessagePanelIfNeeded() {
        if let feedVC = self.presentedViewController as? FeedPanelViewControllerType {
            feedVC.dismiss(animated: false) { [weak self] in
                self?.resizeContentViewIfNeed(nil)
            }
        }
    }

    func resizeContentViewIfNeed(_ height: CGFloat?) {
        guard let areaCommentProtocol = self.children.first as? DriveSupportAreaCommentProtocol, areaCommentProtocol.commentSource == .image else {
            let shouldHide = displayMode == .card || isInFullScreen
            DocsLogger.driveInfo("setNavibarHidden: \(shouldHide)\(isInFullScreen) ")
            setNavibarHidden(isHidden: shouldHide, animated: false)
            setStatusBar(isHidden: shouldHide)
            return
        }
        _ = areaCommentProtocol.areaDisplayView()
        // 局部评论弹起评论框隐藏navbar
        var shouldHide = height != nil
        if displayMode == .card || isInFullScreen {
            // 卡片模式/全屏态下隐藏评论和导航栏
            shouldHide = true
        }
        setNavibarHidden(isHidden: shouldHide, animated: false)
        setStatusBar(isHidden: shouldHide)
        commentBar.isHidden = shouldHide
        let mockCommentBarHeight: CGFloat
        if let height = height {
            // 评论VC的高度包括了底部安全距离，需要减去
            mockCommentBarHeight = height - bottomPlaceHolderView.frame.height
        } else {
            mockCommentBarHeight = commentBar.preferHeight
        }
        commentBar.snp.updateConstraints { (make) in
            make.height.equalTo(mockCommentBarHeight)
        }
        UIView.animate(withDuration: Const.animateDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func canShowCommentBar() -> Bool {
        let orientation = LKDeviceOrientation.convertMaskOrientationToDevice(UIApplication.shared.statusBarOrientation)
        // 手机横屏下不支持评论
        if orientation.isLandscape && SKDisplay.phone {
            return false
        }
        // 特定场景下不能展示（IM、附件等不支持评论场景）
        guard viewModel.shouldShowCommentBar else { return false }
        if viewModel.previewUIStateManager.previewUIState.value.isBottomBarHidden {
            // 被预览业务禁用
            return false
        }
        // 无权限时禁止展示，避免因时序问题被业务方展示出来
        if bottomBarHideByPermission { return false }
        return true
    }
}
